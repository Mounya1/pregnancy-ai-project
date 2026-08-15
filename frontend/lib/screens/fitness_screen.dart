import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/fitness_plan.dart';
import '../models/user_profile.dart';
import '../services/api_client.dart';
import '../services/api_error.dart';
import '../services/local_storage_service.dart';
import '../services/profile_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/ui/app_card.dart';
import '../widgets/ui/photo_banner.dart';
import '../widgets/ui/empty_state.dart';
import '../widgets/ui/gradient_button.dart';
import '../widgets/ui/reveal.dart';
import '../widgets/ui/shimmer.dart';

/// Stage-appropriate exercise guidance, generated against the same profile
/// (life stage, week, conditions) the meal planner uses.
class FitnessScreen extends StatefulWidget {
  const FitnessScreen({super.key, this.embedded = false});

  /// True when hosted inside a section tab, which supplies its own app bar.
  final bool embedded;

  @override
  State<FitnessScreen> createState() => _FitnessScreenState();
}

class _FitnessScreenState extends State<FitnessScreen> {
  final _api = ApiClient();
  final _storage = LocalStorageService();
  FitnessPlan? _plan;
  bool _loading = false;
  String? _error;
  int _days = 7;
  int _selectedDay = 0;
  final Set<String> _constraints = {};

  static const _constraintOptions = [
    'No equipment',
    'Only 15 minutes',
    'Low impact only',
    'Bad knees',
    'Back pain',
    'Very tired',
  ];

  @override
  void initState() {
    super.initState();
    _loadCached();
  }

  Future<void> _loadCached() async {
    final cached = await _storage.loadLastFitnessPlan();
    if (cached != null && mounted) {
      setState(() => _plan = FitnessPlan.fromJson(cached));
    }
  }

