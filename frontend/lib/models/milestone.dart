import 'baby_month.dart';
import 'pregnancy_week.dart';
import 'user_profile.dart';

enum MilestoneKind { pregnancyWeek, babyMonth }

/// One dated "here is what changed" notification.
///
/// Each week (or month) carries different text, so these are scheduled as a
/// series of one-shots rather than one repeating alarm - a weekly repeat can
/// only ever say the same thing.
class Milestone {
  const Milestone({
    required this.kind,
    required this.index,
    required this.when,
    required this.title,
    required this.body,
  });

  final MilestoneKind kind;

  /// Pregnancy week number, or baby age in months.
  final int index;

  final DateTime when;
  final String title;
  final String body;

  /// Sits above the range reminders use (their ids are a 24-bit hash), so the
  /// two schedules can be cancelled independently.
  static const int idBase = 0x01000000;
  static const int idMax = 0x01FFFFFF;

  int get notificationId =>
      idBase + (kind == MilestoneKind.pregnancyWeek ? index : 100 + index);
}

/// The date pregnancy week [week] begins, counting back from the due date.
///
/// Mirrors [UserProfile.pregnancyWeek] exactly - if these two ever disagree,
/// the app announces a week the rest of the UI is not showing yet.
DateTime pregnancyWeekStart(DateTime dueDate, int week) {
  // Calendar arithmetic, not Duration: subtracting 24-hour blocks across a
  // daylight-saving change lands on 23:00 the day before or 01:00 the day
  // after. DateTime's constructor normalises out-of-range days instead.
  return DateTime(dueDate.year, dueDate.month, dueDate.day - (40 - week) * 7);
}

/// The date the baby turns [month] months old. Clamps to the last day of a
/// short month, so a baby born on the 31st gets the 28th in February rather
/// than rolling into March.
DateTime babyMonthStart(DateTime birthDate, int month) {
  final target = DateTime(birthDate.year, birthDate.month + month, 1);
  final daysInMonth = DateTime(target.year, target.month + 1, 0).day;
  return DateTime(target.year, target.month, birthDate.day.clamp(1, daysInMonth));
}

/// Every milestone still ahead of [from], at [hour]:[minute] local time.
///
/// Returns empty when there is no date to count from - a profile with no due
/// date or birth date has nothing to announce, and guessing one would be
/// worse than staying quiet.
List<Milestone> upcomingMilestones(
  UserProfile profile, {
  required DateTime from,
  int hour = 9,
  int minute = 0,
}) {
  // Once the baby is here, the pregnancy countdown is over even if the old
  // due date is still on the profile.
  final birthDate = profile.babyBirthDate;
  if (birthDate != null) {
    return _babyMilestones(birthDate, from: from, hour: hour, minute: minute);
  }

  final dueDate = profile.dueDate;
  if (dueDate != null && profile.lifeStage == LifeStage.pregnancy) {
    return _pregnancyMilestones(dueDate, from: from, hour: hour, minute: minute);
  }

  return const [];
}

List<Milestone> _pregnancyMilestones(
  DateTime dueDate, {
  required DateTime from,
  required int hour,
  required int minute,
}) {
  final out = <Milestone>[];

  for (final info in kPregnancyWeeks) {
    final start = pregnancyWeekStart(dueDate, info.week);
    final when = DateTime(start.year, start.month, start.day, hour, minute);
    if (!when.isAfter(from)) continue;

    out.add(Milestone(
      kind: MilestoneKind.pregnancyWeek,
      index: info.week,
      when: when,
      title: 'Week ${info.week} ${info.emoji}  ·  ${info.trimesterLabel}',
      body: 'Baby is about the size of ${info.sizeComparison}. '
          '${info.babyDevelopment}\n\nYou: ${info.motherExperience}',
    ));
  }

  return out;
}

List<Milestone> _babyMilestones(
  DateTime birthDate, {
  required DateTime from,
  required int hour,
  required int minute,
}) {
  final out = <Milestone>[];

  for (final info in kBabyMonths) {
    // Month 0 is the day they were born - there is nothing to announce.
    if (info.month == 0) continue;

    final start = babyMonthStart(birthDate, info.month);
    final when = DateTime(start.year, start.month, start.day, hour, minute);
    if (!when.isAfter(from)) continue;

    out.add(Milestone(
      kind: MilestoneKind.babyMonth,
      index: info.month,
      when: when,
      title: '${info.ageLabel} ${info.emoji}  ·  ${info.headline}',
      body: '${info.development}\n\nFeeding: ${info.feeding}',
    ));
  }

  return out;
}
