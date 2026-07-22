import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/food_safety_response.dart';
import '../models/user_profile.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/safety_verdict_card.dart';

class FoodAnalysisScreen extends StatefulWidget {
  const FoodAnalysisScreen({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<FoodAnalysisScreen> createState() => _FoodAnalysisScreenState();
}

class _FoodAnalysisScreenState extends State<FoodAnalysisScreen> {
  final _api = ApiClient();
  final _picker = ImagePicker();

  Uint8List? _imageBytes;
  FoodAnalysisResponse? _result;
  bool _loading = false;
  String? _error;

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
    });

    try {
      final result = await _api.analyzeFoodImage(imageBytes: bytes, profile: widget.profile);
      setState(() => _result = result);
    } catch (e) {
      setState(() => _error = "Couldn't analyze that photo. Try again.");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food analysis'),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.ios_share))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ImageArea(imageBytes: _imageBytes, onCapture: () => _pickAndAnalyze(ImageSource.gallery)),
            const SizedBox(height: 16),
            if (_loading) const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
            if (_error != null) Text(_error!, style: const TextStyle(color: AppColors.avoid)),
            if (_result != null) ...[
              Text(_result!.detectedFood, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              if (_result!.detectedIngredients.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  _result!.detectedIngredients.join(', '),
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
              const SizedBox(height: 14),
              DualVerdictSection(
                motherResult: _result!.structured,
                babyResult: _result!.babyStructured,
                onListenMother: () {}, // wire to TTS playback of structured.explanation
                onListenBaby: () {},
              ),
            ],
            if (_result == null && !_loading && _error == null) ...[
              const SizedBox(height: 40),
              const Center(
                child: Text(
                  'Upload a photo of a meal, fruit, packaged food, or nutrition label',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _pickAndAnalyze(ImageSource.gallery),
        backgroundColor: AppColors.purple,
        icon: const Icon(Icons.upload_outlined),
        label: const Text('Upload food photo'),
      ),
    );
  }
}

class _ImageArea extends StatelessWidget {
  const _ImageArea({required this.imageBytes, required this.onCapture});

  final Uint8List? imageBytes;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCapture,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 180,
          width: double.infinity,
          color: AppColors.purpleLight,
          child: imageBytes != null
              ? Image.memory(imageBytes!, fit: BoxFit.cover)
              : const Center(
                  child: Icon(Icons.upload_outlined, size: 32, color: AppColors.purple),
                ),
        ),
      ),
    );
  }
}