  Future<void> _generate() async {
    final profile = context.read<ProfileController>().profile;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final plan = await _api.generateFitnessPlan(
        profile: profile,
        days: _days,
        constraints: _constraints.toList(),
      );
      setState(() {
        _plan = plan;
        _selectedDay = 0;
      });
      await _storage.saveLastFitnessPlan(plan.toJson());
    } catch (e) {
      setState(() => _error = describeApiError(e, baseUrl: _api.baseUrl));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final profile = context.watch<ProfileController>().profile;
    final plan = _plan;

    return Scaffold(
      appBar: widget.embedded ? null : AppBar(title: const Text('Fitness')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          AppSpacing.xxl,
        ),
        children: [
          const Reveal(
            child: PhotoBanner(
              image: 'assets/images/fitness.jpg',
              title: 'Moving safely',
              subtitle: 'Built for your stage - and what to stop for',
              height: 150,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Reveal(child: _StageBanner(profile: profile)),
          const SizedBox(height: AppSpacing.xl),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Plan length', style: context.texts.titleSmall),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [3, 5, 7].map((d) {
                    final selected = d == _days;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: d == 7 ? 0 : AppSpacing.sm),
                        child: Pressable(
                          onTap: () => setState(() => _days = d),
                          child: AnimatedContainer(
                            duration: AppMotion.fast,
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                            decoration: BoxDecoration(
                              color: selected ? p.brand : p.surfaceAlt,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(color: selected ? p.brand : p.border),
                            ),
                            child: Text(
                              '$d days',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: selected ? p.onBrand : p.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('Anything to work around?', style: context.texts.titleSmall),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _constraintOptions.map((c) {
                    final on = _constraints.contains(c);
                    return Pressable(
                      onTap: () => setState(() {
                        on ? _constraints.remove(c) : _constraints.add(c);
                      }),
                      child: AnimatedContainer(
                        duration: AppMotion.fast,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: on ? p.brandSurface : p.surfaceAlt,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: on ? p.brand : Colors.transparent),
                        ),
                        child: Text(
                          c,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: on ? p.brandSoft : p.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.lg),
                GradientButton(
                  label: plan == null ? 'Build my plan' : 'Rebuild plan',
                  icon: Icons.fitness_center_rounded,
                  loading: _loading,
                  onPressed: _generate,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (_error != null) ErrorPanel(message: _error!, onRetry: _generate),
          if (_loading) const SkeletonCardList(count: 2, height: 150),
          if (!_loading && plan == null && _error == null)
            const EmptyState(
              icon: Icons.self_improvement_rounded,
              title: 'No plan yet',
              message: 'Build a movement plan matched to your stage, week, and any conditions on your profile.',
            ),
          if (!_loading && plan != null) ...[
            Reveal(
              child: AppCard(
                color: p.brandSurface,
                borderColor: p.brand.withValues(alpha: 0.18),
                shadow: false,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 17, color: p.brandSoft),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        plan.summary,
                        style: TextStyle(fontSize: 12.5, height: 1.45, color: p.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (plan.days.length > 1) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var i = 0; i < plan.days.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: Pressable(
                          onTap: () => setState(() => _selectedDay = i),
                          child: AnimatedContainer(
                            duration: AppMotion.fast,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: i == _selectedDay ? p.brand : p.surface,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              border: Border.all(
                                color: i == _selectedDay ? p.brand : p.border,
                              ),
                            ),
                            child: Text(
                              plan.days[i].dayLabel,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: i == _selectedDay ? p.onBrand : p.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
            if (plan.days.isNotEmpty)
              // A rebuilt, shorter plan can leave the old index dangling.
              _DayPanel(day: plan.days[_selectedDay.clamp(0, plan.days.length - 1)]),
            const SizedBox(height: AppSpacing.xl),
            _WarningSigns(signs: plan.warningSigns),
            const SizedBox(height: AppSpacing.md),
            Text(
              plan.disclaimer,
              style: TextStyle(fontSize: 10, height: 1.4, color: p.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _StageBanner extends StatelessWidget {
  const _StageBanner({required this.profile});

  final UserProfile profile;

  String get _guidance {
    switch (profile.lifeStage) {
      case LifeStage.pregnancy:
        final week = profile.pregnancyWeek;
        if (week == null) return 'Aim for about 150 minutes of moderate movement a week.';
        if (week <= 13) {
          return 'First trimester: keep what you already do, and let fatigue set the pace.';
        }
        if (week <= 27) {
          return 'Second trimester: usually the easiest window. Avoid lying flat on your back.';
        }
        return 'Third trimester: shorter, gentler sessions. Balance work matters more than intensity.';
      case LifeStage.breastfeeding:
      case LifeStage.postpartum:
        final months = profile.babyAgeMonths;
        if (months != null && months < 2) {
          return 'Early postpartum: walking, breathing, and pelvic floor only until you are cleared.';
        }
        return 'Rebuild gradually - pelvic floor and deep core first, intensity later.';
      case LifeStage.general:
        return 'Set your life stage in Profile and this plan will match it.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.directions_walk_rounded, color: Colors.white, size: 23),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.statusLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _guidance,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayPanel extends StatelessWidget {
  const _DayPanel({required this.day});

  final FitnessDay day;

  @override
  Widget build(BuildContext context) {
    return Column(
      // Replay the entrance when switching days so the change is legible.
      key: ValueKey(day.dayLabel),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Text(day.focus, style: context.texts.titleMedium),
        ),
        for (var i = 0; i < day.items.length; i++)
          Reveal.stagger(
            index: i,
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _ExerciseCard(item: day.items[i]),
            ),
          ),
      ],
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.item});

  final ExerciseItem item;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // Intensity is a state, so it gets a status colour plus an icon and a word.
    final (fg, bg, icon) = switch (item.intensity) {
      ExerciseIntensity.gentle => (p.safe, p.safeSurface, Icons.spa_rounded),
      ExerciseIntensity.moderate => (p.brandSoft, p.brandSurface, Icons.bolt_rounded),
      ExerciseIntensity.rest => (p.neutral, p.neutralSurface, Icons.bedtime_rounded),
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(item.name, style: context.texts.titleSmall)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 11, color: fg),
                    const SizedBox(width: 3),
                    Text(
                      intensityLabel(item.intensity),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: fg,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 12, color: p.textMuted),
              const SizedBox(width: 4),
              Text(item.duration, style: TextStyle(fontSize: 11.5, color: p.textMuted)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            item.howTo,
            style: TextStyle(fontSize: 12.5, height: 1.45, color: p.textSecondary),
          ),
          if (item.whyGood.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm + 2),
              decoration: BoxDecoration(
                color: p.safeSurface,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.favorite_rounded, size: 12, color: p.safe),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      item.whyGood,
                      style: TextStyle(fontSize: 11.5, height: 1.4, color: p.safe),
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

class _WarningSigns extends StatelessWidget {
  const _WarningSigns({required this.signs});

  final List<String> signs;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (signs.isEmpty) return const SizedBox.shrink();

    return AppCard(
      color: p.avoidSurface,
      borderColor: p.avoid.withValues(alpha: 0.25),
      shadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_rounded, size: 17, color: p.avoid),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Stop and call your doctor if you get',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: p.avoid,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...signs.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs + 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('•  ', style: TextStyle(fontSize: 12, color: p.avoid)),
                    Expanded(
                      child: Text(
                        s,
                        style: TextStyle(fontSize: 12, height: 1.4, color: p.avoid),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
