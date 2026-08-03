import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// An animated circular progress arc with a gradient sweep and a free-form
/// centre. Used for the pregnancy-week hero ring and the nutrition dials.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    this.size = 96,
    this.strokeWidth = 9,
    this.trackColor,
    this.colors,
    this.child,
    this.animate = true,
  });

  /// Completion in 0..1. Values outside the range are clamped.
  final double value;
  final double size;
  final double strokeWidth;
  final Color? trackColor;

  /// Sweep colours, start to end. Defaults to the brand gradient.
  final List<Color>? colors;
  final Widget? child;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final target = value.isNaN ? 0.0 : value.clamp(0.0, 1.0).toDouble();
    final sweep = colors ?? [p.brandStrong, p.brand, p.accent];

    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: animate ? 0 : target, end: target),
        duration: animate ? AppMotion.slow : Duration.zero,
        curve: AppMotion.emphasized,
        builder: (context, t, child) => CustomPaint(
          painter: _RingPainter(
            value: t,
            strokeWidth: strokeWidth,
            trackColor: trackColor ?? p.surfaceAlt,
            colors: sweep,
          ),
          child: Center(child: child),
        ),
        child: child,
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.strokeWidth,
    required this.trackColor,
    required this.colors,
  });

  final double value;
  final double strokeWidth;
  final Color trackColor;
  final List<Color> colors;

  static const _start = -math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);

    if (value <= 0) return;

    // Rotate the sweep so its first colour lands at the 12 o'clock start of
    // the arc instead of at 3 o'clock, where SweepGradient begins.
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: math.pi * 2,
        colors: [...colors, colors.first],
        transform: const GradientRotation(_start),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _start,
      math.pi * 2 * value,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.value != value ||
      old.strokeWidth != strokeWidth ||
      old.trackColor != trackColor ||
      !listEquals(old.colors, colors);

  static bool listEquals(List<Color> a, List<Color> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Horizontal progress bar matching the ring's visual language: rounded,
/// gradient-filled, and animated from empty on first paint.
class ProgressTrack extends StatelessWidget {
  const ProgressTrack({
    super.key,
    required this.value,
    this.height = 8,
    this.colors,
  });

  final double value;
  final double height;
  final List<Color>? colors;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final target = value.isNaN ? 0.0 : value.clamp(0.0, 1.0).toDouble();

    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Container(
        height: height,
        color: p.surfaceAlt,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: target),
          duration: AppMotion.slow,
          curve: AppMotion.emphasized,
          builder: (context, t, __) => Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: t == 0 ? 0.0001 : t,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors ?? [p.brandStrong, p.brand]),
                  borderRadius: BorderRadius.circular(height),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
