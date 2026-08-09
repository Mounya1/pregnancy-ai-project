import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/care_plan.dart';
import '../services/care_controller.dart';
import '../services/profile_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/ui/app_card.dart';
import '../widgets/ui/empty_state.dart';
import '../widgets/ui/illustrations.dart';
import '../widgets/ui/reveal.dart';
import 'doctor_notes_screen.dart';

/// What to do and what to take, for whichever stage you are in.
class CareScreen extends StatelessWidget {
  const CareScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final profile = context.watch<ProfileController>().profile;
    final care = context.watch<CareController>();

    final sections = careTasksFor(profile);
    final supplements = supplementsFor(profile);
    final total = sections.fold<int>(0, (sum, s) => sum + s.tasks.length);
    final done = care.doneCountIn(sections);
    final hasBaby = profile.babyAgeMonths != null;

    return Scaffold(
      appBar: embedded ? null : AppBar(title: const Text('Care plan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          AppSpacing.xxl,
        ),
        children: [
          Reveal(child: _CareHero(done: done, total: total, hasBaby: hasBaby)),
          const SizedBox(height: AppSpacing.xl),
          Reveal(
            delay: const Duration(milliseconds: 60),
            child: _DoctorNotesCard(care: care),
          ),

          if (sections.isEmpty && supplements.isEmpty) ...[
            const SizedBox(height: AppSpacing.xxl),
            const EmptyState(
              icon: Icons.checklist_rounded,
              title: 'Nothing scheduled',
              message: 'Set your life stage and dates in Profile to see the to-do '
                  'list and supplements for your stage.',
            ),
          ],

          for (final section in sections) ...[
            const SizedBox(height: AppSpacing.xxl),
            SectionHeader(title: section.title, subtitle: section.subtitle),
            for (var i = 0; i < section.tasks.length; i++)
              Reveal.stagger(
                index: i,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _TaskTile(
                    task: section.tasks[i],
                    done: care.isDone(section.tasks[i].id),
                    onToggle: () => care.toggleTask(section.tasks[i].id),
                  ),
                ),
              ),
          ],

          if (supplements.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxl),
            SectionHeader(
              title: hasBaby ? 'What your baby needs' : 'Vitamins and supplements',
              subtitle: 'Standard guidance - your doctor\'s advice comes first',
            ),
            for (var i = 0; i < supplements.length; i++)
              Reveal.stagger(
                index: i,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _SupplementTile(supplement: supplements[i]),
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              color: p.avoidSurface,
              borderColor: p.avoid.withValues(alpha: 0.25),
              shadow: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.block_rounded, size: 17, color: p.avoid),
                      const SizedBox(width: AppSpacing.sm),
                      Text('Do not take', style: context.texts.titleSmall),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  for (final item in kSupplementsToAvoid)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('•  ', style: TextStyle(color: p.avoid)),
                          Expanded(
                            child: Text(
                              item,
                              style: TextStyle(
                                fontSize: 11.5,
                                height: 1.45,
                                color: p.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Illustrated header, with the tick-off count as the headline number.
class _CareHero extends StatelessWidget {
  const _CareHero({required this.done, required this.total, required this.hasBaby});

  final int done;
  final int total;
  final bool hasBaby;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tones = FigureTones.defaults(hasBaby ? p.accent : p.brand, dark: p.isDark);

    return AppCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [p.brandSurface, p.surface],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(child: BlobDecoration(color: p.brand, seed: 9)),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            total == 0 ? 'Your care plan' : '$done of $total done',
                            style: context.texts.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            hasBaby
                                ? 'Checks, vaccinations, and what your baby needs.'
                                : 'Appointments, tests, and the vitamins that matter.',
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.45,
                              color: p.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    hasBaby
                        ? HoldingBabyIllustration(
                            color: p.accent,
                            tones: tones,
                            size: 112,
                          )
                        : MotherIllustration(
                            color: p.brand,
                            tones: tones,
                            size: 112,
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The bridge to the doctor notes. Shows the next appointment when there is
/// one, because that is the single most useful thing this card can say.
class _DoctorNotesCard extends StatelessWidget {
  const _DoctorNotesCard({required this.care});

  final CareController care;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final next = care.nextAppointment;
    final count = care.notes.length;

    return AppCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DoctorNotesScreen()),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Brand.teal.withValues(alpha: p.isDark ? 0.22 : 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(Icons.medical_information_rounded, size: 19, color: Brand.teal),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Doctor notes', style: context.texts.titleSmall),
                const SizedBox(height: 2),
                Text(
                  next != null
                      ? 'Next: ${next.title} on ${_shortDate(next.nextAppointment!)}'
                      : count == 0
                          ? 'Write down what you were told, while it is fresh'
                          : '$count note${count == 1 ? '' : 's'} saved',
                  style: TextStyle(fontSize: 11.5, color: p.textMuted),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 18, color: p.textMuted),
        ],
      ),
    );
  }

  static String _shortDate(DateTime date) => '${date.day}/${date.month}';
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task, required this.done, required this.onToggle});

  final CareTask task;
  final bool done;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AppCard(
      onTap: onToggle,
      radius: AppRadius.md,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: AppMotion.fast,
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: done ? p.brand : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: done ? p.brand : p.borderStrong,
                width: 1.6,
              ),
            ),
            child: done ? Icon(Icons.check_rounded, size: 15, color: p.onBrand) : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: done ? p.textMuted : p.textPrimary,
                          decoration: done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    if (task.medical) ...[
                      const SizedBox(width: AppSpacing.sm),
                      const _Chip(label: 'With your doctor', color: Brand.teal),
                    ],
                  ],
                ),
                if (task.timing.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    task.timing,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: p.brand,
                    ),
                  ),
                ],
                const SizedBox(height: 3),
                Text(
                  task.detail,
                  style: TextStyle(fontSize: 11.5, height: 1.45, color: p.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SupplementTile extends StatelessWidget {
  const _SupplementTile({required this.supplement});

  final Supplement supplement;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AppCard(
      radius: AppRadius.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: p.brand.withValues(alpha: p.isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(Icons.medication_liquid_rounded, size: 18, color: p.brand),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(supplement.name, style: context.texts.titleSmall),
                        ),
                        if (supplement.confirmWithDoctor)
                          const _Chip(label: 'Only if advised', color: Brand.teal),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      supplement.dose,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: p.brand,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            supplement.why,
            style: TextStyle(fontSize: 11.5, height: 1.45, color: p.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          _MetaRow(icon: Icons.schedule_rounded, text: supplement.when),
          if (supplement.foodSources.isNotEmpty) ...[
            const SizedBox(height: 4),
            _MetaRow(icon: Icons.restaurant_rounded, text: supplement.foodSources),
          ],
          if (supplement.warning.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: p.avoidSurface,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 15, color: p.avoid),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      supplement.warning,
                      style: TextStyle(fontSize: 11, height: 1.4, color: p.avoid),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 13, color: p.textMuted),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 11, height: 1.4, color: p.textMuted),
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: context.palette.isDark ? 0.24 : 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
          color: color,
        ),
      ),
    );
  }
}
