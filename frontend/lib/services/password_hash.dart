import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// PBKDF2-HMAC-SHA256, so the stored account record never contains the
/// password itself.
///
/// The account is device-only, which makes it tempting to skip this - but
/// SharedPreferences is a plain XML file on Android and localStorage on web,
/// and people reuse passwords. A stolen phone should not hand over a password
/// that also opens someone's email.
class PasswordHash {
  /// Slow enough to make guessing expensive, fast enough that unlocking the
  /// app doesn't feel broken. Stored alongside the hash so this number can be
  /// raised later without locking out existing accounts.
  static const int defaultIterations = 20000;

  static final Random _random = Random.secure();

  /// 16 random bytes, base64. A fresh one per account, so two people who pick
  /// the same password don't end up with the same hash.
  static String newSalt() {
    final bytes = Uint8List.fromList(List<int>.generate(16, (_) => _random.nextInt(256)));
    return base64Encode(bytes);
  }

  static String hash(String password, String salt, {int iterations = defaultIterations}) {
    final key = _pbkdf2(
      utf8.encode(password),
      base64Decode(salt),
      iterations,
      32,
    );
    return base64Encode(key);
  }

  /// Compares in constant time. Overkill for a local unlock screen, but it
  /// costs nothing and stops this from being a bad example to copy.
  static bool verify(String password, String salt, String expectedHash, {int iterations = defaultIterations}) {
    final actual = hash(password, salt, iterations: iterations);
    if (actual.length != expectedHash.length) return false;
    var diff = 0;
    for (var i = 0; i < actual.length; i++) {
      diff |= actual.codeUnitAt(i) ^ expectedHash.codeUnitAt(i);
    }
    return diff == 0;
  }

  static Uint8List _pbkdf2(List<int> password, List<int> salt, int iterations, int keyLength) {
    final hmac = Hmac(sha256, password);
    final out = BytesBuilder();
    var block = 1;

    while (out.length < keyLength) {
      // U1 = HMAC(password, salt || INT_32_BE(block))
      var u = hmac.convert([...salt, ..._int32be(block)]).bytes;
      final acc = Uint8List.fromList(u);

      for (var i = 1; i < iterations; i++) {
        u = hmac.convert(u).bytes;
        for (var j = 0; j < acc.length; j++) {
          acc[j] ^= u[j];
        }
      }

      out.add(acc);
      block++;
    }

    return Uint8List.fromList(out.takeBytes().sublist(0, keyLength));
  }

  static List<int> _int32be(int value) => [
        (value >> 24) & 0xff,
        (value >> 16) & 0xff,
        (value >> 8) & 0xff,
        value & 0xff,
      ];
}
