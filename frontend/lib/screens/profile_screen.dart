import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/suggestions.dart';
import '../models/user_profile.dart';
import '../services/profile_controller.dart';
import '../theme/app_theme.dart';
import '../theme/brand_flavor.dart';
import '../widgets/cuisine_picker.dart';
import '../widgets/suggestion_field.dart';
import '../widgets/ui/app_card.dart';
import '../widgets/ui/empty_state.dart';
import '../widgets/ui/reveal.dart';
import 'medical_report_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final controller = context.watch<ProfileController>();
    final profile = controller.profile;
    final dateFormat = DateFormat('MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          AppSpacing.xxl,
        ),
        children: [
          Reveal(child: _ProfileHeader(profile: profile)),
          const SizedBox(height: AppSpacing.xxl),
          const SectionHeader(
            title: 'Life stage',
            subtitle: 'Tailors every answer, target, and meal plan',
          ),
          Reveal(
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: LifeStage.values.map((stage) {
                final selected = profile.lifeStage == stage;
                return Pressable(
                  onTap: () => controller.update((profile) => profile.copyWith(lifeStage: stage)),
                  child: AnimatedContainer(
                    duration: AppMotion.fast,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md - 2,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? p.brand : p.surface,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: selected ? p.brand : p.border),
                      boxShadow: selected ? p.brandShadow(opacity: 0.22) : null,
                    ),
                    child: Text(
                      lifeStageLabel(stage),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected ? p.onBrand : p.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          if (profile.lifeStage == LifeStage.pregnancy) ...[
            const SizedBox(height: AppSpacing.xxl),
            const SectionHeader(title: 'Due date'),
            _DatePickerTile(
              value: profile.dueDate,
              label: profile.dueDate != null
                  ? dateFormat.format(profile.dueDate!)
                  : 'Set your due date',
              trailing: profile.pregnancyWeek != null ? 'Week ${profile.pregnancyWeek}' : null,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 300)),
              onPicked: (d) => controller.update((profile) => profile.copyWith(dueDate: d)),
            ),
          ],
          if (profile.lifeStage == LifeStage.breastfeeding ||
              profile.lifeStage == LifeStage.postpartum) ...[
            const SizedBox(height: AppSpacing.xxl),
            const SectionHeader(title: "Baby's birth date"),
            _DatePickerTile(
              value: profile.babyBirthDate,
              label: profile.babyBirthDate != null
                  ? dateFormat.format(profile.babyBirthDate!)
                  : "Set your baby's birth date",
              trailing: profile.babyAgeMonths != null ? '${profile.babyAgeMonths} months' : null,
              firstDate: DateTime.now().subtract(const Duration(days: 900)),
              lastDate: DateTime.now(),
              onPicked: (d) => controller.update((profile) => profile.copyWith(babyBirthDate: d)),
            ),
          ],
          if (usesBabyFlavor(profile)) ...[
            const SizedBox(height: AppSpacing.xxl),
            const SectionHeader(
              title: "Baby's gender",
              subtitle: 'Sets the app colour after the birth',
            ),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: BabyGender.values.map((gender) {
                final selected = profile.babyGender == gender;
                // Each option previews the colour it applies, so the choice
                // shows its own consequence.
                final preview = switch (gender) {
                  BabyGender.girl => const Color(0xFFE86A93),
                  BabyGender.boy => const Color(0xFF3D8FD6),
                  BabyGender.unspecified => p.textMuted,
                };
                return Pressable(
                  onTap: () =>
                      controller.update((profile) => profile.copyWith(babyGender: gender)),
                  child: AnimatedContainer(
                    duration: AppMotion.fast,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md - 2,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? preview.withValues(alpha: 0.14) : p.surface,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: selected ? preview : p.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(color: preview, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          babyGenderLabel(gender),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected ? preview : p.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: AppSpacing.xxl),
          const SectionHeader(
            title: 'Allergies',
            subtitle: 'Foods to always flag for you',
          ),
          SuggestionField(
            tags: profile.allergies,
            pool: kAllergySuggestions,
            hint: 'Search or type an allergy',
            tint: p.avoid,
            onAdd: (tag) => controller
                .update((profile) => profile.copyWith(allergies: [...profile.allergies, tag])),
            onRemove: (tag) => controller.update((profile) =>
                profile.copyWith(allergies: profile.allergies.where((a) => a != tag).toList())),
          ),
          const SizedBox(height: AppSpacing.xxl),
          const SectionHeader(
            title: 'Cuisines',
            subtitle: 'What your meal plans should be cooked from',
          ),
          CuisinePicker(
            selected: profile.cuisines,
            onToggle: (name) => controller.update((profile) {
              final next = [...profile.cuisines];
              next.contains(name) ? next.remove(name) : next.add(name);
              return profile.copyWith(cuisines: next);
            }),
            onClear: () => controller.update((profile) => profile.copyWith(cuisines: const [])),
          ),
          const SizedBox(height: AppSpacing.xxl),
          const SectionHeader(
            title: 'Health conditions',
            subtitle: 'Added automatically from uploaded reports',
          ),
          SuggestionField(
            tags: profile.healthConditions,
            pool: kConditionSuggestions,
            hint: 'Search or type a condition',
            tint: p.limit,
            onAdd: (tag) => controller.update((profile) =>
                profile.copyWith(healthConditions: [...profile.healthConditions, tag])),
            onRemove: (tag) => controller.update((profile) => profile.copyWith(
                healthConditions:
                    profile.healthConditions.where((c) => c != tag).toList())),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MedicalReportScreen()),
              ),
              icon: const Icon(Icons.upload_file_rounded, size: 16),
              label: const Text('Upload a medical report'),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          const SectionHeader(
            title: 'Dietary preferences',
            subtitle: 'Shapes meal plans and alternatives',
          ),
          SuggestionField(
            tags: profile.dietaryPreferences,
            pool: kDietarySuggestions,
            hint: 'Search or type a preference',
            tint: p.brand,
            onAdd: (tag) => controller.update((profile) =>
                profile.copyWith(dietaryPreferences: [...profile.dietaryPreferences, tag])),
            onRemove: (tag) => controller.update((profile) => profile.copyWith(
                dietaryPreferences:
                    profile.dietaryPreferences.where((t) => t != tag).toList())),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Icon(Icons.cloud_done_rounded, size: 14, color: p.textMuted),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Changes save automatically to this device and apply across chat, scan, meal planning, and nutrition targets.',
                  style: TextStyle(fontSize: 11, height: 1.4, color: p.textMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 27),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.statusLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${profile.allergies.length} allerg${profile.allergies.length == 1 ? 'y' : 'ies'} · '
                  '${profile.dietaryPreferences.length} preference${profile.dietaryPreferences.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.85),
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

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({
    required this.value,
    required this.label,
    required this.firstDate,
    required this.lastDate,
    required this.onPicked,
    this.trailing,
  });

  final DateTime? value;
  final String label;
  final String? trailing;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onPicked;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AppCard(
      radius: AppRadius.md,
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: firstDate,
          lastDate: lastDate,
        );
        if (picked != null) onPicked(picked);
      },
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: p.brandSurface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(Icons.calendar_today_rounded, size: 16, color: p.brandSoft),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(label, style: context.texts.bodyMedium)),
          if (trailing != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 3),
              decoration: BoxDecoration(
                color: p.brandSurface,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                trailing!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: p.brandSoft,
                ),
              ),
            ),
          const SizedBox(width: AppSpacing.sm),
          Icon(Icons.chevron_right_rounded, size: 18, color: p.textMuted),
        ],
      ),
    );
  }
}

