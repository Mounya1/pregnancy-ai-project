import 'package:flutter/foundation.dart';

import '../models/account.dart';
import 'cognito_client.dart';
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

  /// Cloud only: the account was created but the emailed code has not been
  /// entered yet. Cognito refuses sign-in until it is.
  needsConfirmation,

  signedIn,
}

/// Owns the account, in whichever of two modes the build was configured for.
///
/// **Cloud** (AWS Cognito) when COGNITO_REGION and COGNITO_CLIENT_ID were
/// passed at build time: real accounts, email confirmation, password reset,
/// and the same login on any device.
///
/// **Device-only** otherwise: the account lives in this phone's storage and
/// there is no reset, because with no server nobody can verify who you are.
/// This is what a fresh clone and local development get, so the app runs with
/// no AWS setup at all.
///
/// Health data stays on the device in both modes. Cognito holds identity -
/// email, password, name - and nothing else.
class AuthController extends ChangeNotifier {
  AuthController(this._storage, {CognitoClient? cognito})
      : _cognito = cognito ??
            (CognitoClient.isConfigured ? CognitoClient.fromEnvironment() : null);

  final LocalStorageService _storage;
  final CognitoClient? _cognito;

  /// True when this build talks to Cognito. Screens use it to decide whether
  /// to offer "Forgot password?", which cannot work without a server.
  bool get isCloud => _cognito != null;

  Account? _account;
  bool _sessionActive = false;
  AuthStatus _status = AuthStatus.checking;
  bool _busy = false;

  CognitoTokens? _tokens;

  /// The email waiting on a confirmation code, so the code screen knows who
  /// it is confirming after an app restart.
  String? _pendingEmail;
  String? get pendingEmail => _pendingEmail;

  Account? get account => _account;
  AuthStatus get status => _status;

  /// True while hashing. PBKDF2 takes a beat, and the buttons need to say so.
  bool get busy => _busy;

  bool get isSignedIn => _status == AuthStatus.signedIn;

  Future<void> load() async {
    _account = await _storage.loadAccount();
    _sessionActive = await _storage.loadSessionActive();

    if (isCloud) {
      final stored = await _storage.loadCognitoTokens();
      if (stored != null) {
        _tokens = CognitoTokens.fromJson(stored);
        // An expired access token is normal after any gap - the refresh token
        // lasts far longer, so try it before making someone sign in again.
        if (_tokens!.isExpired) await _tryRefresh();
      }
      _pendingEmail = await _storage.loadPendingEmail();
    }

    _recomputeStatus();
    notifyListeners();
  }

  Future<void> _tryRefresh() async {
    final token = _tokens?.refreshToken;
    if (token == null || token.isEmpty) {
      _tokens = null;
      _sessionActive = false;
      return;
    }
    try {
      _tokens = await _cognito!.refresh(token);
      await _storage.saveCognitoTokens(_tokens!.toJson());
    } catch (_) {
      // Refresh tokens expire too, and a revoked one is indistinguishable
      // from a network blip here. Fall back to asking for the password.
      _tokens = null;
      _sessionActive = false;
      await _storage.saveSessionActive(false);
    }
  }

