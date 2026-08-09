import 'package:flutter/foundation.dart';

import '../models/care_plan.dart';
import '../models/doctor_note.dart';
import 'local_storage_service.dart';

/// The care plan: what is ticked off, and what the doctor actually said.
///
/// The two live together because they answer to each other - a task like
/// "ask about Group B Strep" is only really done once there is a note saying
/// what the answer was.
class CareController extends ChangeNotifier {
  CareController(this._storage);

  final LocalStorageService _storage;

  Set<String> _done = <String>{};
  List<DoctorNote> _notes = [];
  bool _loaded = false;

  bool get isLoaded => _loaded;

  bool isDone(String taskId) => _done.contains(taskId);

  /// Newest visit first - the last thing you were told is the thing you are
  /// most likely looking for.
  List<DoctorNote> get notes {
    final sorted = [..._notes]..sort((a, b) => b.visitedAt.compareTo(a.visitedAt));
    return List.unmodifiable(sorted);
  }

  List<DoctorNote> notesFor(NoteSubject subject) =>
      notes.where((n) => n.subject == subject).toList();

  /// True once there is at least one note about the baby.
  ///
  /// Baby guidance in this app is never shown on its own: it is always paired
  /// either with what your own paediatrician said, or with a prompt to go and
  /// ask them. This flag is what tells those screens which of the two to show.
  bool get hasBabyNotes => _notes.any((n) => n.subject == NoteSubject.baby);

  bool get hasMotherNotes => _notes.any((n) => n.subject == NoteSubject.mother);

  /// The soonest appointment still in the future, across both subjects.
  DoctorNote? get nextAppointment {
    final upcoming = _notes.where((n) => n.hasUpcoming).toList()
      ..sort((a, b) => a.nextAppointment!.compareTo(b.nextAppointment!));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  int doneCountIn(List<CareSection> sections) =>
      sections.expand((s) => s.tasks).where((t) => _done.contains(t.id)).length;

  Future<void> load() async {
    _done = (await _storage.loadCareDone()).toSet();
    _notes = await _storage.loadDoctorNotes();
    _loaded = true;
    notifyListeners();
  }

  Future<void> toggleTask(String taskId) async {
    if (!_done.remove(taskId)) _done.add(taskId);
    notifyListeners();
    await _storage.saveCareDone(_done.toList());
  }

  Future<void> saveNote(DoctorNote note) async {
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index >= 0) {
      _notes[index] = note;
    } else {
      _notes.add(note);
    }
    notifyListeners();
    await _storage.saveDoctorNotes(_notes);
  }

  Future<void> removeNote(DoctorNote note) async {
    _notes.removeWhere((n) => n.id == note.id);
    notifyListeners();
    await _storage.saveDoctorNotes(_notes);
  }
}
