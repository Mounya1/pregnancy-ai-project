/// A single timed contraction. [endedAt] is null while one is in progress.
class Contraction {
  const Contraction({required this.id, required this.startedAt, this.endedAt});

  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;

  bool get isRunning => endedAt == null;

  /// How long the contraction lasted, or null while it is still running.
  Duration? get duration => endedAt?.difference(startedAt);

  Contraction stoppedAt(DateTime at) =>
      Contraction(id: id, startedAt: startedAt, endedAt: at);

  bool isSameDay(DateTime day) =>
      startedAt.year == day.year &&
      startedAt.month == day.month &&
      startedAt.day == day.day;

  Map<String, dynamic> toJson() => {
        'id': id,
        'started_at': startedAt.toIso8601String(),
        if (endedAt != null) 'ended_at': endedAt!.toIso8601String(),
      };

  factory Contraction.fromJson(Map<String, dynamic> json) => Contraction(
        id: json['id'] as String,
        startedAt: DateTime.parse(json['started_at'] as String),
        endedAt: json['ended_at'] == null
            ? null
            : DateTime.parse(json['ended_at'] as String),
      );
}

/// What the recent contractions add up to.
///
/// Interval is measured start-to-start, which is how the 5-1-1 guidance is
/// written: contractions five minutes apart means each one begins five
/// minutes after the last began, not five minutes after the last ended.
class ContractionPattern {
  const ContractionPattern({
    required this.count,
    required this.averageDuration,
    required this.averageInterval,
    required this.span,
  });

  const ContractionPattern.empty()
      : count = 0,
        averageDuration = null,
        averageInterval = null,
        span = Duration.zero;

  final int count;
  final Duration? averageDuration;
  final Duration? averageInterval;

  /// First start to last start within the analysed window - how long this
  /// pattern has been holding.
  final Duration span;

  /// How far back to look. Wider than an hour on purpose: the rule asks for a
  /// pattern that has *held* for an hour, which an exactly-one-hour window
  /// could never quite evidence.
  static const lookback = Duration(minutes: 75);

  static const intervalThreshold = Duration(minutes: 5);
  static const durationThreshold = Duration(seconds: 60);
  static const spanThreshold = Duration(minutes: 60);

  /// The 5-1-1 pattern: about five minutes apart, lasting about a minute
  /// each, holding for an hour.
  ///
  /// This is a widely taught rule of thumb for when to phone the hospital -
  /// it is not a diagnosis, and a provider's own instructions always win.
  bool get meets511 {
    final interval = averageInterval;
    final length = averageDuration;
    if (interval == null || length == null) return false;
    return interval <= intervalThreshold &&
        length >= durationThreshold &&
        span >= spanThreshold;
  }

  /// Reads [all] and summarises the contractions inside [lookback] of [now].
  ///
  /// Only finished contractions are counted - one still running has no
  /// duration yet, and including it would drag the average down.
  factory ContractionPattern.from(List<Contraction> all, DateTime now) {
    final cutoff = now.subtract(lookback);
    final recent = all
        .where((c) => !c.isRunning && c.startedAt.isAfter(cutoff))
        .toList()
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));

    if (recent.isEmpty) return const ContractionPattern.empty();

    final totalLength = recent.fold<int>(
      0,
      (sum, c) => sum + c.duration!.inMilliseconds,
    );

    Duration? averageInterval;
    if (recent.length >= 2) {
      var totalGap = 0;
      for (var i = 1; i < recent.length; i++) {
        totalGap +=
            recent[i].startedAt.difference(recent[i - 1].startedAt).inMilliseconds;
      }
      averageInterval =
          Duration(milliseconds: totalGap ~/ (recent.length - 1));
    }

    return ContractionPattern(
      count: recent.length,
      averageDuration: Duration(milliseconds: totalLength ~/ recent.length),
      averageInterval: averageInterval,
      span: recent.last.startedAt.difference(recent.first.startedAt),
    );
  }
}
