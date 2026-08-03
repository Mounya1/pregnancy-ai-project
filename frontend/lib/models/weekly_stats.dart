import 'nutrition_log.dart';
import 'user_profile.dart';

/// One nutrient's week: daily totals, the week average, and how that average
/// compares with the week before.
class NutrientWeek {
  const NutrientWeek({
    required this.label,
    required this.unit,
    required this.dailyTotals,
    required this.target,
    required this.previousAverage,
  });

  final String label;
  final String unit;

  /// Seven entries, Monday first.
  final List<double> dailyTotals;
  final double target;

  /// Average daily intake over the previous 7 days; null when there is no
  /// prior data to compare against.
  final double? previousAverage;

  double get total => dailyTotals.fold(0.0, (a, b) => a + b);

  double get average => dailyTotals.isEmpty ? 0 : total / dailyTotals.length;

  /// Share of the daily target the average day covers, capped for display.
  double get targetRatio => target <= 0 ? 0 : (average / target).clamp(0.0, 1.0).toDouble();

  int get daysTargetMet => dailyTotals.where((d) => target > 0 && d >= target).length;

  /// Percent change in daily average vs the previous week. Null when there is
  /// nothing to compare, or when last week was zero (any increase from zero
  /// would read as an infinite improvement).
  double? get deltaPercent {
    final prev = previousAverage;
    if (prev == null || prev <= 0) return null;
    return ((average - prev) / prev) * 100;
  }
}

/// Aggregates the nutrition log into this-week / last-week comparisons.
///
/// Weeks run Monday to Sunday so "this week" matches how people talk about it,
/// rather than a rolling 7 days that shifts every day.
class WeeklyStats {
  WeeklyStats({required this.entries, required this.lifeStage, DateTime? now})
      : _now = now ?? DateTime.now();

  final List<NutritionEntry> entries;
  final LifeStage lifeStage;
  final DateTime _now;

  DateTime get weekStart {
    final today = DateTime(_now.year, _now.month, _now.day);
    return today.subtract(Duration(days: today.weekday - DateTime.monday));
  }

  DateTime get previousWeekStart => weekStart.subtract(const Duration(days: 7));

  /// Index into the current week for today, 0 = Monday.
  int get todayIndex => _now.weekday - DateTime.monday;

  List<NutrientWeek> build() {
    final targets = targetsForLifeStage(lifeStage);
    final thisWeek = _dailyBuckets(weekStart);
    final lastWeek = _dailyBuckets(previousWeekStart);

    double? prevAvg(double Function(NutrientProfile) pick) {
      final values = lastWeek.map(pick).toList();
      final sum = values.fold(0.0, (a, b) => a + b);
      // No logging at all last week is "no comparison", not "zero intake".
      return sum <= 0 ? null : sum / values.length;
    }

    List<double> daily(double Function(NutrientProfile) pick) =>
        thisWeek.map(pick).toList();

    return [
      NutrientWeek(
        label: 'Iron',
        unit: 'mg',
        dailyTotals: daily((n) => n.ironMg),
        target: targets.ironMg,
        previousAverage: prevAvg((n) => n.ironMg),
      ),
      NutrientWeek(
        label: 'Calcium',
        unit: 'mg',
        dailyTotals: daily((n) => n.calciumMg),
        target: targets.calciumMg,
        previousAverage: prevAvg((n) => n.calciumMg),
      ),
      NutrientWeek(
        label: 'Folate',
        unit: 'mcg',
        dailyTotals: daily((n) => n.folateMcg),
        target: targets.folateMcg,
        previousAverage: prevAvg((n) => n.folateMcg),
      ),
      NutrientWeek(
        label: 'Protein',
        unit: 'g',
        dailyTotals: daily((n) => n.proteinG),
        target: targets.proteinG,
        previousAverage: prevAvg((n) => n.proteinG),
      ),
      NutrientWeek(
        label: 'Vitamin D',
        unit: 'mcg',
        dailyTotals: daily((n) => n.vitaminDMcg),
        target: targets.vitaminDMcg,
        previousAverage: prevAvg((n) => n.vitaminDMcg),
      ),
    ];
  }

  /// Seven per-day nutrient totals starting at [start].
  List<NutrientProfile> _dailyBuckets(DateTime start) {
    return List.generate(7, (i) {
      final day = start.add(Duration(days: i));
      return entries
          .where((e) => e.isSameDay(day))
          .fold(const NutrientProfile(), (sum, e) => sum + e.nutrients);
    });
  }

  /// How many days this week have at least one logged food.
  int get daysLogged {
    return List.generate(7, (i) => weekStart.add(Duration(days: i)))
        .where((day) => entries.any((e) => e.isSameDay(day)))
        .length;
  }

  /// A single plain-language read on the week, used as the screen's headline.
  String summarise(List<NutrientWeek> weeks) {
    if (daysLogged == 0) {
      return 'Nothing logged this week yet. Log a few foods and your trends will appear here.';
    }
    final improving = weeks.where((w) => (w.deltaPercent ?? 0) >= 5).length;
    final declining = weeks.where((w) => (w.deltaPercent ?? 0) <= -5).length;
    final onTarget = weeks.where((w) => w.targetRatio >= 1).length;

    if (weeks.every((w) => w.deltaPercent == null)) {
      return '$daysLogged of 7 days logged. Keep going - next week you will get a comparison.';
    }
    if (improving > declining) {
      return 'Trending up: $improving of ${weeks.length} nutrients improved on last week, and $onTarget are at target.';
    }
    if (declining > improving) {
      return '$declining of ${weeks.length} nutrients dipped below last week. Worth a look at the ones marked lower.';
    }
    return 'Holding steady against last week, with $onTarget of ${weeks.length} nutrients at target.';
  }
}
