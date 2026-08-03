import 'package:flutter/material.dart';
import 'local_storage_service.dart';

/// Holds the app's light/dark preference and persists it locally, so the
/// choice made in Settings survives a restart. Defaults to [ThemeMode.system]
/// until a stored value is loaded.
class ThemeController extends ChangeNotifier {
  ThemeController(this._storage);

  final LocalStorageService _storage;
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  Future<void> load() async {
    _mode = _parse(await _storage.loadThemeMode());
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    await _storage.saveThemeMode(mode.name);
  }

  static ThemeMode _parse(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}

String themeModeLabel(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.system:
      return 'System';
    case ThemeMode.light:
      return 'Light';
    case ThemeMode.dark:
      return 'Dark';
  }
}

IconData themeModeIcon(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.system:
      return Icons.brightness_auto_rounded;
    case ThemeMode.light:
      return Icons.light_mode_rounded;
    case ThemeMode.dark:
      return Icons.dark_mode_rounded;
  }
}
