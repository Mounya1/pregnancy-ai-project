import 'package:flutter/material.dart';
import '../models/suggestions.dart';
import '../theme/app_theme.dart';
import 'ui/app_card.dart';
import 'ui/gradient_button.dart';

/// Tag editor with live suggestions.
///
/// Shows matching options from [pool] as you type and offers a few common ones
/// before you type anything, so the field teaches you what it accepts. Free
/// text is still allowed - pressing enter adds whatever was typed.
class SuggestionField extends StatefulWidget {
  const SuggestionField({
    super.key,
    required this.tags,
    required this.pool,
    required this.hint,
    required this.tint,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> tags;
  final List<String> pool;
  final String hint;
  final Color tint;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  @override
  State<SuggestionField> createState() => _SuggestionFieldState();
}

class _SuggestionFieldState extends State<SuggestionField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _add(String value) {
    final text = value.trim();
    if (text.isEmpty) return;
    // Adding the same tag twice is silently a no-op rather than an error.
    if (widget.tags.any((t) => t.toLowerCase() == text.toLowerCase())) {
      _controller.clear();
      setState(() => _query = '');
      return;
    }
    widget.onAdd(text);
    _controller.clear();
    setState(() => _query = '');
  }

  /// Full list in a sheet, so several can be ticked in one go instead of
  /// typing them one at a time.
  Future<void> _openPicker() async {
    _focusNode.unfocus();
    final picked = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PoolPickerSheet(
        pool: widget.pool,
        already: widget.tags,
        title: widget.hint,
        tint: widget.tint,
      ),
    );
    if (picked == null) return;
    for (final item in picked) {
      widget.onAdd(item);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final matches = filterSuggestions(widget.pool, _query, exclude: widget.tags);
    // Always visible. Hiding these behind focus meant the field looked like a
    // plain text box, and there was no way to discover that "Peanuts" is one
    // tap away without first guessing and typing it.
    final showSuggestions = matches.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.tags.isNotEmpty) ...[
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: widget.tags
                .map((t) => _Tag(
                      label: t,
                      tint: widget.tint,
                      onRemove: () => widget.onRemove(t),
                    ))
                .toList(),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                style: context.texts.bodyMedium,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  prefixIcon: Icon(Icons.search_rounded, size: 18, color: p.textMuted),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: Icon(Icons.close_rounded, size: 16, color: p.textMuted),
                          onPressed: () {
                            _controller.clear();
                            setState(() => _query = '');
                          },
                        ),
                ),
                onChanged: (v) => setState(() => _query = v),
                onSubmitted: _add,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Pressable(
              // With text typed this adds it; empty, it opens the full list.
              // Previously an empty field made this button silently do
              // nothing, which read as the app being broken.
              onTap: () =>
                  _query.trim().isEmpty ? _openPicker() : _add(_controller.text),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: p.brandSurface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  _query.trim().isEmpty ? Icons.list_rounded : Icons.add_rounded,
                  color: p.brandSoft,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        AnimatedSize(
          duration: AppMotion.fast,
          curve: AppMotion.enter,
          alignment: Alignment.topLeft,
          child: showSuggestions
              ? Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _query.isEmpty ? 'COMMON' : 'SUGGESTIONS',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: p.textMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          ...matches
                            .map((s) => Pressable(
                                  onTap: () => _add(s),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                      vertical: AppSpacing.sm - 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: p.surfaceAlt,
                                      borderRadius: BorderRadius.circular(AppRadius.pill),
                                      border: Border.all(color: p.border),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.add_rounded, size: 13, color: p.textMuted),
                                        const SizedBox(width: 4),
                                        Text(
                                          s,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: p.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )),
                          Pressable(
                            onTap: _openPicker,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm - 1,
                              ),
                              decoration: BoxDecoration(
                                color: p.brandSurface,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                                border: Border.all(color: p.brand.withValues(alpha: 0.25)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.list_rounded, size: 13, color: p.brandSoft),
                                  const SizedBox(width: 4),
                                  Text(
                                    'See all',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: p.brandSoft,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.tint, required this.onRemove});

  final String label;
  final Color tint;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.sm,
        top: 5,
        bottom: 5,
      ),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: p.isDark ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: tint.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tint),
          ),
          const SizedBox(width: AppSpacing.xs),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Icon(Icons.close_rounded, size: 14, color: tint),
          ),
        ],
      ),
    );
  }
}

/// Full-list picker with search and multi-select.
///
/// Exists because typing every allergen one at a time is the slowest possible
/// way to answer "which of these apply to you", and the list is short enough
/// to simply show.
class _PoolPickerSheet extends StatefulWidget {
  const _PoolPickerSheet({
    required this.pool,
    required this.already,
    required this.title,
    required this.tint,
  });

  final List<String> pool;
  final List<String> already;
  final String title;
  final Color tint;

  @override
  State<_PoolPickerSheet> createState() => _PoolPickerSheetState();
}

class _PoolPickerSheetState extends State<_PoolPickerSheet> {
  final _selected = <String>{};
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final taken = widget.already.map((e) => e.toLowerCase()).toSet();
    final q = _query.trim().toLowerCase();
    final options = widget.pool
        .where((o) => !taken.contains(o.toLowerCase()))
        .where((o) => q.isEmpty || o.toLowerCase().contains(q))
        .toList();

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
          Text(widget.title, style: context.texts.titleLarge),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search the list...',
              prefixIcon: Icon(Icons.search_rounded, size: 19),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: AppSpacing.lg),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: options.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: Text(
                      widget.already.isEmpty
                          ? 'Nothing matches "$_query".'
                          : 'Nothing left to add here.',
                      style: context.texts.bodySmall?.copyWith(color: p.textMuted),
                    ),
                  )
                : SingleChildScrollView(
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: options.map((option) {
                        final on = _selected.contains(option);
                        return Pressable(
                          onTap: () => setState(() {
                            on ? _selected.remove(option) : _selected.add(option);
                          }),
                          child: AnimatedContainer(
                            duration: AppMotion.fast,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: on
                                  ? widget.tint.withValues(alpha: p.isDark ? 0.22 : 0.13)
                                  : p.surfaceAlt,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              border: Border.all(
                                color: on ? widget.tint : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  on ? Icons.check_circle_rounded : Icons.add_rounded,
                                  size: 14,
                                  color: on ? widget.tint : p.textMuted,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  option,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                                    color: on ? widget.tint : p.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.lg),
          GradientButton(
            label: _selected.isEmpty
                ? 'Done'
                : 'Add ${_selected.length} selected',
            icon: Icons.check_rounded,
            onPressed: () => Navigator.pop(context, _selected.toList()),
          ),
        ],
      ),
    );
  }
}
