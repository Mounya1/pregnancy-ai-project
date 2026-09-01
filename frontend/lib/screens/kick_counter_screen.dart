import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/kick_session.dart';
import '../services/kick_controller.dart';
import '../theme/app_theme.dart';
import '../utils/duration_format.dart';
import '../widgets/ui/app_card.dart';
import '../widgets/ui/empty_state.dart';
import '../widgets/ui/progress_ring.dart';
import '../widgets/ui/reveal.dart';

/// The "count to ten" fetal movement check.
///
/// One big target and a running clock, because this is used lying on one side
/// with a phone held above your face. Everything else on the screen is
/// secondary to hitting that button without looking at it.
class KickCounterScreen extends StatefulWidget {
  const KickCounterScreen({super.key});

  @override
  State<KickCounterScreen> createState() => _KickCounterScreenState();
}

class _KickCounterScreenState extends State<KickCounterScreen> {
  Timer? _ticker;

  /// Redrawn once a second only while a count is open. A timer left running
  /// on a screen with nothing to animate is pure battery cost.
  void _syncTicker(bool counting) {
    if (counting && _ticker == null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!counting && _ticker != null) {
      _ticker!.cancel();
      _ticker = null;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _confirmStop(KickController kicks) async {
    final session = kicks.active;
    final counted = session?.count ?? 0;

    if (counted > 0) {
      final keep = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Stop counting?'),
          content: Text(
            counted == 1
                ? 'You have recorded 1 movement so far.'
                : 'You have recorded $counted movements so far.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Keep counting'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Stop'),
            ),
          ],
        ),
      );
      if (keep != true) return;
    }

    await kicks.stop();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final kicks = context.watch<KickController>();
    final session = kicks.active;
    final history = kicks.sessions.where((s) => s.id != session?.id).toList();

