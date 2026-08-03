import 'package:flutter/material.dart';
import '../models/pregnancy_week.dart';
import '../theme/app_theme.dart';
import '../widgets/ui/app_card.dart';
import '../widgets/ui/illustrations.dart';
import '../widgets/ui/reveal.dart';

/// Full detail for one week: the size comparison, the measurements, what is
/// developing, and what the mother may be feeling. Swipeable across weeks so
/// it is easy to look ahead or back.
class WeekDetailScreen extends StatefulWidget {
  const WeekDetailScreen({super.key, required this.initialWeek});

  final int initialWeek;

  @override
  State<WeekDetailScreen> createState() => _WeekDetailScreenState();
}

class _WeekDetailScreenState extends State<WeekDetailScreen> {
  late final PageController _controller =
      PageController(initialPage: widget.initialWeek.clamp(1, kPregnancyWeeks.length) - 1);
  late int _week = widget.initialWeek.clamp(1, kPregnancyWeeks.length);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      appBar: AppBar(
        title: Text('Week $_week'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xl),
              child: Text(
                pregnancyWeekInfo(_week).trimesterLabel,
                style: TextStyle(fontSize: 12, color: p.textMuted),
              ),
            ),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: kPregnancyWeeks.length,
        onPageChanged: (i) => setState(() => _week = i + 1),
        itemBuilder: (context, i) => _WeekPage(info: kPregnancyWeeks[i]),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: _week > 1
                    ? () => _controller.previousPage(
                          duration: AppMotion.base,
                          curve: AppMotion.emphasized,
                        )
                    : null,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  'Swipe to browse weeks',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: p.textMuted),
                ),
              ),
              IconButton(
                onPressed: _week < kPregnancyWeeks.length
                    ? () => _controller.nextPage(
                          duration: AppMotion.base,
                          curve: AppMotion.emphasized,
                        )
                    : null,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekPage extends StatelessWidget {
  const _WeekPage({required this.info});

  final PregnancyWeek info;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      children: [
        Reveal(child: SizeCard(info: info)),
        const SizedBox(height: AppSpacing.xl),
        Reveal(
          delay: const Duration(milliseconds: 70),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: p.brandSurface,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(Icons.child_care_rounded, size: 17, color: p.brandSoft),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text('Your baby this week', style: context.texts.titleMedium),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  info.babyDevelopment,
                  style: TextStyle(fontSize: 13.5, height: 1.55, color: p.textSecondary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Reveal(
          delay: const Duration(milliseconds: 140),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: p.accent.withValues(alpha: p.isDark ? 0.22 : 0.14),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(Icons.favorite_rounded, size: 17, color: p.accent),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text('How you may feel', style: context.texts.titleMedium),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  info.motherExperience,
                  style: TextStyle(fontSize: 13.5, height: 1.55, color: p.textSecondary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Sizes and weights are averages for this week of pregnancy, not a measurement of your baby. Only your scan can tell you how yours is growing.',
          style: TextStyle(fontSize: 10.5, height: 1.45, color: p.textMuted),
        ),
      ],
    );
  }
}

/// The "your baby is now the size of..." panel from the reference layout.
class SizeCard extends StatelessWidget {
  const SizeCard({super.key, required this.info, this.compact = false});

  final PregnancyWeek info;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AppCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [p.brandSurface, p.surface],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(child: BlobDecoration(color: p.brand, seed: info.week)),
              Padding(
                padding: EdgeInsets.all(compact ? AppSpacing.lg : AppSpacing.xl),
                child: Column(
                  children: [
                    Container(
                      width: compact ? 76 : 104,
                      height: compact ? 76 : 104,
                      decoration: BoxDecoration(
                        color: p.surface,
                        shape: BoxShape.circle,
                        boxShadow: p.softShadow,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        info.emoji,
                        style: TextStyle(fontSize: compact ? 36 : 50),
                      ),
                    ),
                    SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
                    Text(
                      'Your baby is now the size of',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: p.textMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      info.sizeComparison,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: compact ? 17 : 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: p.textPrimary,
                      ),
                    ),
                    SizedBox(height: compact ? AppSpacing.md : AppSpacing.xl),
                    Row(
                      children: [
                        _Metric(label: 'WEIGHT', value: info.weightDisplay),
                        const SizedBox(width: AppSpacing.sm),
                        _Metric(label: 'LENGTH', value: info.lengthDisplay),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'length measured ${info.lengthLabel}',
                      style: TextStyle(fontSize: 9.5, color: p.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: p.border),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
                color: p.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: p.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
