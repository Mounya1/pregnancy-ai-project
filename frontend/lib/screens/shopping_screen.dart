import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/shopping.dart';
import '../models/shopping_region.dart';
import '../services/profile_controller.dart';
import '../services/shopping_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/ui/app_card.dart';
import '../widgets/ui/empty_state.dart';
import '../widgets/ui/photo_banner.dart';
import '../widgets/ui/reveal.dart';

/// What to buy for this stage, in the shops that exist where you live.
class ShoppingScreen extends StatelessWidget {
  const ShoppingScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final shopping = context.watch<ShoppingController>();
    final profile = context.watch<ProfileController>().profile;
    final sections = shopping.sectionsFor(profile);
    final total = sections.fold<int>(0, (sum, s) => sum + s.items.length);
    final done = shopping.checkedCountIn(sections);

    return Scaffold(
      appBar: embedded ? null : AppBar(title: const Text('Shopping')),
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
              image: 'assets/images/baby_shopping.jpg',
              title: 'What to buy',
              subtitle: 'For this stage, in the shops near you',
              alignment: Alignment.topCenter,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Reveal(child: _RegionCard(shopping: shopping)),
          const SizedBox(height: AppSpacing.xl),
          Reveal(child: _NearbyRow(region: shopping.region)),
          const SizedBox(height: AppSpacing.xxl),
          if (total > 0)
            _Progress(done: done, total: total, onClear: shopping.clearChecked),
          for (final section in sections) ...[
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(title: section.title, subtitle: section.subtitle),
            for (var i = 0; i < section.items.length; i++)
              Reveal.stagger(
                index: i,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _ItemTile(
                    item: section.items[i],
                    checked: shopping.isChecked(section.items[i].id),
                    onToggle: () => shopping.toggle(section.items[i].id),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _RegionCard extends StatelessWidget {
  const _RegionCard({required this.shopping});

  final ShoppingController shopping;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AppCard(
      onTap: () => _pickRegion(context, shopping),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: p.brand.withValues(alpha: p.isDark ? 0.22 : 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(Icons.place_rounded, size: 19, color: p.brand),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shopping.region.name, style: context.texts.titleSmall),
                const SizedBox(height: 2),
                Text(
                  shopping.regionWasChosen
                      ? 'Food and shop names for your region'
                      : 'Detected from your device - tap to change',
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

  Future<void> _pickRegion(BuildContext context, ShoppingController shopping) async {
    final chosen = await showModalBottomSheet<ShoppingRegion>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  Text('Where are you shopping?', style: context.texts.titleMedium),
                ],
              ),
            ),
            for (final region in kShoppingRegions)
              ListTile(
                title: Text(region.name),
                subtitle: Text(
                  region.ironFoods.take(3).join(', '),
                  style: const TextStyle(fontSize: 11.5),
                ),
                trailing: region.code == shopping.region.code
                    ? Icon(Icons.check_rounded, color: context.palette.brand)
                    : null,
                onTap: () => Navigator.pop(sheetContext, region),
              ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );

    if (chosen != null) await shopping.setRegion(chosen);
  }
}

/// The actual location-aware part: hands a search to the maps app, which
/// already knows where the phone is.
class _NearbyRow extends StatelessWidget {
  const _NearbyRow({required this.region});

  final ShoppingRegion region;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FIND NEAR ME',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
            color: p.textMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _NearbyChip(
                icon: Icons.local_pharmacy_rounded,
                label: region.pharmacyTerm,
                query: region.pharmacyTerm,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _NearbyChip(
                icon: Icons.child_friendly_rounded,
                label: 'Baby store',
                query: region.babyStoreQuery,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _NearbyChip(
                icon: Icons.shopping_basket_rounded,
                label: 'Groceries',
                query: region.groceryQuery,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NearbyChip extends StatelessWidget {
  const _NearbyChip({required this.icon, required this.label, required this.query});

  final IconData icon;
  final String label;
  final String query;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Pressable(
      onTap: () async {
        final messenger = ScaffoldMessenger.of(context);
        final opened = await context.read<ShoppingController>().openNearby(query);
        if (!opened) {
          messenger.showSnackBar(
            const SnackBar(content: Text('No maps app available to open this')),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: p.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 19, color: p.brand),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.done, required this.total, required this.onClear});

  final int done;
  final int total;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Row(
      children: [
        Expanded(
          child: Text(
            done == 0 ? '$total to look at' : '$done of $total ticked off',
            style: TextStyle(fontSize: 12, color: p.textSecondary),
          ),
        ),
        if (done > 0)
          GestureDetector(
            onTap: onClear,
            child: Text(
              'Reset',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: p.brand,
              ),
            ),
          ),
      ],
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.item, required this.checked, required this.onToggle});

  final ShoppingItem item;
  final bool checked;
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
              color: checked ? p.brand : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: checked ? p.brand : p.borderStrong,
                width: 1.6,
              ),
            ),
            child: checked
                ? Icon(Icons.check_rounded, size: 15, color: p.onBrand)
                : null,
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
                        item.name,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: checked ? p.textMuted : p.textPrimary,
                          decoration: checked ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    if (item.essential) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: p.brandSurface,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          'Essential',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                            color: p.brand,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.why,
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
