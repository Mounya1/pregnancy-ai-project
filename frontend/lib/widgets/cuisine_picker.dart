import 'package:flutter/material.dart';
import '../models/cuisine.dart';
import '../theme/app_theme.dart';
import 'ui/app_card.dart';

/// Multi-select grid of cuisines. Selecting none is a valid, meaningful state
/// ("no preference"), so there is no forced default.
class CuisinePicker extends StatelessWidget {
  const CuisinePicker({
    super.key,
    required this.selected,
    required this.onToggle,
    this.onClear,
  });

  final List<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: kCuisines.map((cuisine) {
            final isOn = selected.contains(cuisine.name);
            return Pressable(
              onTap: () => onToggle(cuisine.name),
              child: AnimatedContainer(
                duration: AppMotion.fast,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isOn ? p.brandSurface : p.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: isOn ? p.brand : p.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(cuisine.flag, style: const TextStyle(fontSize: 15)),
                    const SizedBox(width: AppSpacing.sm),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cuisine.name,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isOn ? p.brandSoft : p.textPrimary,
                          ),
                        ),
                        Text(
                          cuisine.note,
                          style: TextStyle(fontSize: 10, color: p.textMuted),
                        ),
                      ],
                    ),
                    if (isOn) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Icon(Icons.check_circle_rounded, size: 15, color: p.brand),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: Text(
                selected.isEmpty
                    ? 'No preference - meals will be international.'
                    : '${selected.length} selected',
                style: TextStyle(fontSize: 11.5, color: p.textMuted),
              ),
            ),
            if (selected.isNotEmpty && onClear != null)
              TextButton(onPressed: onClear, child: const Text('Clear')),
          ],
        ),
      ],
    );
  }
}
