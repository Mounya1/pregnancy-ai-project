import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Hand-built vector illustrations, gently animated.
///
/// Drawn with paths rather than shipped as images so they take the current
/// palette, stay sharp at any size, add nothing to the bundle, and carry no
/// licensing questions. All geometry is in a 0..1 space scaled to the widget's
/// size, so every figure composes at any dimension.
///
/// Motion is deliberately slow and small. These sit behind text at low
/// opacity, so anything faster would pull the eye away from the content. Every
/// figure freezes at a neutral pose when the OS asks for reduced motion.

/// Mixin for the shared "breathe unless motion is switched off" loop.
mixin _BreathingState<T extends StatefulWidget> on State<T>, TickerProvider {
  late final AnimationController breathController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3800),
  );

  /// The widget's own `animate` flag. Motion stops if either this is false or
  /// the OS asks for reduced motion.
  bool get wantsMotion;

  bool _frozen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    syncMotion();
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    syncMotion();
  }

  /// Starts or stops every loop to match the current settings. Subclasses
  /// override this to handle their own extra controllers, then call super.
  @mustCallSuper
  void syncMotion() {
    _frozen = !wantsMotion || (MediaQuery.maybeOf(context)?.disableAnimations ?? false);
    if (_frozen) {
      if (breathController.isAnimating) breathController.stop();
      // Mid-breath is the most natural resting pose.
      breathController.value = 0.5;
    } else if (!breathController.isAnimating) {
      breathController.repeat(reverse: true);
    }
  }

  /// 0..1 eased breath phase.
  double get breath => Curves.easeInOut.transform(breathController.value);

  /// True when every loop is held still.
  bool get frozen => _frozen;

  @override
  void dispose() {
    breathController.dispose();
    super.dispose();
  }
}

/// The tones an illustration is painted in.
///
/// Passing a single [color] gives a flat silhouette, which suits a faint
/// background watermark. Passing separate tones gives a proper full-colour
/// figure, which is what a card actually meant to be looked at should use.
class FigureTones {
  const FigureTones({
    required this.dress,
    required this.skin,
    required this.hair,
    required this.detail,
  });

  /// Flat one-colour version, for background use.
  const FigureTones.mono(Color color)
      : dress = color,
        skin = color,
        hair = color,
        detail = color;

  final Color dress;
  final Color skin;
  final Color hair;

  /// Hearts, sleep marks, closed eyes.
  final Color detail;

  /// Warm, friendly defaults that sit well on both light and dark cards.
  static FigureTones defaults(Color dress, {bool dark = false}) => FigureTones(
        dress: dress,
        skin: dark ? const Color(0xFFE8B98F) : const Color(0xFFF2C6A0),
        hair: dark ? const Color(0xFF4A3A46) : const Color(0xFF3B2E3A),
        detail: dark ? const Color(0xFFF2A9C4) : const Color(0xFFE0709A),
      );

  FigureTones copyWithHair(Color newHair) => FigureTones(
        dress: dress,
        skin: skin,
        hair: newHair,
        detail: newHair,
      );
}

/// Stylised side profile of a pregnant woman, one hand resting on the bump.
/// Breathes slowly, with a heart drifting up from the belly.
class MotherIllustration extends StatefulWidget {
  const MotherIllustration({
    super.key,
    required this.color,
    this.size = 120,
    this.accent,
    this.animate = true,
    this.tones,
  });

  final Color color;
  final double size;

  /// Optional second tone for the hair and arm, for a little depth.
  final Color? accent;
  final bool animate;

  /// Full-colour tones. When null the figure is a flat [color] silhouette.
  final FigureTones? tones;

  @override
  State<MotherIllustration> createState() => _MotherIllustrationState();
}

class _MotherIllustrationState extends State<MotherIllustration>
    with TickerProviderStateMixin, _BreathingState {
  late final AnimationController _heartController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5200),
  );

  @override
  bool get wantsMotion => widget.animate;

  @override
  void syncMotion() {
    super.syncMotion();
    if (frozen) {
      if (_heartController.isAnimating) _heartController.stop();
      _heartController.value = 0;
    } else if (!_heartController.isAnimating) {
      _heartController.repeat();
    }
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tones = widget.tones ??
        FigureTones.mono(widget.color).copyWithHair(widget.accent ?? widget.color);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([breathController, _heartController]),
        builder: (context, _) => CustomPaint(
          painter: _MotherPainter(
            tones: tones,
            breath: frozen ? 0.5 : breath,
            heart: frozen ? null : _heartController.value,
          ),
        ),
      ),
    );
  }
}

class _MotherPainter extends CustomPainter {
  _MotherPainter({
    required this.tones,
    required this.breath,
    required this.heart,
  });

  final FigureTones tones;
  final double breath;

  /// 0..1 position of the rising heart, or null when it is not shown.
  final double? heart;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // The bump grows very slightly on the in-breath, and the chest lifts.
    final swell = 1 + 0.035 * breath;
    final lift = -h * 0.006 * breath;

