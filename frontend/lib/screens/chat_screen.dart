import 'package:flutter/material.dart';
import '../models/food_safety_response.dart';
import '../models/user_profile.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/safety_verdict_card.dart';

sealed class _ChatEntry {}

class _UserMessage extends _ChatEntry {
  final String text;
  _UserMessage(this.text);
}

class _AssistantMessage extends _ChatEntry {
  final ChatResponse response;
  _AssistantMessage(this.response);
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.profile, this.startWithVoice = false});

  final UserProfile profile;
  final bool startWithVoice;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _api = ApiClient();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatEntry> _entries = [];
  bool _loading = false;
  bool _voiceMode = false;

  @override
  void initState() {
    super.initState();
    _voiceMode = widget.startWithVoice;
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
      setState(() => _entries.add(_AssistantMessage(response)));
    } catch (e) {
      // Surface a lightweight inline error entry rather than crashing the chat.
      setState(() => _entries.add(_AssistantMessage(ChatResponse(
            replyText: "Sorry, I couldn't reach the server. Try again.",
            structured: FoodSafetyResponse(
              foodName: text,
              target: Target.mother,
              verdict: SafetyVerdict.unknown,
              explanation: "Sorry, I couldn't reach the server. Try again.",
            ),
          ))));
    } finally {
      setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI assistant')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _entries.length + (_loading ? 1 : 0),
              itemBuilder: (context, i) {
                if (i >= _entries.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final entry = _entries[i];
                if (entry is _UserMessage) return _UserBubble(text: entry.text);
                if (entry is _AssistantMessage) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DualVerdictSection(
                          motherResult: entry.response.structured,
                          babyResult: entry.response.babyStructured,
                        ),
                        if (entry.response.suggestedFollowups.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: entry.response.suggestedFollowups
                                .map((q) => ActionChip(
                                      label: Text(q, style: const TextStyle(fontSize: 12)),
                                      backgroundColor: AppColors.purpleLight,
                                      side: BorderSide.none,
                                      onPressed: () => _send(q),
                                    ))
                                .toList(),
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
            onToggleVoice: () => setState(() => _voiceMode = !_voiceMode),
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 260),
        decoration: BoxDecoration(color: AppColors.purple, borderRadius: BorderRadius.circular(16)),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13)),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.voiceMode,
    required this.onToggleVoice,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool voiceMode;
  final VoidCallback onToggleVoice;
  final ValueChanged<String> onSend;

  @override
  Widget build(BuildContext context) {
    if (voiceMode) {
      // Tap-to-speak panel. Wire this button to a real recorder
      // (e.g. the `record` package) that saves an m4a file, then call
      // ApiClient.voiceQuery with it - see services/api_client.dart.
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Column(
          children: [
            const Text('Tap to speak', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(onPressed: onToggleVoice, icon: const Icon(Icons.keyboard)),
                InkWell(
                  onTap: () {}, // start/stop recording
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(color: AppColors.purple, shape: BoxShape.circle),
                    child: const Icon(Icons.mic, color: Colors.white),
                  ),
                ),
                IconButton(onPressed: () {}, icon: const Icon(Icons.camera_alt_outlined)),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
      child: Row(
        children: [
          IconButton(onPressed: onToggleVoice, icon: const Icon(Icons.mic_none)),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Ask about a food...',
                border: InputBorder.none,
              ),
              onSubmitted: onSend,
            ),
          ),
          IconButton(
            onPressed: () => onSend(controller.text),
            icon: const Icon(Icons.send, color: AppColors.purple),
          ),
        ],
      ),
    );
  }
}
