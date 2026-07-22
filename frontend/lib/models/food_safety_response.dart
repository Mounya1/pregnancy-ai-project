enum SafetyVerdict { safe, limit, avoid, unknown }

SafetyVerdict verdictFromString(String value) {
  switch (value) {
    case 'Safe':
      return SafetyVerdict.safe;
    case 'Limit':
      return SafetyVerdict.limit;
    case 'Avoid':
      return SafetyVerdict.avoid;
    default:
      return SafetyVerdict.unknown;
  }
}

String verdictLabel(SafetyVerdict v) {
  switch (v) {
    case SafetyVerdict.safe:
      return 'Safe';
    case SafetyVerdict.limit:
      return 'Limit';
    case SafetyVerdict.avoid:
      return 'Avoid';
    case SafetyVerdict.unknown:
      return 'Ask your doctor';
  }
}

enum Target { mother, baby }

Target targetFromString(String value) => value == 'baby' ? Target.baby : Target.mother;

/// Mirrors app/schemas.py: FoodSafetyResponse
class FoodSafetyResponse {
  final String foodName;
  final Target target;
  final SafetyVerdict verdict;
  final String explanation;
  final List<String> benefits;
  final List<String> risks;
  final String? recommendedServing;
  final List<String> betterAlternatives;
  final List<String> sources;
  final bool isHighRiskOverride;
  final String disclaimer;

  FoodSafetyResponse({
    required this.foodName,
    required this.target,
    required this.verdict,
    required this.explanation,
    this.benefits = const [],
    this.risks = const [],
    this.recommendedServing,
    this.betterAlternatives = const [],
    this.sources = const [],
    this.isHighRiskOverride = false,
    this.disclaimer = 'This is not medical advice. Consult your doctor or pediatrician.',
  });

  factory FoodSafetyResponse.fromJson(Map<String, dynamic> json) {
    return FoodSafetyResponse(
      foodName: json['food_name'] as String,
      target: targetFromString(json['target'] as String? ?? 'mother'),
      verdict: verdictFromString(json['verdict'] as String),
      explanation: json['explanation'] as String,
      benefits: List<String>.from(json['benefits'] ?? const []),
      risks: List<String>.from(json['risks'] ?? const []),
      recommendedServing: json['recommended_serving'] as String?,
      betterAlternatives: List<String>.from(json['better_alternatives'] ?? const []),
      sources: List<String>.from(json['sources'] ?? const []),
      isHighRiskOverride: json['is_high_risk_override'] as bool? ?? false,
      disclaimer: json['disclaimer'] as String? ??
          'This is not medical advice. Consult your doctor or pediatrician.',
    );
  }
}

/// Mirrors app/schemas.py: ChatResponse
class ChatResponse {
  final String replyText;
  final FoodSafetyResponse structured;
  final FoodSafetyResponse? babyStructured;
  final List<String> suggestedFollowups;

  ChatResponse({
    required this.replyText,
    required this.structured,
    this.babyStructured,
    this.suggestedFollowups = const [],
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      replyText: json['reply_text'] as String,
      structured: FoodSafetyResponse.fromJson(json['structured']),
      babyStructured: json['baby_structured'] != null
          ? FoodSafetyResponse.fromJson(json['baby_structured'])
          : null,
      suggestedFollowups: List<String>.from(json['suggested_followups'] ?? const []),
    );
  }
}

/// Mirrors app/schemas.py: FoodAnalysisResponse
class FoodAnalysisResponse {
  final String detectedFood;
  final List<String> detectedIngredients;
  final FoodSafetyResponse structured;
  final FoodSafetyResponse? babyStructured;

  FoodAnalysisResponse({
    required this.detectedFood,
    this.detectedIngredients = const [],
    required this.structured,
    this.babyStructured,
  });

  factory FoodAnalysisResponse.fromJson(Map<String, dynamic> json) {
    return FoodAnalysisResponse(
      detectedFood: json['detected_food'] as String,
      detectedIngredients: List<String>.from(json['detected_ingredients'] ?? const []),
      structured: FoodSafetyResponse.fromJson(json['structured']),
      babyStructured: json['baby_structured'] != null
          ? FoodSafetyResponse.fromJson(json['baby_structured'])
          : null,
    );
  }
}
