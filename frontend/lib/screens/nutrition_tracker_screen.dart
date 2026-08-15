import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/nutrition_log.dart';
import '../services/api_client.dart';
import '../services/api_error.dart';
import '../services/nutrition_controller.dart';
import '../services/profile_controller.dart';
import '../theme/app_theme.dart';
import '../theme/chart_colors.dart';
import '../widgets/ui/app_card.dart';
import '../widgets/ui/empty_state.dart';
import '../widgets/ui/gradient_button.dart';
import '../widgets/ui/progress_ring.dart';
import '../widgets/ui/photo_banner.dart';
import '../widgets/nutrient_breakdown.dart';
import '../widgets/ui/reveal.dart';
import 'food_analysis_screen.dart';

class NutritionTrackerScreen extends StatefulWidget {
  const NutritionTrackerScreen({super.key, this.embedded = false});

  /// True when hosted inside a section tab, which supplies its own app bar.
  final bool embedded;

  @override
  State<NutritionTrackerScreen> createState() => _NutritionTrackerScreenState();
}

class _NutritionTrackerScreenState extends State<NutritionTrackerScreen> {
  Future<void> _addEntry() async {
    final controller = context.read<NutritionController>();
    final result = await showModalBottomSheet<NutritionEntry>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddEntrySheet(),
    );
    if (result != null) await controller.add(result);
  }

  /// The camera route into the log. Scanning already told you whether a food
  /// is safe; not being able to log it from there made you type it again.
  void _scanEntry() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FoodAnalysisScreen(
          profile: context.read<ProfileController>().profile,
        ),
      ),
    );
  }

  Future<void> _removeEntry(NutritionEntry entry) async {
    await context.read<NutritionController>().remove(entry);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Removed ${entry.foodName}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final profile = context.watch<ProfileController>().profile;
    final log = context.watch<NutritionController>();
    final targets = targetsForLifeStage(profile.lifeStage);
    final entries = log.today;
    final total = log.totalFor(entries);

    // One hue for every nutrient on purpose. These bars show magnitude against
    // a target, not identity - the row label already says which nutrient it is.
    // A five-hue set also could not pass colour-vision separation on all pairs.
    final nutrients = <(String, double, double, String)>[
      ('Iron', total.ironMg, targets.ironMg, 'mg'),
      ('Calcium', total.calciumMg, targets.calciumMg, 'mg'),
      ('Folate', total.folateMcg, targets.folateMcg, 'mcg'),
      ('Protein', total.proteinG, targets.proteinG, 'g'),
      ('Vitamin D', total.vitaminDMcg, targets.vitaminDMcg, 'mcg'),
    ];

    // Overall completion is the mean of the five capped ratios, so one
    // over-served nutrient can't mask four empty ones.
    final overall = nutrients
            .map((n) => n.$3 > 0 ? (n.$2 / n.$3).clamp(0.0, 1.0).toDouble() : 0.0)
            .reduce((a, b) => a + b) /
        nutrients.length;

    return Scaffold(
      appBar: widget.embedded ? null : AppBar(title: const Text('Nutrition tracker')),
      body: !log.isLoaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                100,
              ),
              children: [
                const Reveal(
                  child: PhotoBanner(
                    image: 'assets/images/food_log.jpg',
                    title: 'What you ate today',
                    subtitle: 'Type it, scan it, or pick from the list',
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Reveal(
                  child: _TodayHero(
                    overall: overall,
                    loggedCount: entries.length,
                    stageLabel: profile.statusLabel,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Reveal(
                  delay: const Duration(milliseconds: 80),
                  child: AppCard(
                    child: Column(
                      children: [
                        for (var i = 0; i < nutrients.length; i++) ...[
                          if (i > 0) const SizedBox(height: AppSpacing.lg),
                          _NutrientRow(
                            label: nutrients[i].$1,
                            value: nutrients[i].$2,
                            target: nutrients[i].$3,
                            unit: nutrients[i].$4,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                SectionHeader(
                  title: "Today's log",
                  subtitle: entries.isEmpty ? null : '${entries.length} item${entries.length == 1 ? '' : 's'}',
                ),
                if (entries.isEmpty)
                  AppCard(
                    shadow: false,
                    color: p.surfaceAlt,
                    borderColor: Colors.transparent,
                    child: Row(
                      children: [
                        Icon(Icons.add_circle_outline_rounded, size: 18, color: p.textMuted),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            'Nothing logged today. Add a food to start filling your rings.',
                            style: context.texts.bodySmall?.copyWith(color: p.textMuted),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  for (var i = 0; i < entries.length; i++)
                    Reveal.stagger(
                      index: i,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _LogTile(
                          entry: entries[i],
                          onRemove: () => _removeEntry(entries[i]),
                        ),
                      ),
                    ),
              ],
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Row(
          children: [
            Expanded(
              child: GradientButton(
                label: 'Log a food',
                icon: Icons.add_rounded,
                onPressed: _addEntry,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SoftButton(
              label: 'Scan',
              icon: Icons.camera_alt_rounded,
              onPressed: _scanEntry,
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayHero extends StatelessWidget {
  const _TodayHero({
    required this.overall,
    required this.loggedCount,
    required this.stageLabel,
  });

  final double overall;
  final int loggedCount;
  final String stageLabel;

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      child: Row(
        children: [
          ProgressRing(
            value: overall,
            size: 82,
            strokeWidth: 8,
            trackColor: Colors.white.withValues(alpha: 0.22),
            colors: [Colors.white, Colors.white.withValues(alpha: 0.7)],
            child: Text(
              '${(overall * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Today',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  loggedCount == 0
                      ? 'Log your first food of the day'
                      : '$loggedCount food${loggedCount == 1 ? '' : 's'} logged',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    'Targets for: $stageLabel',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
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

class _NutrientRow extends StatelessWidget {
  const _NutrientRow({
    required this.label,
    required this.value,
    required this.target,
    required this.unit,
  });

  final String label;
  final double value;
  final double target;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final mark = ChartColors.mark(context);
    final good = ChartColors.good(context);
    final ratio = target > 0 ? (value / target).clamp(0.0, 1.0).toDouble() : 0.0;
    final met = ratio >= 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: context.texts.titleSmall)),
            if (met) ...[
              Icon(Icons.check_circle_rounded, size: 13, color: good),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              '${value.toStringAsFixed(0)} / ${target.toStringAsFixed(0)} $unit',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: met ? good : p.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ProgressTrack(
          value: ratio,
          colors: met ? [good, good] : [mark, mark.withValues(alpha: 0.75)],
        ),
      ],
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.entry, required this.onRemove});

  final NutritionEntry entry;
  final VoidCallback onRemove;

  IconData get _icon => switch (entry.source) {
        NutritionSource.scanned => Icons.camera_alt_rounded,
        NutritionSource.typed => Icons.edit_rounded,
        NutritionSource.picked => Icons.restaurant_rounded,
      };

  String get _servingLabel {
    final count = '${entry.servings} serving${entry.servings > 1 ? 's' : ''}';
    final description = entry.servingDescription;
    return description == null ? count : '$count  ·  $description';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AppCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      shadow: false,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: p.surfaceAlt,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(_icon, size: 15, color: p.textSecondary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.foodName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.bodyMedium,
                ),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _servingLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: p.textMuted),
                      ),
                    ),
                    // An estimate never sits in the log looking like a
                    // measured value.
                    if (entry.isEstimated) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'est.',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: p.limit,
                        ),
                      ),
                    ],
                    if (!entry.hasNutrients) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'no nutrient data',
                        style: TextStyle(fontSize: 9.5, color: p.textMuted),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.close_rounded, size: 17, color: p.textMuted),
          ),
        ],
      ),
    );
  }
}


/// Three ways in: pick one of the built-in foods, type any food at all and
/// have its nutrients estimated, or scan a photo.
///
/// The typed path is the important one. A log that only accepts fifteen foods
/// is a demo, not a food diary.
class _AddEntrySheet extends StatefulWidget {
  const _AddEntrySheet();

  @override
  State<_AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<_AddEntrySheet> {
  final _api = ApiClient();

  String? _selectedFood;
  int _servings = 1;
  String _query = '';

  /// Set once a typed food has been looked up. Holding it here is what lets
  /// the numbers be shown before committing, rather than logging blind.
  NutrientEstimate? _estimate;
  bool _estimating = false;
  String? _error;

  List<String> get _matches {
    final foods = kNutrientDatabase.keys.toList();
    if (_query.trim().isEmpty) return foods;
    final q = _query.toLowerCase();
    return foods.where((f) => f.toLowerCase().contains(q)).toList();
  }

  /// True when the typed text is worth estimating: something was typed, and it
  /// is not just the name of a food already in the table.
  bool get _canEstimate {
    final typed = _query.trim();
    if (typed.length < 2) return false;
    if (_estimate?.foodName.toLowerCase() == typed.toLowerCase()) return false;
    return !kNutrientDatabase.keys.any((f) => f.toLowerCase() == typed.toLowerCase());
  }

  Future<void> _estimateTyped() async {
    final typed = _query.trim();
    setState(() {
      _estimating = true;
      _error = null;
      _selectedFood = null;
    });

    try {
      final estimate = await _api.estimateNutrients(
        foodName: typed,
        profile: context.read<ProfileController>().profile,
      );
      if (!mounted) return;
      setState(() {
        _estimate = estimate;
        _estimating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _estimating = false;
        _error = describeApiError(e, baseUrl: _api.baseUrl);
      });
    }
  }

  void _submit() {
    final estimate = _estimate;
    final entry = estimate != null
        ? NutritionEntry(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            foodName: estimate.foodName,
            servings: _servings,
            perServing: estimate.perServing,
            servingDescription: estimate.servingDescription,
            source: NutritionSource.typed,
          )
        : NutritionEntry(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            foodName: _selectedFood!,
            servings: _servings,
          );
    Navigator.pop(context, entry);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final matches = _matches;
    final estimate = _estimate;
    final targets = targetsForLifeStage(context.watch<ProfileController>().profile.lifeStage);
    final ready = _selectedFood != null || estimate != null;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.sm,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Log a food', style: context.texts.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Type any food, e.g. rajma chawal',
                prefixIcon: Icon(Icons.search_rounded, size: 19),
              ),
              onChanged: (v) => setState(() {
                _query = v;
                // A new search invalidates the last estimate, otherwise the
                // Add button would log a food nobody is looking at any more.
                _estimate = null;
                _error = null;
              }),
              onSubmitted: (_) => _canEstimate && !_estimating ? _estimateTyped() : null,
            ),

            // The way out of the built-in table. Offered as soon as what was
            // typed is not one of the fifteen.
            if (_canEstimate) ...[
              const SizedBox(height: AppSpacing.md),
              Pressable(
                onTap: _estimating ? null : _estimateTyped,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: p.brandSurface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: p.brand.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      if (_estimating)
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: p.brand),
                        )
                      else
                        Icon(Icons.auto_awesome_rounded, size: 17, color: p.brand),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          _estimating
                              ? 'Working out the nutrients...'
                              : 'Get nutrients for "${_query.trim()}"',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: p.brand,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _error!,
                style: TextStyle(fontSize: 11.5, height: 1.4, color: p.avoid),
              ),
            ],

            if (estimate != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                shadow: false,
                color: p.surfaceAlt,
                borderColor: Colors.transparent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(estimate.foodName, style: context.texts.titleSmall),
                    const SizedBox(height: AppSpacing.md),
                    if (!estimate.recognised)
                      Text(
                        estimate.note.isEmpty
                            ? 'That does not look like a food. You can still log it, but it will not count towards anything.'
                            : estimate.note,
                        style: TextStyle(fontSize: 11.5, height: 1.4, color: p.limit),
                      )
                    else
                      NutrientBreakdown(
                        nutrients: estimate.perServing,
                        targets: targets,
                        servingDescription: estimate.servingDescription,
                        note: estimate.note,
                        isEstimate: estimate.isEstimate,
                        dense: true,
                      ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: AppSpacing.lg),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: matches.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        child: Text(
                          'Not one of the built-in foods - use the button above to '
                          'look up "${_query.trim()}".',
                          style: context.texts.bodySmall?.copyWith(color: p.textMuted),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: matches.length,
                        itemBuilder: (context, i) {
                          final food = matches[i];
                          final selected = food == _selectedFood;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Pressable(
                              onTap: () => setState(() => _selectedFood = food),
                              child: AnimatedContainer(
                                duration: AppMotion.fast,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.md,
                                ),
                                decoration: BoxDecoration(
                                  color: selected ? p.brandSurface : p.surfaceAlt,
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                  border: Border.all(
                                    color: selected ? p.brand : Colors.transparent,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        food,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight:
                                              selected ? FontWeight.w600 : FontWeight.w400,
                                          color: p.textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (selected)
                                      Icon(Icons.check_circle_rounded,
                                          size: 16, color: p.brand),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],

            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Text('Servings', style: context.texts.titleSmall),
                const Spacer(),
                IconButton(
                  onPressed: _servings > 1 ? () => setState(() => _servings--) : null,
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                ),
                SizedBox(
                  width: 28,
                  child: Text(
                    '$_servings',
                    textAlign: TextAlign.center,
                    style: context.texts.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _servings++),
                  icon: const Icon(Icons.add_circle_outline_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            GradientButton(
              label: 'Add to today',
              icon: Icons.check_rounded,
              onPressed: ready ? _submit : null,
            ),
          ],
        ),
      ),
    );
  }
}
