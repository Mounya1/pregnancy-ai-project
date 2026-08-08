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

/// A mother holding her baby, cradled in both arms.
///
/// The third figure in the set: [MotherIllustration] carries the pregnancy,
/// [BabyIllustration] the baby alone, and this one the part in between that
/// the app is actually about - the two of them together.
///
/// She breathes; the bundle rocks very gently against her, out of phase with
/// the breath so the motion never looks mechanical.
class HoldingBabyIllustration extends StatefulWidget {
  const HoldingBabyIllustration({
    super.key,
    required this.color,
    this.size = 120,
    this.accent,
    this.animate = true,
    this.tones,
  });

  final Color color;
  final double size;

  /// Second tone for hair and the baby's blanket when [tones] is not given.
  final Color? accent;
  final bool animate;

  /// Full-colour tones. When null the pair is a flat [color] silhouette,
  /// which is what the gradient headers use behind their text.
  final FigureTones? tones;

  @override
  State<HoldingBabyIllustration> createState() => _HoldingBabyIllustrationState();
}

class _HoldingBabyIllustrationState extends State<HoldingBabyIllustration>
    with TickerProviderStateMixin, _BreathingState {
  late final AnimationController _rockController = AnimationController(
    vsync: this,
    // Deliberately not a multiple of the 3800ms breath: the two drift in and
    // out of phase, which is what stops it reading as a single mechanism.
    duration: const Duration(milliseconds: 5100),
  );

  late final AnimationController _heartController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 6000),
  );

  @override
  bool get wantsMotion => widget.animate;

  @override
  void syncMotion() {
    super.syncMotion();
    for (final controller in [_rockController, _heartController]) {
      if (frozen) {
        if (controller.isAnimating) controller.stop();
        controller.value = 0;
      } else if (!controller.isAnimating) {
        controller.repeat();
      }
    }
  }

  @override
  void dispose() {
    _rockController.dispose();
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
        animation: Listenable.merge([breathController, _rockController, _heartController]),
        builder: (context, _) => CustomPaint(
          painter: _HoldingBabyPainter(
            tones: tones,
            breath: frozen ? 0.5 : breath,
            rock: frozen ? 0.5 : _rockController.value,
            heart: frozen ? null : _heartController.value,
          ),
        ),
      ),
    );
  }
}

class _HoldingBabyPainter extends CustomPainter {
  _HoldingBabyPainter({
    required this.tones,
    required this.breath,
    required this.rock,
    required this.heart,
  });

  final FigureTones tones;
  final double breath;

  /// 0..1 through one rocking cycle.
  final double rock;

  /// 0..1 position of the rising heart, or null when motion is off.
  final double? heart;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final lift = -h * 0.006 * breath;
    // A degree and a half either way. Any more and it stops looking like
    // someone soothing a baby and starts looking like a metronome.
    final tilt = math.sin(rock * 2 * math.pi) * 0.026;

    final dress = Paint()
      ..color = tones.dress
      ..isAntiAlias = true;
    final skin = Paint()
      ..color = tones.skin
      ..isAntiAlias = true;

    // Torso: shoulders squared toward us, hem flaring out. She stands
    // straight here rather than in the pregnancy S-curve - the weight she is
    // carrying is in front of her now, not inside her.
    final torso = Path()
      ..moveTo(w * 0.36, h * 0.30 + lift)
      ..cubicTo(w * 0.30, h * 0.40, w * 0.27, h * 0.62, w * 0.26, h * 0.99)
      ..lineTo(w * 0.74, h * 0.99)
      ..cubicTo(w * 0.73, h * 0.62, w * 0.70, h * 0.40, w * 0.64, h * 0.30 + lift)
      ..cubicTo(w * 0.58, h * 0.25 + lift, w * 0.42, h * 0.25 + lift, w * 0.36, h * 0.30 + lift)
      ..close();
    canvas.drawPath(torso, dress);

    // Head, tipped very slightly toward the baby.
    canvas.drawCircle(Offset(w * 0.44, h * 0.155 + lift), w * 0.098, skin);

    // Hair: a cap over the crown and back, leaving the face open.
    final hair = Path()
      ..moveTo(w * 0.343, h * 0.168 + lift)
      ..cubicTo(w * 0.335, h * 0.055 + lift, w * 0.545, h * 0.042 + lift, w * 0.540, h * 0.140 + lift)
      ..cubicTo(w * 0.492, h * 0.088 + lift, w * 0.398, h * 0.094 + lift, w * 0.380, h * 0.198 + lift)
      ..close();
    canvas.drawPath(hair, Paint()..color = tones.hair..isAntiAlias = true);

