import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pregnancy_ai_assistant/models/contraction.dart';
import 'package:pregnancy_ai_assistant/models/kick_session.dart';
import 'package:pregnancy_ai_assistant/services/contraction_controller.dart';
import 'package:pregnancy_ai_assistant/services/kick_controller.dart';
import 'package:pregnancy_ai_assistant/services/local_storage_service.dart';
import 'package:pregnancy_ai_assistant/utils/duration_format.dart';

/// Builds a run of contractions ending at [now], spaced [apart] start-to-start
/// and each lasting [length].
List<Contraction> _run({
  required DateTime now,
  required int count,
  required Duration apart,
  required Duration length,
}) {
  final out = <Contraction>[];
  for (var i = 0; i < count; i++) {
    // The oldest is (count - 1) intervals back from now.
    final start = now.subtract(apart * (count - 1 - i));
    out.add(Contraction(
      id: '$i',
      startedAt: start,
      endedAt: start.add(length),
    ));
  }
  return out;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('formatClock', () {
    test('pads seconds and drops the hour until it is needed', () {
      expect(formatClock(const Duration(seconds: 9)), '0:09');
      expect(formatClock(const Duration(minutes: 9, seconds: 5)), '9:05');
      expect(formatClock(const Duration(minutes: 75)), '1:15:00');
    });

    test('never renders a negative clock', () {
      expect(formatClock(const Duration(seconds: -30)), '0:00');
    });
  });

  group('formatApprox', () {
    test('switches units as the duration grows', () {
      expect(formatApprox(const Duration(seconds: 48)), '48 sec');
      expect(formatApprox(const Duration(minutes: 12)), '12 min');
      expect(formatApprox(const Duration(minutes: 60)), '1 hr');
      expect(formatApprox(const Duration(minutes: 65)), '1 hr 5 min');
    });
  });

  group('KickSession', () {
    final start = DateTime(2026, 3, 2, 20);

    KickSession sessionWith(int count, Duration spacing) {
      var session = KickSession(id: 'k', startedAt: start, kicks: const []);
      for (var i = 1; i <= count; i++) {
        session = session.withKickAt(start.add(spacing * i));
      }
      return session;
    }

    test('completes on the tenth movement, not the eleventh', () {
      expect(sessionWith(9, const Duration(minutes: 1)).isComplete, isFalse);
      expect(sessionWith(10, const Duration(minutes: 1)).isComplete, isTrue);
    });

    test('duration is measured to the tenth kick', () {
      final session = sessionWith(10, const Duration(minutes: 3));
      expect(session.duration, const Duration(minutes: 30));
    });

    test('extra movements past ten do not extend the duration', () {
      final session = sessionWith(12, const Duration(minutes: 3));
      expect(session.count, 12);
      expect(session.duration, const Duration(minutes: 30));
    });

    test('flags a count that took longer than two hours', () {
      expect(sessionWith(10, const Duration(minutes: 5)).tookLongerThanUsual,
          isFalse);
      expect(sessionWith(10, const Duration(minutes: 20)).tookLongerThanUsual,
          isTrue);
    });

    test('an unfinished session reports the last kick, not the wall clock', () {
      final session = sessionWith(4, const Duration(minutes: 2));
      expect(session.duration, const Duration(minutes: 8));
    });

    test('survives a round trip through JSON', () {
      final session = sessionWith(3, const Duration(minutes: 2));
      final restored = KickSession.fromJson(session.toJson());
      expect(restored.id, session.id);
      expect(restored.startedAt, session.startedAt);
      expect(restored.kicks, session.kicks);
    });
  });

  group('ContractionPattern', () {
    final now = DateTime(2026, 3, 2, 23);

    test('is empty with nothing recorded', () {
      final pattern = ContractionPattern.from(const [], now);
      expect(pattern.count, 0);
      expect(pattern.meets511, isFalse);
    });

    test('measures interval start-to-start, not end-to-start', () {
      final pattern = ContractionPattern.from(
        _run(
          now: now,
          count: 3,
          apart: const Duration(minutes: 5),
          length: const Duration(seconds: 60),
        ),
        now,
      );
      expect(pattern.averageInterval, const Duration(minutes: 5));
      expect(pattern.averageDuration, const Duration(seconds: 60));
    });

    test('meets 5-1-1 for an hour of five-minute, one-minute contractions', () {
      // 13 contractions five minutes apart spans a full hour.
      final pattern = ContractionPattern.from(
        _run(
          now: now,
          count: 13,
          apart: const Duration(minutes: 5),
          length: const Duration(seconds: 65),
        ),
        now,
      );
      expect(pattern.span, const Duration(minutes: 60));
      expect(pattern.meets511, isTrue);
    });

    test('does not fire when the pattern is too young', () {
      // The right spacing and length, but only twenty minutes of it.
      final pattern = ContractionPattern.from(
        _run(
          now: now,
          count: 5,
          apart: const Duration(minutes: 5),
          length: const Duration(seconds: 65),
        ),
        now,
      );
      expect(pattern.count, 5);
      expect(pattern.meets511, isFalse);
    });

    test('does not fire when contractions are too far apart', () {
      final pattern = ContractionPattern.from(
        _run(
          now: now,
          count: 9,
          apart: const Duration(minutes: 8),
          length: const Duration(seconds: 65),
        ),
        now,
      );
      expect(pattern.span, const Duration(minutes: 64));
      expect(pattern.meets511, isFalse);
    });

    test('does not fire when contractions are too short', () {
      final pattern = ContractionPattern.from(
        _run(
          now: now,
          count: 13,
          apart: const Duration(minutes: 5),
          length: const Duration(seconds: 30),
        ),
        now,
      );
      expect(pattern.meets511, isFalse);
    });

    test('ignores contractions older than the lookback window', () {
      final old = _run(
        now: now.subtract(const Duration(hours: 6)),
        count: 13,
        apart: const Duration(minutes: 5),
        length: const Duration(seconds: 65),
      );
      final pattern = ContractionPattern.from(old, now);
      expect(pattern.count, 0);
      expect(pattern.meets511, isFalse);
    });

    test('a running contraction is left out of the averages', () {
      final finished = _run(
        now: now.subtract(const Duration(minutes: 5)),
        count: 3,
        apart: const Duration(minutes: 5),
        length: const Duration(seconds: 60),
      );
      final pattern = ContractionPattern.from(
        [...finished, Contraction(id: 'live', startedAt: now)],
        now,
      );
      expect(pattern.count, 3);
      expect(pattern.averageDuration, const Duration(seconds: 60));
    });
  });

  group('KickController', () {
    test('records movements and stops itself at ten', () async {
      final controller = KickController(LocalStorageService());
      await controller.load();

      await controller.start();
      expect(controller.isCounting, isTrue);

      for (var i = 0; i < 10; i++) {
        await controller.recordKick();
      }

      expect(controller.isCounting, isFalse);
      expect(controller.lastCompleted?.count, 10);
    });

    test('start is a no-op while a count is already open', () async {
      final controller = KickController(LocalStorageService());
      await controller.load();

      await controller.start();
      final id = controller.active!.id;
      await controller.start();

      expect(controller.active!.id, id);
      expect(controller.sessions.length, 1);
    });

    test('stopping an empty count discards it rather than saving a zero',
        () async {
      final controller = KickController(LocalStorageService());
      await controller.load();

      await controller.start();
      await controller.stop();

      expect(controller.sessions, isEmpty);
    });

    test('stopping a partial count keeps what was recorded', () async {
      final controller = KickController(LocalStorageService());
      await controller.load();

      await controller.start();
      await controller.recordKick();
      await controller.recordKick();
      await controller.stop();

      expect(controller.isCounting, isFalse);
      expect(controller.sessions.single.count, 2);
    });

    test('an interrupted count is resumed on reload', () async {
      final storage = LocalStorageService();
      final first = KickController(storage);
      await first.load();
      await first.start();
      await first.recordKick();

      final second = KickController(storage);
      await second.load();

      expect(second.isCounting, isTrue);
      expect(second.active!.count, 1);
    });

    test('a stale count is loaded as history, not resumed', () async {
      final storage = LocalStorageService();
      final stale = KickSession(
        id: 'old',
        startedAt: DateTime.now().subtract(const Duration(hours: 5)),
        kicks: [DateTime.now().subtract(const Duration(hours: 5))],
      );
      await storage.saveKickSessions([stale]);

      final controller = KickController(storage);
      await controller.load();

      expect(controller.isCounting, isFalse);
      expect(controller.sessions.length, 1);
    });
  });

  group('ContractionController', () {
    test('start then stop produces one finished contraction', () async {
      final controller = ContractionController(LocalStorageService());
      await controller.load();

      await controller.start();
      expect(controller.isTiming, isTrue);
      await controller.stop();

      expect(controller.isTiming, isFalse);
      expect(controller.contractions.single.duration, isNotNull);
    });

    test('start is ignored while one is already running', () async {
      final controller = ContractionController(LocalStorageService());
      await controller.load();

      await controller.start();
      await controller.start();

      expect(controller.contractions.length, 1);
    });

    test('a finished contraction reloads with its timing intact', () async {
      final storage = LocalStorageService();
      final first = ContractionController(storage);
      await first.load();
      await first.start();
      await first.stop();

      final second = ContractionController(storage);
      await second.load();

      expect(second.contractions.length, 1);
      expect(second.contractions.single.isRunning, isFalse);
    });

    test('a contraction left running overnight is dropped on load', () async {
      final storage = LocalStorageService();
      await storage.saveContractions([
        Contraction(
          id: 'stuck',
          startedAt: DateTime.now().subtract(const Duration(hours: 9)),
        ),
      ]);

      final controller = ContractionController(storage);
      await controller.load();

      expect(controller.contractions, isEmpty);
      expect(controller.isTiming, isFalse);
    });

    test('clear empties the log', () async {
      final controller = ContractionController(LocalStorageService());
      await controller.load();
      await controller.start();
      await controller.stop();

      await controller.clear();

      expect(controller.contractions, isEmpty);
    });
  });
}
