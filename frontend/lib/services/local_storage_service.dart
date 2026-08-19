import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account.dart';
import '../models/baby_record.dart';
import '../models/doctor_note.dart';
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
  static const _tokensKey = 'cognito_tokens';
  static const _pendingEmailKey = 'pending_confirmation_email';
  static const _profileKey = 'user_profile';
  static const _savedFoodsKey = 'saved_foods';
  static const _historyKey = 'history_entries';
  static const _nutritionKey = 'nutrition_entries';
  static const _mealPlanKey = 'last_meal_plan';
  static const _themeModeKey = 'theme_mode';
  static const _remindersKey = 'reminders';
  static const _milestonesKey = 'milestone_settings';
  static const _contactsKey = 'emergency_contacts';
  static const _notesKey = 'doctor_notes';
  static const _careDoneKey = 'care_done';
  static const _shoppingRegionKey = 'shopping_region';
  static const _shoppingCheckedKey = 'shopping_checked';
  static const _reportsKey = 'medical_reports';
  static const _babyKey = 'baby_records';
  static const _fitnessPlanKey = 'last_fitness_plan';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  /// Decodes a stored list, dropping rows that will not parse.
  ///
  /// One malformed entry used to take the whole collection with it - the food
  /// log would come back empty rather than missing a single row. That became
  /// a real risk once documents can arrive from a server, possibly written by
  /// a different version of the app.
  static List<T> _decodeList<T>(List<String> raw, T Function(Map<String, dynamic>) parse) {
    final out = <T>[];
    for (final entry in raw) {
      try {
        out.add(parse(jsonDecode(entry) as Map<String, dynamic>));
      } catch (_) {
        continue;
      }
    }
    return out;
  }

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

  // ---- Cloud session (AWS Cognito) ----
  //
  // Tokens, not a password. The refresh token is the sensitive one - it is
  // what keeps someone signed in - and it lives in the same local store as
  // everything else, which is device-level protection, not secret-grade.

  Future<Map<String, dynamic>?> loadCognitoTokens() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_tokensKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> saveCognitoTokens(Map<String, dynamic>? tokens) async {
    final prefs = await _prefs;
    if (tokens == null) {
      await prefs.remove(_tokensKey);
    } else {
      await prefs.setString(_tokensKey, jsonEncode(tokens));
    }
  }

  /// The address waiting on a confirmation code, so closing the app mid
  /// sign-up does not strand the account in an unconfirmed state with no way
  /// back to the code screen.
  Future<String?> loadPendingEmail() async {
    final prefs = await _prefs;
    return prefs.getString(_pendingEmailKey);
  }

  Future<void> savePendingEmail(String? email) async {
    final prefs = await _prefs;
    if (email == null) {
      await prefs.remove(_pendingEmailKey);
    } else {
      await prefs.setString(_pendingEmailKey, email);
    }
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
    return _decodeList(raw, SavedFood.fromJson)
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
    return _decodeList(raw, HistoryEntry.fromJson)
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
    return _decodeList(raw, NutritionEntry.fromJson);
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
    return _decodeList(raw, Reminder.fromJson)
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

  // ---- Doctor notes ----

  Future<List<DoctorNote>> loadDoctorNotes() async {
    final prefs = await _prefs;
    final raw = prefs.getStringList(_notesKey) ?? [];
    return _decodeList(raw, DoctorNote.fromJson);
  }

  Future<void> saveDoctorNotes(List<DoctorNote> notes) async {
    final prefs = await _prefs;
    await prefs.setStringList(
      _notesKey,
      notes.map((n) => jsonEncode(n.toJson())).toList(),
    );
  }

  // ---- Care plan tick marks ----

  Future<List<String>> loadCareDone() async {
    final prefs = await _prefs;
    return prefs.getStringList(_careDoneKey) ?? const [];
  }

  Future<void> saveCareDone(List<String> ids) async {
    final prefs = await _prefs;
    await prefs.setStringList(_careDoneKey, ids);
  }

  // ---- Emergency contacts ----

  Future<List<EmergencyContact>> loadEmergencyContacts() async {
    final prefs = await _prefs;
    final raw = prefs.getStringList(_contactsKey) ?? [];
    return _decodeList(raw, EmergencyContact.fromJson);
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
    return _decodeList(raw, MedicalReport.fromJson)
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
    return _decodeList(raw, BabyRecord.fromJson)
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

  // ---- Sync ----

  /// Keys that must never leave this device.
  ///
  /// Session tokens identify *this* device's login - copying them to another
  /// device would share a session rather than sync data. Theme is a per-device
  /// preference, not something to force on your other phone.
  static const _neverSync = {
    _accountKey,
    _sessionKey,
    _tokensKey,
    _pendingEmailKey,
    _themeModeKey,
  };

  /// Every syncable key, as one JSON-safe map.
  ///
  /// Values are stored as either a String or a List<String>, so both shapes
  /// are preserved rather than flattened - restoring a list as a string would
  /// silently empty the food log.
  Future<Map<String, dynamic>> exportAll() async {
    final prefs = await _prefs;
    final out = <String, dynamic>{};

    for (final key in prefs.getKeys()) {
      if (_neverSync.contains(key)) continue;
      final value = prefs.get(key);
      if (value is String) {
        out[key] = {'type': 'string', 'value': value};
      } else if (value is List<String>) {
        out[key] = {'type': 'list', 'value': value};
      } else if (value is bool) {
        out[key] = {'type': 'bool', 'value': value};
      } else if (value is int) {
        out[key] = {'type': 'int', 'value': value};
      } else if (value is double) {
        out[key] = {'type': 'double', 'value': value};
      }
    }
    return out;
  }

  /// Replaces the syncable keys with [data].
  ///
  /// Only touches keys present in the incoming document, and never the
  /// never-sync set - so restoring on a second device cannot sign you out or
  /// change that device's theme.
  Future<void> importAll(Map<String, dynamic> data) async {
    final prefs = await _prefs;

    for (final entry in data.entries) {
      if (_neverSync.contains(entry.key)) continue;
      final wrapped = entry.value;
      if (wrapped is! Map) continue;

      final value = wrapped['value'];
      switch (wrapped['type']) {
        case 'string':
          await prefs.setString(entry.key, value as String);
        case 'list':
          await prefs.setStringList(
            entry.key,
            (value as List).map((e) => e.toString()).toList(),
          );
        case 'bool':
          await prefs.setBool(entry.key, value as bool);
        case 'int':
          await prefs.setInt(entry.key, (value as num).toInt());
        case 'double':
          await prefs.setDouble(entry.key, (value as num).toDouble());
      }
    }
  }

  // ---- Reset ----

  Future<void> clearAllData() async {
    final prefs = await _prefs;
    await prefs.clear();
  }
}
