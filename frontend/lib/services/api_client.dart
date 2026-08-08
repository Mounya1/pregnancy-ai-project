import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../models/fitness_plan.dart';
import '../models/food_safety_response.dart';
import '../models/meal_plan.dart';
import '../models/medical_report.dart';
import '../models/nutrition_log.dart';
import '../models/user_profile.dart';

/// Thin wrapper around the FastAPI backend from pregnancy-ai-backend/.
///
/// Uses raw bytes (Uint8List) rather than dart:io File for every upload -
/// dart:io.File does not exist on Flutter Web, and this app targets web
/// for the portfolio demo. image_picker's XFile.readAsBytes() and the
/// `record` package's byte-stream output both work fine as the source.
class ApiClient {
  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? defaultBaseUrl {
    _dio = Dio(BaseOptions(baseUrl: this.baseUrl));
  }

  late final Dio _dio;
  final String baseUrl;

  /// Exposed so callers can do things Dio supports that this wrapper
  /// doesn't have a dedicated method for - e.g. fetching a browser blob:
  /// URL (from the `record` package's web output) back into raw bytes.
  Dio get rawDio => _dio;

  static const defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );
  // Using 127.0.0.1 rather than 'localhost' explicitly - on some Windows
  // setups 'localhost' resolves to IPv6 (::1) first, which can behave
  // inconsistently with uvicorn's default binding. 127.0.0.1 is unambiguous.
  // For the deployed demo, build with:
  //   flutter build web --dart-define=API_BASE_URL=https://your-backend.onrender.com

  Future<ChatResponse> chat({required String message, required UserProfile profile}) async {
    final res = await _dio.post('/chat', data: {
      'message': message,
      'profile': profile.toApiJson(),
    });
    return ChatResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<MealPlan> generateMealPlan({
    required UserProfile profile,
    int days = 3,
    List<String>? cuisines,
  }) async {
    final res = await _dio.post('/meal-plan', data: {
      'profile': profile.toApiJson(),
      'days': days,
      'dietary_preferences': profile.dietaryPreferences,
      'allergies': profile.allergies,
      // Lets the planner screen try a cuisine mix without editing the profile.
      'cuisines': cuisines ?? profile.cuisines,
      'health_conditions': profile.healthConditions,
    });
    return MealPlan.fromJson(res.data as Map<String, dynamic>);
  }

  Future<FitnessPlan> generateFitnessPlan({
    required UserProfile profile,
    int days = 7,
    List<String> constraints = const [],
  }) async {
    final res = await _dio.post('/fitness-plan', data: {
      'profile': profile.toApiJson(),
      'days': days,
      'health_conditions': profile.healthConditions,
      'constraints': constraints,
    });
    return FitnessPlan.fromJson(res.data as Map<String, dynamic>);
  }

  /// Uploads a lab report (photo or PDF) and gets back the diet-relevant
  /// conditions, findings, and food guidance extracted from it.
  Future<MedicalReport> analyzeMedicalReport({
    required Uint8List fileBytes,
    required UserProfile profile,
    required String filename,
  }) async {
    final form = FormData.fromMap({
      'report': MultipartFile.fromBytes(fileBytes, filename: filename),
      'profile_json': jsonEncode(profile.toApiJson()),
    });
    final res = await _dio.post('/medical-report', data: form);
    return MedicalReport.fromJson({
      ...res.data as Map<String, dynamic>,
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'uploaded_at': DateTime.now().toIso8601String(),
    });
  }

  Future<FoodAnalysisResponse> analyzeFoodImage({
    required Uint8List imageBytes,
    required UserProfile profile,
    String filename = 'food.jpg',
  }) async {
    final form = FormData.fromMap({
      'image': MultipartFile.fromBytes(imageBytes, filename: filename),
      'profile_json': jsonEncode(profile.toApiJson()),
    });
    final res = await _dio.post('/food-analysis', data: form);
    return FoodAnalysisResponse.fromJson(res.data as Map<String, dynamic>);
  }

  /// Per-serving nutrients for a food the user typed by hand.
  ///
  /// The built-in table covers fifteen foods; this covers everything else, so
  /// "log a food" stops meaning "log one of our fifteen foods".
  Future<NutrientEstimate> estimateNutrients({
    required String foodName,
    required UserProfile profile,
  }) async {
    final res = await _dio.post('/nutrition/estimate', data: {
      'food_name': foodName,
      'profile': profile.toApiJson(),
    });
    return NutrientEstimate.fromJson(res.data as Map<String, dynamic>);
  }

  /// Sends recorded audio, gets back the transcribed question's chat response.
  /// Playback of the reply is handled separately via TtsService.speak(),
  /// same mechanism as the "Listen to explanation" buttons.
  Future<ChatResponse> voiceQuery({
    required Uint8List audioBytes,
    required UserProfile profile,
    String filename = 'question.webm',
  }) async {
    final form = FormData.fromMap({
      'audio': MultipartFile.fromBytes(audioBytes, filename: filename),
      'profile_json': jsonEncode(profile.toApiJson()),
    });
    final res = await _dio.post('/voice', data: form);
    final data = res.data as Map<String, dynamic>;
    return ChatResponse.fromJson(data['chat_response'] as Map<String, dynamic>);
  }
}
