import 'package:flutter/material.dart';

/// Who this number reaches. Drives the icon and the ordering - in an
/// emergency the list must not be alphabetical.
enum ContactKind { hospital, doctor, midwife, person, ambulance }

ContactKind contactKindFromString(String? value) => ContactKind.values.firstWhere(
      (k) => k.name == value,
      orElse: () => ContactKind.person,
    );

String contactKindLabel(ContactKind kind) => switch (kind) {
      ContactKind.hospital => 'Hospital',
      ContactKind.doctor => 'Doctor',
      ContactKind.midwife => 'Midwife',
      ContactKind.person => 'Person',
      ContactKind.ambulance => 'Ambulance',
    };

IconData contactKindIcon(ContactKind kind) => switch (kind) {
      ContactKind.hospital => Icons.local_hospital_rounded,
      ContactKind.doctor => Icons.medical_services_rounded,
      ContactKind.midwife => Icons.pregnant_woman_rounded,
      ContactKind.person => Icons.person_rounded,
      ContactKind.ambulance => Icons.emergency_rounded,
    };

/// Sort weight. Hospital and ambulance first, the people who know you next.
/// Nobody scrolls carefully while panicking.
int contactKindPriority(ContactKind kind) => switch (kind) {
      ContactKind.ambulance => 0,
      ContactKind.hospital => 1,
      ContactKind.midwife => 2,
      ContactKind.doctor => 3,
      ContactKind.person => 4,
    };

class EmergencyContact {
  const EmergencyContact({
    required this.id,
    required this.kind,
    required this.name,
    required this.phone,
    this.relationship = '',
    this.notes = '',
  });

  final String id;
  final ContactKind kind;
  final String name;

  /// Kept as typed. Phone numbers are not a format to normalise - extensions,
  /// country codes and local prefixes all matter, and rewriting them is how
  /// you end up dialling the wrong thing.
  final String phone;

  /// "Husband", "My mum", "Ward 4". Optional.
  final String relationship;

  final String notes;

  String get subtitle {
    final parts = [
      if (relationship.isNotEmpty) relationship else contactKindLabel(kind),
      phone,
    ];
    return parts.join('  ·  ');
  }

  EmergencyContact copyWith({
    ContactKind? kind,
    String? name,
    String? phone,
    String? relationship,
    String? notes,
  }) =>
      EmergencyContact(
        id: id,
        kind: kind ?? this.kind,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        relationship: relationship ?? this.relationship,
        notes: notes ?? this.notes,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'name': name,
        'phone': phone,
        'relationship': relationship,
        'notes': notes,
      };

  factory EmergencyContact.fromJson(Map<String, dynamic> json) => EmergencyContact(
        id: json['id'] as String,
        kind: contactKindFromString(json['kind'] as String?),
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        relationship: json['relationship'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
      );
}

/// The national emergency number, by the same regions the shopping list uses.
///
/// Worth having built in: it is the one number nobody should have to add
/// themselves, and the one most likely to be wrong if guessed from a film.
String emergencyNumberFor(String regionCode) => switch (regionCode) {
      'IN' => '112',
      'US' => '911',
      'GB' => '999',
      'AE' => '999',
      'AU' => '000',
      'SG' => '995',
      _ => '112',
    };

/// Signs that mean stop reading and call someone, now.
///
/// Taken from standard ACOG/NHS "seek urgent care" lists. Deliberately short:
/// a page of twenty symptoms gets skimmed, and these are the ones where hours
/// matter. Split by stage because the answers genuinely differ.
class WarningSign {
  const WarningSign({required this.sign, required this.why});

  final String sign;
  final String why;
}

const kPregnancyWarningSigns = <WarningSign>[
  WarningSign(
    sign: 'Bleeding from the vagina',
    why: 'Any amount, at any stage, needs to be assessed the same day.',
  ),
  WarningSign(
    sign: 'Baby moving less than usual',
    why: 'Never wait until morning, and never try to "wake" the baby with cold drinks first.',
  ),
  WarningSign(
    sign: 'A bad headache with blurred vision or spots',
    why: 'Together with swelling, these can mean pre-eclampsia.',
  ),
  WarningSign(
    sign: 'Sudden swelling of the face, hands, or feet',
    why: 'Gradual ankle swelling is normal. Sudden or facial swelling is not.',
  ),
  WarningSign(
    sign: 'Fluid leaking before 37 weeks',
    why: 'Waters breaking early needs care straight away, even without contractions.',
  ),
  WarningSign(
    sign: 'Severe or constant tummy pain',
    why: 'Different from the stretching aches - this is pain that does not ease.',
  ),
  WarningSign(
    sign: 'Fever over 38C, or chills',
    why: 'Infection in pregnancy is treated urgently.',
  ),
];

const kBabyWarningSigns = <WarningSign>[
  WarningSign(
    sign: 'Fever in a baby under 3 months',
    why: 'A temperature of 38C or above is an emergency at this age. Do not wait.',
  ),
  WarningSign(
    sign: 'Trouble breathing, or grunting with each breath',
    why: 'Also ribs pulling in, or a pause in breathing.',
  ),
  WarningSign(
    sign: 'Far fewer wet nappies than usual',
    why: 'Under six wet nappies a day in a newborn can mean dehydration.',
  ),
  WarningSign(
    sign: 'Refusing feeds, or very hard to wake',
    why: 'A baby who will not feed at all needs to be seen.',
  ),
  WarningSign(
    sign: 'A rash that does not fade when pressed',
    why: 'Press a glass against it. If it stays visible, call emergency services.',
  ),
  WarningSign(
    sign: 'Choking, or blue around the lips',
    why: 'Call emergency services immediately.',
  ),
];
