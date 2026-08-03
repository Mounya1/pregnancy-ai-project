import 'package:flutter/material.dart';

/// What a reminder is for. Drives its icon, tint, and the default title
/// offered when creating one.
enum ReminderKind { motherMeal, babyFeed, medicine, supplement, water, bedtime }

ReminderKind reminderKindFromString(String? value) {
  return ReminderKind.values.firstWhere(
    (k) => k.name == value,
    orElse: () => ReminderKind.motherMeal,
  );
}

String reminderKindLabel(ReminderKind kind) {
  switch (kind) {
    case ReminderKind.motherMeal:
      return 'My meal';
    case ReminderKind.babyFeed:
      return 'Baby feed';
    case ReminderKind.medicine:
      return 'Medicine';
    case ReminderKind.supplement:
      return 'Supplement';
    case ReminderKind.water:
      return 'Water';
    case ReminderKind.bedtime:
      return 'Bedtime';
  }
}

IconData reminderKindIcon(ReminderKind kind) {
  switch (kind) {
    case ReminderKind.motherMeal:
      return Icons.restaurant_rounded;
    case ReminderKind.babyFeed:
      return Icons.child_care_rounded;
    case ReminderKind.medicine:
      return Icons.medication_rounded;
    case ReminderKind.supplement:
      return Icons.medication_liquid_rounded;
    case ReminderKind.water:
      return Icons.water_drop_rounded;
    case ReminderKind.bedtime:
      return Icons.bedtime_rounded;
  }
}

/// Sensible default title so creating a reminder is a two-tap job.
String reminderKindDefaultTitle(ReminderKind kind) {
  switch (kind) {
    case ReminderKind.motherMeal:
      return 'Time to eat';
    case ReminderKind.babyFeed:
      return 'Baby feeding time';
    case ReminderKind.medicine:
      return 'Take your medicine';
    case ReminderKind.supplement:
      return 'Take your supplement';
    case ReminderKind.water:
      return 'Drink some water';
    case ReminderKind.bedtime:
      return 'Time to wind down';
  }
}

const kWeekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

class Reminder {
  Reminder({
    required this.id,
    required this.kind,
    required this.title,
    required this.hour,
    required this.minute,
    this.notes = '',
    Set<int>? weekdays,
    this.enabled = true,
  }) : weekdays = weekdays ?? const {};

  final String id;
  final ReminderKind kind;
  final String title;
  final int hour;
  final int minute;
  final String notes;

  /// DateTime.monday(1) .. DateTime.sunday(7). Empty means every day.
  final Set<int> weekdays;
  final bool enabled;

  bool get isDaily => weekdays.isEmpty || weekdays.length == 7;

  TimeOfDay get time => TimeOfDay(hour: hour, minute: minute);

  /// Stable positive base for platform notification ids, which must be ints.
  /// Per-weekday schedules offset from this by the weekday number.
  int get notificationBaseId => id.hashCode & 0x00FFFFFF;

  String get scheduleLabel {
    if (isDaily) return 'Every day';
    final days = weekdays.toList()..sort();
    return days.map((d) => kWeekdayLabels[d - 1]).join(' ');
  }

  String formattedTime(BuildContext context) =>
      MaterialLocalizations.of(context).formatTimeOfDay(time);

  Reminder copyWith({
    ReminderKind? kind,
    String? title,
    int? hour,
    int? minute,
    String? notes,
    Set<int>? weekdays,
    bool? enabled,
  }) {
    return Reminder(
      id: id,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      notes: notes ?? this.notes,
      weekdays: weekdays ?? this.weekdays,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'title': title,
        'hour': hour,
        'minute': minute,
        'notes': notes,
        'weekdays': weekdays.toList(),
        'enabled': enabled,
      };

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
        id: json['id'] as String,
        kind: reminderKindFromString(json['kind'] as String?),
        title: json['title'] as String? ?? '',
        hour: json['hour'] as int? ?? 8,
        minute: json['minute'] as int? ?? 0,
        notes: json['notes'] as String? ?? '',
        weekdays: Set<int>.from(json['weekdays'] ?? const []),
        enabled: json['enabled'] as bool? ?? true,
      );
}
