import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Which way a tracked measure moved.
enum TrendDirection { up, down, steady, none }

/// Whether a move is a good thing. Eating more iron is good; a rising blood
/// pressure reading is not, so direction alone can't pick the colour.
enum TrendPolarity { higherIsBetter, lowerIsBetter, neutral }

/// Reads a change as improving / declining / steady.
///
/// Status colours are reserved for exactly this and always ship with an icon
/// and a word, so the state never depends on colour alone.
class TrendBadge extends StatelessWidget {
  const TrendBadge({
    super.key,
    required this.deltaPercent,
    this.polarity = TrendPolarity.higherIsBetter,
    this.compact = false,
  });

  /// Percentage change vs the previous period. Null means no comparison yet.
  final double? deltaPercent;
  final TrendPolarity polarity;
  final bool compact;

  /// Moves smaller than this are noise, not a trend.
  static const _steadyBand = 5.0;

  TrendDirection get direction {
    final d = deltaPercent;
    if (d == null) return TrendDirection.none;
    if (d.abs() < _steadyBand) return TrendDirection.steady;
    return d > 0 ? TrendDirection.up : TrendDirection.down;
  }

  bool get _isImprovement {
    switch (polarity) {
      case TrendPolarity.higherIsBetter:
        return direction == TrendDirection.up;
      case TrendPolarity.lowerIsBetter:
        return direction == TrendDirection.down;
      case TrendPolarity.neutral:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    late final Color fg;
    late final Color bg;
    late final IconData icon;
    late final String label;

    switch (direction) {
      case TrendDirection.none:
        fg = p.neutral;
        bg = p.neutralSurface;
        icon = Icons.remove_rounded;
        label = 'No data';
      case TrendDirection.steady:
        fg = p.neutral;
        bg = p.neutralSurface;
        icon = Icons.trending_flat_rounded;
        label = 'Steady';
      case TrendDirection.up:
      case TrendDirection.down:
        final improving = _isImprovement;
        final neutralPolarity = polarity == TrendPolarity.neutral;
        fg = neutralPolarity ? p.neutral : (improving ? p.safe : p.limit);
        bg = neutralPolarity ? p.neutralSurface : (improving ? p.safeSurface : p.limitSurface);
        icon = direction == TrendDirection.up
            ? Icons.trending_up_rounded
            : Icons.trending_down_rounded;
        final magnitude = '${deltaPercent!.abs().toStringAsFixed(0)}%';
        label = neutralPolarity
            ? (direction == TrendDirection.up ? 'Up $magnitude' : 'Down $magnitude')
            : (improving ? 'Better $magnitude' : 'Lower $magnitude');
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: fg.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 11 : 13, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 10 : 11.5,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
