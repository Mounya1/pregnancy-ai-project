import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/history_entry.dart';
import '../models/food_safety_response.dart';
import '../models/saved_food.dart';
import '../models/user_profile.dart';
import '../services/api_client.dart';
import '../services/api_error.dart';
import '../services/local_storage_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import '../widgets/safety_verdict_card.dart';
import '../widgets/ui/app_card.dart';
import '../widgets/ui/empty_state.dart';
import '../widgets/ui/gradient_button.dart';
import '../widgets/ui/reveal.dart';
import '../widgets/ui/shimmer.dart';

class FoodAnalysisScreen extends StatefulWidget {
  const FoodAnalysisScreen({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<FoodAnalysisScreen> createState() => _FoodAnalysisScreenState();
}

class _FoodAnalysisScreenState extends State<FoodAnalysisScreen> {
  final _api = ApiClient();
  final _storage = LocalStorageService();
  late final _tts = TtsService(baseUrl: _api.baseUrl);
  final _picker = ImagePicker();

  Uint8List? _imageBytes;
  FoodAnalysisResponse? _result;
  bool _loading = false;
  bool _saved = false;
  String? _error;

  @override
  void dispose() {
    _tts.dispose();
    super.dispose();
  }

  Future<void> _pickAndAnalyze(ImageSource source) async {
    // ImagePicker's XFile + readAsBytes works identically on web and mobile,
    // unlike dart:io.File which does not exist on Flutter Web.
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();

    setState(() {
      _imageBytes = bytes;
      _loading = true;
      _error = null;
      _result = null;
      _saved = false;
    });

    try {
      final result = await _api.analyzeFoodImage(imageBytes: bytes, profile: widget.profile);
      setState(() => _result = result);
      await _storage.logHistory(HistoryEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        query: result.detectedFood,
        motherResult: result.structured,
        babyResult: result.babyStructured,
        source: HistorySource.scan,
      ));
    } catch (e) {
      setState(() => _error = describeApiError(e, baseUrl: _api.baseUrl));
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Camera and gallery are both worth offering: a label in a shop is a
  /// camera moment, a meal photo is usually already in the gallery.
  Future<void> _chooseSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.sm,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add a photo', style: Theme.of(sheetContext).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xl),
              _SourceTile(
                icon: Icons.photo_camera_rounded,
                title: 'Take a photo',
                subtitle: 'Point at a meal or nutrition label',
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
              const SizedBox(height: AppSpacing.md),
              _SourceTile(
                icon: Icons.photo_library_rounded,
                title: 'Choose from gallery',
                subtitle: 'Pick an existing picture',
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source != null && mounted) await _pickAndAnalyze(source);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      appBar: AppBar(title: const Text('Scan food')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          120,
        ),
        children: [
          _ImageArea(
            imageBytes: _imageBytes,
            loading: _loading,
            onCapture: _chooseSource,
          ),
          const SizedBox(height: AppSpacing.xl),
          if (_loading) const _AnalyzingSkeleton(),
          if (_error != null)
            ErrorPanel(message: _error!, onRetry: _chooseSource),
          if (_result != null) ...[
            Reveal(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_result!.detectedFood, style: context.texts.headlineSmall),
                        if (_result!.detectedIngredients.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            _result!.detectedIngredients.join('  •  '),
                            style: context.texts.bodySmall?.copyWith(color: p.textMuted),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            DualVerdictSection(
              motherResult: _result!.structured,
              babyResult: _result!.babyStructured,
              onListenMother: () => _tts.speak(_result!.structured.explanation),
              onListenBaby: _result!.babyStructured != null
                  ? () => _tts.speak(_result!.babyStructured!.explanation)
                  : null,
              isSaved: _saved,
              onSave: () async {
                await _storage.saveFoodBookmark(SavedFood(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  foodName: _result!.detectedFood,
                  motherResult: _result!.structured,
                  babyResult: _result!.babyStructured,
                ));
                setState(() => _saved = true);
              },
            ),
          ],
          if (_result == null && !_loading && _error == null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xl),
              child: Column(
                children: [
                  Text(
                    'What can I scan?',
                    style: context.texts.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ...[
                    ('A plated meal or dish', Icons.dinner_dining_rounded),
                    ('A packaged product', Icons.inventory_2_rounded),
                    ('An ingredients or nutrition label', Icons.receipt_long_rounded),
                  ].map((tip) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Row(
                          children: [
                            Icon(tip.$2, size: 17, color: p.brandSoft),
                            const SizedBox(width: AppSpacing.md),
                            Text(tip.$1, style: context.texts.bodyMedium),
                          ],
                        ),
                      )),
                ],
              ),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: GradientButton(
          label: _result == null ? 'Add food photo' : 'Scan another',
          icon: Icons.camera_alt_rounded,
          loading: _loading,
          onPressed: _chooseSource,
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AppCard(
      onTap: onTap,
      shadow: false,
      radius: AppRadius.md,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: p.brandSurface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 20, color: p.brandSoft),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.texts.titleSmall),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11.5, color: p.textMuted),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 18, color: p.textMuted),
        ],
      ),
    );
  }
}

class _ImageArea extends StatelessWidget {
  const _ImageArea({
    required this.imageBytes,
    required this.loading,
    required this.onCapture,
  });

  final Uint8List? imageBytes;
  final bool loading;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Pressable(
      onTap: onCapture,
      child: AnimatedContainer(
        duration: AppMotion.base,
        height: imageBytes == null ? 190 : 240,
        width: double.infinity,
        decoration: BoxDecoration(
          color: p.brandSurface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: imageBytes == null ? p.brand.withValues(alpha: 0.3) : p.border,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: imageBytes == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: p.heroGradient,
                      shape: BoxShape.circle,
                      boxShadow: p.brandShadow(),
                    ),
                    child: const Icon(Icons.add_a_photo_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Tap to add a photo', style: context.texts.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    'Camera or gallery',
                    style: TextStyle(fontSize: 11.5, color: p.textMuted),
                  ),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(imageBytes!, fit: BoxFit.cover),
                  // Scrim keeps the "scanning" caption legible over any photo.
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: loading ? 0.55 : 0.25),
                        ],
                      ),
                    ),
                  ),
                  if (loading)
                    const Center(
                      child: SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      ),
                    ),
                  Positioned(
                    left: AppSpacing.lg,
                    bottom: AppSpacing.md,
                    child: Text(
                      loading ? 'Analyzing photo...' : 'Tap to replace',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _AnalyzingSkeleton extends StatelessWidget {
  const _AnalyzingSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Shimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 160, height: 22),
          SizedBox(height: AppSpacing.sm),
          SkeletonBox(width: 220, height: 12),
          SizedBox(height: AppSpacing.xl),
          SkeletonBox(height: 190, radius: AppRadius.lg),
        ],
      ),
    );
  }
}
