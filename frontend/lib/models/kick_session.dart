/// One round of the "count to ten" fetal movement check.
///
/// The method clinicians usually describe: pick a time when the baby is
/// normally active, lie on your side, and count distinct movements until you
/// reach ten. Ten movements normally arrive well inside two hours; taking
/// longer is the thing worth reporting, not any single quiet stretch.
class KickSession {
  const KickSession({
    required this.id,
    required this.startedAt,
    required this.kicks,
  });

  final String id;
  final DateTime startedAt;

  /// When each movement was tapped, oldest first.
  final List<DateTime> kicks;

  /// Ten is the count every version of this method uses.
  static const target = 10;

  /// The span the count is expected to fit inside. Beyond this the session
  /// still counts - it is just flagged for the user to mention to their
  /// provider.
  static const window = Duration(hours: 2);

  int get count => kicks.length;
  bool get isComplete => kicks.length >= target;

  /// When the tenth movement landed, or null while still counting.
  DateTime? get completedAt => isComplete ? kicks[target - 1] : null;

  /// How long this session ran, measured to the tenth kick once complete and
  /// to [now] while it is still going.
  Duration elapsedAt(DateTime now) =>
      (completedAt ?? now).difference(startedAt);

  /// Settled duration for a session that is no longer being counted. Falls
  /// back to the last movement so an abandoned session does not report the
  /// hours it sat open.
  Duration get duration =>
      (completedAt ?? (kicks.isEmpty ? startedAt : kicks.last))
          .difference(startedAt);

  /// True when ten movements took longer than the usual two hours. Worth
  /// raising with a provider - on its own it is not an emergency.
  bool get tookLongerThanUsual => isComplete && duration > window;

  KickSession copyWith({List<DateTime>? kicks}) => KickSession(
        id: id,
        startedAt: startedAt,
        kicks: kicks ?? this.kicks,
      );

  KickSession withKickAt(DateTime at) => copyWith(kicks: [...kicks, at]);

  bool isSameDay(DateTime day) =>
      startedAt.year == day.year &&
      startedAt.month == day.month &&
      startedAt.day == day.day;

  Map<String, dynamic> toJson() => {
        'id': id,
        'started_at': startedAt.toIso8601String(),
        'kicks': kicks.map((k) => k.toIso8601String()).toList(),
      };

  factory KickSession.fromJson(Map<String, dynamic> json) => KickSession(
        id: json['id'] as String,
        startedAt: DateTime.parse(json['started_at'] as String),
        kicks: ((json['kicks'] as List?) ?? const [])
            .map((k) => DateTime.parse(k as String))
            .toList(),
      );
}
