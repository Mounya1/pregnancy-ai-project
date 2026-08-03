import 'food_safety_response.dart';

class SavedFood {
  final String id;
  final String foodName;
  final FoodSafetyResponse motherResult;
  final FoodSafetyResponse? babyResult;
  final DateTime savedAt;

  SavedFood({
    required this.id,
    required this.foodName,
    required this.motherResult,
    this.babyResult,
    DateTime? savedAt,
  }) : savedAt = savedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'food_name': foodName,
        'mother_result': resultToJson(motherResult),
        'baby_result': babyResult != null ? resultToJson(babyResult!) : null,
        'saved_at': savedAt.toIso8601String(),
      };

  factory SavedFood.fromJson(Map<String, dynamic> json) => SavedFood(
        id: json['id'] as String,
        foodName: json['food_name'] as String,
        motherResult: FoodSafetyResponse.fromJson(json['mother_result']),
        babyResult: json['baby_result'] != null ? FoodSafetyResponse.fromJson(json['baby_result']) : null,
        savedAt: DateTime.tryParse(json['saved_at'] as String? ?? '') ?? DateTime.now(),
      );
}

// Reuses the same field-mirroring helper as HistoryEntry, exposed publicly
// here since both models need it for local storage serialization.
Map<String, dynamic> resultToJson(FoodSafetyResponse r) => {
      'food_name': r.foodName,
      'target': r.target == Target.baby ? 'baby' : 'mother',
      'verdict': verdictLabel(r.verdict) == 'Ask your doctor' ? 'Unknown' : verdictLabel(r.verdict),
      'explanation': r.explanation,
      'benefits': r.benefits,
      'risks': r.risks,
      'recommended_serving': r.recommendedServing,
      'better_alternatives': r.betterAlternatives,
      'sources': r.sources,
      'is_high_risk_override': r.isHighRiskOverride,
      'disclaimer': r.disclaimer,
    };
