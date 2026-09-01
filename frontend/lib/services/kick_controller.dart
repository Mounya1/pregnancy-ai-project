import 'package:flutter/foundation.dart';

import '../models/kick_session.dart';
import 'local_storage_service.dart';

/// Owns the fetal movement count.
///
/// Lives above the screen so an open count survives leaving the tab, and is
/// written to storage on every tap so it also survives a page reload - on the
/// web that is one accidental refresh away, and losing a count halfway means
/// starting the two-hour clock again.
class KickController extends ChangeNotifier {
  KickController(this._storage);

  final LocalStorageService _storage;

  /// Older sessions are dropped rather than kept forever: the whole store is
  /// synced as a single document with a size ceiling, and a count from four
  /// months ago is not something anyone scrolls back to.
  static const historyLimit = 60;

  List<KickSession> _sessions = [];
  String? _activeId;
  bool _loaded = false;

  bool get isLoaded => _loaded;

  /// Newest first, which is the order they are shown in.
  List<KickSession> get sessions => List.unmodifiable(_sessions.reversed);

  KickSession? get active {
    final id = _activeId;
    if (id == null) return null;
    for (final session in _sessions) {
      if (session.id == id) return session;
    }
    return null;
  }

  bool get isCounting => active != null;

  List<KickSession> sessionsOn(DateTime day) =>
      sessions.where((s) => s.isSameDay(day)).toList();

  KickSession? get lastCompleted {
    for (final session in _sessions.reversed) {
      if (session.isComplete) return session;
    }
    return null;
  }

  Future<void> load() async {
    _sessions = await _storage.loadKickSessions();

    // Resume a count that was interrupted rather than silently discarding it.
    // Anything older than the two-hour window is stale - the session it
    // belonged to is over whether or not it reached ten.
    final last = _sessions.isEmpty ? null : _sessions.last;
    if (last != null &&
        !last.isComplete &&
        DateTime.now().difference(last.startedAt) < KickSession.window) {
      _activeId = last.id;
    }

    _loaded = true;
    notifyListeners();
  }

  Future<void> start() async {
    if (isCounting) return;

    final session = KickSession(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      startedAt: DateTime.now(),
      kicks: const [],
    );
    _activeId = session.id;
    _sessions = [..._sessions, session];
    _trim();
    notifyListeners();
    await _persist();
  }

  /// Records one movement. Stops the session automatically on the tenth.
  Future<void> recordKick() async {
    final session = active;
    if (session == null || session.isComplete) return;

    final updated = session.withKickAt(DateTime.now());
    _sessions = [
      for (final s in _sessions) s.id == session.id ? updated : s,
    ];
    if (updated.isComplete) _activeId = null;

    notifyListeners();
    await _persist();
  }

  /// Ends the count early. A session with no movements recorded is thrown
  /// away rather than saved as a zero - it is a false start, not a result.
  Future<void> stop() async {
    final session = active;
    _activeId = null;
    if (session != null && session.kicks.isEmpty) {
      _sessions = _sessions.where((s) => s.id != session.id).toList();
    }
    notifyListeners();
    await _persist();
  }

  Future<void> remove(String id) async {
    if (_activeId == id) _activeId = null;
    _sessions = _sessions.where((s) => s.id != id).toList();
    notifyListeners();
    await _persist();
  }

  void _trim() {
    if (_sessions.length <= historyLimit) return;
    _sessions = _sessions.sublist(_sessions.length - historyLimit);
  }

  Future<void> _persist() => _storage.saveKickSessions(_sessions);
}
