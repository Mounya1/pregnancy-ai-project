import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/nutrition_log.dart';
import '../services/local_storage_service.dart';
import '../services/profile_controller.dart';
import '../theme/app_theme.dart';
import '../theme/chart_colors.dart';
import '../widgets/ui/app_card.dart';
import '../widgets/ui/empty_state.dart';
import '../widgets/ui/gradient_button.dart';
import '../widgets/ui/progress_ring.dart';
import '../widgets/ui/reveal.dart';

class NutritionTrackerScreen extends StatefulWidget {
  const NutritionTrackerScreen({super.key, this.embedded = false});

  /// True when hosted inside a section tab, which supplies its own app bar.
  final bool embedded;

  @override
  State<NutritionTrackerScreen> createState() => _NutritionTrackerScreenState();
}

class _NutritionTrackerScreenState extends State<NutritionTrackerScreen> {
  final _storage = LocalStorageService();
  List<NutritionEntry> _allEntries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await _storage.loadNutritionEntries();
    if (mounted) {
      setState(() {
        _allEntries = entries;
        _loading = false;
      });
    }
  }

  List<NutritionEntry> get _todayEntries =>
      _allEntries.where((e) => e.isSameDay(DateTime.now())).toList()
        ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));

  NutrientProfile get _todayTotal =>
      _todayEntries.fold(const NutrientProfile(), (sum, e) => sum + e.nutrients);

  Future<void> _addEntry() async {
    final result = await showModalBottomSheet<NutritionEntry>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddEntrySheet(),
    );
    if (result != null) {
      await _storage.logNutritionEntry(result);
      await _load();
    }
  }

  Future<void> _removeEntry(NutritionEntry entry) async {
    await _storage.removeNutritionEntry(entry.id);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Removed ${entry.foodName}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final profile = context.watch<ProfileController>().profile;
    final targets = targetsForLifeStage(profile.lifeStage);
    final total = _todayTotal;
    final entries = _todayEntries;

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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                100,
              ),
              children: [
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
        child: GradientButton(
          label: 'Log a food',
          icon: Icons.add_rounded,
          onPressed: _addEntry,
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
            child: Icon(Icons.restaurant_rounded, size: 15, color: p.textSecondary),
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
                Text(
                  '${entry.servings} serving${entry.servings > 1 ? 's' : ''}',
                  style: TextStyle(fontSize: 11, color: p.textMuted),
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

class _AddEntrySheet extends StatefulWidget {
  const _AddEntrySheet();

  @override
  State<_AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<_AddEntrySheet> {
  String? _selectedFood;
  int _servings = 1;
  String _query = '';

  List<String> get _matches {
    final foods = kNutrientDatabase.keys.toList();
    if (_query.trim().isEmpty) return foods;
    final q = _query.toLowerCase();
    return foods.where((f) => f.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final matches = _matches;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.sm,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Log a food', style: context.texts.titleLarge),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Search foods...',
              prefixIcon: Icon(Icons.search_rounded, size: 19),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: AppSpacing.lg),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: matches.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: Text(
                      'No foods match "$_query".',
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
                                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                                      color: p.textPrimary,
                                    ),
                                  ),
                                ),
                                if (selected)
                                  Icon(Icons.check_circle_rounded, size: 16, color: p.brand),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
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
            onPressed: _selectedFood == null
                ? null
                : () => Navigator.pop(
                      context,
                      NutritionEntry(
                        id: DateTime.now().microsecondsSinceEpoch.toString(),
                        foodName: _selectedFood!,
                        servings: _servings,
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
