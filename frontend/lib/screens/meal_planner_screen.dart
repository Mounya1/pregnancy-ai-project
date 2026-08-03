import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/meal_plan.dart';
import '../services/api_client.dart';
import '../services/api_error.dart';
import '../services/local_storage_service.dart';
import '../services/profile_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/cuisine_picker.dart';
import '../widgets/ui/app_card.dart';
import '../widgets/ui/empty_state.dart';
import '../widgets/ui/gradient_button.dart';
import '../widgets/ui/reveal.dart';
import '../widgets/ui/shimmer.dart';

class MealPlannerScreen extends StatefulWidget {
  const MealPlannerScreen({super.key, this.embedded = false});

  /// True when hosted inside a section tab, which supplies its own app bar.
  final bool embedded;

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> {
  final _api = ApiClient();
  final _storage = LocalStorageService();
  MealPlan? _plan;
  bool _loading = false;
  String? _error;
  int _days = 3;
  int _selectedDay = 0;

  /// Cuisines for this generation only. Seeded from the profile, but the user
  /// can try a different mix here without changing what they saved.
  List<String>? _cuisines;

  List<String> get _activeCuisines =>
      _cuisines ?? context.read<ProfileController>().profile.cuisines;

  List<String> get _conditions =>
      context.read<ProfileController>().profile.healthConditions;

  @override
  void initState() {
    super.initState();
    _loadCached();
  }

  Future<void> _loadCached() async {
    final cached = await _storage.loadLastMealPlan();
    if (cached != null && mounted) setState(() => _plan = MealPlan.fromJson(cached));
  }

  Future<void> _generate() async {
    final profile = context.read<ProfileController>().profile;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final plan = await _api.generateMealPlan(
        profile: profile,
        days: _days,
        cuisines: _activeCuisines,
      );
      setState(() {
        _plan = plan;
        _selectedDay = 0;
      });
      await _storage.saveLastMealPlan(plan.toJson());
    } catch (e) {
      setState(() => _error = describeApiError(e, baseUrl: _api.baseUrl));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final plan = _plan;

    return Scaffold(
      appBar: widget.embedded ? null : AppBar(title: const Text('Meal planner')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          AppSpacing.xxl,
        ),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Plan length', style: context.texts.titleSmall),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [1, 3, 5, 7].map((d) {
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
                              '$d day${d > 1 ? 's' : ''}',
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
                Row(
                  children: [
                    Expanded(child: Text('Cuisines', style: context.texts.titleSmall)),
                    Text(
                      _activeCuisines.isEmpty ? 'Any' : '${_activeCuisines.length} picked',
                      style: TextStyle(fontSize: 11.5, color: p.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                CuisinePicker(
                  selected: _activeCuisines,
                  onToggle: (name) => setState(() {
                    final next = [..._activeCuisines];
                    next.contains(name) ? next.remove(name) : next.add(name);
                    _cuisines = next;
                  }),
                  onClear: () => setState(() => _cuisines = const []),
                ),
                if (_conditions.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: p.limitSurface,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.health_and_safety_rounded, size: 15, color: p.limit),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Planning around: ${_conditions.join(', ')}',
                            style: TextStyle(fontSize: 11.5, height: 1.4, color: p.limit),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                GradientButton(
                  label: plan == null ? 'Generate plan' : 'Regenerate',
                  icon: Icons.auto_awesome_rounded,
                  loading: _loading,
                  onPressed: _generate,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (_error != null) ErrorPanel(message: _error!, onRetry: _generate),
          if (_loading) const SkeletonCardList(count: 2, height: 190),
          if (!_loading && plan == null && _error == null)
            const EmptyState(
              icon: Icons.restaurant_menu_rounded,
              title: 'No plan yet',
              message: 'Generate a plan tailored to your life stage, allergies, and dietary preferences.',
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
              _DayTabs(
                days: plan.days,
                selected: _selectedDay,
                onSelected: (i) => setState(() => _selectedDay = i),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
            if (plan.days.isNotEmpty)
              _DayPanel(
                // A regenerated shorter plan can leave the old index dangling.
                day: plan.days[_selectedDay.clamp(0, plan.days.length - 1)],
              ),
            const SizedBox(height: AppSpacing.lg),
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

class _DayTabs extends StatelessWidget {
  const _DayTabs({required this.days, required this.selected, required this.onSelected});

  final List<DayPlan> days;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < days.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Pressable(
                onTap: () => onSelected(i),
                child: AnimatedContainer(
                  duration: AppMotion.fast,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: i == selected ? p.brand : p.surface,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: i == selected ? p.brand : p.border),
                  ),
                  child: Text(
                    days[i].dayLabel,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: i == selected ? p.onBrand : p.textSecondary,
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

class _DayPanel extends StatelessWidget {
  const _DayPanel({required this.day});

  final DayPlan day;

  @override
  Widget build(BuildContext context) {
    final meals = <(String, IconData, MealItem)>[
      ('Breakfast', Icons.wb_twilight_rounded, day.breakfast),
      ('Lunch', Icons.light_mode_rounded, day.lunch),
      ('Dinner', Icons.nightlight_round, day.dinner),
      ('Snack', Icons.cookie_rounded, day.snack),
    ];

    return Column(
      // Rebuild the column when the day changes so each meal card replays its
      // entrance animation, making the tab switch legible.
      key: ValueKey(day.dayLabel),
      children: [
        for (var i = 0; i < meals.length; i++)
          Reveal.stagger(
            index: i,
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _MealCard(
                label: meals[i].$1,
                icon: meals[i].$2,
                meal: meals[i].$3,
              ),
            ),
          ),
      ],
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({required this.label, required this.icon, required this.meal});

  final String label;
  final IconData icon;
  final MealItem meal;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: p.brandSurface,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, size: 15, color: p.brandSoft),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: p.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(meal.name, style: context.texts.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            meal.description,
            style: TextStyle(fontSize: 12.5, height: 1.45, color: p.textSecondary),
          ),
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
                Icon(Icons.eco_rounded, size: 13, color: p.safe),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    meal.whyGood,
                    style: TextStyle(fontSize: 11.5, height: 1.4, color: p.safe),
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
