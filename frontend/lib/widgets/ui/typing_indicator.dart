import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Three dots bouncing in sequence, shown while the assistant is composing a
/// reply. Reads as "thinking" far better than a bare spinner in a chat.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key, this.label = 'Checking trusted sources'});

  final String label;

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg).copyWith(
            bottomLeft: const Radius.circular(AppSpacing.xs),
          ),
          border: Border.all(color: p.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  // Stagger each dot a third of a cycle behind the last.
                  final phase = (_controller.value - i * 0.18) % 1.0;
                  final lift = math.sin(phase * math.pi).clamp(0.0, 1.0);
                  return Padding(
                    padding: EdgeInsets.only(right: i == 2 ? 0 : 4),
                    child: Transform.translate(
                      offset: Offset(0, -3 * lift),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: p.brand.withValues(alpha: 0.45 + 0.55 * lift),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              widget.label,
              style: context.texts.bodySmall?.copyWith(color: p.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
