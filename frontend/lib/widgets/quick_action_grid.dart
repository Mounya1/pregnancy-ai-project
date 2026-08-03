import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'ui/app_card.dart';
import 'ui/reveal.dart';

class QuickAction {
  const QuickAction({
    required this.label,
    required this.description,
    required this.icon,
    required this.tint,
    required this.onTap,
  });

  final String label;
  final String description;
  final IconData icon;

  /// Accent hue for this tile's icon badge, so the four actions read as
  /// distinct destinations rather than one undifferentiated block.
  final Color tint;
  final VoidCallback onTap;
}

/// Two-column grid of feature shortcuts on the home screen.
class QuickActionGrid extends StatelessWidget {
  const QuickActionGrid({super.key, required this.actions});

  final List<QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        mainAxisExtent: 116,
      ),
      itemBuilder: (context, i) => Reveal.stagger(
        index: i,
        child: _QuickActionTile(action: actions[i]),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});

  final QuickAction action;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AppCard(
      onTap: action.onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: action.tint.withValues(alpha: p.isDark ? 0.22 : 0.14),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(action.icon, size: 19, color: action.tint),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                action.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.texts.titleSmall,
              ),
              const SizedBox(height: 2),
              Text(
                action.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: p.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
