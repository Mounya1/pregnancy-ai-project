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

  /// True when there is anything worth showing. A food that contributes none
  /// of the five tracked nutrients should say so rather than render five
  /// zeroes as if that were a result.
  bool get isEmpty =>
      ironMg == 0 && calciumMg == 0 && folateMcg == 0 && proteinG == 0 && vitaminDMcg == 0;

  Map<String, dynamic> toJson() => {
        'iron_mg': ironMg,
        'calcium_mg': calciumMg,
        'folate_mcg': folateMcg,
        'protein_g': proteinG,
        'vitamin_d_mcg': vitaminDMcg,
      };

  factory NutrientProfile.fromJson(Map<String, dynamic> json) => NutrientProfile(
        ironMg: (json['iron_mg'] as num?)?.toDouble() ?? 0,
        calciumMg: (json['calcium_mg'] as num?)?.toDouble() ?? 0,
        folateMcg: (json['folate_mcg'] as num?)?.toDouble() ?? 0,
        proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0,
        vitaminDMcg: (json['vitamin_d_mcg'] as num?)?.toDouble() ?? 0,
      );
}

/// A per-serving estimate for a food that is not in [kNutrientDatabase] -
/// typed by hand or read off a photo.
///
/// Mirrors app/schemas.py: NutrientEstimate. [isEstimate] is carried all the
/// way to the UI so a guess is never displayed as a measurement.
class NutrientEstimate {
  const NutrientEstimate({
    required this.foodName,
    required this.perServing,
    this.servingDescription = '1 serving',
    this.note = '',
    this.isEstimate = true,
    this.recognised = true,
  });

  final String foodName;
  final NutrientProfile perServing;
  final String servingDescription;
  final String note;
  final bool isEstimate;

  /// False when the text was not a food at all, so the UI can say that
  /// instead of logging a row of zeroes.
  final bool recognised;

  factory NutrientEstimate.fromJson(Map<String, dynamic> json) => NutrientEstimate(
        foodName: json['food_name'] as String? ?? '',
        perServing: NutrientProfile.fromJson(json),
        servingDescription: json['serving_description'] as String? ?? '1 serving',
        note: json['note'] as String? ?? '',
        isEstimate: json['is_estimate'] as bool? ?? true,
        recognised: json['recognised'] as bool? ?? true,
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

/// How the entry got into the log. Only used for wording and an icon, but
/// the difference matters: a value looked up in the built-in table is exact,
/// and one estimated from a name or a photo is not.
enum NutritionSource { picked, typed, scanned }

NutritionSource nutritionSourceFromString(String? value) =>
    NutritionSource.values.firstWhere(
      (s) => s.name == value,
      orElse: () => NutritionSource.picked,
    );

class NutritionEntry {
  final String id;
  final String foodName;
  final int servings;
  final DateTime loggedAt;

  /// Nutrients for ONE serving, carried on the entry itself.
  ///
  /// Null for foods that came from [kNutrientDatabase], which stays the
  /// source of truth for those. Anything typed or scanned has no table entry
  /// to look up later, so its numbers have to live here or they are lost.
  final NutrientProfile? perServing;

  /// What one serving means for this food, e.g. "1 cup cooked (180g)". Null
  /// for built-in foods, whose names already carry the serving.
  final String? servingDescription;

  final NutritionSource source;

  NutritionEntry({
    required this.id,
    required this.foodName,
    required this.servings,
    DateTime? loggedAt,
    this.perServing,
    this.servingDescription,
    this.source = NutritionSource.picked,
  }) : loggedAt = loggedAt ?? DateTime.now();

  NutrientProfile get nutrients =>
      (perServing ?? kNutrientDatabase[foodName] ?? const NutrientProfile()) * servings;

  /// False when nothing is known about this food - it still belongs in the
  /// log as a record of what was eaten, but it must not silently count as
  /// zero towards the day's targets without saying so.
  bool get hasNutrients =>
      perServing != null || kNutrientDatabase.containsKey(foodName);

  /// Estimated values are never presented as measured ones.
  bool get isEstimated => source != NutritionSource.picked;

  Map<String, dynamic> toJson() => {
        'id': id,
        'food_name': foodName,
        'servings': servings,
        'logged_at': loggedAt.toIso8601String(),
        if (perServing != null) 'per_serving': perServing!.toJson(),
        if (servingDescription != null) 'serving_description': servingDescription,
        'source': source.name,
      };

  factory NutritionEntry.fromJson(Map<String, dynamic> json) => NutritionEntry(
        id: json['id'] as String,
        foodName: json['food_name'] as String,
        servings: json['servings'] as int,
        loggedAt: DateTime.tryParse(json['logged_at'] as String? ?? '') ?? DateTime.now(),
        // Absent on entries written before foods could be typed or scanned;
        // those all came from the built-in table, so the lookup still works.
        perServing: json['per_serving'] == null
            ? null
            : NutrientProfile.fromJson(json['per_serving'] as Map<String, dynamic>),
        servingDescription: json['serving_description'] as String?,
        source: nutritionSourceFromString(json['source'] as String?),
      );

  bool isSameDay(DateTime day) =>
      loggedAt.year == day.year && loggedAt.month == day.month && loggedAt.day == day.day;
}
