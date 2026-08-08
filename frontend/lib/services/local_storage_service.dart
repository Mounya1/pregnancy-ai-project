import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account.dart';
import '../models/baby_record.dart';
import '../models/emergency_contact.dart';
import '../models/history_entry.dart';
import '../models/medical_report.dart';
import '../models/nutrition_log.dart';
import '../models/reminder.dart';
import '../models/saved_food.dart';
import '../models/user_profile.dart';

/// Wraps SharedPreferences (which uses the browser's localStorage on
/// Flutter Web) for everything the app persists locally: the account,
/// profile, saved foods, interaction history, and the nutrition log. There is
/// no server behind any of it - all data lives on this device only, per the
/// portfolio-demo scope (see GETTING_STARTED.md).
class LocalStorageService {
  static const _accountKey = 'account';
  static const _sessionKey = 'session_active';
  static const _profileKey = 'user_profile';
  static const _savedFoodsKey = 'saved_foods';
  static const _historyKey = 'history_entries';
  static const _nutritionKey = 'nutrition_entries';
  static const _mealPlanKey = 'last_meal_plan';
  static const _themeModeKey = 'theme_mode';
  static const _remindersKey = 'reminders';
  static const _milestonesKey = 'milestone_settings';
  static const _contactsKey = 'emergency_contacts';
  static const _shoppingRegionKey = 'shopping_region';
  static const _shoppingCheckedKey = 'shopping_checked';
  static const _reportsKey = 'medical_reports';
  static const _babyKey = 'baby_records';
  static const _fitnessPlanKey = 'last_fitness_plan';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  // ---- Account ----
  //
  // One account per device. The record holds a PBKDF2 hash, never the
  // password. "Session" is just a flag saying the password was entered since
  // the last sign-out, so a restart doesn't ask again.

  Future<Account?> loadAccount() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_accountKey);
    if (raw == null) return null;
    return Account.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveAccount(Account account) async {
    final prefs = await _prefs;
    await prefs.setString(_accountKey, jsonEncode(account.toJson()));
  }

  Future<bool> loadSessionActive() async {
    final prefs = await _prefs;
    return prefs.getBool(_sessionKey) ?? false;
  }

  Future<void> saveSessionActive(bool active) async {
    final prefs = await _prefs;
    await prefs.setBool(_sessionKey, active);
  }

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

  // ---- Weekly milestone updates ----

  Future<Map<String, dynamic>?> loadMilestoneSettings() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_milestonesKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> saveMilestoneSettings(Map<String, dynamic> json) async {
    final prefs = await _prefs;
    await prefs.setString(_milestonesKey, jsonEncode(json));
  }

  // ---- Emergency contacts ----

  Future<List<EmergencyContact>> loadEmergencyContacts() async {
    final prefs = await _prefs;
    final raw = prefs.getStringList(_contactsKey) ?? [];
    return raw.map((s) => EmergencyContact.fromJson(jsonDecode(s))).toList();
  }

  Future<void> saveEmergencyContacts(List<EmergencyContact> contacts) async {
    final prefs = await _prefs;
    await prefs.setStringList(
      _contactsKey,
      contacts.map((c) => jsonEncode(c.toJson())).toList(),
    );
  }

  // ---- Shopping ----

  /// Null means never chosen, which is different from 'XX' (International
  /// chosen deliberately) - the UI says "detected" only for the former.
  Future<String?> loadShoppingRegion() async {
    final prefs = await _prefs;
    return prefs.getString(_shoppingRegionKey);
  }

  Future<void> saveShoppingRegion(String code) async {
    final prefs = await _prefs;
    await prefs.setString(_shoppingRegionKey, code);
  }

  Future<List<String>> loadShoppingChecked() async {
    final prefs = await _prefs;
    return prefs.getStringList(_shoppingCheckedKey) ?? const [];
  }

  Future<void> saveShoppingChecked(List<String> ids) async {
    final prefs = await _prefs;
    await prefs.setStringList(_shoppingCheckedKey, ids);
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
