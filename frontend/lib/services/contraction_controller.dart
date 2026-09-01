import 'package:flutter/foundation.dart';

import '../models/contraction.dart';
import 'local_storage_service.dart';

/// Owns the contraction timer.
///
/// Every start and stop is written straight to storage. Someone timing
/// contractions is not in a position to redo the last hour of taps because
/// the tab reloaded, and the timings are the thing they will be reading out
/// over the phone.
class ContractionController extends ChangeNotifier {
  ContractionController(this._storage);

  final LocalStorageService _storage;

  /// Labour can run long, but the whole store syncs as one size-capped
  /// document, so the tail is dropped.
  static const historyLimit = 300;

  List<Contraction> _contractions = [];
  bool _loaded = false;

  bool get isLoaded => _loaded;

  /// Newest first, matching how they are listed.
  List<Contraction> get contractions => List.unmodifiable(_contractions.reversed);

  /// The contraction currently being timed, if any.
  Contraction? get running {
    for (final c in _contractions.reversed) {
      if (c.isRunning) return c;
    }
    return null;
  }

  bool get isTiming => running != null;

  List<Contraction> contractionsOn(DateTime day) =>
      contractions.where((c) => c.isSameDay(day)).toList();

  /// Summary of the recent pattern. Takes [now] rather than reading the clock
  /// so the screen's per-second tick drives it and tests stay deterministic.
  ContractionPattern patternAt(DateTime now) =>
      ContractionPattern.from(_contractions, now);

  Future<void> load() async {
    _contractions = await _storage.loadContractions();

    // A contraction left running from a previous session has no believable
    // end time - it could have been closed mid-labour or left open all night.
    // Drop it rather than invent a duration or resume a stale timer.
    final stale = DateTime.now().subtract(const Duration(minutes: 30));
    _contractions = _contractions
        .where((c) => !c.isRunning || c.startedAt.isAfter(stale))
        .toList();

    _loaded = true;
    notifyListeners();
  }

  Future<void> start() async {
    if (isTiming) return;

    _contractions = [
      ..._contractions,
      Contraction(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        startedAt: DateTime.now(),
      ),
    ];
    _trim();
    notifyListeners();
    await _persist();
  }

  Future<void> stop() async {
    final current = running;
    if (current == null) return;

    final ended = current.stoppedAt(DateTime.now());
    _contractions = [
      for (final c in _contractions) c.id == current.id ? ended : c,
    ];
    notifyListeners();
    await _persist();
  }

  Future<void> remove(String id) async {
    _contractions = _contractions.where((c) => c.id != id).toList();
    notifyListeners();
    await _persist();
  }

  /// Clears the log so a new episode starts from a clean pattern. Timings
  /// from a bout of false labour two days ago would otherwise be averaged
  /// into today's.
  Future<void> clear() async {
    _contractions = [];
    notifyListeners();
    await _persist();
  }

  void _trim() {
    if (_contractions.length <= historyLimit) return;
    _contractions = _contractions.sublist(_contractions.length - historyLimit);
  }

  Future<void> _persist() => _storage.saveContractions(_contractions);
}