    final body = Paint()
      ..color = tones.dress
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Torso: back falls in a gentle S, the front swells over the bump and
    // tucks under it before the hem. Only the front control points scale, so
    // the spine stays put while the belly moves.
    final torso = Path()
      ..moveTo(w * 0.44, h * 0.22 + lift)
      ..cubicTo(w * 0.34, h * 0.30, w * 0.30, h * 0.44, w * 0.33, h * 0.60)
      ..cubicTo(w * 0.35, h * 0.74, w * 0.36, h * 0.86, w * 0.36, h * 0.98)
      ..lineTo(w * 0.68, h * 0.98)
      ..cubicTo(w * 0.70, h * 0.86, w * 0.72, h * 0.74, w * 0.74 * swell, h * 0.64)
      ..cubicTo(w * 0.89 * swell, h * 0.54, w * 0.88 * swell, h * 0.32, w * 0.70, h * 0.26 + lift)
      ..cubicTo(w * 0.62, h * 0.23 + lift, w * 0.55, h * 0.22 + lift, w * 0.50, h * 0.22 + lift)
      ..close();
    canvas.drawPath(torso, body);

    // Head and neck in skin tone, sitting slightly forward of the spine so
    // the posture reads natural.
    final skin = Paint()
      ..color = tones.skin
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawCircle(Offset(w * 0.455, h * 0.135 + lift), w * 0.095, skin);

    // Hair: a soft cap over the back of the head.
    final hair = Path()
      ..moveTo(w * 0.36, h * 0.145 + lift)
      ..cubicTo(w * 0.355, h * 0.045 + lift, w * 0.55, h * 0.03 + lift, w * 0.548, h * 0.12 + lift)
      ..cubicTo(w * 0.50, h * 0.075 + lift, w * 0.41, h * 0.08 + lift, w * 0.395, h * 0.175 + lift)
      ..close();
    canvas.drawPath(hair, Paint()..color = tones.hair..isAntiAlias = true);

    // Arm resting on top of the bump, riding the swell with it.
    final arm = Paint()
      ..color = tones.skin
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.055
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.47, h * 0.34 + lift)
        ..cubicTo(w * 0.50, h * 0.47, w * 0.62, h * 0.52, w * 0.72 * swell, h * 0.47),
      arm,
    );

    if (heart != null) _paintHeart(canvas, size, heart!);
  }

  /// A heart rising from the bump: fades in, drifts up and slightly right,
  /// then fades out before looping.
  void _paintHeart(Canvas canvas, Size size, double t) {
    final w = size.width;
    final h = size.height;

    // Fade in over the first 20%, hold, fade out over the last 35%.
    final opacity = t < 0.2
        ? t / 0.2
        : t > 0.65
            ? (1 - t) / 0.35
            : 1.0;
    if (opacity <= 0) return;

    final cx = w * (0.70 + 0.10 * t);
    final cy = h * (0.44 - 0.34 * t);
    final s = w * 0.075 * (0.75 + 0.25 * t);

    final path = Path()
      ..moveTo(cx, cy + s * 0.32)
      ..cubicTo(cx - s * 1.1, cy - s * 0.45, cx - s * 0.35, cy - s * 1.05, cx, cy - s * 0.35)
      ..cubicTo(cx + s * 0.35, cy - s * 1.05, cx + s * 1.1, cy - s * 0.45, cx, cy + s * 0.32)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = tones.detail.withValues(alpha: opacity.clamp(0.0, 1.0) * 0.85)
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant _MotherPainter old) =>
      old.tones != tones ||
      
      old.breath != breath ||
      old.heart != heart;
}

/// Stylised sleeping baby: breathes, rocks very gently, and lets a "z" drift
/// up from time to time.
class BabyIllustration extends StatefulWidget {
  const BabyIllustration({
    super.key,
    required this.color,
    this.size = 120,
    this.accent,
    this.animate = true,
    this.tones,
  });

  final Color color;
  final double size;
  final Color? accent;
  final bool animate;

  /// Full-colour tones. When null the figure is a flat [color] silhouette.
  final FigureTones? tones;

  @override
  State<BabyIllustration> createState() => _BabyIllustrationState();
}

class _BabyIllustrationState extends State<BabyIllustration>
    with TickerProviderStateMixin, _BreathingState {
  late final AnimationController _sleepController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4600),
  );

  @override
  bool get wantsMotion => widget.animate;

  @override
  void syncMotion() {
    super.syncMotion();
    if (frozen) {
      if (_sleepController.isAnimating) _sleepController.stop();
      _sleepController.value = 0;
    } else if (!_sleepController.isAnimating) {
      _sleepController.repeat();
    }
  }

  @override
  void dispose() {
    _sleepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tones = widget.tones ??
        FigureTones.mono(widget.color).copyWithHair(widget.accent ?? widget.color);
    final phase = frozen ? 0.5 : breath;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([breathController, _sleepController]),
        builder: (context, _) => Transform.rotate(
          // A whisper of a rock: +/- 1.2 degrees.
          angle: (phase - 0.5) * 0.042,
          child: CustomPaint(
            painter: _BabyPainter(
              tones: tones,
              breath: phase,
              sleep: frozen ? null : _sleepController.value,
            ),
          ),
        ),
      ),
    );
  }
}

