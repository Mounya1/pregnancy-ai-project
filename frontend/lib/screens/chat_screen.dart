import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import '../models/food_safety_response.dart';
import '../models/nutrition_log.dart';
import '../models/history_entry.dart';
import '../models/saved_food.dart';
import '../models/user_profile.dart';
import '../services/api_client.dart';
import '../services/api_error.dart';
import '../services/local_storage_service.dart';
import '../services/nutrition_controller.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import '../widgets/safety_verdict_card.dart';
import '../widgets/ui/app_card.dart';
import '../widgets/ui/gradient_button.dart';
import '../widgets/ui/reveal.dart';
import '../widgets/nutrient_breakdown.dart';
import '../widgets/ui/typing_indicator.dart';

sealed class _ChatEntry {}

class _UserMessage extends _ChatEntry {
  final String text;
  _UserMessage(this.text);
}

class _AssistantMessage extends _ChatEntry {
  final ChatResponse response;
  final String query;
  _AssistantMessage(this.response, this.query);
}

/// A photo the user sent, shown as their side of the conversation.
class _UserPhoto extends _ChatEntry {
  final Uint8List bytes;
  _UserPhoto(this.bytes);
}

/// The answer to a photo: what it is, whether it is safe, and what is in it.
class _ScanMessage extends _ChatEntry {
  final FoodAnalysisResponse result;
  _ScanMessage(this.result);
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.profile,
    this.startWithVoice = false,
    this.startWithScan = false,
    this.initialQuestion,
  });

  final UserProfile profile;
  final bool startWithVoice;

  /// Opens the photo picker as soon as the screen appears, so "Scan" from
  /// elsewhere lands on the camera rather than on an empty chat.
  final bool startWithScan;

  /// Sent automatically as soon as the screen opens, so an entry point that
  /// already knows the question lands straight on an answer.
  final String? initialQuestion;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _api = ApiClient();
  final _storage = LocalStorageService();
  late final _tts = TtsService(baseUrl: _api.baseUrl);
  final _recorder = AudioRecorder();
  final _picker = ImagePicker();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatEntry> _entries = [];
  final Set<int> _savedEntryIndices = {};
  bool _loading = false;
  bool _voiceMode = false;
  bool _recording = false;
  StreamSubscription<Uint8List>? _recordingSub;
  final List<int> _recordedChunks = [];

  static const _starters = [
    'Is sushi safe right now?',
    'How much coffee can I have?',
    'Can I eat soft cheese?',
    'Best foods for iron?',
  ];

  @override
  void initState() {
    super.initState();
    _voiceMode = widget.startWithVoice;
    if (widget.startWithScan) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scan());
    }

    final question = widget.initialQuestion;
    if (question != null && question.trim().isNotEmpty) {
      // After the first frame so the send can safely call setState.
      WidgetsBinding.instance.addPostFrameCallback((_) => _send(question));
    }
  }

  @override
  void dispose() {
    _tts.dispose();
    _recordingSub?.cancel();
    _recorder.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _entries.add(_UserMessage(text));
      _loading = true;
      _controller.clear();
    });
    _scrollToBottom();

    try {
      final response = await _api.chat(message: text, profile: widget.profile);
      setState(() => _entries.add(_AssistantMessage(response, text)));
      await _storage.logHistory(HistoryEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        query: text,
        motherResult: response.structured,
        babyResult: response.babyStructured,
        source: HistorySource.chat,
      ));
    } catch (e) {
      final message = describeApiError(e, baseUrl: _api.baseUrl);
      setState(() => _entries.add(_AssistantMessage(
            ChatResponse(
              replyText: message,
              structured: FoodSafetyResponse(
                foodName: text,
                target: Target.mother,
                verdict: SafetyVerdict.unknown,
                explanation: message,
              ),
            ),
            text,
          )));
    } finally {
      setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  /// Camera or gallery, straight into the conversation.
  ///
  /// The photo becomes the user's message and the verdict becomes the reply,
  /// so scanning is one more way of asking rather than a separate screen with
  /// its own history.
  Future<void> _scan() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Take a photo'),
              subtitle: const Text('A meal, a package, or a label'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;

    setState(() {
      _entries.add(_UserPhoto(bytes));
      _loading = true;
      _voiceMode = false;
    });
    _scrollToBottom();

    try {
      final result = await _api.analyzeFoodImage(
        imageBytes: bytes,
        profile: widget.profile,
      );
      if (!mounted) return;
      setState(() {
        _entries.add(_ScanMessage(result));
        _loading = false;
      });
      await _storage.logHistory(HistoryEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        query: result.detectedFood,
        motherResult: result.structured,
        babyResult: result.babyStructured,
        source: HistorySource.scan,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(describeApiError(e, baseUrl: _api.baseUrl))),
      );
    }
    _scrollToBottom();
  }

  Future<void> _toggleRecording() async {
    if (_recording) {
      // Stop and send.
      await _recorder.stop();
      await _recordingSub?.cancel();
      final pcmBytes = Uint8List.fromList(_recordedChunks);
      _recordedChunks.clear();
      setState(() => _recording = false);

      if (pcmBytes.isEmpty) return;

      final wavBytes = _pcm16ToWav(pcmBytes, sampleRate: 16000, numChannels: 1);

      setState(() {
        _entries.add(_UserMessage('🎤 Voice question'));
        _loading = true;
      });
      _scrollToBottom();

      try {
        final response = await _api.voiceQuery(
          audioBytes: wavBytes,
          profile: widget.profile,
          filename: 'question.wav',
        );
        setState(() => _entries.add(_AssistantMessage(response, response.structured.foodName)));
        await _storage.logHistory(HistoryEntry(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          query: response.structured.foodName,
          motherResult: response.structured,
          babyResult: response.babyStructured,
          source: HistorySource.voice,
        ));
        await _tts.speak(response.structured.explanation);
      } catch (e) {
        final message = describeApiError(e, baseUrl: _api.baseUrl);
        setState(() => _entries.add(_AssistantMessage(
              ChatResponse(
                replyText: message,
                structured: FoodSafetyResponse(
                  foodName: 'voice question',
                  target: Target.mother,
                  verdict: SafetyVerdict.unknown,
                  explanation: message,
                ),
              ),
              'voice question',
            )));
      } finally {
        setState(() => _loading = false);
        _scrollToBottom();
      }
    } else {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) return;

      // record's web backend only supports PCM16 for startStream() - Opus
      // streaming needs MediaRecorder, which the plugin's stream API doesn't
      // use on web (that mismatch was the earlier "Stream not supported"
      // crash). PCM16 works, but is headerless raw samples, so we wrap it
      // in a WAV header ourselves after stopping - see _pcm16ToWav below.
      _recordedChunks.clear();
      final stream = await _recorder.startStream(
        const RecordConfig(encoder: AudioEncoder.pcm16bits, sampleRate: 16000, numChannels: 1),
      );
      _recordingSub = stream.listen(_recordedChunks.addAll);
      setState(() => _recording = true);
    }
  }

  /// Wraps headerless 16-bit PCM samples in a minimal 44-byte WAV header so
  /// the backend's Whisper call recognizes it as a valid audio file.
  Uint8List _pcm16ToWav(Uint8List pcmData, {required int sampleRate, required int numChannels}) {
    final byteRate = sampleRate * numChannels * 2;
    final blockAlign = numChannels * 2;
    final dataLength = pcmData.length;
    final header = ByteData(44);

    void writeString(int offset, String s) {
      for (var i = 0; i < s.length; i++) {
        header.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    writeString(0, 'RIFF');
    header.setUint32(4, 36 + dataLength, Endian.little);
    writeString(8, 'WAVE');
    writeString(12, 'fmt ');
    header.setUint32(16, 16, Endian.little); // fmt chunk size
    header.setUint16(20, 1, Endian.little); // PCM format
    header.setUint16(22, numChannels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, 16, Endian.little); // bits per sample
    writeString(36, 'data');
    header.setUint32(40, dataLength, Endian.little);

    return Uint8List.fromList([...header.buffer.asUint8List(), ...pcmData]);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: AppMotion.base,
          curve: AppMotion.enter,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI assistant'),
        flexibleSpace: DecoratedBox(
          decoration: BoxDecoration(gradient: p.heroGradient),
        ),
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        actions: [
          if (_entries.isNotEmpty)
            IconButton(
              tooltip: 'Clear conversation',
              onPressed: () => setState(() {
                _entries.clear();
                _savedEntryIndices.clear();
              }),
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _entries.isEmpty && !_loading
                ? _ChatIntro(onPick: _send)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: _entries.length + (_loading ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i >= _entries.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                          child: TypingIndicator(),
                        );
                      }
                      final entry = _entries[i];
                      if (entry is _UserMessage) return _UserBubble(text: entry.text);
                      if (entry is _UserPhoto) return _UserPhotoBubble(bytes: entry.bytes);
                      if (entry is _ScanMessage) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                          child: _ScanResult(
                            result: entry.result,
                            profile: widget.profile,
                            onListen: () => _tts.speak(entry.result.structured.explanation),
                            isSaved: _savedEntryIndices.contains(i),
                            onSave: () async {
                              await _storage.saveFoodBookmark(SavedFood(
                                id: DateTime.now().microsecondsSinceEpoch.toString(),
                                foodName: entry.result.detectedFood,
                                motherResult: entry.result.structured,
                                babyResult: entry.result.babyStructured,
                              ));
                              setState(() => _savedEntryIndices.add(i));
                            },
                          ),
                        );
                      }
                      if (entry is _AssistantMessage) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DualVerdictSection(
                                motherResult: entry.response.structured,
                                babyResult: entry.response.babyStructured,
                                onListenMother: () => _tts.speak(entry.response.structured.explanation),
                                onListenBaby: entry.response.babyStructured != null
                                    ? () => _tts.speak(entry.response.babyStructured!.explanation)
                                    : null,
                                isSaved: _savedEntryIndices.contains(i),
                                onSave: () async {
                                  await _storage.saveFoodBookmark(SavedFood(
                                    id: DateTime.now().microsecondsSinceEpoch.toString(),
                                    foodName: entry.query,
                                    motherResult: entry.response.structured,
                                    babyResult: entry.response.babyStructured,
                                  ));
                                  setState(() => _savedEntryIndices.add(i));
                                },
                              ),
                              if (entry.response.suggestedFollowups.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.md),
                                _FollowUpRow(
                                  questions: entry.response.suggestedFollowups,
                                  onPick: _send,
                                ),
                              ],
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
          ),
          _InputBar(
            controller: _controller,
            voiceMode: _voiceMode,
            recording: _recording,
            onToggleVoice: () => setState(() => _voiceMode = !_voiceMode),
            onToggleRecording: _toggleRecording,
            onSend: _send,
            onScan: _scan,
          ),
        ],
      ),
    );
  }
}

