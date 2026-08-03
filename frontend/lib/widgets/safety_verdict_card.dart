import 'package:flutter/material.dart';
import '../models/food_safety_response.dart';
import '../theme/app_theme.dart';
import 'ui/app_card.dart';
import 'ui/reveal.dart';
import 'ui/verdict_chip.dart';

/// The app's core answer surface: one verdict for one audience (mother or
/// baby), with the reasoning, benefits, risks, serving guidance, and sources
/// behind it.
class SafetyVerdictCard extends StatelessWidget {
  const SafetyVerdictCard({
    super.key,
    required this.result,
    this.title,
    this.onListenPressed,
  });

  final FoodSafetyResponse result;

  /// Overrides the default "For you" / "For baby" label, e.g. "For you while nursing".
  final String? title;

  final VoidCallback? onListenPressed;

  String get _defaultTitle => result.target == Target.baby ? 'For baby' : 'For you';

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final style = VerdictStyle.of(context, result.verdict);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Verdict-tinted banner so the answer reads at a glance before
            // any of the explanation is processed.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              color: style.background,
              child: Row(
                children: [
                  Icon(
                    result.target == Target.baby
                        ? Icons.child_care_rounded
                        : Icons.pregnant_woman_rounded,
                    size: 17,
                    color: style.foreground,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      title ?? _defaultTitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: style.foreground,
                      ),
                    ),
                  ),
                  VerdictChip(verdict: result.verdict),
                ],
              ),
            ),
            if (result.isHighRiskOverride)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                color: p.avoidSurface,
                child: Row(
                  children: [
                    Icon(Icons.priority_high_rounded, size: 14, color: p.avoid),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Flagged as high risk by clinical guidance',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: p.avoid,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(result.explanation, style: context.texts.bodyMedium),
                  if (result.benefits.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _BulletList(
                      items: result.benefits,
                      icon: Icons.check_circle_rounded,
                      color: p.safe,
                    ),
                  ],
                  if (result.risks.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    _BulletList(
                      items: result.risks,
                      icon: Icons.error_rounded,
                      color: p.avoid,
                    ),
                  ],
                  if (result.recommendedServing != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _InfoPill(
                      icon: Icons.local_dining_rounded,
                      label: 'Recommended',
                      value: result.recommendedServing!,
                    ),
                  ],
                  if (result.betterAlternatives.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    _InfoPill(
                      icon: Icons.swap_horiz_rounded,
                      label: 'Try instead',
                      value: result.betterAlternatives.join(', '),
                    ),
                  ],
                  if (result.sources.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: result.sources
                          .map((s) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: p.surfaceAlt,
                                  borderRadius: BorderRadius.circular(AppRadius.pill),
                                  border: Border.all(color: p.border),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified_rounded, size: 11, color: p.textMuted),
                                    const SizedBox(width: 4),
                                    Text(
                                      s,
                                      style: TextStyle(fontSize: 11, color: p.textSecondary),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                  if (onListenPressed != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onListenPressed,
                        icon: const Icon(Icons.volume_up_rounded, size: 16),
                        label: const Text('Listen to explanation'),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    result.disclaimer,
                    style: TextStyle(fontSize: 10, height: 1.4, color: p.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({required this.items, required this.icon, required this.color});

  final List<String> items;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map((item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs + 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Icon(icon, size: 14, color: color),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: context.palette.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: p.brandSurface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: p.brandSoft),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 12, height: 1.4, color: p.textSecondary),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: TextStyle(fontWeight: FontWeight.w700, color: p.brandSoft),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders one or two SafetyVerdictCards stacked - mother always, baby only
/// when the backend returned a baby_structured verdict.
class DualVerdictSection extends StatelessWidget {
  const DualVerdictSection({
    super.key,
    required this.motherResult,
    this.babyResult,
    this.onListenMother,
    this.onListenBaby,
    this.onSave,
    this.isSaved = false,
  });

  final FoodSafetyResponse motherResult;
  final FoodSafetyResponse? babyResult;
  final VoidCallback? onListenMother;
  final VoidCallback? onListenBaby;

  /// If provided, shows a bookmark button that saves both verdicts together.
  final VoidCallback? onSave;
  final bool isSaved;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (onSave != null)
          Align(
            alignment: Alignment.centerRight,
            child: Pressable(
              onTap: isSaved ? null : onSave,
              child: Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm - 2,
                ),
                decoration: BoxDecoration(
                  color: isSaved ? p.brandSurface : p.surface,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: isSaved ? Colors.transparent : p.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      size: 15,
                      color: isSaved ? p.brandSoft : p.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.xs + 2),
                    Text(
                      isSaved ? 'Saved' : 'Save',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSaved ? p.brandSoft : p.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Reveal(child: SafetyVerdictCard(result: motherResult, onListenPressed: onListenMother)),
        if (babyResult != null) ...[
          const SizedBox(height: AppSpacing.md),
          Reveal(
            delay: const Duration(milliseconds: 90),
            child: SafetyVerdictCard(
              result: babyResult!,
              title: 'For baby',
              onListenPressed: onListenBaby,
            ),
          ),
        ],
      ],
    );
  }
}
