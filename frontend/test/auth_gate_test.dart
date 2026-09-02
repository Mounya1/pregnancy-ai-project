import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pregnancy_ai_assistant/models/account.dart';
import 'package:pregnancy_ai_assistant/services/auth_controller.dart';
import 'package:pregnancy_ai_assistant/services/cognito_client.dart';
import 'package:pregnancy_ai_assistant/services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A cloud controller that never reaches the network: showSignUp, showSignIn
/// and load() all stay inside storage, and no test here calls anything else.
AuthController _cloudAuth() => AuthController(
      LocalStorageService(),
      cognito: CognitoClient(region: 'us-east-1', clientId: 'test-client'),
    );

final _account = Account(
  id: 'a1',
  name: 'Priya Sharma',
  email: 'priya@example.com',
  passwordHash: 'hash',
  salt: 'salt',
  iterations: 1000,
  createdAt: DateTime(2026, 1, 1),
);

Map<String, Object> _remembered() => {
      'flutter.account': jsonEncode(_account.toJson()),
      'flutter.session_active': false,
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('cloud auth gate', () {
    test('a browser with no account opens on sign-up', () async {
      SharedPreferences.setMockInitialValues({});
      final auth = _cloudAuth();
      await auth.load();

      expect(auth.status, AuthStatus.needsSignUp);
    });

    test('a remembered account opens on sign-in', () async {
      SharedPreferences.setMockInitialValues(_remembered());
      final auth = _cloudAuth();
      await auth.load();

      expect(auth.status, AuthStatus.needsSignIn);
    });

    // The case that had no way out before: someone who already has an account
    // opens the site on a new browser and lands on the sign-up form.
    test('showSignIn reaches the sign-in form with no account stored', () async {
      SharedPreferences.setMockInitialValues({});
      final auth = _cloudAuth();
      await auth.load();
      expect(auth.status, AuthStatus.needsSignUp);

      auth.showSignIn();

      expect(auth.status, AuthStatus.needsSignIn);
      // Nothing was invented to fill the form with.
      expect(auth.account, isNull);
    });

    test('showSignUp reaches the sign-up form with an account stored', () async {
      SharedPreferences.setMockInitialValues(_remembered());
      final auth = _cloudAuth();
      await auth.load();
      expect(auth.status, AuthStatus.needsSignIn);

      auth.showSignUp();

      expect(auth.status, AuthStatus.needsSignUp);
    });

    test('the choice survives an unrelated recompute', () async {
      SharedPreferences.setMockInitialValues({});
      final auth = _cloudAuth();
      await auth.load();
      auth.showSignIn();

      // signOut recomputes; the form the user asked for should not snap back.
      await auth.signOut();

      expect(auth.status, AuthStatus.needsSignIn);
    });

    test('switching notifies so the gate rebuilds', () async {
      SharedPreferences.setMockInitialValues({});
      final auth = _cloudAuth();
      await auth.load();

      var notified = 0;
      auth.addListener(() => notified++);
      auth.showSignIn();

      expect(notified, 1);
    });

    test('asking for the form already showing is a no-op', () async {
      SharedPreferences.setMockInitialValues({});
      final auth = _cloudAuth();
      await auth.load();

      var notified = 0;
      auth.addListener(() => notified++);
      auth.showSignUp();

      expect(notified, 0);
      expect(auth.status, AuthStatus.needsSignUp);
    });
  });

  group('device-only auth gate', () {
    // One account per phone, and creating a second wipes the first - so the
    // links are hidden there and the controller refuses the switch too.
    test('showSignUp cannot escape the sign-in screen', () async {
      SharedPreferences.setMockInitialValues(_remembered());
      final auth = AuthController(LocalStorageService());
      await auth.load();
      expect(auth.isCloud, isFalse);
      expect(auth.status, AuthStatus.needsSignIn);

      auth.showSignUp();

      expect(auth.status, AuthStatus.needsSignIn);
    });
  });
}
