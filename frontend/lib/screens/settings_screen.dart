import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_controller.dart';
import '../services/theme_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/ui/app_card.dart';
import '../widgets/ui/empty_state.dart';
import '../widgets/ui/reveal.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          AppSpacing.xxl,
        ),
        children: [
          const SectionHeader(
            title: 'Appearance',
            subtitle: 'Choose how the app looks',
          ),
          const Reveal(child: _ThemeSelector()),
          const SizedBox(height: AppSpacing.xxl),
          const SectionHeader(title: 'Data'),
          _SettingsTile(
            icon: Icons.delete_outline_rounded,
            title: 'Clear all local data',
            subtitle:
                'Removes your profile, saved foods, history, and nutrition log from this device. Your account stays.',
            iconColor: p.avoid,
            onTap: () => _confirmClear(context),
          ),
          const SizedBox(height: AppSpacing.xxl),
          const SectionHeader(title: 'About'),
          const _SettingsTile(
            icon: Icons.verified_rounded,
            title: 'Pregnancy & baby nutrition AI',
            subtitle:
                'Guidance grounded in ACOG, CDC, FDA, NIH, and AAP sources. This app does not provide medical advice - always consult your doctor or pediatrician.',
          ),
          const SizedBox(height: AppSpacing.md),
          const _SettingsTile(
            icon: Icons.phonelink_lock_rounded,
            title: 'Local-only storage',
            subtitle:
                'Your account and all your data are saved on this device only. Nothing is uploaded and there is no cloud sync.',
          ),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear all data?'),
        content: const Text(
          'This removes your profile, saved foods, history, and nutrition log. '
          'Your account stays, so you will not be signed out. This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: context.palette.avoid),
            onPressed: () async {
              await context.read<AuthController>().clearDataKeepingAccount();
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All local data cleared. Restart the app to reset your profile.'),
                  ),
                );
              }
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

/// Segmented System / Light / Dark control. Selecting an option animates the
/// entire app's palette because MaterialApp lerps between the two themes.
class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final controller = context.watch<ThemeController>();

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: ThemeMode.values.map((mode) {
          final selected = controller.mode == mode;
          return Expanded(
            child: Pressable(
              onTap: () => controller.setMode(mode),
              child: AnimatedContainer(
                duration: AppMotion.base,
                curve: AppMotion.emphasized,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: selected ? p.brandSurface : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: selected ? p.brand : Colors.transparent),
                ),
                child: Column(
                  children: [
                    Icon(
                      themeModeIcon(mode),
                      size: 19,
                      color: selected ? p.brandSoft : p.textMuted,
                    ),
                    const SizedBox(height: AppSpacing.xs + 2),
                    Text(
                      themeModeLabel(mode),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? p.brandSoft : p.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color? iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tint = iconColor ?? p.brandSoft;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        onTap: onTap,
        radius: AppRadius.md,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: p.isDark ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: tint, size: 18),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.texts.titleSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11.5, height: 1.45, color: p.textSecondary),
                  ),
                ],
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Icon(Icons.chevron_right_rounded, size: 18, color: p.textMuted),
            ],
          ],
        ),
      ),
    );
  }
}
