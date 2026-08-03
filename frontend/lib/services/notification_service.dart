import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/reminder.dart';

/// Schedules the repeating local notifications behind the Reminders screen.
///
/// Android is the platform that can actually wake the device when the app is
/// closed, so everything here is written for it and simply no-ops on web,
/// where a browser cannot fire a scheduled alarm without a push server. Call
/// [supportsScheduling] before promising the user an alarm.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  /// Web can show a notification while the tab is open but cannot schedule
  /// one for later, so the UI presents reminders as an in-app schedule there.
  bool get supportsScheduling => !kIsWeb;

  static const _channel = AndroidNotificationDetails(
    'reminders',
    'Reminders',
    channelDescription: 'Meals, feeds, medicines, and bedtime reminders',
    importance: Importance.max,
    priority: Priority.high,
  );

  Future<void> init() async {
    if (_ready || !supportsScheduling) return;

    tz_data.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // An unrecognised zone shouldn't stop the app booting; UTC still fires
      // reminders, just anchored to the wrong offset until the next launch.
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    _ready = true;
  }

  /// Asks for the runtime notification permission (Android 13+) and the
  /// exact-alarm permission that makes reminders fire on the minute.
  Future<bool> requestPermissions() async {
    if (!supportsScheduling) return false;
    await init();

    final android =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission() ?? false;
      await android.requestExactAlarmsPermission();
      return granted;
    }

    final ios =
        _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    }
    return false;
  }

  /// Rewrites every scheduled notification to match [reminders]. Cheaper to
  /// reason about than diffing, and the list is only ever a handful of items.
  Future<void> syncAll(List<Reminder> reminders) async {
    if (!supportsScheduling) return;
    await init();
    await _plugin.cancelAll();
    for (final reminder in reminders.where((r) => r.enabled)) {
      await _schedule(reminder);
    }
  }

  Future<void> cancel(Reminder reminder) async {
    if (!supportsScheduling) return;
    await init();
    await _plugin.cancel(id: reminder.notificationBaseId);
    for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++) {
      await _plugin.cancel(id: reminder.notificationBaseId + weekday);
    }
  }

  Future<void> _schedule(Reminder reminder) async {
    const details = NotificationDetails(android: _channel, iOS: DarwinNotificationDetails());
    final body = reminder.notes.isEmpty
        ? '${reminderKindLabel(reminder.kind)} reminder'
        : reminder.notes;

    if (reminder.isDaily) {
      await _plugin.zonedSchedule(
        id: reminder.notificationBaseId,
        title: reminder.title,
        body: body,
        scheduledDate: _nextInstance(reminder.hour, reminder.minute),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      return;
    }

    // A weekly repeat can only match one weekday, so a Mon/Wed/Fri reminder
    // becomes three separate schedules offset from the same base id.
    for (final weekday in reminder.weekdays) {
      await _plugin.zonedSchedule(
        id: reminder.notificationBaseId + weekday,
        title: reminder.title,
        body: body,
        scheduledDate: _nextInstance(reminder.hour, reminder.minute, weekday: weekday),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  /// Next occurrence of [hour]:[minute], optionally on a given weekday.
  /// Always in the future, so a time earlier today rolls to the next day.
  static tz.TZDateTime _nextInstance(int hour, int minute, {int? weekday}) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (weekday == null) {
      if (!scheduled.isAfter(now)) scheduled = scheduled.add(const Duration(days: 1));
      return scheduled;
    }

    while (scheduled.weekday != weekday || !scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
