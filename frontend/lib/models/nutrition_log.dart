import 'user_profile.dart';

/// Nutrient amounts per typical serving, for a small set of common foods.
/// Values are approximate (rounded, from standard USDA-style references) -
/// good enough for a self-tracking tool, not a substitute for precise
/// nutrition labeling.
class NutrientProfile {
  final double ironMg;
  final double calciumMg;
  final double folateMcg;
  final double proteinG;
  final double vitaminDMcg;

  const NutrientProfile({
    this.ironMg = 0,
    this.calciumMg = 0,
    this.folateMcg = 0,
    this.proteinG = 0,
    this.vitaminDMcg = 0,
  });

  NutrientProfile operator *(int servings) => NutrientProfile(
        ironMg: ironMg * servings,
        calciumMg: calciumMg * servings,
        folateMcg: folateMcg * servings,
        proteinG: proteinG * servings,
        vitaminDMcg: vitaminDMcg * servings,
      );

  NutrientProfile operator +(NutrientProfile other) => NutrientProfile(
        ironMg: ironMg + other.ironMg,
        calciumMg: calciumMg + other.calciumMg,
        folateMcg: folateMcg + other.folateMcg,
        proteinG: proteinG + other.proteinG,
        vitaminDMcg: vitaminDMcg + other.vitaminDMcg,
      );
}

/// A small reference set of common foods. Extend freely - this isn't meant
/// to be exhaustive, just enough for a self-tracking demo to be genuinely
/// useful rather than requiring a full food database integration.
const Map<String, NutrientProfile> kNutrientDatabase = {
  'Spinach (1 cup cooked)': NutrientProfile(ironMg: 6.4, calciumMg: 245, folateMcg: 263, proteinG: 5.3),
  'Lentils (1 cup cooked)': NutrientProfile(ironMg: 6.6, folateMcg: 358, proteinG: 18),
  'Greek yogurt (1 cup)': NutrientProfile(calciumMg: 300, proteinG: 23, vitaminDMcg: 0.1),
  'Salmon, cooked (3 oz)': NutrientProfile(proteinG: 22, vitaminDMcg: 14.2, ironMg: 0.3),
  'Eggs (2 large)': NutrientProfile(proteinG: 12.6, vitaminDMcg: 1.9, folateMcg: 44),
  'Milk, fortified (1 cup)': NutrientProfile(calciumMg: 300, vitaminDMcg: 2.9, proteinG: 8),
  'Orange (1 medium)': NutrientProfile(folateMcg: 40, calciumMg: 52),
  'Chicken breast, cooked (3 oz)': NutrientProfile(proteinG: 26, ironMg: 0.4),
  'Fortified cereal (1 cup)': NutrientProfile(ironMg: 18, folateMcg: 400),
  'Broccoli (1 cup cooked)': NutrientProfile(calciumMg: 62, folateMcg: 168, ironMg: 1),
  'Almonds (1 oz, ~23)': NutrientProfile(calciumMg: 76, ironMg: 1.1, proteinG: 6),
  'Beef, lean, cooked (3 oz)': NutrientProfile(ironMg: 2.9, proteinG: 25, vitaminDMcg: 0.1),
  'Tofu (1/2 cup)': NutrientProfile(calciumMg: 253, ironMg: 3.4, proteinG: 10),
  'Black beans (1 cup cooked)': NutrientProfile(folateMcg: 256, ironMg: 3.6, proteinG: 15),
  'Avocado (1/2 medium)': NutrientProfile(folateMcg: 60, proteinG: 1.5),
};

/// Daily RDA-style targets by life stage. Pregnancy and breastfeeding values
/// are elevated versions of general adult female targets - approximate,
/// intended for self-tracking motivation, not clinical precision.
NutrientProfile targetsForLifeStage(LifeStage stage) {
  switch (stage) {
    case LifeStage.pregnancy:
      return const NutrientProfile(ironMg: 27, calciumMg: 1000, folateMcg: 600, proteinG: 71, vitaminDMcg: 15);
    case LifeStage.breastfeeding:
      return const NutrientProfile(ironMg: 9, calciumMg: 1000, folateMcg: 500, proteinG: 71, vitaminDMcg: 15);
    case LifeStage.postpartum:
    case LifeStage.general:
      return const NutrientProfile(ironMg: 18, calciumMg: 1000, folateMcg: 400, proteinG: 46, vitaminDMcg: 15);
  }
}

class NutritionEntry {
  final String id;
  final String foodName;
  final int servings;
  final DateTime loggedAt;

  NutritionEntry({
    required this.id,
    required this.foodName,
    required this.servings,
    DateTime? loggedAt,
  }) : loggedAt = loggedAt ?? DateTime.now();

  NutrientProfile get nutrients => (kNutrientDatabase[foodName] ?? const NutrientProfile()) * servings;

  Map<String, dynamic> toJson() => {
        'id': id,
        'food_name': foodName,
        'servings': servings,
        'logged_at': loggedAt.toIso8601String(),
      };

  factory NutritionEntry.fromJson(Map<String, dynamic> json) => NutritionEntry(
        id: json['id'] as String,
        foodName: json['food_name'] as String,
        servings: json['servings'] as int,
        loggedAt: DateTime.tryParse(json['logged_at'] as String? ?? '') ?? DateTime.now(),
      );

  bool isSameDay(DateTime day) =>
      loggedAt.year == day.year && loggedAt.month == day.month && loggedAt.day == day.day;
}
