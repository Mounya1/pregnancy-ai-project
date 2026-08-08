import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/milestone.dart';
import '../models/user_profile.dart';
import '../screens/profile_screen.dart';
import '../services/milestone_controller.dart';
import '../services/profile_controller.dart';
import '../theme/app_theme.dart';
import 'ui/app_card.dart';

/// The switch for week-by-week updates, plus a preview of what the next one
/// will actually say.
///
/// The preview is the point: "weekly notifications" is a promise, and showing
/// the real title and date of the next one turns it into something you can
/// check before deciding to trust it.
class WeeklyUpdatesCard extends StatelessWidget {
  const WeeklyUpdatesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final milestones = context.watch<MilestoneController>();
    final profile = context.watch<ProfileController>().profile;

    final hasDate = profile.babyBirthDate != null ||
        (profile.dueDate != null && profile.lifeStage == LifeStage.pregnancy);
    final enabled = milestones.settings.enabled;
    final next = milestones.next;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: p.brand.withValues(alpha: p.isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(Icons.auto_awesome_rounded, size: 19, color: p.brand),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_title(profile), style: context.texts.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle(profile),
                      style: TextStyle(fontSize: 11.5, color: p.textMuted, height: 1.35),
                    ),
                  ],
                ),
              ),
              Switch(
                value: enabled,
                onChanged: hasDate
                    ? (on) => context.read<MilestoneController>().setEnabled(on, profile)
                    : null,
              ),
            ],
          ),

          // Nothing to count from, so the switch is dead. Say why, and offer
          // the one action that fixes it.
          if (!hasDate) ...[
            const SizedBox(height: AppSpacing.md),
            _Note(
              icon: Icons.event_rounded,
              text: profile.lifeStage == LifeStage.pregnancy
                  ? 'Add your due date to get week-by-week updates.'
                  : 'Add your baby\'s birth date to get monthly updates.',
              actionLabel: 'Open profile',
              onAction: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
            ),
          ],

          if (hasDate && enabled) ...[
            const SizedBox(height: AppSpacing.lg),
            Divider(height: 1, color: p.border),
            const SizedBox(height: AppSpacing.md),
            _TimeRow(
              hour: milestones.settings.hour,
              minute: milestones.settings.minute,
              onPick: () => _pickTime(context, milestones, profile),
            ),
            if (next != null) ...[
              const SizedBox(height: AppSpacing.md),
              _NextPreview(milestone: next, total: milestones.scheduled.length),
            ] else ...[
              const SizedBox(height: AppSpacing.md),
              const _Note(
                icon: Icons.check_circle_rounded,
                text: 'No updates left to send - you are at the end of the guide.',
              ),
            ],
            if (!milestones.canSchedule) ...[
              const SizedBox(height: AppSpacing.md),
              const _Note(
                icon: Icons.info_rounded,
                text: 'A browser cannot fire a notification weeks from now. '
                    'Install the Android build for these to arrive on time.',
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _title(UserProfile profile) =>
      profile.babyBirthDate != null ? 'Monthly baby updates' : 'Weekly pregnancy updates';

  String _subtitle(UserProfile profile) => profile.babyBirthDate != null
      ? 'What changes each month, and what to feed'
      : 'How your baby is growing, and how you may feel';

  Future<void> _pickTime(
    BuildContext context,
    MilestoneController milestones,
    UserProfile profile,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: milestones.settings.hour, minute: milestones.settings.minute),
    );
    if (picked == null) return;
    await milestones.setTime(picked.hour, picked.minute, profile);
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({required this.hour, required this.minute, required this.onPick});

  final int hour;
  final int minute;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final label = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay(hour: hour, minute: minute));

    return Row(
      children: [
        Icon(Icons.schedule_rounded, size: 16, color: p.textMuted),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text('Arrives at', style: TextStyle(fontSize: 12.5, color: p.textSecondary)),
        ),
        Pressable(
          onTap: onPick,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: p.brandSurface,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: p.brand.withValues(alpha: 0.3)),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: p.brand,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NextPreview extends StatelessWidget {
  const _NextPreview({required this.milestone, required this.total});

  final Milestone milestone;
  final int total;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: p.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'NEXT',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: p.textMuted,
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('EEE d MMM').format(milestone.when),
                style: TextStyle(fontSize: 11, color: p.textMuted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            milestone.title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 3),
          Text(
            milestone.body.split('\n').first,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11.5, height: 1.4, color: p.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            total == 1 ? '1 update scheduled' : '$total updates scheduled',
            style: TextStyle(fontSize: 10.5, color: p.textMuted),
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: p.textMuted),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: TextStyle(fontSize: 11.5, height: 1.4, color: p.textSecondary),
              ),
              if (actionLabel != null)
                GestureDetector(
                  onTap: onAction,
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      actionLabel!,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: p.brand,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
