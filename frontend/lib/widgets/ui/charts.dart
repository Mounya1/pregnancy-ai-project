import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/chart_colors.dart';

/// One column in a [WeeklyBarChart].
class BarDatum {
  const BarDatum({required this.label, required this.value, this.highlight = false});

  final String label;
  final double value;

  /// Marks today, so the current day reads differently without a second hue.
  final bool highlight;
}

/// Vertical bars for a short series - a week of daily totals.
///
/// Single hue by design: this shows magnitude, not identity, so a colour per
/// bar would encode nothing. Bars that meet [target] switch to the reserved
/// "good" status colour and carry a tick, so the state is never colour-alone.
class WeeklyBarChart extends StatelessWidget {
  const WeeklyBarChart({
    super.key,
    required this.data,
    this.target,
    this.height = 120,
    this.unit = '',
  });

  final List<BarDatum> data;

  /// Optional reference line, e.g. the daily nutrient target.
  final double? target;
  final double height;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final mark = ChartColors.mark(context);
    final good = ChartColors.good(context);

    // Scale to the target when there is one, so bars are read against the
    // goal rather than against whichever day happened to be biggest.
    final maxValue = data.isEmpty
        ? 1.0
        : math.max(
            data.map((d) => d.value).reduce(math.max),
            target ?? 0,
          );
    final scale = maxValue <= 0 ? 1.0 : maxValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: height,
          child: Stack(
            children: [
              if (target != null)
                Positioned(
                  left: 0,
                  right: 0,
                  // Reference line sits at the target's share of the scale.
                  bottom: (target! / scale) * height,
                  child: _TargetLine(label: 'target', color: p.textMuted),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: data.map((d) {
                  final met = target != null && d.value >= target!;
                  final barHeight = (d.value / scale) * height;
                  return Expanded(
                    child: Padding(
                      // 2px surface gap between adjacent fills.
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (met)
                            Icon(Icons.check_rounded, size: 10, color: good),
                          const SizedBox(height: 2),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: barHeight.clamp(0.0, height)),
                            duration: AppMotion.slow,
                            curve: AppMotion.emphasized,
                            builder: (context, h, __) => Container(
                              height: h < 2 && d.value > 0 ? 2 : h,
                              decoration: BoxDecoration(
                                color: met ? good : mark,
                                // Rounded data-end, square against the baseline.
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                                border: d.highlight
                                    ? Border.all(color: p.textPrimary, width: 1.5)
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: data
              .map((d) => Expanded(
                    child: Text(
                      d.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        // Weight, not colour, marks today.
                        fontWeight: d.highlight ? FontWeight.w700 : FontWeight.w400,
                        color: d.highlight ? p.textPrimary : p.textMuted,
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _TargetLine extends StatelessWidget {
  const _TargetLine({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CustomPaint(
            size: const Size(double.infinity, 1),
            painter: _DashedLinePainter(color: color.withValues(alpha: 0.6)),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 8.5, color: color)),
      ],
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dash = 3.0;
    const gap = 3.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(math.min(x + dash, size.width), 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter old) => old.color != color;
}

/// A compact line chart for a measure over time, e.g. baby weight.
/// One series, 2px stroke, 8px markers - no legend needed, the title names it.
class TrendLineChart extends StatelessWidget {
  const TrendLineChart({
    super.key,
    required this.values,
    required this.labels,
    this.height = 140,
  });

  final List<double> values;
  final List<String> labels;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    if (values.length < 2) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'Add at least two entries to see a trend.',
            style: TextStyle(fontSize: 12, color: p.textMuted),
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: height,
          width: double.infinity,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: AppMotion.slow,
            curve: AppMotion.emphasized,
            builder: (context, t, __) => CustomPaint(
              painter: _LinePainter(
                values: values,
                progress: t,
                line: ChartColors.mark(context),
                grid: ChartColors.grid(context),
                surface: p.surface,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(labels.first, style: TextStyle(fontSize: 10, color: p.textMuted)),
            if (labels.length > 2)
              Text(labels[labels.length ~/ 2],
                  style: TextStyle(fontSize: 10, color: p.textMuted)),
            Text(labels.last, style: TextStyle(fontSize: 10, color: p.textMuted)),
          ],
        ),
      ],
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.values,
    required this.progress,
    required this.line,
    required this.grid,
    required this.surface,
  });

  final List<double> values;
  final double progress;
  final Color line;
  final Color grid;
  final Color surface;

  @override
  void paint(Canvas canvas, Size size) {
    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    // Flat series would divide by zero; give it a nominal band so the line
    // renders through the middle instead of collapsing.
    final span = (maxV - minV).abs() < 0.0001 ? 1.0 : maxV - minV;

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    Offset pointAt(int i) {
      final x = size.width * i / (values.length - 1);
      final norm = (values[i] - minV) / span;
      // Inset vertically so markers never clip at the edges.
      final y = size.height - 8 - norm * (size.height - 16);
      return Offset(x, y);
    }

    final path = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (var i = 1; i < values.length; i++) {
      path.lineTo(pointAt(i).dx, pointAt(i).dy);
    }

    // Reveal the line left-to-right as it animates in.
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * progress, size.height));
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    for (var i = 0; i < values.length; i++) {
      final point = pointAt(i);
      // 2px surface ring keeps overlapping markers separable.
      canvas.drawCircle(point, 5, Paint()..color = surface);
      canvas.drawCircle(point, 4, Paint()..color = line);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) =>
      old.progress != progress || old.values != values || old.line != line;
}
