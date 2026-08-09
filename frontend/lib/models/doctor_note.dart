import 'package:flutter/material.dart';

/// Who the note is about. The app answers for two people, and mixing their
/// records up is the one thing a health note must never do.
enum NoteSubject { mother, baby }

NoteSubject noteSubjectFromString(String? value) =>
    value == 'baby' ? NoteSubject.baby : NoteSubject.mother;

String noteSubjectLabel(NoteSubject s) => s == NoteSubject.baby ? 'Baby' : 'Me';

IconData noteSubjectIcon(NoteSubject s) =>
    s == NoteSubject.baby ? Icons.child_care_rounded : Icons.pregnant_woman_rounded;

/// Something a clinician actually said, written down while it was fresh.
///
/// This is the record the rest of the app defers to. When a screen gives
/// feeding or growth guidance it points here, because a general guideline
/// should never outrank what your own doctor told you about your own baby.
class DoctorNote {
  const DoctorNote({
    required this.id,
    required this.subject,
    required this.title,
    required this.body,
    required this.visitedAt,
    this.clinician = '',
    this.nextAppointment,
  });

  final String id;
  final NoteSubject subject;

  /// What the visit was about, e.g. "20 week scan".
  final String title;

  /// What was said. Free text on purpose - a form with fields would lose the
  /// half-sentence that turns out to matter.
  final String body;

  final DateTime visitedAt;

  /// Who said it. Useful when three people have given three answers.
  final String clinician;

  final DateTime? nextAppointment;

  bool get hasUpcoming =>
      nextAppointment != null && nextAppointment!.isAfter(DateTime.now());

  DoctorNote copyWith({
    NoteSubject? subject,
    String? title,
    String? body,
    DateTime? visitedAt,
    String? clinician,
    DateTime? nextAppointment,
    bool clearNextAppointment = false,
  }) =>
      DoctorNote(
        id: id,
        subject: subject ?? this.subject,
        title: title ?? this.title,
        body: body ?? this.body,
        visitedAt: visitedAt ?? this.visitedAt,
        clinician: clinician ?? this.clinician,
        nextAppointment:
            clearNextAppointment ? null : (nextAppointment ?? this.nextAppointment),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'subject': subject.name,
        'title': title,
        'body': body,
        'visited_at': visitedAt.toIso8601String(),
        'clinician': clinician,
        'next_appointment': nextAppointment?.toIso8601String(),
      };

  factory DoctorNote.fromJson(Map<String, dynamic> json) => DoctorNote(
        id: json['id'] as String,
        subject: noteSubjectFromString(json['subject'] as String?),
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        visitedAt:
            DateTime.tryParse(json['visited_at'] as String? ?? '') ?? DateTime.now(),
        clinician: json['clinician'] as String? ?? '',
        nextAppointment: json['next_appointment'] == null
            ? null
            : DateTime.tryParse(json['next_appointment'] as String),
      );
}
