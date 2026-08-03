enum ExerciseIntensity { gentle, moderate, rest }

ExerciseIntensity intensityFromString(String? value) {
  switch (value?.toLowerCase()) {
    case 'moderate':
      return ExerciseIntensity.moderate;
    case 'rest':
      return ExerciseIntensity.rest;
    default:
      return ExerciseIntensity.gentle;
  }
}

String intensityLabel(ExerciseIntensity i) {
  switch (i) {
    case ExerciseIntensity.gentle:
      return 'Gentle';
    case ExerciseIntensity.moderate:
      return 'Moderate';
    case ExerciseIntensity.rest:
      return 'Rest';
  }
}

class ExerciseItem {
  const ExerciseItem({
    required this.name,
    required this.duration,
    required this.intensity,
    required this.howTo,
    required this.whyGood,
  });

  final String name;
  final String duration;
  final ExerciseIntensity intensity;
  final String howTo;
  final String whyGood;

  factory ExerciseItem.fromJson(Map<String, dynamic> json) => ExerciseItem(
        name: json['name'] as String? ?? '',
        duration: json['duration'] as String? ?? '',
        intensity: intensityFromString(json['intensity'] as String?),
        howTo: json['how_to'] as String? ?? '',
        whyGood: json['why_good'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'duration': duration,
        'intensity': intensity.name,
        'how_to': howTo,
        'why_good': whyGood,
      };
}

class FitnessDay {
  const FitnessDay({required this.dayLabel, required this.focus, required this.items});

  final String dayLabel;
  final String focus;
  final List<ExerciseItem> items;

  factory FitnessDay.fromJson(Map<String, dynamic> json) => FitnessDay(
        dayLabel: json['day_label'] as String? ?? '',
        focus: json['focus'] as String? ?? '',
        items: (json['items'] as List? ?? const [])
            .map((i) => ExerciseItem.fromJson(i as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'day_label': dayLabel,
        'focus': focus,
        'items': items.map((i) => i.toJson()).toList(),
      };
}

class FitnessPlan {
  FitnessPlan({
    required this.summary,
    required this.days,
    this.warningSigns = const [],
    this.disclaimer = '',
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  final String summary;
  final List<FitnessDay> days;

  /// Symptoms that mean stop exercising and contact a clinician. The backend
  /// guarantees these are populated, so the UI can always show them.
  final List<String> warningSigns;
  final String disclaimer;
  final DateTime generatedAt;

  factory FitnessPlan.fromJson(Map<String, dynamic> json) => FitnessPlan(
        summary: json['summary'] as String? ?? '',
        days: (json['days'] as List? ?? const [])
            .map((d) => FitnessDay.fromJson(d as Map<String, dynamic>))
            .toList(),
        warningSigns: List<String>.from(json['warning_signs'] ?? const []),
        disclaimer: json['disclaimer'] as String? ?? '',
        generatedAt: DateTime.tryParse(json['generated_at'] as String? ?? ''),
      );

  Map<String, dynamic> toJson() => {
        'summary': summary,
        'days': days.map((d) => d.toJson()).toList(),
        'warning_signs': warningSigns,
        'disclaimer': disclaimer,
        'generated_at': generatedAt.toIso8601String(),
      };
}
