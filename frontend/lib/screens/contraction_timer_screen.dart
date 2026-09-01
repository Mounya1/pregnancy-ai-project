import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/contraction.dart';
import '../services/contraction_controller.dart';
import '../theme/app_theme.dart';
import '../utils/duration_format.dart';
import '../widgets/ui/app_card.dart';
import '../widgets/ui/empty_state.dart';
import '../widgets/ui/reveal.dart';

/// Times contractions and reports the pattern they make.
///
/// One button, held to a single job: press when a contraction starts, press
/// again when it eases. Everything the hospital asks for - how long, how far
/// apart, how long it has been going on - is derived rather than typed.
class ContractionTimerScreen extends StatefulWidget {
  const ContractionTimerScreen({super.key});

  @override
  State<ContractionTimerScreen> createState() => _ContractionTimerScreenState();
}

class _ContractionTimerScreenState extends State<ContractionTimerScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Unlike the kick counter this ticks the whole time the screen is open:
    // the time *since* the last contraction is as informative as the length
    // of the current one, so the display is never static.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _confirmClear(ContractionController timer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear this log?'),
        content: const Text(
          'Removes every timed contraction so a new episode starts fresh. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) await timer.clear();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final timer = context.watch<ContractionController>();
    final now = DateTime.now();
    final running = timer.running;
    final logged = timer.contractions.where((c) => !c.isRunning).toList();
    final pattern = timer.patternAt(now);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contraction timer'),
        actions: [
          if (logged.isNotEmpty)
            IconButton(
              tooltip: 'Clear log',
              onPressed: () => _confirmClear(timer),
              icon: const Icon(Icons.delete_sweep_rounded),
            ),
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
          if (pattern.meets511) ...[
            const Reveal(child: _CallNowCard()),
            const SizedBox(height: AppSpacing.xl),
          ],
          Reveal(
            child: _TimerCard(
              running: running,
              now: now,
              lastFinished: logged.isEmpty ? null : logged.first,
              onStart: () {
                HapticFeedback.mediumImpact();
                timer.start();
              },
              onStop: () {
                HapticFeedback.mediumImpact();
                timer.stop();
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Reveal.stagger(index: 1, child: _PatternCard(pattern: pattern)),
          if (logged.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxl),
            Reveal.stagger(
              index: 2,
              child: SectionHeader(
                title: 'Timed contractions',
                subtitle: logged.length == 1
                    ? '1 recorded'
                    : '${logged.length} recorded',
              ),
            ),
            for (var i = 0; i < logged.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Reveal.stagger(
                  index: (i + 3).clamp(0, 12),
                  child: _ContractionTile(
                    contraction: logged[i],
                    // The list runs newest first, so the one *after* this in
                    // the list is the one that came before it in time.
                    previous: i + 1 < logged.length ? logged[i + 1] : null,
                    onDelete: () => timer.remove(logged[i].id),
                  ),
                ),
              ),
          ] else if (running == null) ...[
            const SizedBox(height: AppSpacing.xxl),
            const Reveal(
              child: EmptyState(
                icon: Icons.timer_outlined,
                title: 'Nothing timed yet',
                message:
                    'Press start when a contraction begins and stop when it '
                    'eases. The pattern builds itself from there.',
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Text(
            'This timer records what you tell it - it cannot tell whether you '
            'are in labour. Follow whatever your midwife or maternity unit has '
            'told you, and call them if you are bleeding, leaking fluid, in '
            'constant pain, or your baby is moving less.',
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
        title: const Text('Timing contractions'),
        content: const Text(
          'Press start the moment a contraction begins to tighten, and stop '
          'when it fades. Do not try to time one that has already started - '
          'wait and catch the next.\n\n'
          'Length is how long one contraction lasts. Interval is measured '
          'from the start of one to the start of the next, so it includes the '
          'contraction itself.\n\n'
          'Many units use 5-1-1 as the point to phone: contractions about '
          'five minutes apart, each lasting about a minute, keeping that up '
          'for an hour. Your own unit may have told you something different - '
          'theirs is the one to follow.',
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

/// Shown when the recent pattern matches 5-1-1.
class _CallNowCard extends StatelessWidget {
  const _CallNowCard();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AppCard(
      color: p.limitSurface,
      borderColor: p.limit,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.phone_in_talk_rounded, color: p.limit),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Time to call',
                  style: context.texts.titleSmall?.copyWith(color: p.limit),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Your contractions have matched the 5-1-1 pattern for the '
                  'last hour: about five minutes apart, around a minute each. '
                  'That is the point most units ask to hear from you.',
                  style:
                      context.texts.bodySmall?.copyWith(color: p.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The start/stop control, plus whichever clock is currently relevant.
class _TimerCard extends StatelessWidget {
  const _TimerCard({
    required this.running,
    required this.now,
    required this.lastFinished,
    required this.onStart,
    required this.onStop,
  });

  final Contraction? running;
  final DateTime now;
  final Contraction? lastFinished;
  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final active = running != null;

    final elapsed = active
        ? now.difference(running!.startedAt)
        : lastFinished == null
            ? null
            : now.difference(lastFinished!.endedAt!);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Text(
            active
                ? 'Contraction in progress'
                : lastFinished == null
                    ? 'Ready when you are'
                    : 'Since the last one ended',
            style: context.texts.bodySmall?.copyWith(color: p.textMuted),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            elapsed == null ? '--:--' : formatClock(elapsed),
            style: context.texts.displayMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: active ? p.brandStrong : p.textSecondary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            height: 96,
            child: Pressable(
              onTap: active ? onStop : onStart,
              scale: 0.94,
              child: Container(
                decoration: BoxDecoration(
                  gradient: active ? null : p.heroGradient,
                  color: active ? p.avoidSurface : null,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: active ? Border.all(color: p.avoid, width: 2) : null,
                  boxShadow: active ? null : p.brandShadow(opacity: 0.3),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        active ? Icons.stop_rounded : Icons.play_arrow_rounded,
                        size: 30,
                        color: active ? p.avoid : p.onBrand,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        active ? 'It is easing' : 'A contraction is starting',
                        style: context.texts.titleMedium?.copyWith(
                          color: active ? p.avoid : p.onBrand,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Averages over the recent window - the three numbers a maternity unit asks
/// for on the phone.
class _PatternCard extends StatelessWidget {
  const _PatternCard({required this.pattern});

  final ContractionPattern pattern;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    if (pattern.count == 0) {
      return AppCard(
        color: p.surfaceAlt,
        shadow: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.insights_rounded, color: p.brandSoft, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Once you have timed a couple of contractions, their length '
                'and spacing will be summarised here.',
                style:
                    context.texts.bodySmall?.copyWith(color: p.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Last 75 minutes', style: context.texts.titleSmall),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              _Stat(
                label: 'Average length',
                value: pattern.averageDuration == null
                    ? '--'
                    : formatApprox(pattern.averageDuration!),
              ),
              _Stat(
                label: 'Apart',
                value: pattern.averageInterval == null
                    ? '--'
                    : formatApprox(pattern.averageInterval!),
              ),
              _Stat(label: 'Contractions', value: '${pattern.count}'),
            ],
          ),
          if (!pattern.meets511 && pattern.count >= 2) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Not yet the 5-1-1 pattern. Keep timing - and call your unit '
              'sooner if anything worries you.',
              style: context.texts.bodySmall?.copyWith(color: p.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: context.texts.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700, color: p.brandStrong),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: context.texts.bodySmall?.copyWith(color: p.textMuted),
          ),
        ],
      ),
    );
  }
}

class _ContractionTile extends StatelessWidget {
  const _ContractionTile({
    required this.contraction,
    required this.previous,
    required this.onDelete,
  });

  final Contraction contraction;

  /// The contraction immediately before this one, used for the start-to-start
  /// interval. Null for the earliest one, which has nothing to measure from.
  final Contraction? previous;

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final interval = previous == null
        ? null
        : contraction.startedAt.difference(previous!.startedAt);
    final at = contraction.startedAt;
    final clock =
        '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Text(
            clock,
            style: context.texts.bodySmall?.copyWith(
              color: p.textMuted,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lasted ${formatApprox(contraction.duration ?? Duration.zero)}',
                  style: context.texts.bodyMedium,
                ),
                if (interval != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${formatApprox(interval)} after the previous one started',
                    style: context.texts.bodySmall?.copyWith(color: p.textMuted),
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
}