    _syncTicker(session != null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kick counter'),
        actions: [
          IconButton(
            tooltip: 'How this works',
            onPressed: () => _showHelp(context),
            icon: const Icon(Icons.help_outline_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          110,
        ),
        children: [
          Reveal(
            child: session == null
                ? _StartCard(onStart: kicks.start)
                : _CountingCard(
                    session: session,
                    onKick: () {
                      HapticFeedback.mediumImpact();
                      kicks.recordKick();
                    },
                    onStop: () => _confirmStop(kicks),
                  ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Reveal.stagger(index: 1, child: const _GuidanceCard()),
          if (history.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxl),
            Reveal.stagger(
              index: 2,
              child: SectionHeader(
                title: 'Past counts',
                subtitle: history.length == 1
                    ? '1 session recorded'
                    : '${history.length} sessions recorded',
              ),
            ),
            for (var i = 0; i < history.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Reveal.stagger(
                  index: (i + 3).clamp(0, 12),
                  child: _SessionTile(
                    session: history[i],
                    onDelete: () => kicks.remove(history[i].id),
                  ),
                ),
              ),
          ] else if (session == null) ...[
            const SizedBox(height: AppSpacing.xxl),
            const Reveal(
              child: EmptyState(
                icon: Icons.favorite_rounded,
                title: 'No counts yet',
                message:
                    'Start a count when your baby is normally active - often '
                    'after a meal or in the evening.',
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Text(
            'A kick count is a self-check, not a diagnosis. If your baby is '
            'moving less than usual, call your midwife or maternity unit '
            'straight away - at any hour, and without waiting to finish a '
            'count.',
            style: context.texts.bodySmall?.copyWith(color: p.textMuted),
          ),
        ],
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Counting to ten'),
        content: const Text(
          'Pick a time your baby is usually active. Lie on your left side or '
          'sit somewhere comfortable, and tap once for every movement you '
          'feel - a kick, roll, flutter or swish.\n\n'
          'Ten movements normally arrive well within two hours. If it takes '
          'longer, or the pattern is different from your baby’s usual, '
          'contact your midwife or maternity unit.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _StartCard extends StatelessWidget {
  const _StartCard({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return GradientCard(
      onTap: onStart,
      child: Column(
        children: [
          Icon(Icons.touch_app_rounded, size: 44, color: p.onBrand),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Start a count',
            style: context.texts.titleLarge?.copyWith(color: p.onBrand),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Tap once for every movement until you reach ten.',
            textAlign: TextAlign.center,
            style: context.texts.bodyMedium
                ?.copyWith(color: p.onBrand.withValues(alpha: 0.85)),
          ),
        ],
      ),
    );
  }
}

/// The active count: a ring, the clock, and one very large button.
class _CountingCard extends StatelessWidget {
  const _CountingCard({
    required this.session,
    required this.onKick,
    required this.onStop,
  });

  final KickSession session;
  final VoidCallback onKick;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final elapsed = session.elapsedAt(DateTime.now());
    final overWindow = elapsed > KickSession.window;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          ProgressRing(
            value: session.count / KickSession.target,
            size: 168,
            strokeWidth: 14,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${session.count}',
                  style: context.texts.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: p.brandStrong,
                  ),
                ),
                Text(
                  'of ${KickSession.target}',
                  style: context.texts.bodySmall?.copyWith(color: p.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.schedule_rounded, size: 16, color: p.textMuted),
              const SizedBox(width: AppSpacing.xs),
              Text(
                formatClock(elapsed),
                style: context.texts.titleMedium?.copyWith(
                  color: overWindow ? p.limit : p.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          if (overWindow) ...[
            const SizedBox(height: AppSpacing.md),
            _Notice(
              color: p.limit,
              surface: p.limitSurface,
              icon: Icons.info_outline_rounded,
              text:
                  'This count has passed two hours. Mention it to your midwife '
                  'or maternity unit.',
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          // Deliberately oversized. It has to be findable by feel.
          SizedBox(
            width: double.infinity,
            height: 96,
            child: Pressable(
              onTap: onKick,
              scale: 0.94,
              child: Container(
                decoration: BoxDecoration(
                  gradient: p.heroGradient,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: p.brandShadow(opacity: 0.3),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 30, color: p.onBrand),
                      Text(
                        'I felt a movement',
                        style: context.texts.titleMedium
                            ?.copyWith(color: p.onBrand),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton.icon(
            onPressed: onStop,
            icon: const Icon(Icons.stop_rounded, size: 18),
            label: const Text('Stop counting'),
          ),
        ],
      ),
    );
  }
}

class _GuidanceCard extends StatelessWidget {
  const _GuidanceCard();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AppCard(
      color: p.surfaceAlt,
      shadow: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline_rounded, color: p.brandSoft, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'What matters is your baby’s own pattern. A day that feels '
              'quieter than normal is worth a phone call, even if you still '
              'reach ten.',
              style: context.texts.bodySmall?.copyWith(color: p.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session, required this.onDelete});

  final KickSession session;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final complete = session.isComplete;
    final flagged = session.tookLongerThanUsual;

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: complete ? p.safeSurface : p.neutralSurface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Center(
              child: Text(
                '${session.count}',
                style: context.texts.titleSmall?.copyWith(
                  color: complete ? p.safe : p.neutral,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  complete
                      ? 'Ten movements in ${formatApprox(session.duration)}'
                      : '${session.count} movements recorded',
                  style: context.texts.bodyMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  _when(session.startedAt),
                  style: context.texts.bodySmall?.copyWith(color: p.textMuted),
                ),
                if (flagged) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Took longer than two hours',
                    style: context.texts.bodySmall?.copyWith(color: p.limit),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: onDelete,
            icon: Icon(Icons.close_rounded, size: 18, color: p.textMuted),
          ),
        ],
      ),
    );
  }

  static String _when(DateTime at) {
    final now = DateTime.now();
    final sameDay =
        at.year == now.year && at.month == now.month && at.day == now.day;
    final hour = at.hour.toString().padLeft(2, '0');
    final minute = at.minute.toString().padLeft(2, '0');
    if (sameDay) return 'Today at $hour:$minute';

    final yesterday = now.subtract(const Duration(days: 1));
    if (at.year == yesterday.year &&
        at.month == yesterday.month &&
        at.day == yesterday.day) {
      return 'Yesterday at $hour:$minute';
    }
    return '${at.day}/${at.month} at $hour:$minute';
  }
}

/// Inline coloured note used for the over-two-hours flag.
class _Notice extends StatelessWidget {
  const _Notice({
    required this.color,
    required this.surface,
    required this.icon,
    required this.text,
  });

  final Color color;
  final Color surface;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: context.texts.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
