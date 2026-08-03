import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/profile_controller.dart';
import '../services/reminder_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/ui/app_card.dart';
import '../widgets/ui/empty_state.dart';
import '../widgets/ui/illustrations.dart';
import '../widgets/ui/reveal.dart';
import 'medical_report_screen.dart';
import 'profile_screen.dart';
import 'reminders_screen.dart';
import 'saved_foods_screen.dart';
import 'settings_screen.dart';

/// "Me" section: the account-shaped part of the app. A summary of who the
/// app thinks you are, then everything that configures or belongs to you.
class MeScreen extends StatelessWidget {
  const MeScreen({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final profile = context.watch<ProfileController>().profile;
    final reminders = context.watch<ReminderController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Me')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          AppSpacing.xxl,
        ),
        children: [
          Reveal(
            child: _SummaryCard(
              statusLabel: profile.statusLabel,
              allergies: profile.allergies.length,
              cuisines: profile.cuisines.length,
              conditions: profile.healthConditions.length,
              onTap: () => _open(context, const ProfileScreen()),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          const SectionHeader(title: 'Your details'),
          _MenuTile(
            icon: Icons.person_rounded,
            tint: p.brand,
            title: 'Profile',
            subtitle: 'Life stage, dates, allergies, cuisines',
            onTap: () => _open(context, const ProfileScreen()),
          ),
          _MenuTile(
            icon: Icons.health_and_safety_rounded,
            tint: Brand.blossom,
            title: 'Medical reports',
            subtitle: 'Upload results and adapt your diet',
            onTap: () => _open(context, const MedicalReportScreen()),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Saved & scheduled'),
          _MenuTile(
            icon: Icons.alarm_rounded,
            tint: Brand.violetDeep,
            title: 'Reminders',
            subtitle: reminders.activeCount == 0
                ? 'Meals, medicines, feeds, bedtime'
                : '${reminders.activeCount} active',
            onTap: () => _open(context, const RemindersScreen()),
          ),
          _MenuTile(
            icon: Icons.bookmark_rounded,
            tint: Brand.indigo,
            title: 'Saved foods',
            subtitle: 'Answers you bookmarked',
            onTap: () => _open(context, const SavedFoodsScreen()),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'App'),
          _MenuTile(
            icon: Icons.settings_rounded,
            tint: Brand.teal,
            title: 'Settings',
            subtitle: 'Appearance, data, about',
            onTap: () => _open(context, const SettingsScreen()),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.statusLabel,
    required this.allergies,
    required this.cuisines,
    required this.conditions,
    required this.onTap,
  });

  final String statusLabel;
  final int allergies;
  final int cuisines;
  final int conditions;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          const Positioned.fill(child: BlobDecoration(color: Colors.white, seed: 2)),
          const Positioned(
            right: -8,
            bottom: -10,
            child: Opacity(
              opacity: 0.3,
              child: MotherIllustration(
                color: Colors.white,
                accent: Color(0xFFEDE7FF),
                size: 112,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                      ),
                      child: const Icon(Icons.person_rounded, color: Colors.white, size: 23),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Text(
                        statusLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Colors.white),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    _Stat(value: allergies, label: 'allergies'),
                    _Stat(value: cuisines, label: 'cuisines'),
                    _Stat(value: conditions, label: 'conditions'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color tint;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        onTap: onTap,
        radius: AppRadius.md,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: p.isDark ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, size: 19, color: tint),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.texts.titleSmall),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 11.5, color: p.textMuted)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: p.textMuted),
          ],
        ),
      ),
    );
  }
}
