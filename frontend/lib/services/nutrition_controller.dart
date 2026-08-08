import 'package:flutter/foundation.dart';

import '../models/nutrition_log.dart';
import 'local_storage_service.dart';

/// Single source of truth for the food log.
///
/// It used to live inside the tracker screen's State, which meant a food
/// logged from the scan screen was invisible until the tracker was rebuilt -
/// and an IndexedStack keeps every tab alive, so that rebuild never came.
class NutritionController extends ChangeNotifier {
  NutritionController(this._storage);

  final LocalStorageService _storage;

  List<NutritionEntry> _entries = [];
  bool _loaded = false;

  bool get isLoaded => _loaded;
  List<NutritionEntry> get entries => List.unmodifiable(_entries);

  List<NutritionEntry> entriesOn(DateTime day) =>
      _entries.where((e) => e.isSameDay(day)).toList()
        ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));

  List<NutritionEntry> get today => entriesOn(DateTime.now());

  NutrientProfile totalFor(List<NutritionEntry> entries) =>
      entries.fold(const NutrientProfile(), (sum, e) => sum + e.nutrients);

  NutrientProfile get todayTotal => totalFor(today);

  Future<void> load() async {
    _entries = await _storage.loadNutritionEntries();
    _loaded = true;
    notifyListeners();
  }

  Future<void> add(NutritionEntry entry) async {
    _entries = [..._entries, entry];
    notifyListeners();
    await _storage.logNutritionEntry(entry);
  }

  Future<void> remove(NutritionEntry entry) async {
    _entries = _entries.where((e) => e.id != entry.id).toList();
    notifyListeners();
    await _storage.removeNutritionEntry(entry.id);
  }
}
