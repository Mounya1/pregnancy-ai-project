import 'package:flutter/material.dart';
import '../models/suggestions.dart';
import '../theme/app_theme.dart';
import 'ui/app_card.dart';

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

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final matches = filterSuggestions(widget.pool, _query, exclude: widget.tags);
    // Suggestions stay out of the way until the field is in use.
    final showSuggestions = (_focusNode.hasFocus || _query.isNotEmpty) && matches.isNotEmpty;

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
              onTap: () => _add(_controller.text),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: p.brandSurface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(Icons.add_rounded, color: p.brandSoft, size: 20),
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
                        children: matches
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
                                ))
                            .toList(),
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
