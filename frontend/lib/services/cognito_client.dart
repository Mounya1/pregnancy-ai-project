import 'dart:convert';

import 'package:dio/dio.dart';

/// Talks to an AWS Cognito user pool over plain HTTPS.
///
/// Deliberately not the Amplify SDK. Amplify pulls a large native dependency
/// tree into both platforms, and this project's Android release build already
/// fails on memory before it gets that far. Every call below is an
/// unauthenticated user-pool operation - they need only the app client id, no
/// request signing - so a JSON POST does the whole job and behaves identically
/// on web and Android.
///
/// The app client must be created **without a client secret**. A secret would
/// require a SECRET_HASH on every call, and shipping the secret inside a
/// mobile or web app to compute it would defeat the point of having one.
class CognitoClient {
  CognitoClient({
    required this.region,
    required this.clientId,
    Dio? dio,
  }) : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: 'https://cognito-idp.$region.amazonaws.com/',
              headers: {'Content-Type': 'application/x-amz-json-1.1'},
              // Cognito answers fast; a long hang here is a network fault,
              // not the service thinking.
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 30),
            ));

  final String region;
  final String clientId;
  final Dio _dio;

  /// Whether the app was built with a pool configured. False means the app
  /// falls back to device-only accounts, which is what local development and
  /// a fresh clone get.
  static bool get isConfigured => kCognitoClientId.isNotEmpty && kCognitoRegion.isNotEmpty;

  static const kCognitoRegion = String.fromEnvironment('COGNITO_REGION');
  static const kCognitoClientId = String.fromEnvironment('COGNITO_CLIENT_ID');

  factory CognitoClient.fromEnvironment() =>
      CognitoClient(region: kCognitoRegion, clientId: kCognitoClientId);

  Future<Map<String, dynamic>> _call(String operation, Map<String, dynamic> body) async {
    final res = await _dio.post(
      '',
      data: jsonEncode(body),
      options: Options(
        headers: {'X-Amz-Target': 'AWSCognitoIdentityProviderService.$operation'},
        // Cognito signals failure with a 400 and a typed body. Letting Dio
        // treat that as a normal response keeps the error handling in one
        // place instead of split across exceptions and return values.
        validateStatus: (_) => true,
      ),
    );

    final data = res.data is String
        ? jsonDecode(res.data as String) as Map<String, dynamic>
        : (res.data as Map).cast<String, dynamic>();

    if (res.statusCode != null && res.statusCode! >= 400) {
      throw CognitoException.fromResponse(data);
    }
    return data;
  }

  /// Creates the account. Cognito emails a six-digit code; the account cannot
  /// sign in until [confirmSignUp] is called with it.
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) =>
      _call('SignUp', {
        'ClientId': clientId,
        'Username': email,
        'Password': password,
        'UserAttributes': [
          {'Name': 'email', 'Value': email},
          {'Name': 'name', 'Value': name},
        ],
      });

  Future<void> confirmSignUp({required String email, required String code}) =>
      _call('ConfirmSignUp', {
        'ClientId': clientId,
        'Username': email,
        'ConfirmationCode': code,
      });

  Future<void> resendCode(String email) =>
      _call('ResendConfirmationCode', {'ClientId': clientId, 'Username': email});

  /// Returns the token set on success. Requires USER_PASSWORD_AUTH to be
  /// enabled on the app client - without it Cognito answers with
  /// InvalidParameterException and no explanation of which parameter.
  Future<CognitoTokens> signIn({required String email, required String password}) async {
    final data = await _call('InitiateAuth', {
      'ClientId': clientId,
      'AuthFlow': 'USER_PASSWORD_AUTH',
      'AuthParameters': {'USERNAME': email, 'PASSWORD': password},
    });
    return CognitoTokens.fromAuthResult(data['AuthenticationResult'] as Map);
  }

  Future<CognitoTokens> refresh(String refreshToken) async {
    final data = await _call('InitiateAuth', {
      'ClientId': clientId,
      'AuthFlow': 'REFRESH_TOKEN_AUTH',
      'AuthParameters': {'REFRESH_TOKEN': refreshToken},
    });
    // A refresh response omits the refresh token - the old one stays valid.
    return CognitoTokens.fromAuthResult(
      data['AuthenticationResult'] as Map,
      fallbackRefreshToken: refreshToken,
    );
  }

  /// Starts a password reset. Cognito emails a code.
  Future<void> forgotPassword(String email) =>
      _call('ForgotPassword', {'ClientId': clientId, 'Username': email});

  Future<void> confirmForgotPassword({
    required String email,
    required String code,
    required String newPassword,
  }) =>
      _call('ConfirmForgotPassword', {
        'ClientId': clientId,
        'Username': email,
        'ConfirmationCode': code,
        'Password': newPassword,
      });

  Future<Map<String, String>> getUser(String accessToken) async {
    final data = await _call('GetUser', {'AccessToken': accessToken});
    final attributes = <String, String>{};
    for (final a in (data['UserAttributes'] as List? ?? [])) {
      attributes[a['Name'] as String] = (a['Value'] ?? '').toString();
    }
    return attributes;
  }

  Future<void> changePassword({
    required String accessToken,
    required String currentPassword,
    required String newPassword,
  }) =>
      _call('ChangePassword', {
        'AccessToken': accessToken,
        'PreviousPassword': currentPassword,
        'ProposedPassword': newPassword,
      });

  /// Invalidates every token for this user, on every device.
  Future<void> globalSignOut(String accessToken) =>
      _call('GlobalSignOut', {'AccessToken': accessToken});

  Future<void> deleteUser(String accessToken) =>
      _call('DeleteUser', {'AccessToken': accessToken});
}

