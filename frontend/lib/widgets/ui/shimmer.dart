import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Sweeps a soft highlight across its children to signal loading. Wrapping
/// skeleton boxes in one Shimmer keeps the whole block's sweep in sync.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final highlight = p.isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.75);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Colors.transparent, highlight, Colors.transparent],
          stops: const [0.0, 0.5, 1.0],
          // Travel from fully off the left edge to fully off the right.
          transform: _SlideGradient(_controller.value * 2 - 1),
        ).createShader(bounds),
        child: child,
      ),
      child: widget.child,
    );
  }
}

class _SlideGradient extends GradientTransform {
  const _SlideGradient(this.fraction);

  final double fraction;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * fraction, 0, 0);
}

/// A neutral placeholder block. Compose these into the shape of the content
/// that is loading, then wrap the group in a [Shimmer].
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 14,
    this.radius = AppRadius.sm,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.palette.surfaceAlt,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Ready-made skeleton for a list of cards, e.g. while a meal plan or the
/// history list is loading.
class SkeletonCardList extends StatelessWidget {
  const SkeletonCardList({super.key, this.count = 3, this.height = 96});

  final int count;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Column(
        children: List.generate(
          count,
          (i) => Padding(
            padding: EdgeInsets.only(bottom: i == count - 1 ? 0 : AppSpacing.md),
            child: SkeletonBox(height: height, radius: AppRadius.lg),
          ),
        ),
      ),
    );
  }
}
