import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/medical_report.dart';
import '../models/nutrition_log.dart';
import '../models/weekly_stats.dart';
import '../services/local_storage_service.dart';
import '../services/profile_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/ui/app_card.dart';
import '../widgets/ui/charts.dart';
import '../widgets/ui/empty_state.dart';
import '../widgets/ui/reveal.dart';
import '../widgets/ui/shimmer.dart';
import '../widgets/ui/trend_badge.dart';

/// Weekly view of diet and medical trends: what moved up, what slipped, and
/// what the last few reports say about the same measure over time.
class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key, this.embedded = false});

  /// True when hosted inside a section tab, which supplies its own app bar.
  final bool embedded;

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  final _storage = LocalStorageService();
  List<NutritionEntry> _entries = [];
  List<MedicalReport> _reports = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await _storage.loadNutritionEntries();
    final reports = await _storage.loadMedicalReports();
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _reports = reports;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final profile = context.watch<ProfileController>().profile;
    final stats = WeeklyStats(entries: _entries, lifeStage: profile.lifeStage);
    final weeks = stats.build();

    return Scaffold(
      appBar: widget.embedded ? null : AppBar(title: const Text('Weekly trends')),
      body: _loading
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: SkeletonCardList(count: 3, height: 170),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.sm,
                  AppSpacing.xl,
                  AppSpacing.xxl,
                ),
                children: [
                  Reveal(child: _WeekHeader(stats: stats, weeks: weeks)),
                  const SizedBox(height: AppSpacing.xxl),
                  const SectionHeader(
                    title: 'Nutrients this week',
                    subtitle: 'Daily totals against your target, vs last week',
                  ),
                  for (var i = 0; i < weeks.length; i++)
                    Reveal.stagger(
                      index: i,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _NutrientWeekCard(
                          week: weeks[i],
                          todayIndex: stats.todayIndex,
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xl),
                  const SectionHeader(
                    title: 'Medical findings',
                    subtitle: 'How the same measure moved across your reports',
                  ),
                  if (_reports.length < 2)
                    AppCard(
                      shadow: false,
                      color: p.surfaceAlt,
                      borderColor: Colors.transparent,
                      child: Row(
                        children: [
                          Icon(Icons.info_rounded, size: 17, color: p.textMuted),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              _reports.isEmpty
                                  ? 'Upload a medical report and its values will be tracked here.'
                                  : 'Upload one more report and you will see how each value has moved.',
                              style: context.texts.bodySmall?.copyWith(color: p.textMuted),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    _FindingsTrend(reports: _reports),
                ],
              ),
            ),
    );
  }
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader({required this.stats, required this.weeks});

  final WeeklyStats stats;
  final List<NutrientWeek> weeks;

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('MMM d');
    final end = stats.weekStart.add(const Duration(days: 6));

    return GradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, color: Colors.white, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${format.format(stats.weekStart)} - ${format.format(end)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '${stats.daysLogged}/7 days',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            stats.summarise(weeks),
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }
}

class _NutrientWeekCard extends StatelessWidget {
  const _NutrientWeekCard({required this.week, required this.todayIndex});

  final NutrientWeek week;
  final int todayIndex;

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(week.label, style: context.texts.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      'Avg ${week.average.toStringAsFixed(0)} of ${week.target.toStringAsFixed(0)} ${week.unit} a day',
                      style: TextStyle(fontSize: 11.5, color: p.textMuted),
                    ),
                  ],
                ),
              ),
              // Every nutrient here is one you want more of, not less.
              TrendBadge(deltaPercent: week.deltaPercent),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          WeeklyBarChart(
            data: List.generate(
              week.dailyTotals.length,
              (i) => BarDatum(
                label: _dayLabels[i],
                value: week.dailyTotals[i],
                highlight: i == todayIndex,
              ),
            ),
            target: week.target,
            unit: week.unit,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(Icons.check_circle_rounded, size: 13, color: p.safe),
              const SizedBox(width: AppSpacing.xs + 2),
              Text(
                '${week.daysTargetMet} of 7 days at target',
                style: TextStyle(fontSize: 11.5, color: p.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Pairs findings with the same label across reports so a value that went from
/// low to normal reads as an improvement.
class _FindingsTrend extends StatelessWidget {
  const _FindingsTrend({required this.reports});

  final List<MedicalReport> reports;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // loadMedicalReports() sorts newest first.
    final latest = reports.first;
    final previous = reports[1];

    final rows = <Widget>[];
    for (final finding in latest.findings) {
      final before = previous.findings.firstWhere(
        (f) => f.label.toLowerCase() == finding.label.toLowerCase(),
        orElse: () => const ReportFinding(
          label: '',
          value: '',
          status: FindingStatus.unknown,
        ),
      );
      rows.add(_FindingRow(now: finding, before: before.label.isEmpty ? null : before));
    }

    if (rows.isEmpty) {
      return AppCard(
        shadow: false,
        color: p.surfaceAlt,
        borderColor: Colors.transparent,
        child: Text(
          'Your latest report had no measured values to compare.',
          style: context.texts.bodySmall?.copyWith(color: p.textMuted),
        ),
      );
    }

    return AppCard(child: Column(children: rows));
  }
}

class _FindingRow extends StatelessWidget {
  const _FindingRow({required this.now, this.before});

  final ReportFinding now;
  final ReportFinding? before;

  /// Ranks a status so "low -> normal" can be recognised as getting better.
  static int _rank(FindingStatus s) {
    switch (s) {
      case FindingStatus.normal:
        return 2;
      case FindingStatus.low:
      case FindingStatus.high:
        return 1;
      case FindingStatus.unknown:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final prev = before;

    Widget badge;
    if (prev == null || prev.status == FindingStatus.unknown) {
      badge = Text('new', style: TextStyle(fontSize: 10.5, color: p.textMuted));
    } else {
      final delta = _rank(now.status) - _rank(prev.status);
      final (fg, bg, icon, label) = delta > 0
          ? (p.safe, p.safeSurface, Icons.trending_up_rounded, 'Improved')
          : delta < 0
              ? (p.limit, p.limitSurface, Icons.trending_down_rounded, 'Worse')
              : (p.neutral, p.neutralSurface, Icons.trending_flat_rounded, 'Same');
      badge = Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: fg.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: fg),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(now.label, style: context.texts.titleSmall),
                const SizedBox(height: 2),
                Text(
                  prev == null
                      ? '${now.value}  (${findingStatusLabel(now.status)})'
                      : '${prev.value} -> ${now.value}  (${findingStatusLabel(prev.status)} -> ${findingStatusLabel(now.status)})',
                  style: TextStyle(fontSize: 11.5, color: p.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          badge,
        ],
      ),
    );
  }
}
