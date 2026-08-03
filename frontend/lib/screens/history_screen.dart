import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/history_entry.dart';
import '../services/local_storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/safety_verdict_card.dart';
import '../widgets/ui/app_card.dart';
import '../widgets/ui/empty_state.dart';
import '../widgets/ui/reveal.dart';
import '../widgets/ui/shimmer.dart';
import '../widgets/ui/verdict_chip.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, this.embedded = false});

  /// True when hosted inside a section tab, which supplies its own app bar.
  final bool embedded;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _storage = LocalStorageService();
  List<HistoryEntry> _entries = [];
  bool _loading = true;

  /// null = all sources.
  HistorySource? _filter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await _storage.loadHistory();
    if (mounted) {
      setState(() {
        _entries = entries;
        _loading = false;
      });
    }
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear history?'),
        content: const Text('This removes every past question and scan from this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: context.palette.avoid),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await _storage.clearHistory();
      await _load();
    }
  }

  List<HistoryEntry> get _visible =>
      _filter == null ? _entries : _entries.where((e) => e.source == _filter).toList();

  /// Groups entries under Today / Yesterday / date headers, so a long list
  /// reads as a timeline instead of an undifferentiated feed.
  Map<String, List<HistoryEntry>> get _grouped {
    final groups = <String, List<HistoryEntry>>{};
    for (final entry in _visible) {
      groups.putIfAbsent(_dayLabel(entry.timestamp), () => []).add(entry);
    }
    return groups;
  }

  static String _dayLabel(DateTime time) {
    final now = DateTime.now();
    final day = DateTime(time.year, time.month, time.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat('EEEE').format(time);
    return DateFormat('MMMM d').format(time);
  }

  @override
  Widget build(BuildContext context) {
    final groups = _grouped;

    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text('History'),
              actions: [
                if (_entries.isNotEmpty)
                  IconButton(
                    tooltip: 'Clear history',
                    onPressed: _confirmClear,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
              ],
            ),
      body: _loading
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: SkeletonCardList(count: 5, height: 64),
            )
          : _entries.isEmpty
              ? const EmptyState(
                  icon: Icons.history_rounded,
                  title: 'No checks yet',
                  message: 'Questions you ask and foods you scan will collect here, so you can look them up again in a second.',
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.sm,
                      AppSpacing.xl,
                      AppSpacing.xxl,
                    ),
                    children: [
                      _FilterBar(
                        current: _filter,
                        onChanged: (f) => setState(() => _filter = f),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      if (_visible.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
                          child: Text(
                            'Nothing here for this filter.',
                            textAlign: TextAlign.center,
                            style: context.texts.bodySmall
                                ?.copyWith(color: context.palette.textMuted),
                          ),
                        ),
                      for (final group in groups.entries) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: Text(
                            group.key.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                              color: context.palette.textMuted,
                            ),
                          ),
                        ),
                        for (var i = 0; i < group.value.length; i++)
                          Reveal.stagger(
                            index: i,
                            child: _HistoryTile(
                              entry: group.value[i],
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => _HistoryDetailScreen(entry: group.value[i]),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.current, required this.onChanged});

  final HistorySource? current;
  final ValueChanged<HistorySource?> onChanged;

  static const _options = <(String, HistorySource?)>[
    ('All', null),
    ('Chat', HistorySource.chat),
    ('Voice', HistorySource.voice),
    ('Scan', HistorySource.scan),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _options.map((option) {
          final selected = current == option.$2;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Pressable(
              onTap: () => onChanged(option.$2),
              child: AnimatedContainer(
                duration: AppMotion.fast,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: selected ? p.brand : p.surface,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: selected ? p.brand : p.border),
                ),
                child: Text(
                  option.$1,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: selected ? p.onBrand : p.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry, required this.onTap});

  final HistoryEntry entry;
  final VoidCallback onTap;

  IconData get _icon => switch (entry.source) {
        HistorySource.voice => Icons.graphic_eq_rounded,
        HistorySource.scan => Icons.center_focus_strong_rounded,
        HistorySource.chat => Icons.chat_bubble_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final style = VerdictStyle.of(context, entry.motherResult.verdict);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        onTap: onTap,
        radius: AppRadius.md,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: style.background,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(_icon, size: 17, color: style.foreground),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.query,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.texts.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('h:mm a').format(entry.timestamp),
                    style: TextStyle(fontSize: 11, color: p.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            VerdictChip(verdict: entry.motherResult.verdict, compact: true),
          ],
        ),
      ),
    );
  }
}

class _HistoryDetailScreen extends StatelessWidget {
  const _HistoryDetailScreen({required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(entry.query, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          AppSpacing.xxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEEE, MMMM d · h:mm a').format(entry.timestamp),
              style: context.texts.bodySmall?.copyWith(color: context.palette.textMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
            DualVerdictSection(motherResult: entry.motherResult, babyResult: entry.babyResult),
          ],
        ),
      ),
    );
  }
}
