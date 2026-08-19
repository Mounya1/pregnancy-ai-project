import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'auth_controller.dart';
import 'local_storage_service.dart';

enum SyncState { idle, syncing, done, failed, unavailable }

/// Keeps this device's data and the server copy in step.
///
/// The whole local store travels as one document. That mirrors how the app
/// already stores things and makes a sync one request instead of twenty, at
/// the cost of not being able to merge two devices that both changed while
/// offline - see [pull] for how that is handled.
class SyncController extends ChangeNotifier {
  SyncController(this._storage, this._auth);

  final LocalStorageService _storage;
  final AuthController _auth;
  final _api = ApiClient();

  SyncState _state = SyncState.idle;
  String? _message;
  DateTime? _lastSynced;

  SyncState get state => _state;
  String? get message => _message;
  DateTime? get lastSynced => _lastSynced;

  /// Sync needs an account to attach data to, so it is off on device-only
  /// builds - there is no identity to key a server copy on.
  bool get isAvailable => _auth.isCloud && _auth.isSignedIn;

  void _set(SyncState state, [String? message]) {
    _state = state;
    _message = message;
    notifyListeners();
  }

  /// Sends this device's data up, replacing the server copy.
  Future<void> push() async {
    if (!isAvailable) return _set(SyncState.unavailable, 'Sign in to sync.');

    _set(SyncState.syncing);
    try {
      final data = await _storage.exportAll();
      final res = await _api.rawDio.put(
        '/sync',
        data: {'data': data},
        options: Options(headers: await _authHeader()),
      );
      _lastSynced = DateTime.tryParse(res.data['updated_at'] as String? ?? '');
      _set(SyncState.done, 'Saved to your account.');
    } catch (e) {
      _set(SyncState.failed, _describe(e));
    }
  }

  /// Brings the server copy down, replacing this device's data.
  ///
  /// Returns false when there is nothing stored yet. That case must not wipe
  /// the device: a brand new account has no server copy, and treating "never
  /// synced" as "synced and empty" would delete everything on first run.
  Future<bool> pull() async {
    if (!isAvailable) {
      _set(SyncState.unavailable, 'Sign in to sync.');
      return false;
    }

    _set(SyncState.syncing);
    try {
      final res = await _api.rawDio.get(
        '/sync',
        options: Options(headers: await _authHeader()),
      );
      final data = res.data['data'];
      if (data == null) {
        _set(SyncState.done, 'Nothing saved to your account yet.');
        return false;
      }

      await _storage.importAll((data as Map).cast<String, dynamic>());
      _lastSynced = DateTime.tryParse(res.data['updated_at'] as String? ?? '');
      _set(SyncState.done, 'Restored from your account.');
      return true;
    } catch (e) {
      _set(SyncState.failed, _describe(e));
      return false;
    }
  }

  /// Removes the server copy. The device keeps its own data.
  Future<void> deleteRemote() async {
    if (!isAvailable) return _set(SyncState.unavailable, 'Sign in to sync.');

    _set(SyncState.syncing);
    try {
      await _api.rawDio.delete('/sync', options: Options(headers: await _authHeader()));
      _lastSynced = null;
      _set(SyncState.done, 'Removed from your account. This device still has its copy.');
    } catch (e) {
      _set(SyncState.failed, _describe(e));
    }
  }

  Future<Map<String, String>> _authHeader() async {
    final token = await _auth.accessToken();
    return {'Authorization': 'Bearer $token'};
  }

  String _describe(Object error) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      final detail = error.response?.data is Map
          ? (error.response!.data as Map)['detail']?.toString()
          : null;
      if (status == 401) return 'Your session expired. Sign in again.';
      if (status == 501) return 'Sync is not switched on for this server.';
      if (status == 413) {
        return detail ?? 'Your data is too large to sync.';
      }
      if (detail != null) return detail;
      return 'Sync failed${status == null ? '' : ' ($status)'}.';
    }
    return 'Sync failed. Check your connection.';
  }
}
