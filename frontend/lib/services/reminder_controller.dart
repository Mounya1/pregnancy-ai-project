import 'package:flutter/foundation.dart';
import '../models/reminder.dart';
import 'local_storage_service.dart';
import 'notification_service.dart';

/// Single source of truth for reminders: persists them locally and keeps the
/// scheduled OS notifications in step after every change.
class ReminderController extends ChangeNotifier {
  ReminderController(this._storage);

  final LocalStorageService _storage;
  List<Reminder> _reminders = [];
  bool _loaded = false;

  List<Reminder> get reminders => List.unmodifiable(_reminders);
  bool get isLoaded => _loaded;
  int get activeCount => _reminders.where((r) => r.enabled).length;

  List<Reminder> ofKind(ReminderKind kind) =>
      _reminders.where((r) => r.kind == kind).toList();

  /// The next reminder due today, used for the home screen's "up next" card.
  Reminder? get nextUpToday {
    final now = DateTime.now();
    final minutesNow = now.hour * 60 + now.minute;
    final candidates = _reminders
        .where((r) => r.enabled)
        .where((r) => r.isDaily || r.weekdays.contains(now.weekday))
        .where((r) => r.hour * 60 + r.minute >= minutesNow)
        .toList()
      ..sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
    return candidates.isEmpty ? null : candidates.first;
  }

  Future<void> load() async {
    _reminders = await _storage.loadReminders();
    _loaded = true;
    notifyListeners();
    await NotificationService.instance.syncAll(_reminders);
  }

  Future<void> save(Reminder reminder) async {
    final index = _reminders.indexWhere((r) => r.id == reminder.id);
    if (index >= 0) {
      _reminders[index] = reminder;
    } else {
      _reminders.add(reminder);
    }
    _reminders.sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
    await _persist();
  }

  Future<void> remove(Reminder reminder) async {
    _reminders.removeWhere((r) => r.id == reminder.id);
    await NotificationService.instance.cancel(reminder);
    await _persist();
  }

  Future<void> toggle(Reminder reminder, bool enabled) =>
      save(reminder.copyWith(enabled: enabled));

  Future<void> _persist() async {
    notifyListeners();
    await _storage.saveReminders(_reminders);
    await NotificationService.instance.syncAll(_reminders);
  }
}
