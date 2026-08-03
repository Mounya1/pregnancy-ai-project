/// A weight (and optional length) measurement for the baby on a given day.
class BabyRecord {
  BabyRecord({
    required this.id,
    required this.weightKg,
    this.lengthCm,
    this.note = '',
    DateTime? recordedAt,
  }) : recordedAt = recordedAt ?? DateTime.now();

  final String id;
  final double weightKg;
  final double? lengthCm;
  final String note;
  final DateTime recordedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'weight_kg': weightKg,
        'length_cm': lengthCm,
        'note': note,
        'recorded_at': recordedAt.toIso8601String(),
      };

  factory BabyRecord.fromJson(Map<String, dynamic> json) => BabyRecord(
        id: json['id'] as String,
        weightKg: (json['weight_kg'] as num).toDouble(),
        lengthCm: (json['length_cm'] as num?)?.toDouble(),
        note: json['note'] as String? ?? '',
        recordedAt: DateTime.tryParse(json['recorded_at'] as String? ?? '') ?? DateTime.now(),
      );
}

/// Approximate healthy weight range (kg) by age in months, blending the WHO
/// growth-standard bands for boys and girls.
///
/// Deliberately wide and advisory only: this app does not know the baby's sex
/// or birth weight, so it can flag "worth mentioning to your paediatrician"
/// but must never be read as a percentile or a diagnosis.
const _weightBands = <int, (double, double)>{
  0: (2.5, 4.4),
  1: (3.4, 5.8),
  2: (4.3, 7.1),
  3: (5.0, 8.0),
  4: (5.6, 8.7),
  5: (6.0, 9.3),
  6: (6.4, 9.8),
  7: (6.7, 10.3),
  8: (6.9, 10.7),
  9: (7.1, 11.0),
  10: (7.4, 11.4),
  11: (7.6, 11.7),
  12: (7.7, 12.0),
  15: (8.3, 12.8),
  18: (8.8, 13.7),
  21: (9.2, 14.5),
  24: (9.7, 15.3),
  30: (10.5, 16.9),
  36: (11.3, 18.3),
};

/// Nearest published band at or below [months], so in-between ages still get
/// a sensible reference rather than nothing.
(double, double)? weightRangeForMonths(int months) {
  if (months < 0) return null;
  final keys = _weightBands.keys.toList()..sort();
  int? best;
  for (final k in keys) {
    if (k <= months) best = k;
  }
  best ??= keys.first;
  return _weightBands[best];
}

enum WeightRead { below, within, above, unknown }

WeightRead readWeight(double weightKg, int? ageMonths) {
  if (ageMonths == null) return WeightRead.unknown;
  final range = weightRangeForMonths(ageMonths);
  if (range == null) return WeightRead.unknown;
  if (weightKg < range.$1) return WeightRead.below;
  if (weightKg > range.$2) return WeightRead.above;
  return WeightRead.within;
}

String weightReadLabel(WeightRead read) {
  switch (read) {
    case WeightRead.below:
      return 'Below typical range';
    case WeightRead.within:
      return 'In typical range';
    case WeightRead.above:
      return 'Above typical range';
    case WeightRead.unknown:
      return 'Set birth date for a range';
  }
}
