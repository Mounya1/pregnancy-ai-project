import 'food_safety_response.dart';

enum HistorySource { chat, voice, scan }

HistorySource _sourceFromString(String? v) {
  switch (v) {
    case 'voice':
      return HistorySource.voice;
    case 'scan':
      return HistorySource.scan;
    default:
      return HistorySource.chat;
  }
}

class HistoryEntry {
  final String id;
  final String query; // the question asked, or detected food name for scans
  final FoodSafetyResponse motherResult;
  final FoodSafetyResponse? babyResult;
  final HistorySource source;
  final DateTime timestamp;

  HistoryEntry({
    required this.id,
    required this.query,
    required this.motherResult,
    this.babyResult,
    required this.source,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'query': query,
        'mother_result': _resultToJson(motherResult),
        'baby_result': babyResult != null ? _resultToJson(babyResult!) : null,
        'source': source.name,
        'timestamp': timestamp.toIso8601String(),
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        id: json['id'] as String,
        query: json['query'] as String,
        motherResult: FoodSafetyResponse.fromJson(json['mother_result']),
        babyResult: json['baby_result'] != null ? FoodSafetyResponse.fromJson(json['baby_result']) : null,
        source: _sourceFromString(json['source'] as String?),
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      );
}

// FoodSafetyResponse doesn't have toJson itself (it's built via fromJson only
// on the way in from the API) - this mirrors its fields for local storage.
Map<String, dynamic> _resultToJson(FoodSafetyResponse r) => {
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
