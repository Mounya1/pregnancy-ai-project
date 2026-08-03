import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import 'local_storage_service.dart';

/// Holds the single UserProfile used throughout the app, persisted to local
/// storage. Provided at the app root via ChangeNotifierProvider so any
/// screen can read the current profile or update it and have every other
/// screen (home header, chat requests, meal planner, nutrition targets)
/// stay in sync automatically.
class ProfileController extends ChangeNotifier {
  ProfileController(this._storage);

  final LocalStorageService _storage;
  UserProfile _profile = UserProfile();
  bool _loaded = false;

  UserProfile get profile => _profile;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    final stored = await _storage.loadProfile();
    if (stored != null) _profile = stored;
    _loaded = true;
    notifyListeners();
  }

  Future<void> update(UserProfile Function(UserProfile current) updater) async {
    _profile = updater(_profile);
    notifyListeners();
    await _storage.saveProfile(_profile);
  }
}
