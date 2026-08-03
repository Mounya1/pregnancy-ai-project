import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/baby_record.dart';
import '../models/history_entry.dart';
import '../models/medical_report.dart';
import '../models/nutrition_log.dart';
import '../models/reminder.dart';
import '../models/saved_food.dart';
import '../models/user_profile.dart';

/// Wraps SharedPreferences (which uses the browser's localStorage on
/// Flutter Web) for everything the app persists locally: profile, saved
/// foods, interaction history, and the nutrition log. No backend/account
/// needed - all data lives on this device only, per the portfolio-demo
/// scope (see GETTING_STARTED.md).
class LocalStorageService {
  static const _profileKey = 'user_profile';
  static const _savedFoodsKey = 'saved_foods';
  static const _historyKey = 'history_entries';
  static const _nutritionKey = 'nutrition_entries';
  static const _mealPlanKey = 'last_meal_plan';
  static const _themeModeKey = 'theme_mode';
  static const _remindersKey = 'reminders';
  static const _reportsKey = 'medical_reports';
  static const _babyKey = 'baby_records';
  static const _fitnessPlanKey = 'last_fitness_plan';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  // ---- Appearance ----

  /// Stored as a plain string ('system' | 'light' | 'dark') so this service
  /// stays free of Flutter widget imports; ThemeController maps it.
  Future<String?> loadThemeMode() async {
    final prefs = await _prefs;
    return prefs.getString(_themeModeKey);
  }

  Future<void> saveThemeMode(String mode) async {
    final prefs = await _prefs;
    await prefs.setString(_themeModeKey, mode);
  }

  // ---- Profile ----

  Future<UserProfile?> loadProfile() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_profileKey);
    if (raw == null) return null;
    return UserProfile.fromStorageJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveProfile(UserProfile profile) async {
    final prefs = await _prefs;
    await prefs.setString(_profileKey, jsonEncode(profile.toStorageJson()));
  }

  // ---- Saved foods ----

  Future<List<SavedFood>> loadSavedFoods() async {
    final prefs = await _prefs;
    final raw = prefs.getStringList(_savedFoodsKey) ?? [];
    return raw.map((s) => SavedFood.fromJson(jsonDecode(s))).toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
  }

  Future<void> saveFoodBookmark(SavedFood food) async {
    final prefs = await _prefs;
    final raw = prefs.getStringList(_savedFoodsKey) ?? [];
    raw.add(jsonEncode(food.toJson()));
    await prefs.setStringList(_savedFoodsKey, raw);
  }

  Future<void> removeSavedFood(String id) async {
    final prefs = await _prefs;
    final raw = prefs.getStringList(_savedFoodsKey) ?? [];
    raw.removeWhere((s) => (jsonDecode(s) as Map<String, dynamic>)['id'] == id);
    await prefs.setStringList(_savedFoodsKey, raw);
  }

  // ---- History ----

  Future<List<HistoryEntry>> loadHistory() async {
    final prefs = await _prefs;
    final raw = prefs.getStringList(_historyKey) ?? [];
    return raw.map((s) => HistoryEntry.fromJson(jsonDecode(s))).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> logHistory(HistoryEntry entry) async {
    final prefs = await _prefs;
    final raw = prefs.getStringList(_historyKey) ?? [];
    raw.add(jsonEncode(entry.toJson()));
    // Cap history length so local storage doesn't grow unbounded.
    if (raw.length > 200) raw.removeRange(0, raw.length - 200);
    await prefs.setStringList(_historyKey, raw);
  }

  Future<void> clearHistory() async {
    final prefs = await _prefs;
    await prefs.remove(_historyKey);
  }

  // ---- Nutrition log ----

  Future<List<NutritionEntry>> loadNutritionEntries() async {
    final prefs = await _prefs;
    final raw = prefs.getStringList(_nutritionKey) ?? [];
    return raw.map((s) => NutritionEntry.fromJson(jsonDecode(s))).toList();
  }

  Future<void> logNutritionEntry(NutritionEntry entry) async {
    final prefs = await _prefs;
    final raw = prefs.getStringList(_nutritionKey) ?? [];
    raw.add(jsonEncode(entry.toJson()));
    await prefs.setStringList(_nutritionKey, raw);
  }

  Future<void> removeNutritionEntry(String id) async {
    final prefs = await _prefs;
    final raw = prefs.getStringList(_nutritionKey) ?? [];
    raw.removeWhere((s) => (jsonDecode(s) as Map<String, dynamic>)['id'] == id);
    await prefs.setStringList(_nutritionKey, raw);
  }

  // ---- Last meal plan (cached so it survives navigating away/back) ----

  Future<Map<String, dynamic>?> loadLastMealPlan() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_mealPlanKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> saveLastMealPlan(Map<String, dynamic> planJson) async {
    final prefs = await _prefs;
    await prefs.setString(_mealPlanKey, jsonEncode(planJson));
  }

  Future<Map<String, dynamic>?> loadLastFitnessPlan() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_fitnessPlanKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> saveLastFitnessPlan(Map<String, dynamic> planJson) async {
    final prefs = await _prefs;
    await prefs.setString(_fitnessPlanKey, jsonEncode(planJson));
  }

  // ---- Reminders ----

  Future<List<Reminder>> loadReminders() async {
    final prefs = await _prefs;
    final raw = prefs.getStringList(_remindersKey) ?? [];
    return raw.map((s) => Reminder.fromJson(jsonDecode(s))).toList()
      ..sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
  }

  Future<void> saveReminders(List<Reminder> reminders) async {
    final prefs = await _prefs;
    await prefs.setStringList(
      _remindersKey,
      reminders.map((r) => jsonEncode(r.toJson())).toList(),
    );
  }

  // ---- Medical reports ----

  Future<List<MedicalReport>> loadMedicalReports() async {
    final prefs = await _prefs;
    final raw = prefs.getStringList(_reportsKey) ?? [];
    return raw.map((s) => MedicalReport.fromJson(jsonDecode(s))).toList()
      ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
  }

  Future<void> saveMedicalReport(MedicalReport report) async {
    final prefs = await _prefs;
    final raw = prefs.getStringList(_reportsKey) ?? [];
    raw.add(jsonEncode(report.toJson()));
    await prefs.setStringList(_reportsKey, raw);
  }

  Future<void> removeMedicalReport(String id) async {
    final prefs = await _prefs;
    final raw = prefs.getStringList(_reportsKey) ?? [];
    raw.removeWhere((s) => (jsonDecode(s) as Map<String, dynamic>)['id'] == id);
    await prefs.setStringList(_reportsKey, raw);
  }

  // ---- Baby growth records ----

  Future<List<BabyRecord>> loadBabyRecords() async {
    final prefs = await _prefs;
    final raw = prefs.getStringList(_babyKey) ?? [];
    return raw.map((s) => BabyRecord.fromJson(jsonDecode(s))).toList()
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
  }

  Future<void> saveBabyRecord(BabyRecord record) async {
    final prefs = await _prefs;
    final raw = prefs.getStringList(_babyKey) ?? [];
    raw.add(jsonEncode(record.toJson()));
    await prefs.setStringList(_babyKey, raw);
  }

  Future<void> removeBabyRecord(String id) async {
    final prefs = await _prefs;
    final raw = prefs.getStringList(_babyKey) ?? [];
    raw.removeWhere((s) => (jsonDecode(s) as Map<String, dynamic>)['id'] == id);
    await prefs.setStringList(_babyKey, raw);
  }

  // ---- Reset ----

  Future<void> clearAllData() async {
    final prefs = await _prefs;
    await prefs.clear();
  }
}
