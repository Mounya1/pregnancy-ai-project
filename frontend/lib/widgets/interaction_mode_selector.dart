import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'ui/app_card.dart';

/// "How would you like to ask?" - Type / Voice / Scan, the three entry points
/// into the assistant.
class InteractionModeSelector extends StatelessWidget {
  const InteractionModeSelector({
    super.key,
    required this.onType,
    required this.onVoice,
    required this.onScan,
  });

  final VoidCallback onType;
  final VoidCallback onVoice;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Expanded(
          child: _ModeCard(
            icon: Icons.chat_bubble_rounded,
            title: 'Type',
            subtitle: 'Ask with text',
            tint: p.brand,
            onTap: onType,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ModeCard(
            icon: Icons.graphic_eq_rounded,
            title: 'Voice',
            subtitle: 'Speak it',
            tint: Brand.teal,
            onTap: onVoice,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ModeCard(
            icon: Icons.center_focus_strong_rounded,
            title: 'Scan',
            subtitle: 'Take a photo',
            tint: p.accent,
            onTap: onScan,
          ),
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tint,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.lg,
        horizontal: AppSpacing.sm,
      ),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [tint, tint.withValues(alpha: 0.65)],
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: [
                BoxShadow(
                  color: tint.withValues(alpha: p.isDark ? 0.25 : 0.32),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: context.texts.titleSmall),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10.5, color: p.textMuted),
          ),
        ],
      ),
    );
  }
}