    // The cradle: one arm sweeps under the bundle, the far arm supports the
    // head. Drawn before the baby so the baby sits inside the crook.
    final arm = Paint()
      ..color = tones.skin
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.062
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.335, h * 0.395 + lift)
        ..cubicTo(w * 0.32, h * 0.56, w * 0.46, h * 0.66, w * 0.70, h * 0.575),
      arm,
    );

    _paintBundle(canvas, size, tilt, lift);

    // The near arm's hand, resting over the blanket. Drawn last so it reads
    // as being on top of the baby rather than behind it.
    canvas.drawCircle(Offset(w * 0.695, h * 0.565 + lift), w * 0.045, skin);

    if (heart != null) _paintHeart(canvas, size, heart!);
  }

  /// Swaddled baby: blanket, head, and a sleeping curve of a closed eye.
  /// Rotated as a group so the whole bundle rocks together.
  void _paintBundle(Canvas canvas, Size size, double tilt, double lift) {
    final w = size.width;
    final h = size.height;

    canvas.save();
    // Pivot at the elbow, where a real bundle would swing from.
    canvas.translate(w * 0.40, h * 0.60);
    canvas.rotate(tilt);
    canvas.translate(-w * 0.40, -h * 0.60);

    // Blanket: a rounded wedge, wide at the feet, tapering to the shoulders.
    final blanket = Path()
      ..moveTo(w * 0.395, h * 0.545 + lift)
      ..cubicTo(w * 0.40, h * 0.435, w * 0.55, h * 0.395, w * 0.665, h * 0.415 + lift)
      ..cubicTo(w * 0.755, h * 0.432, w * 0.775, h * 0.545, w * 0.685, h * 0.565 + lift)
      ..cubicTo(w * 0.575, h * 0.588, w * 0.445, h * 0.60, w * 0.395, h * 0.545 + lift)
      ..close();
    canvas.drawPath(
      blanket,
      Paint()
        ..color = tones.detail
        ..isAntiAlias = true,
    );

    // Head clear of the blanket at the top end, where an arm would support it.
    final headCentre = Offset(w * 0.70, h * 0.415 + lift);
    canvas.drawCircle(headCentre, w * 0.078, Paint()..color = tones.skin..isAntiAlias = true);

    // A tuft of hair, and one closed eye - asleep, which is the only
    // expression a stylised face this small can carry without looking odd.
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.665, h * 0.355 + lift)
        ..cubicTo(w * 0.685, h * 0.325 + lift, w * 0.735, h * 0.335 + lift, w * 0.742, h * 0.372 + lift)
        ..cubicTo(w * 0.715, h * 0.352 + lift, w * 0.688, h * 0.352 + lift, w * 0.665, h * 0.355 + lift)
        ..close(),
      Paint()..color = tones.hair..isAntiAlias = true,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w * 0.723, h * 0.418 + lift), radius: w * 0.021),
      math.pi * 0.15,
      math.pi * 0.7,
      false,
      Paint()
        ..color = tones.hair
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.013
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true,
    );

    canvas.restore();
  }

  /// A heart rising between the two of them.
  void _paintHeart(Canvas canvas, Size size, double t) {
    final w = size.width;
    final h = size.height;

    final opacity = t < 0.2
        ? t / 0.2
        : t > 0.65
            ? (1 - t) / 0.35
            : 1.0;
    if (opacity <= 0) return;

    final cx = w * (0.60 + 0.08 * t);
    final cy = h * (0.36 - 0.28 * t);
    final s = w * 0.07 * (0.75 + 0.25 * t);

    final path = Path()
      ..moveTo(cx, cy + s * 0.32)
      ..cubicTo(cx - s * 1.1, cy - s * 0.45, cx - s * 0.35, cy - s * 1.05, cx, cy - s * 0.35)
      ..cubicTo(cx + s * 0.35, cy - s * 1.05, cx + s * 1.1, cy - s * 0.45, cx, cy + s * 0.32)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = tones.detail.withValues(alpha: opacity.clamp(0.0, 1.0) * 0.8)
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant _HoldingBabyPainter old) =>
      old.tones != tones ||
      old.breath != breath ||
      old.rock != rock ||
      old.heart != heart;
}
