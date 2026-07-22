enum LifeStage { pregnancy, breastfeeding, postpartum, general }

String lifeStageToApiString(LifeStage s) {
  switch (s) {
    case LifeStage.pregnancy:
      return 'pregnancy';
    case LifeStage.breastfeeding:
      return 'breastfeeding';
    case LifeStage.postpartum:
      return 'postpartum';
    case LifeStage.general:
      return 'general';
  }
}

/// Mirrors app/schemas.py: UserProfile. Kept in memory / local storage for
/// now; wire to a real user store once auth exists.
class UserProfile {
  LifeStage lifeStage;
  int? pregnancyWeek;
  int? babyAgeMonths;
  List<String> allergies;
  List<String> dietaryPreferences;

  UserProfile({
    this.lifeStage = LifeStage.general,
    this.pregnancyWeek,
    this.babyAgeMonths,
    this.allergies = const [],
    this.dietaryPreferences = const [],
  });

  Map<String, dynamic> toJson() => {
        'life_stage': lifeStageToApiString(lifeStage),
        'pregnancy_week': pregnancyWeek,
        'baby_age_months': babyAgeMonths,
        'allergies': allergies,
        'dietary_preferences': dietaryPreferences,
      };

  /// Short label for the home screen header, e.g. "20 weeks pregnant"
  /// or "Breastfeeding, baby 7 months".
  String get statusLabel {
    switch (lifeStage) {
      case LifeStage.pregnancy:
        return pregnancyWeek != null ? '$pregnancyWeek weeks pregnant' : 'Pregnancy';
      case LifeStage.breastfeeding:
        return babyAgeMonths != null
            ? 'Breastfeeding, baby $babyAgeMonths months'
            : 'Breastfeeding';
      case LifeStage.postpartum:
        return 'Postpartum';
      case LifeStage.general:
        return 'General nutrition';
    }
  }
}
