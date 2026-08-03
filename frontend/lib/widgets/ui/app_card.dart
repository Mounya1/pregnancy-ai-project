import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

/// Wraps any widget so it scales down slightly while pressed. Gives taps a
/// physical response that Material's ink ripple alone doesn't convey on
/// large surfaces like cards and tiles.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.97,
    this.haptics = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final bool haptics;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool value) {
    if (widget.onTap == null || _down == value) return;
    setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap == null
          ? null
          : () {
              if (widget.haptics) HapticFeedback.selectionClick();
              widget.onTap!();
            },
      child: AnimatedScale(
        scale: _down ? widget.scale : 1.0,
        duration: AppMotion.fast,
        curve: AppMotion.enter,
        child: widget.child,
      ),
    );
  }
}

/// The app's standard raised surface: rounded, hairline-bordered, softly
/// shadowed, and press-responsive when [onTap] is supplied.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.radius = AppRadius.lg,
    this.color,
    this.borderColor,
    this.shadow = true,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;
  final Color? color;
  final Color? borderColor;
  final bool shadow;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final card = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? p.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? p.border),
        boxShadow: shadow ? p.softShadow : null,
      ),
      child: child,
    );

    return onTap == null ? card : Pressable(onTap: onTap, child: card);
  }
}

/// A card whose background is the brand gradient - used for hero panels and
/// primary calls to action. Text inside should use `palette.onBrand`.
class GradientCard extends StatelessWidget {
  const GradientCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.onTap,
    this.radius = AppRadius.xl,
    this.gradient,
    this.glow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;
  final Gradient? gradient;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient ?? p.heroGradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: glow ? p.brandShadow() : null,
      ),
      child: child,
    );

    return onTap == null ? card : Pressable(onTap: onTap, child: card);
  }
}
