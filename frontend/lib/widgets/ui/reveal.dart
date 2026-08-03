import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Fades and lifts its child into place once, on first build.
///
/// Screens compose these with an increasing [delay] so a list of cards
/// arrives as a staggered cascade rather than all at once - use
/// [Reveal.stagger] to get the standard 55ms-per-item rhythm.
class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 18,
  });

  /// Standard staggered entrance for the nth item in a list.
  Reveal.stagger({
    super.key,
    required int index,
    required this.child,
    this.offset = 18,
  }) : delay = Duration(milliseconds: (index.clamp(0, 12)) * 55);

  final Widget child;
  final Duration delay;

  /// Vertical distance (logical px) the child travels while fading in.
  final double offset;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: AppMotion.reveal);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _controller, curve: AppMotion.enter);
    return FadeTransition(
      opacity: curved,
      child: AnimatedBuilder(
        animation: curved,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, widget.offset * (1 - curved.value)),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
