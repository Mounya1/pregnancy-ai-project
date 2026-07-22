import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../models/food_safety_response.dart';
import '../models/user_profile.dart';

/// Thin wrapper around the FastAPI backend from pregnancy-ai-backend/.
///
/// Uses raw bytes (Uint8List) rather than dart:io File for every upload -
/// dart:io.File does not exist on Flutter Web, and this app targets web
/// for the portfolio demo. image_picker's XFile.readAsBytes() and the
/// `record` package's byte-stream output both work fine as the source.
class ApiClient {
  ApiClient({String? baseUrl}) : _dio = Dio(BaseOptions(baseUrl: baseUrl ?? defaultBaseUrl));

  final Dio _dio;

  static const defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
  // Local dev default is localhost:8000 (works for Flutter Web + `flutter run -d chrome`).
  // For the deployed demo, build with:
  //   flutter build web --dart-define=API_BASE_URL=https://your-backend.onrender.com

  Future<ChatResponse> chat({required String message, required UserProfile profile}) async {
    final res = await _dio.post('/chat', data: {
      'message': message,
      'profile': profile.toJson(),
    });
    return ChatResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<FoodAnalysisResponse> analyzeFoodImage({
    required Uint8List imageBytes,
    required UserProfile profile,
    String filename = 'food.jpg',
  }) async {
    final form = FormData.fromMap({
      'image': MultipartFile.fromBytes(imageBytes, filename: filename),
      'profile_json': jsonEncode(profile.toJson()),
    });
    final res = await _dio.post('/food-analysis', data: form);
    return FoodAnalysisResponse.fromJson(res.data as Map<String, dynamic>);
  }

  /// Returns the parsed chat response plus a URL to the generated TTS audio.
  Future<(ChatResponse, String audioUrl)> voiceQuery({
    required Uint8List audioBytes,
    required UserProfile profile,
    String filename = 'question.webm',
  }) async {
    final form = FormData.fromMap({
      'audio': MultipartFile.fromBytes(audioBytes, filename: filename),
      'profile_json': jsonEncode(profile.toJson()),
    });
    final res = await _dio.post('/voice', data: form);
    final data = res.data as Map<String, dynamic>;
    final chatResponse = ChatResponse.fromJson(data['chat_response'] as Map<String, dynamic>);
    return (chatResponse, data['audio_url'] as String);
  }
}
