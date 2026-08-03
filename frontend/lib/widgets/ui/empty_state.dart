import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'app_card.dart';
import 'reveal.dart';

/// Section title with an optional trailing action, e.g. "Today's log  + Add".
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.texts.titleMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: context.texts.bodySmall?.copyWith(color: p.textMuted),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

/// Friendly placeholder for screens with nothing to show yet. An empty
/// history or saved-foods list should still feel designed, not broken.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Reveal(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: p.brandSurface,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 34, color: p.brandSoft),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(title, style: context.texts.titleMedium, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: context.texts.bodySmall?.copyWith(color: p.textMuted),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.xl),
                FilledButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Inline error panel used when a network call fails, with a retry affordance.
class ErrorPanel extends StatelessWidget {
  const ErrorPanel({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      color: p.avoidSurface,
      borderColor: p.avoid.withValues(alpha: 0.25),
      shadow: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 18, color: p.avoid),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: context.texts.bodySmall?.copyWith(color: p.avoid),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(foregroundColor: p.avoid),
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}
