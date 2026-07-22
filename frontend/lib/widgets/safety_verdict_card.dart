import 'package:flutter/material.dart';
import '../models/food_safety_response.dart';
import '../theme/app_theme.dart';

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

  (Color, Color) get _verdictColors {
    switch (result.verdict) {
      case SafetyVerdict.safe:
        return (AppColors.safeBg, AppColors.safe);
      case SafetyVerdict.limit:
        return (AppColors.limitBg, AppColors.limit);
      case SafetyVerdict.avoid:
        return (AppColors.avoidBg, AppColors.avoid);
      case SafetyVerdict.unknown:
        return (AppColors.border, AppColors.textSecondary);
    }
  }

  String get _defaultTitle => result.target == Target.baby ? 'For baby' : 'For you';

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _verdictColors;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title ?? _defaultTitle,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    verdictLabel(result.verdict),
                    style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(result.explanation, style: const TextStyle(fontSize: 13, height: 1.5)),
            if (result.benefits.isNotEmpty) ...[
              const SizedBox(height: 10),
              ..._bulletList(result.benefits, Icons.check_circle, AppColors.safe),
            ],
            if (result.risks.isNotEmpty) ...[
              const SizedBox(height: 6),
              ..._bulletList(result.risks, Icons.error_outline, AppColors.avoid),
            ],
            if (result.recommendedServing != null) ...[
              const SizedBox(height: 8),
              Text(
                'Recommended: ${result.recommendedServing}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
            if (result.sources.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                children: result.sources
                    .map((s) => Chip(
                          label: Text(s, style: const TextStyle(fontSize: 11)),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: AppColors.border),
                        ))
                    .toList(),
              ),
            ],
            if (onListenPressed != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onListenPressed,
                  icon: const Icon(Icons.volume_up, size: 16),
                  label: const Text('Listen to explanation'),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              result.disclaimer,
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _bulletList(List<String> items, IconData icon, Color color) {
    return items
        .map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 13, color: color),
                  const SizedBox(width: 6),
                  Expanded(child: Text(item, style: const TextStyle(fontSize: 12))),
                ],
              ),
            ))
        .toList();
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
  });

  final FoodSafetyResponse motherResult;
  final FoodSafetyResponse? babyResult;
  final VoidCallback? onListenMother;
  final VoidCallback? onListenBaby;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SafetyVerdictCard(result: motherResult, onListenPressed: onListenMother),
        if (babyResult != null) ...[
          const SizedBox(height: 10),
          SafetyVerdictCard(
            result: babyResult!,
            title: 'For baby',
            onListenPressed: onListenBaby,
          ),
        ],
      ],
    );
  }
}