class CognitoTokens {
  const CognitoTokens({
    required this.accessToken,
    required this.idToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  final String accessToken;
  final String idToken;
  final String refreshToken;
  final DateTime expiresAt;

  /// Treated as expired a minute early, so a request never leaves with a
  /// token that dies in flight.
  bool get isExpired => DateTime.now().isAfter(expiresAt.subtract(const Duration(minutes: 1)));

  factory CognitoTokens.fromAuthResult(Map result, {String? fallbackRefreshToken}) {
    final seconds = (result['ExpiresIn'] as num?)?.toInt() ?? 3600;
    return CognitoTokens(
      accessToken: result['AccessToken'] as String? ?? '',
      idToken: result['IdToken'] as String? ?? '',
      refreshToken: result['RefreshToken'] as String? ?? fallbackRefreshToken ?? '',
      expiresAt: DateTime.now().add(Duration(seconds: seconds)),
    );
  }

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'id_token': idToken,
        'refresh_token': refreshToken,
        'expires_at': expiresAt.toIso8601String(),
      };

  factory CognitoTokens.fromJson(Map<String, dynamic> json) => CognitoTokens(
        accessToken: json['access_token'] as String? ?? '',
        idToken: json['id_token'] as String? ?? '',
        refreshToken: json['refresh_token'] as String? ?? '',
        expiresAt: DateTime.tryParse(json['expires_at'] as String? ?? '') ?? DateTime(2000),
      );
}

/// A Cognito failure, translated into something worth showing a person.
class CognitoException implements Exception {
  const CognitoException(this.type, this.message);

  /// Cognito's error type, e.g. `UserNotConfirmedException`. Screens branch on
  /// this - an unconfirmed account needs a code screen, not an error.
  final String type;

  final String message;

  bool get needsConfirmation => type == 'UserNotConfirmedException';
  bool get userExists => type == 'UsernameExistsException';

  factory CognitoException.fromResponse(Map<String, dynamic> data) {
    // Cognito puts the type in __type, sometimes prefixed with a namespace.
    final raw = (data['__type'] ?? data['type'] ?? 'UnknownError').toString();
    final type = raw.contains('#') ? raw.split('#').last : raw;
    final message = (data['message'] ?? data['Message'] ?? '').toString();
    return CognitoException(type, _friendly(type, message));
  }

  /// Cognito's own wording is written for developers. These are the cases a
  /// person actually hits, in words that tell them what to do next.
  static String _friendly(String type, String fallback) {
    switch (type) {
      case 'NotAuthorizedException':
        return 'That email and password do not match.';
      case 'UserNotFoundException':
        // Deliberately identical to the wrong-password message: telling a
        // stranger which emails have accounts is an account-enumeration leak.
        return 'That email and password do not match.';
      case 'UserNotConfirmedException':
        return 'This account still needs confirming. Check your email for the code.';
      case 'UsernameExistsException':
        return 'An account already exists for this email. Try signing in.';
      case 'CodeMismatchException':
        return 'That code is not right. Check it and try again.';
      case 'ExpiredCodeException':
        return 'That code has expired. Ask for a new one.';
      case 'InvalidPasswordException':
        return 'That password does not meet the requirements: at least 8 '
            'characters, with an uppercase letter, a lowercase letter and a number.';
      case 'InvalidParameterException':
        return fallback.isEmpty ? 'Something in that request was not valid.' : fallback;
      case 'LimitExceededException':
      case 'TooManyRequestsException':
        return 'Too many attempts. Wait a few minutes and try again.';
      case 'TooManyFailedAttemptsException':
        return 'Too many failed attempts. Wait a few minutes before trying again.';
      case 'CodeDeliveryFailureException':
        return 'The code could not be emailed. Check the address and try again.';
      default:
        return fallback.isEmpty ? 'Something went wrong ($type).' : fallback;
    }
  }

  @override
  String toString() => message;
}
