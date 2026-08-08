import 'package:flutter/material.dart';

import '../models/nutrition_log.dart';
import '../theme/app_theme.dart';

/// The five tracked nutrients for one food, with each shown as a share of the
/// day's target.
///
/// Used by the scan result and the add-food sheet, so a food's numbers look
/// the same wherever you meet them.
class NutrientBreakdown extends StatelessWidget {
  const NutrientBreakdown({
    super.key,
    required this.nutrients,
    required this.targets,
    this.servingDescription,
    this.note = '',
    this.isEstimate = false,
    this.dense = false,
  });

  final NutrientProfile nutrients;
  final NutrientProfile targets;

  /// What one serving means, e.g. "1 cup cooked (180g)".
  final String? servingDescription;

  /// What the estimate assumed. Shown only when there is something to say.
  final String note;

  /// Drives the "Estimated" chip. An estimate is never shown as a measurement.
  final bool isEstimate;

  final bool dense;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    final rows = <(String, double, double, String)>[
      ('Iron', nutrients.ironMg, targets.ironMg, 'mg'),
      ('Calcium', nutrients.calciumMg, targets.calciumMg, 'mg'),
      ('Folate', nutrients.folateMcg, targets.folateMcg, 'mcg'),
      ('Protein', nutrients.proteinG, targets.proteinG, 'g'),
      ('Vitamin D', nutrients.vitaminDMcg, targets.vitaminDMcg, 'mcg'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (servingDescription != null || isEstimate) ...[
          Row(
            children: [
              if (servingDescription != null)
                Expanded(
                  child: Text(
                    servingDescription!,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: p.textSecondary,
                    ),
                  ),
                ),
              if (isEstimate)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: p.limitSurface,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    'Estimated',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                      color: p.limit,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: dense ? AppSpacing.sm : AppSpacing.md),
        ],
        if (nutrients.isEmpty)
          Text(
            'None of the five tracked nutrients in any meaningful amount.',
            style: TextStyle(fontSize: 11.5, height: 1.4, color: p.textMuted),
          )
        else
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) SizedBox(height: dense ? AppSpacing.sm : AppSpacing.md),
            _Row(
              label: rows[i].$1,
              value: rows[i].$2,
              target: rows[i].$3,
              unit: rows[i].$4,
            ),
          ],
        if (note.isNotEmpty) ...[
          SizedBox(height: dense ? AppSpacing.sm : AppSpacing.md),
          Text(
            note,
            style: TextStyle(fontSize: 10.5, height: 1.4, color: p.textMuted),
          ),
        ],
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    required this.target,
    required this.unit,
  });

  final String label;
  final double value;
  final double target;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ratio = target > 0 ? (value / target).clamp(0.0, 1.0).toDouble() : 0.0;
    final percent = target > 0 ? (value / target * 100).round() : 0;

    return Row(
      children: [
        SizedBox(
          width: 62,
          child: Text(
            label,
            style: TextStyle(fontSize: 11.5, color: p.textSecondary),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: p.surfaceAlt,
              // One hue for all five: these bars show magnitude against a
              // target, not identity - the label already says which nutrient
              // it is, and five hues could not pass colour-vision separation.
              valueColor: AlwaysStoppedAnimation(p.brand),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        SizedBox(
          width: 74,
          child: Text(
            '${_format(value)}$unit  ·  $percent%',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: p.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  static String _format(double value) {
    if (value == 0) return '0';
    if (value < 10) return value.toStringAsFixed(1);
    return value.round().toString();
  }
}
