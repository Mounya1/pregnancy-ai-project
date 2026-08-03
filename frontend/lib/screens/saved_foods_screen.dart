import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/saved_food.dart';
import '../services/local_storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/safety_verdict_card.dart';
import '../widgets/ui/empty_state.dart';
import '../widgets/ui/shimmer.dart';

class SavedFoodsScreen extends StatefulWidget {
  const SavedFoodsScreen({super.key});

  @override
  State<SavedFoodsScreen> createState() => _SavedFoodsScreenState();
}

class _SavedFoodsScreenState extends State<SavedFoodsScreen> {
  final _storage = LocalStorageService();
  List<SavedFood> _foods = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final foods = await _storage.loadSavedFoods();
    if (mounted) {
      setState(() {
        _foods = foods;
        _loading = false;
      });
    }
  }

  Future<void> _remove(SavedFood food) async {
    await _storage.removeSavedFood(food.id);
    if (!mounted) return;
    setState(() => _foods = _foods.where((f) => f.id != food.id).toList());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Removed ${food.foodName}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved foods'),
        bottom: _foods.isEmpty
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(28),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.lg, bottom: AppSpacing.md),
                    child: Text(
                      '${_foods.length} bookmarked',
                      style: context.texts.bodySmall?.copyWith(color: p.textMuted),
                    ),
                  ),
                ),
              ),
      ),
      body: _loading
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: SkeletonCardList(count: 3, height: 150),
            )
          : _foods.isEmpty
              ? const EmptyState(
                  icon: Icons.bookmark_border_rounded,
                  title: 'Nothing saved yet',
                  message: 'Tap Save on any answer from chat or a scan and it will wait for you here.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.sm,
                    AppSpacing.xl,
                    AppSpacing.xxl,
                  ),
                  itemCount: _foods.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xl),
                  itemBuilder: (context, i) {
                    final food = _foods[i];
                    return Dismissible(
                      key: ValueKey(food.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => _remove(food),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: AppSpacing.xl),
                        decoration: BoxDecoration(
                          color: p.avoidSurface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Icon(Icons.delete_outline_rounded, color: p.avoid),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    food.foodName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.texts.titleMedium,
                                  ),
                                ),
                                Text(
                                  DateFormat('MMM d').format(food.savedAt),
                                  style: TextStyle(fontSize: 11, color: p.textMuted),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                InkWell(
                                  onTap: () => _remove(food),
                                  borderRadius: BorderRadius.circular(AppRadius.pill),
                                  child: Padding(
                                    padding: const EdgeInsets.all(AppSpacing.xs),
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 16,
                                      color: p.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DualVerdictSection(
                            motherResult: food.motherResult,
                            babyResult: food.babyResult,
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
