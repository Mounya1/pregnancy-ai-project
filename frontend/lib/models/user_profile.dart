enum LifeStage { pregnancy, breastfeeding, postpartum, general }

/// Optional. Drives the app's colour after the birth, so "not said" has to be
/// a real state rather than defaulting to one of the two.
enum BabyGender { girl, boy, unspecified }

BabyGender babyGenderFromString(String? value) {
  switch (value) {
    case 'girl':
      return BabyGender.girl;
    case 'boy':
      return BabyGender.boy;
    default:
      return BabyGender.unspecified;
  }
}

String babyGenderLabel(BabyGender g) {
  switch (g) {
    case BabyGender.girl:
      return 'Girl';
    case BabyGender.boy:
      return 'Boy';
    case BabyGender.unspecified:
      return 'Prefer not to say';
  }
}

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

LifeStage lifeStageFromString(String? value) {
  switch (value) {
    case 'pregnancy':
      return LifeStage.pregnancy;
    case 'breastfeeding':
      return LifeStage.breastfeeding;
    case 'postpartum':
      return LifeStage.postpartum;
    default:
      return LifeStage.general;
  }
}

String lifeStageLabel(LifeStage s) {
  switch (s) {
    case LifeStage.pregnancy:
      return 'Pregnant';
    case LifeStage.breastfeeding:
      return 'Breastfeeding';
    case LifeStage.postpartum:
      return 'Postpartum';
    case LifeStage.general:
      return 'General';
  }
}

/// Mirrors app/schemas.py: UserProfile, plus dueDate/babyBirthDate so the
/// user sets a date once (in the Profile screen) instead of updating a
/// week/month number manually - mirrors the backend's date_helpers.py logic.
class UserProfile {
  LifeStage lifeStage;
  DateTime? dueDate;
  DateTime? babyBirthDate;
  List<String> allergies;
  List<String> dietaryPreferences;

  /// Cuisines the meal planner should cook in, e.g. Indian, Chinese.
  /// Empty means no preference - the planner stays international.
  List<String> cuisines;

  /// Conditions the diet has to account for, e.g. gestational diabetes.
  /// Filled in from an uploaded medical report, or edited by hand.
  List<String> healthConditions;

  /// Baby's gender, once known. Only used for the app's colour after birth.
  BabyGender babyGender;

  UserProfile({
    this.lifeStage = LifeStage.general,
    this.dueDate,
    this.babyBirthDate,
    this.allergies = const [],
    this.dietaryPreferences = const [],
    this.cuisines = const [],
    this.healthConditions = const [],
    this.babyGender = BabyGender.unspecified,
  });

  /// Standard pregnancy is ~40 weeks; count backward from the due date.
  int? get pregnancyWeek {
    if (dueDate == null) return null;
    final daysRemaining = dueDate!.difference(DateTime.now()).inDays;
    final weeksRemaining = daysRemaining ~/ 7;
    final week = 40 - weeksRemaining;
    return week.clamp(1, 42);
  }

  int? get babyAgeMonths {
    if (babyBirthDate == null) return null;
    final now = DateTime.now();
    var months = (now.year - babyBirthDate!.year) * 12 + (now.month - babyBirthDate!.month);
    if (now.day < babyBirthDate!.day) months -= 1;
    return months < 0 ? 0 : months;
  }

  Map<String, dynamic> toApiJson() => {
        'life_stage': lifeStageToApiString(lifeStage),
        'pregnancy_week': pregnancyWeek,
        'baby_age_months': babyAgeMonths,
        'allergies': allergies,
        'dietary_preferences': dietaryPreferences,
        'cuisines': cuisines,
        'health_conditions': healthConditions,
      };

  Map<String, dynamic> toStorageJson() => {
        'life_stage': lifeStageToApiString(lifeStage),
        'due_date': dueDate?.toIso8601String(),
        'baby_birth_date': babyBirthDate?.toIso8601String(),
        'allergies': allergies,
        'dietary_preferences': dietaryPreferences,
        'cuisines': cuisines,
        'health_conditions': healthConditions,
        'baby_gender': babyGender.name,
      };

  factory UserProfile.fromStorageJson(Map<String, dynamic> json) {
    return UserProfile(
      lifeStage: lifeStageFromString(json['life_stage'] as String?),
      dueDate: json['due_date'] != null ? DateTime.tryParse(json['due_date'] as String) : null,
      babyBirthDate:
          json['baby_birth_date'] != null ? DateTime.tryParse(json['baby_birth_date'] as String) : null,
      allergies: List<String>.from(json['allergies'] ?? const []),
      dietaryPreferences: List<String>.from(json['dietary_preferences'] ?? const []),
      cuisines: List<String>.from(json['cuisines'] ?? const []),
      healthConditions: List<String>.from(json['health_conditions'] ?? const []),
      babyGender: babyGenderFromString(json['baby_gender'] as String?),
    );
  }

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

  UserProfile copyWith({
    LifeStage? lifeStage,
    DateTime? dueDate,
    DateTime? babyBirthDate,
    List<String>? allergies,
    List<String>? dietaryPreferences,
    List<String>? cuisines,
    List<String>? healthConditions,
    BabyGender? babyGender,
  }) {
    return UserProfile(
      lifeStage: lifeStage ?? this.lifeStage,
      dueDate: dueDate ?? this.dueDate,
      babyBirthDate: babyBirthDate ?? this.babyBirthDate,
      allergies: allergies ?? this.allergies,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      cuisines: cuisines ?? this.cuisines,
      healthConditions: healthConditions ?? this.healthConditions,
      babyGender: babyGender ?? this.babyGender,
    );
  }
}
