import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The big week dial: an arc showing progress through the pregnancy, with the
/// week in the middle and the percentage done and days left flanking it.
///
/// Painted rather than composed from ProgressRing because this one needs a
/// gap at the top of the arc and a much heavier stroke - it is the hero of the
/// screen, not a small indicator.
class WeekRing extends StatelessWidget {
  const WeekRing({
    super.key,
    required this.week,
    required this.progress,
    required this.daysToGo,
    this.size = 190,
    this.dayInWeek,
  });

  final int week;

  /// 0..1 through the whole pregnancy.
  final double progress;
  final int daysToGo;
  final double size;

  /// Day within the current week, shown as "(8+2)" like a clinical note.
  final int? dayInWeek;

  @override
  Widget build(BuildContext context) {
    const onBrand = Colors.white;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _SideStat(
          value: '${(progress * 100).round()}%',
          label: 'DONE',
          color: onBrand,
        ),
        SizedBox(
          width: size,
          height: size,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
            duration: AppMotion.slow,
            curve: AppMotion.emphasized,
            builder: (context, value, _) => CustomPaint(
              painter: _WeekRingPainter(
                progress: value,
                track: onBrand.withValues(alpha: 0.28),
                arc: onBrand,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Week $week',
                      style: TextStyle(
                        fontSize: size * 0.17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        color: onBrand,
                        height: 1.1,
                      ),
                    ),
                    if (dayInWeek != null)
                      Text(
                        '($week+$dayInWeek)',
                        style: TextStyle(
                          fontSize: size * 0.075,
                          color: onBrand.withValues(alpha: 0.85),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        _SideStat(
          value: '$daysToGo',
          label: 'DAYS TO GO',
          color: onBrand,
        ),
      ],
    );
  }
}

class _SideStat extends StatelessWidget {
  const _SideStat({required this.value, required this.label, required this.color});

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 62,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 8.5,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekRingPainter extends CustomPainter {
  _WeekRingPainter({
    required this.progress,
    required this.track,
    required this.arc,
  });

  final double progress;
  final Color track;
  final Color arc;

  /// Leaves a gap centred at the top so the ring reads as a dial with a
  /// beginning and an end, rather than a closed loop.
  static const _gap = math.pi * 0.16;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.055;
    final radius = (size.width - stroke) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    const start = -math.pi / 2 + _gap / 2;
    const sweep = math.pi * 2 - _gap;

    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = track
        ..isAntiAlias = true,
    );

    if (progress <= 0) return;
    canvas.drawArc(
      rect,
      start,
      sweep * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = arc
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant _WeekRingPainter old) =>
      old.progress != progress || old.arc != arc || old.track != track;
}
