import 'package:flutter/material.dart';
import '../../models/food_safety_response.dart';
import '../../theme/app_theme.dart';

/// Foreground/background pair and icon for a safety verdict. Centralised so
/// the badge, the verdict card, and the history list can never drift apart.
class VerdictStyle {
  const VerdictStyle(this.foreground, this.background, this.icon);

  final Color foreground;
  final Color background;
  final IconData icon;

  static VerdictStyle of(BuildContext context, SafetyVerdict verdict) {
    final p = context.palette;
    switch (verdict) {
      case SafetyVerdict.safe:
        return VerdictStyle(p.safe, p.safeSurface, Icons.check_circle_rounded);
      case SafetyVerdict.limit:
        return VerdictStyle(p.limit, p.limitSurface, Icons.info_rounded);
      case SafetyVerdict.avoid:
        return VerdictStyle(p.avoid, p.avoidSurface, Icons.cancel_rounded);
      case SafetyVerdict.unknown:
        return VerdictStyle(p.neutral, p.neutralSurface, Icons.help_rounded);
    }
  }
}

/// Pill badge showing "Safe" / "Limit" / "Avoid" / "Ask your doctor".
class VerdictChip extends StatelessWidget {
  const VerdictChip({super.key, required this.verdict, this.compact = false});

  final SafetyVerdict verdict;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final style = VerdictStyle.of(context, verdict);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: style.foreground.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: compact ? 11 : 13, color: style.foreground),
          SizedBox(width: compact ? 3 : 5),
          Text(
            verdictLabel(verdict),
            style: TextStyle(
              color: style.foreground,
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
