import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/milestone.dart';
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
  bool _unavailable = false;

  /// Web can show a notification while the tab is open but cannot schedule
  /// one for later, so the UI presents reminders as an in-app schedule there.
  bool get supportsScheduling => !kIsWeb;

  /// True once the platform plugin has actually initialised. False in unit
  /// tests and anywhere the plugin is missing - callers use this to tell
  /// "the user said no" apart from "there was nobody to ask".
  bool get isAvailable => _ready;

  static const _channel = AndroidNotificationDetails(
    'reminders',
    'Reminders',
    channelDescription: 'Meals, feeds, medicines, and bedtime reminders',
    importance: Importance.max,
    priority: Priority.high,
  );

  /// A separate channel so a weekly "your baby is the size of a lime" update
  /// can be silenced in Android settings without also silencing the alarm
  /// that says to take an iron tablet.
  static const _milestoneChannel = AndroidNotificationDetails(
    'milestones',
    'Weekly updates',
    channelDescription: 'Week-by-week pregnancy and baby development updates',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
    styleInformation: BigTextStyleInformation(''),
  );

  Future<void> init() async {
    if (_ready || _unavailable || !supportsScheduling) return;

    tz_data.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // An unrecognised zone shouldn't stop the app booting; UTC still fires
      // reminders, just anchored to the wrong offset until the next launch.
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      _ready = true;
    } catch (_) {
      // No platform plugin behind us - a unit test, or a desktop build. Every
      // scheduling call below turns into a no-op rather than taking down the
      // controller that called it.
      _unavailable = true;
    }
  }

  /// Asks for the runtime notification permission (Android 13+) and the
  /// exact-alarm permission that makes reminders fire on the minute.
  Future<bool> requestPermissions() async {
    if (!supportsScheduling) return false;
    await init();
    if (!_ready) return false;

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

  /// Rewrites every scheduled reminder to match [reminders]. Cheaper to
  /// reason about than diffing, and the list is only ever a handful of items.
  ///
  /// Cancels by id range rather than with cancelAll(), which would also drop
  /// the milestone series scheduled alongside it.
  Future<void> syncAll(List<Reminder> reminders) async {
    if (!supportsScheduling) return;
    await init();
    if (!_ready) return;
    await _cancelRange(0, Milestone.idBase - 1);
    for (final reminder in reminders.where((r) => r.enabled)) {
      await _schedule(reminder);
    }
  }

  /// Replaces the milestone series. Each entry is a one-shot with its own
  /// text, because the whole point is that week 21 does not say what week 20
  /// said - a repeating alarm cannot do that.
  Future<void> syncMilestones(List<Milestone> milestones) async {
    if (!supportsScheduling) return;
    await init();
    if (!_ready) return;
    await _cancelRange(Milestone.idBase, Milestone.idMax);

    const details = NotificationDetails(
      android: _milestoneChannel,
      iOS: DarwinNotificationDetails(),
    );

    for (final milestone in milestones) {
      final when = tz.TZDateTime.from(milestone.when, tz.local);
      // Skip anything already past: the caller filters on wall-clock time, but
      // a timezone shift between the two can move a same-day entry backwards.
      if (!when.isAfter(tz.TZDateTime.now(tz.local))) continue;

      await _plugin.zonedSchedule(
        id: milestone.notificationId,
        title: milestone.title,
        body: milestone.body,
        scheduledDate: when,
        notificationDetails: details,
        // These are informational, so they can wait for a battery-friendly
        // window instead of forcing the device awake on the minute.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<void> _cancelRange(int min, int max) async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      if (request.id >= min && request.id <= max) {
        await _plugin.cancel(id: request.id);
      }
    }
  }

  Future<void> cancel(Reminder reminder) async {
    if (!supportsScheduling) return;
    await init();
    if (!_ready) return;
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