class _BabyPainter extends CustomPainter {
  _BabyPainter({
    required this.tones,
    required this.breath,
    required this.sleep,
  });

  final FigureTones tones;
  final double breath;

  /// 0..1 position of the drifting "z", or null when it is not shown.
  final double? sleep;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final swell = 1 + 0.03 * breath;

    final body = Paint()
      ..color = tones.dress
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Swaddle: a soft teardrop, wide at the shoulders, tapering to the feet.
    // It is the part that visibly rises and falls.
    final swaddle = Path()
      ..moveTo(w * 0.28, h * 0.62)
      ..cubicTo(w * 0.24, h * 0.86, w * 0.42, h * 0.99, w * 0.56, h * 0.95)
      ..cubicTo(w * 0.74 * swell, h * 0.90, w * 0.80 * swell, h * 0.72, w * 0.72, h * 0.58)
      ..cubicTo(w * 0.62, h * 0.50, w * 0.36, h * 0.51, w * 0.28, h * 0.62)
      ..close();
    canvas.drawPath(swaddle, body);

    // Head in skin tone, tilted into the swaddle.
    canvas.drawCircle(
      Offset(w * 0.50, h * 0.34),
      w * 0.20,
      Paint()
        ..color = tones.skin
        ..isAntiAlias = true,
    );

    // A single curl - the detail that makes it read as a baby rather than a
    // snowman.
    final curl = Paint()
      ..color = tones.hair
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.50, h * 0.155)
        ..cubicTo(w * 0.60, h * 0.10, w * 0.63, h * 0.20, w * 0.55, h * 0.20),
      curl,
    );

    // Closed eyes: two small downward arcs.
    final eye = Paint()
      ..color = tones.hair
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.032
      ..strokeCap = StrokeCap.round;
    for (final dx in [0.42, 0.58]) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(w * dx, h * 0.345), radius: w * 0.045),
        math.pi * 0.15,
        math.pi * 0.7,
        false,
        eye,
      );
    }

    if (sleep != null) _paintSleepMark(canvas, size, sleep!);
  }

  /// A small "z" drifting up and away from the head.
  void _paintSleepMark(Canvas canvas, Size size, double t) {
    final w = size.width;
    final h = size.height;

    final opacity = t < 0.15
        ? t / 0.15
        : t > 0.6
            ? (1 - t) / 0.4
            : 1.0;
    if (opacity <= 0) return;

    final x = w * (0.70 + 0.12 * t);
    final y = h * (0.26 - 0.20 * t);
    final s = w * 0.10 * (0.7 + 0.3 * t);

    final stroke = Paint()
      ..color = tones.detail.withValues(alpha: opacity.clamp(0.0, 1.0) * 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.028
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    canvas.drawPath(
      Path()
        ..moveTo(x, y)
        ..lineTo(x + s, y)
        ..lineTo(x, y + s)
        ..lineTo(x + s, y + s),
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _BabyPainter old) =>
      old.tones != tones || old.breath != breath || old.sleep != sleep;
}

/// Soft overlapping circles used behind hero panels, drifting slowly. Purely
/// decorative, so it stays very low contrast and never sits on top of text.
class BlobDecoration extends StatefulWidget {
  const BlobDecoration({
    super.key,
    required this.color,
    this.seed = 0,
    this.animate = true,
  });

  final Color color;

  /// Shifts the arrangement so different screens don't look identical.
  final int seed;
  final bool animate;

  @override
  State<BlobDecoration> createState() => _BlobDecorationState();
}

class _BlobDecorationState extends State<BlobDecoration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    // Long enough that the drift reads as ambient rather than as motion.
    duration: const Duration(seconds: 18),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (!widget.animate || reduce) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        painter: _BlobPainter(
          color: widget.color,
          seed: widget.seed,
          phase: _controller.value,
        ),
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  _BlobPainter({required this.color, required this.seed, required this.phase});

  final Color color;
  final int seed;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    final paint = Paint()..isAntiAlias = true;

    for (var i = 0; i < 4; i++) {
      final radius = size.height * (0.28 + rng.nextDouble() * 0.42);
      final baseX = size.width * (0.55 + rng.nextDouble() * 0.55);
      final baseY = size.height * (rng.nextDouble() * 1.1 - 0.15);

      // Each blob travels its own small ellipse, offset in phase so they never
      // move as a block.
      final angle = (phase + i / 4) * 2 * math.pi;
      final dx = math.cos(angle) * size.width * 0.03;
      final dy = math.sin(angle) * size.height * 0.05;

      paint.color = color.withValues(alpha: 0.05 + rng.nextDouble() * 0.05);
      canvas.drawCircle(Offset(baseX + dx, baseY + dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BlobPainter old) =>
      old.color != color || old.seed != seed || old.phase != phase;
}
