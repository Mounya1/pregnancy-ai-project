import 'package:just_audio/just_audio.dart';

/// Plays text as speech by pointing just_audio directly at the backend's
/// GET /tts?text=... endpoint - no separate fetch/decode step needed,
/// just_audio streams straight from the URL.
class TtsService {
  TtsService({required this.baseUrl});

  final String baseUrl;
  final AudioPlayer _player = AudioPlayer();

  Future<void> speak(String text) async {
    final url = '$baseUrl/tts?text=${Uri.encodeComponent(text)}';
    await _player.setUrl(url);
    await _player.play();
  }

  Future<void> stop() => _player.stop();

  void dispose() => _player.dispose();
}
