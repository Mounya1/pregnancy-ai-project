import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_controller.dart';
import '../services/profile_controller.dart';
import '../services/reminder_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/ui/app_card.dart';
import '../widgets/ui/empty_state.dart';
import '../widgets/ui/illustrations.dart';
import '../widgets/ui/reveal.dart';
import 'auth/account_screen.dart';
import 'doctor_notes_screen.dart';
import 'emergency_screen.dart';
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

  /// Confirms first. A stray tap here should not lock someone out mid-task,
  /// and the dialog is also where the "your data stays" promise is made.
  Future<void> _confirmSignOut(BuildContext context) async {
    final auth = context.read<AuthController>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Your profile, plans, logs, and notes stay on this device. You will '
          'need your password to get back in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed == true) await auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final profile = context.watch<ProfileController>().profile;
    final reminders = context.watch<ReminderController>();
    final account = context.watch<AuthController>().account;

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
              hasBaby: profile.babyBirthDate != null,
              name: account?.name ?? 'Your profile',
              initials: account?.initials,
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
            icon: Icons.account_circle_rounded,
            tint: Brand.teal,
            title: 'Account',
            subtitle: account == null
                ? 'Sign in details'
                : 'Password, sign out, delete data',
            onTap: () => _open(context, const AccountScreen()),
          ),
          _MenuTile(
            icon: Icons.person_rounded,
            tint: p.brand,
            title: 'Profile',
            subtitle: 'Life stage, dates, allergies, cuisines',
            onTap: () => _open(context, const ProfileScreen()),
          ),
          _MenuTile(
            icon: Icons.emergency_rounded,
            tint: p.avoid,
            title: 'Emergency contacts',
            subtitle: 'Hospital, midwife, and who to call',
            onTap: () => _open(context, const EmergencyScreen()),
          ),
          _MenuTile(
            icon: Icons.medical_information_rounded,
            tint: Brand.teal,
            title: 'Doctor notes',
            subtitle: 'What you were told, about you and your baby',
            onTap: () => _open(context, const DoctorNotesScreen()),
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
          const SizedBox(height: AppSpacing.xl),
          // Signing out belongs where people look for it, not two screens
          // deep inside Account.
          _MenuTile(
            icon: Icons.logout_rounded,
            tint: p.avoid,
            title: 'Sign out',
            subtitle: account == null
                ? 'Not signed in'
                : 'Locks the app - your data stays on this device',
            onTap: () => _confirmSignOut(context),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.hasBaby,
    required this.name,
    required this.initials,
    required this.statusLabel,
    required this.allergies,
    required this.cuisines,
    required this.conditions,
    required this.onTap,
  });

  /// Swaps the watermark figure once there is a baby to hold.
  final bool hasBaby;

  final String name;

  /// Null before an account exists, which only happens in tests - the gate
  /// means a signed-in app always has one.
  final String? initials;

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
          Positioned(
            right: -8,
            bottom: -10,
            child: Opacity(
              opacity: 0.3,
              child: hasBaby
                  ? const HoldingBabyIllustration(
                      color: Colors.white,
                      accent: Color(0xFFEDE7FF),
                      size: 116,
                    )
                  : const MotherIllustration(
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
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                      ),
                      child: initials == null
                          ? const Icon(Icons.person_rounded, color: Colors.white, size: 23)
                          : Text(
                              initials!,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
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
