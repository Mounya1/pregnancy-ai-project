class MealItem {
  final String name;
  final String description;
  final String whyGood;

  MealItem({required this.name, required this.description, required this.whyGood});

  factory MealItem.fromJson(Map<String, dynamic> json) => MealItem(
        name: json['name'] as String,
        description: json['description'] as String,
        whyGood: json['why_good'] as String,
      );

  Map<String, dynamic> toJson() => {'name': name, 'description': description, 'why_good': whyGood};
}

class DayPlan {
  final String dayLabel;
  final MealItem breakfast;
  final MealItem lunch;
  final MealItem dinner;
  final MealItem snack;

  DayPlan({
    required this.dayLabel,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.snack,
  });

  factory DayPlan.fromJson(Map<String, dynamic> json) => DayPlan(
        dayLabel: json['day_label'] as String,
        breakfast: MealItem.fromJson(json['breakfast']),
        lunch: MealItem.fromJson(json['lunch']),
        dinner: MealItem.fromJson(json['dinner']),
        snack: MealItem.fromJson(json['snack']),
      );

  Map<String, dynamic> toJson() => {
        'day_label': dayLabel,
        'breakfast': breakfast.toJson(),
        'lunch': lunch.toJson(),
        'dinner': dinner.toJson(),
        'snack': snack.toJson(),
      };
}

class MealPlan {
  final String summary;
  final List<DayPlan> days;
  final String disclaimer;
  final DateTime generatedAt;

  MealPlan({
    required this.summary,
    required this.days,
    this.disclaimer = 'This is not medical advice. Consult your doctor or a registered dietitian.',
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  factory MealPlan.fromJson(Map<String, dynamic> json) => MealPlan(
        summary: json['summary'] as String,
        days: (json['days'] as List).map((d) => DayPlan.fromJson(d)).toList(),
        disclaimer: json['disclaimer'] as String? ??
            'This is not medical advice. Consult your doctor or a registered dietitian.',
        generatedAt: json['generated_at'] != null ? DateTime.tryParse(json['generated_at']) : null,
      );

  Map<String, dynamic> toJson() => {
        'summary': summary,
        'days': days.map((d) => d.toJson()).toList(),
        'disclaimer': disclaimer,
        'generated_at': generatedAt.toIso8601String(),
      };
}
