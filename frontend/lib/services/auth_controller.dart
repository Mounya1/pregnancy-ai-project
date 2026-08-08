import 'package:flutter/foundation.dart';

import '../models/account.dart';
import 'local_storage_service.dart';
import 'password_hash.dart';

enum AuthStatus {
  /// Still reading storage. Shown as a splash, never as a form - flashing a
  /// sign-up screen at someone who already has an account looks like data loss.
  checking,

  /// No account on this device yet.
  needsSignUp,

  /// An account exists but the password hasn't been entered since sign-out.
  needsSignIn,

  signedIn,
}

/// Owns the device-only account: create it, unlock it, sign out, delete it.
///
/// Nothing here talks to a server. "Sign in" means "prove you know the
/// password that was set on this device", which is what protects the food
/// log, medical reports, and baby records already stored locally.
class AuthController extends ChangeNotifier {
  AuthController(this._storage);

  final LocalStorageService _storage;

  Account? _account;
  bool _sessionActive = false;
  AuthStatus _status = AuthStatus.checking;
  bool _busy = false;

  Account? get account => _account;
  AuthStatus get status => _status;

  /// True while hashing. PBKDF2 takes a beat, and the buttons need to say so.
  bool get busy => _busy;

  bool get isSignedIn => _status == AuthStatus.signedIn;

  Future<void> load() async {
    _account = await _storage.loadAccount();
    _sessionActive = await _storage.loadSessionActive();
    _recomputeStatus();
    notifyListeners();
  }

  void _recomputeStatus() {
    if (_account == null) {
      _status = AuthStatus.needsSignUp;
    } else if (_sessionActive) {
      _status = AuthStatus.signedIn;
    } else {
      _status = AuthStatus.needsSignIn;
    }
  }

  // ---- Validation ----
  //
  // Returned as messages rather than thrown, because every one of these is
  // something to show under a text field, not an error to log.

  static String? validateName(String value) {
    if (value.trim().isEmpty) return 'Please enter your name';
    if (value.trim().length < 2) return 'That looks too short';
    return null;
  }

  /// Optional field: empty is fine, malformed is not.
  static String? validateEmail(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$').hasMatch(trimmed);
    return ok ? null : 'Check this email address';
  }

  static String? validatePassword(String value) {
    if (value.isEmpty) return 'Please choose a password';
    if (value.length < 6) return 'Use at least 6 characters';
    return null;
  }

  // ---- Actions ----

  /// Creates the account and signs in immediately - asking someone to type a
  /// password they just chose, twice, and then again to sign in is pure
  /// friction. Returns an error message, or null on success.
  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final problem = validateName(name) ?? validateEmail(email) ?? validatePassword(password);
    if (problem != null) return problem;

    _setBusy(true);
    try {
      final salt = PasswordHash.newSalt();
      final account = Account(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name.trim(),
        email: email.trim(),
        salt: salt,
        iterations: PasswordHash.defaultIterations,
        passwordHash: PasswordHash.hash(password, salt),
        createdAt: DateTime.now(),
      );

      await _storage.saveAccount(account);
      await _storage.saveSessionActive(true);
      _account = account;
      _sessionActive = true;
      _recomputeStatus();
      return null;
    } finally {
      _setBusy(false);
    }
  }

  /// Returns an error message, or null on success.
  Future<String?> signIn(String password) async {
    final account = _account;
    if (account == null) return 'No account on this device yet';
    if (password.isEmpty) return 'Enter your password';

    _setBusy(true);
    try {
      final ok = PasswordHash.verify(
        password,
        account.salt,
        account.passwordHash,
        iterations: account.iterations,
      );
      if (!ok) return 'That password does not match';

      await _storage.saveSessionActive(true);
      _sessionActive = true;
      _recomputeStatus();
      return null;
    } finally {
      _setBusy(false);
    }
  }

  /// Locks the app. Deliberately leaves every other key in storage alone -
  /// signing out is not the same as wanting your history erased.
  Future<void> signOut() async {
    await _storage.saveSessionActive(false);
    _sessionActive = false;
    _recomputeStatus();
    notifyListeners();
  }

  Future<String?> updateDetails({required String name, required String email}) async {
    final account = _account;
    if (account == null) return 'No account on this device yet';
    final problem = validateName(name) ?? validateEmail(email);
    if (problem != null) return problem;

    final updated = account.copyWith(name: name.trim(), email: email.trim());
    await _storage.saveAccount(updated);
    _account = updated;
    notifyListeners();
    return null;
  }

  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final account = _account;
    if (account == null) return 'No account on this device yet';

    final problem = validatePassword(newPassword);
    if (problem != null) return problem;

    _setBusy(true);
    try {
      final ok = PasswordHash.verify(
        currentPassword,
        account.salt,
        account.passwordHash,
        iterations: account.iterations,
      );
      if (!ok) return 'Your current password does not match';

      final salt = PasswordHash.newSalt();
      final updated = account.copyWith(
        salt: salt,
        iterations: PasswordHash.defaultIterations,
        passwordHash: PasswordHash.hash(newPassword, salt),
      );
      await _storage.saveAccount(updated);
      _account = updated;
      return null;
    } finally {
      _setBusy(false);
    }
  }

  /// Clears the stored data but keeps you signed in.
  ///
  /// Storage is one flat key-value store, so wiping it takes the account with
  /// it. Putting the account back afterwards is what keeps "clear my history"
  /// in Settings from silently meaning "delete my account".
  Future<void> clearDataKeepingAccount() async {
    final account = _account;
    final wasSignedIn = _sessionActive;

    await _storage.clearAllData();

    if (account != null) {
      await _storage.saveAccount(account);
      await _storage.saveSessionActive(wasSignedIn);
    }
    notifyListeners();
  }

  /// Wipes the account *and* everything it owns.
  ///
  /// This is also the only answer to a forgotten password: with no server
  /// there is nobody to verify identity, so the honest option is starting
  /// over rather than a fake "reset link".
  Future<void> deleteAccountAndData() async {
    await _storage.clearAllData();
    _account = null;
    _sessionActive = false;
    _recomputeStatus();
    notifyListeners();
  }

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }
}
