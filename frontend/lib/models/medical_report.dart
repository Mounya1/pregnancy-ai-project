/// Where a single measured value sits against its reference range.
enum FindingStatus { low, normal, high, unknown }

FindingStatus findingStatusFromString(String? value) {
  switch (value) {
    case 'low':
      return FindingStatus.low;
    case 'high':
      return FindingStatus.high;
    case 'normal':
      return FindingStatus.normal;
    default:
      return FindingStatus.unknown;
  }
}

String findingStatusLabel(FindingStatus s) {
  switch (s) {
    case FindingStatus.low:
      return 'Low';
    case FindingStatus.high:
      return 'High';
    case FindingStatus.normal:
      return 'Normal';
    case FindingStatus.unknown:
      return 'Unclear';
  }
}

/// One line item pulled out of a lab report, e.g. "Haemoglobin 9.4 g/dL - low".
class ReportFinding {
  const ReportFinding({
    required this.label,
    required this.value,
    required this.status,
    this.note = '',
  });

  final String label;
  final String value;
  final FindingStatus status;
  final String note;

  Map<String, dynamic> toJson() => {
        'label': label,
        'value': value,
        'status': status.name,
        'note': note,
      };

  factory ReportFinding.fromJson(Map<String, dynamic> json) => ReportFinding(
        label: json['label'] as String? ?? '',
        value: json['value'] as String? ?? '',
        status: findingStatusFromString(json['status'] as String?),
        note: json['note'] as String? ?? '',
      );
}

/// The parsed result of uploading a lab report or doctor's summary. The
/// [conditions] list is what feeds back into the profile so meal plans and
/// chat answers adapt to it.
class MedicalReport {
  MedicalReport({
    required this.id,
    required this.title,
    required this.summary,
    this.conditions = const [],
    this.findings = const [],
    this.foodsToEmphasize = const [],
    this.foodsToLimit = const [],
    this.keyNutrients = const [],
    this.disclaimer = 'This is not a diagnosis. Always review results with your doctor.',
    DateTime? uploadedAt,
  }) : uploadedAt = uploadedAt ?? DateTime.now();

  final String id;
  final String title;
  final String summary;
  final List<String> conditions;
  final List<ReportFinding> findings;
  final List<String> foodsToEmphasize;
  final List<String> foodsToLimit;

  /// Nutrients the report suggests prioritising, e.g. "iron", "vitamin D".
  final List<String> keyNutrients;
  final String disclaimer;
  final DateTime uploadedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'summary': summary,
        'conditions': conditions,
        'findings': findings.map((f) => f.toJson()).toList(),
        'foods_to_emphasize': foodsToEmphasize,
        'foods_to_limit': foodsToLimit,
        'key_nutrients': keyNutrients,
        'disclaimer': disclaimer,
        'uploaded_at': uploadedAt.toIso8601String(),
      };

  factory MedicalReport.fromJson(Map<String, dynamic> json) => MedicalReport(
        id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
        title: json['title'] as String? ?? 'Medical report',
        summary: json['summary'] as String? ?? '',
        conditions: List<String>.from(json['conditions'] ?? const []),
        findings: (json['findings'] as List? ?? const [])
            .map((f) => ReportFinding.fromJson(f as Map<String, dynamic>))
            .toList(),
        foodsToEmphasize: List<String>.from(json['foods_to_emphasize'] ?? const []),
        foodsToLimit: List<String>.from(json['foods_to_limit'] ?? const []),
        keyNutrients: List<String>.from(json['key_nutrients'] ?? const []),
        disclaimer: json['disclaimer'] as String? ??
            'This is not a diagnosis. Always review results with your doctor.',
        uploadedAt: DateTime.tryParse(json['uploaded_at'] as String? ?? '') ?? DateTime.now(),
      );
}