  void _recomputeStatus() {
    if (isCloud) {
      if (_pendingEmail != null) {
        _status = AuthStatus.needsConfirmation;
      } else if (_tokens != null && _sessionActive) {
        _status = AuthStatus.signedIn;
      } else if (_account != null) {
        // The account is remembered so returning users see "Welcome back"
        // with their email filled in rather than a blank sign-up form.
        _status = AuthStatus.needsSignIn;
      } else {
        _status = AuthStatus.needsSignUp;
      }
      return;
    }

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

  /// Cognito enforces its own policy server-side and rejects with a generic
  /// message. Checking the same rules here means the person is told what is
  /// wrong while they are still typing, not after a round trip.
  static String? validateCloudPassword(String value) {
    if (value.isEmpty) return 'Please choose a password';
    if (value.length < 8) return 'Use at least 8 characters';
    if (!value.contains(RegExp(r'[A-Z]'))) return 'Include an uppercase letter';
    if (!value.contains(RegExp(r'[a-z]'))) return 'Include a lowercase letter';
    if (!value.contains(RegExp(r'[0-9]'))) return 'Include a number';
    return null;
  }

  /// Email is optional for a device-only account but required in the cloud -
  /// it is the username, and the only route a reset code can travel.
  static String? validateRequiredEmail(String value) {
    if (value.trim().isEmpty) return 'Enter your email address';
    return validateEmail(value);
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
    if (isCloud) return _cloudSignUp(name: name, email: email, password: password);

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
  ///
  /// In cloud mode [email] identifies the account; on a device-only build it
  /// is ignored, because there is only ever one account to unlock.
  Future<String?> signIn(String password, {String? email}) async {
    if (isCloud) return _cloudSignIn(email: email ?? _account?.email ?? '', password: password);

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

  /// A valid access token, refreshing it first if it is close to expiry.
  ///
  /// Returns an empty string on a device-only build or when signed out, which
  /// callers treat as "sync unavailable" rather than an error.
  Future<String> accessToken() async {
    if (!isCloud) return '';
    if (_tokens == null) return '';
    if (_tokens!.isExpired) await _tryRefresh();
    return _tokens?.accessToken ?? '';
  }

  // ---- Cloud (Cognito) ----

  Future<String?> _cloudSignUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final problem = validateName(name) ??
        validateRequiredEmail(email) ??
        validateCloudPassword(password);
    if (problem != null) return problem;

    _setBusy(true);
    try {
      await _cognito!.signUp(
        email: email.trim(),
        password: password,
        name: name.trim(),
      );
      // Remembered so a restart lands back on the code screen rather than an
      // empty sign-up form for an account that already half exists.
      _pendingEmail = email.trim();
      await _storage.savePendingEmail(_pendingEmail);
      await _storage.saveAccount(Account(
        id: email.trim(),
        name: name.trim(),
        email: email.trim(),
        salt: '',
        iterations: 0,
        passwordHash: '',
        createdAt: DateTime.now(),
      ));
      _account = await _storage.loadAccount();
      _recomputeStatus();
      return null;
    } on CognitoException catch (e) {
      // An existing unconfirmed account should continue to the code screen
      // rather than dead-end on "already exists".
      if (e.userExists) {
        _pendingEmail = email.trim();
        await _storage.savePendingEmail(_pendingEmail);
        _recomputeStatus();
        return 'An account already exists for this email. '
            'If you never confirmed it, enter the code below or ask for a new one.';
      }
      return e.message;
    } catch (e) {
      return _networkMessage(e);
    } finally {
      _setBusy(false);
    }
  }

  /// Confirms a new account with the emailed code.
  Future<String?> confirmSignUp(String code) async {
    final email = _pendingEmail;
    if (email == null) return 'Nothing is waiting to be confirmed.';
    if (code.trim().isEmpty) return 'Enter the code from your email';

    _setBusy(true);
    try {
      await _cognito!.confirmSignUp(email: email, code: code.trim());
      _pendingEmail = null;
      await _storage.savePendingEmail(null);
      _recomputeStatus();
      return null;
    } on CognitoException catch (e) {
      return e.message;
    } catch (e) {
      return _networkMessage(e);
    } finally {
      _setBusy(false);
    }
  }

  Future<String?> resendCode() async {
    final email = _pendingEmail ?? _account?.email;
    if (email == null || email.isEmpty) return 'No email to send a code to.';

    _setBusy(true);
    try {
      await _cognito!.resendCode(email);
      return null;
    } on CognitoException catch (e) {
      return e.message;
    } catch (e) {
      return _networkMessage(e);
    } finally {
      _setBusy(false);
    }
  }

  Future<String?> _cloudSignIn({required String email, required String password}) async {
    final problem = validateRequiredEmail(email);
    if (problem != null) return problem;
    if (password.isEmpty) return 'Enter your password';

    _setBusy(true);
    try {
      _tokens = await _cognito!.signIn(email: email.trim(), password: password);
      await _storage.saveCognitoTokens(_tokens!.toJson());
      await _storage.saveSessionActive(true);
      _sessionActive = true;

      // Name comes from Cognito so it follows the account across devices,
      // rather than being whatever this particular phone remembered.
      final attributes = await _cognito.getUser(_tokens!.accessToken);
      await _storage.saveAccount(Account(
        id: attributes['sub'] ?? email.trim(),
        name: attributes['name'] ?? '',
        email: attributes['email'] ?? email.trim(),
        salt: '',
        iterations: 0,
        passwordHash: '',
        createdAt: DateTime.now(),
      ));
      _account = await _storage.loadAccount();
      _pendingEmail = null;
      await _storage.savePendingEmail(null);
      _recomputeStatus();
      return null;
    } on CognitoException catch (e) {
      if (e.needsConfirmation) {
        _pendingEmail = email.trim();
        await _storage.savePendingEmail(_pendingEmail);
        _recomputeStatus();
      }
      return e.message;
    } catch (e) {
      return _networkMessage(e);
    } finally {
      _setBusy(false);
    }
  }

  /// Starts a password reset. Cognito emails a code to the address.
  Future<String?> forgotPassword(String email) async {
    if (!isCloud) {
      return 'This build has no password reset. The account exists only on '
          'this device, so nobody can verify who you are.';
    }
    final problem = validateRequiredEmail(email);
    if (problem != null) return problem;

    _setBusy(true);
    try {
      await _cognito!.forgotPassword(email.trim());
      return null;
    } on CognitoException catch (e) {
      return e.message;
    } catch (e) {
      return _networkMessage(e);
    } finally {
      _setBusy(false);
    }
  }

  Future<String?> confirmForgotPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final problem = validateRequiredEmail(email) ?? validateCloudPassword(newPassword);
    if (problem != null) return problem;
    if (code.trim().isEmpty) return 'Enter the code from your email';

    _setBusy(true);
    try {
      await _cognito!.confirmForgotPassword(
        email: email.trim(),
        code: code.trim(),
        newPassword: newPassword,
      );
      return null;
    } on CognitoException catch (e) {
      return e.message;
    } catch (e) {
      return _networkMessage(e);
    } finally {
      _setBusy(false);
    }
  }

  /// Dio and the platform throw a dozen different things for "no network".
  /// None of them are worth showing raw.
  String _networkMessage(Object error) =>
      'Could not reach the sign-in service. Check your connection and try again.';

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }
}
