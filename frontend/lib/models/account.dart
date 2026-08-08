/// The account that owns everything stored on this device.
///
/// There is no server behind it. The password never leaves the phone and is
/// only ever stored as a PBKDF2 hash, so the record below is safe to sit in
/// SharedPreferences next to the profile and the food log.
class Account {
  final String id;
  final String name;

  /// Optional. Kept only so the account has something to show besides a name;
  /// nothing is ever sent to it, and it is not a recovery route.
  final String email;

  final String passwordHash;
  final String salt;
  final int iterations;
  final DateTime createdAt;

  const Account({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.salt,
    required this.iterations,
    required this.createdAt,
  });

  /// What the home screen greets you with - "Good morning, Priya" reads far
  /// better than the full name someone typed on the sign-up form.
  String get firstName {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'there';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  /// Up to two letters for the avatar circle.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.firstLetters(2);
    return '${parts.first.firstLetters(1)}${parts.last.firstLetters(1)}';
  }

  Account copyWith({String? name, String? email, String? passwordHash, String? salt, int? iterations}) {
    return Account(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      salt: salt ?? this.salt,
      iterations: iterations ?? this.iterations,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'password_hash': passwordHash,
        'salt': salt,
        'iterations': iterations,
        'created_at': createdAt.toIso8601String(),
      };

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        passwordHash: json['password_hash'] as String? ?? '',
        salt: json['salt'] as String? ?? '',
        iterations: (json['iterations'] as num?)?.toInt() ?? 1,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}

extension on String {
  /// Takes the first [n] characters, upper-cased, without blowing up on
  /// single-letter names.
  String firstLetters(int n) => substring(0, n.clamp(0, length)).toUpperCase();
}