/// Shown before the first message: sets expectations and offers one-tap
/// starter questions so the input box is never a blank wall.
class _ChatIntro extends StatelessWidget {
  const _ChatIntro({required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        const SizedBox(height: AppSpacing.xxl),
        Reveal(
          child: Center(
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                gradient: p.heroGradient,
                shape: BoxShape.circle,
                boxShadow: p.brandShadow(),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 32),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Reveal(
          delay: const Duration(milliseconds: 80),
          child: Text(
            'Ask me anything about food',
            textAlign: TextAlign.center,
            style: context.texts.titleLarge,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Reveal(
          delay: const Duration(milliseconds: 120),
          child: Text(
            'Every answer is checked against ACOG, CDC, FDA, NIH, and AAP guidance for your life stage.',
            textAlign: TextAlign.center,
            style: context.texts.bodySmall?.copyWith(color: p.textMuted),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        for (var i = 0; i < _ChatScreenState._starters.length; i++)
          Reveal.stagger(
            index: i + 3,
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                onTap: () => onPick(_ChatScreenState._starters[i]),
                radius: AppRadius.md,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                shadow: false,
                child: Row(
                  children: [
                    Icon(Icons.north_east_rounded, size: 15, color: p.brandSoft),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        _ChatScreenState._starters[i],
                        style: context.texts.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FollowUpRow extends StatelessWidget {
  const _FollowUpRow({required this.questions, required this.onPick});

  final List<String> questions;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: questions
          .map((q) => Pressable(
                onTap: () => onPick(q),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: p.brandSurface,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: p.brand.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    q,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: p.brandSoft,
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Reveal(
      offset: 10,
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md, left: AppSpacing.xxxl),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            gradient: p.brandGradient,
            borderRadius: BorderRadius.circular(AppRadius.lg).copyWith(
              bottomRight: const Radius.circular(AppSpacing.xs),
            ),
            boxShadow: p.brandShadow(opacity: 0.22),
          ),
          child: Text(
            text,
            style: TextStyle(color: p.onBrand, fontSize: 13.5, height: 1.4),
          ),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.voiceMode,
    required this.recording,
    required this.onToggleVoice,
    required this.onToggleRecording,
    required this.onSend,
    required this.onScan,
  });

  final TextEditingController controller;
  final bool voiceMode;
  final bool recording;
  final VoidCallback onToggleVoice;
  final VoidCallback onToggleRecording;
  final ValueChanged<String> onSend;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.border)),
      ),
      child: SafeArea(
        top: false,
        child: AnimatedSize(
          duration: AppMotion.base,
          curve: AppMotion.emphasized,
          child: voiceMode ? _buildVoice(context, p) : _buildText(context, p),
        ),
      ),
    );
  }

  Widget _buildVoice(BuildContext context, AppPalette p) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        children: [
          Text(
            recording ? 'Listening - tap to stop' : 'Tap the mic and ask',
            style: context.texts.bodySmall?.copyWith(color: p.textMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 56,
                child: IconButton(
                  onPressed: onToggleVoice,
                  tooltip: 'Switch to keyboard',
                  icon: Icon(Icons.keyboard_rounded, color: p.textSecondary),
                ),
              ),
              const SizedBox(width: AppSpacing.xl),
              _PulsingMic(recording: recording, onTap: onToggleRecording),
              const SizedBox(width: AppSpacing.xl),
              SizedBox(
                width: 56,
                child: IconButton(
                  onPressed: onScan,
                  tooltip: 'Scan a food photo',
                  icon: Icon(Icons.photo_camera_outlined, color: p.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildText(BuildContext context, AppPalette p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          // Voice and camera sit beside the keyboard, so all three ways of
          // asking are one tap from the same place instead of three screens.
          IconButton(
            onPressed: onToggleVoice,
            tooltip: 'Ask by voice',
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.mic_none_rounded, color: p.textSecondary),
          ),
          IconButton(
            onPressed: onScan,
            tooltip: 'Scan a food photo',
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.photo_camera_outlined, color: p.textSecondary),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              textCapitalization: TextCapitalization.sentences,
              style: context.texts.bodyMedium,
              decoration: const InputDecoration(
                hintText: 'Ask, speak, or scan a food...',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
              ),
              onSubmitted: onSend,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Pressable(
            onTap: () => onSend(controller.text),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: p.brandGradient,
                borderRadius: BorderRadius.circular(AppRadius.md),
                boxShadow: p.brandShadow(opacity: 0.25),
              ),
              child: Icon(Icons.arrow_upward_rounded, color: p.onBrand, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

/// Record button that emits an expanding halo while recording, so it is
/// obvious the mic is live without watching a waveform.
class _PulsingMic extends StatefulWidget {
  const _PulsingMic({required this.recording, required this.onTap});

  final bool recording;
  final VoidCallback onTap;

  @override
  State<_PulsingMic> createState() => _PulsingMicState();
}

class _PulsingMicState extends State<_PulsingMic> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  @override
  void initState() {
    super.initState();
    if (widget.recording) _controller.repeat();
  }

  @override
  void didUpdateWidget(_PulsingMic old) {
    super.didUpdateWidget(old);
    if (widget.recording && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.recording && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = widget.recording ? p.avoid : p.brand;

    return SizedBox(
      width: 104,
      height: 104,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.recording)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => Container(
                width: 64 + 40 * _controller.value,
                height: 64 + 40 * _controller.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.25 * (1 - _controller.value)),
                ),
              ),
            ),
          Pressable(
            onTap: widget.onTap,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                widget.recording ? Icons.stop_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The photo the user sent, on their side of the conversation.
class _UserPhotoBubble extends StatelessWidget {
  const _UserPhotoBubble({required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Align(
        alignment: Alignment.centerRight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 220, maxHeight: 220),
            decoration: BoxDecoration(border: Border.all(color: p.border)),
            child: Image.memory(bytes, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}

/// The answer to a photo: what it was read as, the safety verdict, and the
/// nutrients - with one tap to put it in today's log.
class _ScanResult extends StatefulWidget {
  const _ScanResult({
    required this.result,
    required this.profile,
    required this.onListen,
    required this.isSaved,
    required this.onSave,
  });

  final FoodAnalysisResponse result;
  final UserProfile profile;
  final VoidCallback onListen;
  final bool isSaved;
  final VoidCallback onSave;

  @override
  State<_ScanResult> createState() => _ScanResultState();
}

class _ScanResultState extends State<_ScanResult> {
  bool _logged = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final result = widget.result;
    final estimate = result.nutrients;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // What the photo was read as. Shown first and plainly, because every
        // verdict below it is only as right as this line.
        Row(
          children: [
            Icon(Icons.photo_camera_rounded, size: 15, color: p.textMuted),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Read as: ${result.detectedFood}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: p.textSecondary,
                ),
              ),
            ),
          ],
        ),
        if (result.detectedIngredients.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            result.detectedIngredients.join('  •  '),
            style: TextStyle(fontSize: 11, color: p.textMuted),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        DualVerdictSection(
          motherResult: result.structured,
          babyResult: result.babyStructured,
          onListenMother: widget.onListen,
          isSaved: widget.isSaved,
          onSave: widget.onSave,
        ),
        if (estimate != null && estimate.recognised) ...[
          const SizedBox(height: AppSpacing.md),
          AppCard(
            radius: AppRadius.md,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("What's in it", style: context.texts.titleSmall),
                const SizedBox(height: AppSpacing.md),
                NutrientBreakdown(
                  nutrients: estimate.perServing,
                  targets: targetsForLifeStage(widget.profile.lifeStage),
                  servingDescription: estimate.servingDescription,
                  note: estimate.note,
                  isEstimate: estimate.isEstimate,
                  dense: true,
                ),
                const SizedBox(height: AppSpacing.md),
                SoftButton(
                  label: _logged ? 'Added to today' : "Add to today's log",
                  icon: _logged ? Icons.check_rounded : Icons.add_rounded,
                  onPressed: _logged
                      ? null
                      : () async {
                          await context.read<NutritionController>().add(
                                NutritionEntry(
                                  id: DateTime.now()
                                      .microsecondsSinceEpoch
                                      .toString(),
                                  foodName: result.detectedFood,
                                  servings: 1,
                                  perServing: estimate.perServing,
                                  servingDescription: estimate.servingDescription,
                                  source: NutritionSource.scanned,
                                ),
                              );
                          if (context.mounted) setState(() => _logged = true);
                        },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
