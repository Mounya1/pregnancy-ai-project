import 'package:flutter/foundation.dart';

import '../models/milestone.dart';
import '../models/user_profile.dart';
import 'local_storage_service.dart';
import 'notification_service.dart';

/// When the weekly update should arrive. Off by default - an app that starts
/// sending notifications nobody asked for gets its notifications turned off
/// wholesale, taking the reminders with them.
class MilestoneSettings {
  const MilestoneSettings({
    this.enabled = false,
    this.hour = 9,
    this.minute = 0,
  });

  final bool enabled;
  final int hour;
  final int minute;

  MilestoneSettings copyWith({bool? enabled, int? hour, int? minute}) => MilestoneSettings(
        enabled: enabled ?? this.enabled,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
      );

  Map<String, dynamic> toJson() => {'enabled': enabled, 'hour': hour, 'minute': minute};

  factory MilestoneSettings.fromJson(Map<String, dynamic> json) => MilestoneSettings(
        enabled: json['enabled'] as bool? ?? false,
        hour: (json['hour'] as num?)?.toInt() ?? 9,
        minute: (json['minute'] as num?)?.toInt() ?? 0,
      );
}

/// Keeps the weekly pregnancy / monthly baby updates scheduled.
///
/// The schedule is derived from the profile, so it has to be rebuilt whenever
/// the due date or birth date changes - [syncFor] is called from the app root
/// on every profile change rather than only when these settings are edited.
class MilestoneController extends ChangeNotifier {
  MilestoneController(this._storage);

  final LocalStorageService _storage;

  MilestoneSettings _settings = const MilestoneSettings();
  bool _loaded = false;

  /// The inputs behind the current schedule, so an unrelated profile edit
  /// doesn't trigger a pointless reschedule. Empty until the first sync.
  String _signature = '';

  /// What is actually scheduled right now, newest first. Backs the preview in
  /// the UI so "weekly updates" is something you can see rather than trust.
  List<Milestone> _scheduled = const [];

  MilestoneSettings get settings => _settings;
  bool get isLoaded => _loaded;
  List<Milestone> get scheduled => List.unmodifiable(_scheduled);
  Milestone? get next => _scheduled.isEmpty ? null : _scheduled.first;

  /// Web can show a notification while the tab is open but cannot schedule one
  /// for a date weeks away, so the UI offers this as an in-app preview there.
  bool get canSchedule => NotificationService.instance.supportsScheduling;

  /// Reads the settings *and* the stored profile, then schedules from both.
  ///
  /// Reading the profile directly rather than waiting to be handed one avoids
  /// a startup race: ProfileController loads on its own schedule, and until it
  /// finishes there is nothing to derive a due date from.
  Future<void> load() async {
    final stored = await _storage.loadMilestoneSettings();
    if (stored != null) _settings = MilestoneSettings.fromJson(stored);
    _loaded = true;

    await syncFor(await _storage.loadProfile() ?? UserProfile());
  }

  Future<void> setEnabled(bool enabled, UserProfile profile) async {
    if (enabled) {
      // Ask before promising anything. A silently-denied permission looks
      // exactly like a feature that does not work.
      //
      // Only a real refusal blocks the toggle: isAvailable separates "the
      // user said no" from "there was no plugin to ask", which is the case
      // in tests and on desktop.
      final granted = await NotificationService.instance.requestPermissions();
      if (!granted && NotificationService.instance.isAvailable) {
        await _apply(_settings.copyWith(enabled: false), profile);
        return;
      }
    }
    await _apply(_settings.copyWith(enabled: enabled), profile);
  }

  Future<void> setTime(int hour, int minute, UserProfile profile) =>
      _apply(_settings.copyWith(hour: hour, minute: minute), profile);

  /// Recomputes and reschedules from the current profile.
  ///
  /// Called on every profile change, so it short-circuits when nothing that
  /// affects the schedule has actually moved - otherwise editing an allergy
  /// would rewrite forty alarms.
  Future<void> syncFor(UserProfile profile) async {
    if (!_loaded) return;

    final signature = '${_settings.enabled}|${_settings.hour}:${_settings.minute}'
        '|${profile.lifeStage.name}|${profile.dueDate}|${profile.babyBirthDate}';
    if (signature == _signature) return;
    _signature = signature;

    _scheduled = _settings.enabled
        ? upcomingMilestones(
            profile,
            from: DateTime.now(),
            hour: _settings.hour,
            minute: _settings.minute,
          )
        : const [];

    notifyListeners();
    await NotificationService.instance.syncMilestones(_scheduled);
  }

  Future<void> _apply(MilestoneSettings next, UserProfile profile) async {
    _settings = next;
    await _storage.saveMilestoneSettings(next.toJson());
    await syncFor(profile);
  }
}
