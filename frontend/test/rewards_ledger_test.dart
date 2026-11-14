import 'package:flutter_test/flutter_test.dart';
import 'package:notteodo/core/rewards/reward_bus.dart';
import 'package:notteodo/core/rewards/reward_ceremony.dart';
import 'package:notteodo/core/rewards/rewards_ledger.dart';

void main() {
  final day1 = DateTime(2026, 11, 14, 9);
  final day2 = DateTime(2026, 11, 15, 9);

  group('seed', () {
    test('a new user is not welcomed yet and has no badges', () {
      final m = RewardsLedger.seed({}, newUser: true, alreadyUsed: {}, milestoneReached: 0, now: day1);
      final l = RewardsLedger(m);
      expect(l.seeded, isTrue);
      expect(l.welcomed, isFalse);
      expect(l.badges, isEmpty);
    });

    test('an existing user keeps badges for past work and is not welcomed again', () {
      final m = RewardsLedger.seed(
        {},
        newUser: false,
        alreadyUsed: {RewardAction.note, RewardAction.taskDone},
        milestoneReached: 7,
        now: day1,
      );
      final l = RewardsLedger(m);
      expect(l.welcomed, isTrue);
      expect(l.badges.keys, containsAll(['first_light', 'first_note', 'first_done', 'streak_3', 'streak_7']));
      expect(l.has('streak_14'), isFalse);
      expect(l.used, containsAll(['note', 'task']));
    });

    test('seeding twice changes nothing', () {
      final once = RewardsLedger.seed({}, newUser: true, alreadyUsed: {}, milestoneReached: 0, now: day1);
      final twice = RewardsLedger.seed(once, newUser: false, alreadyUsed: {RewardAction.pin}, milestoneReached: 30, now: day1);
      expect(twice, same(once));
    });
  });

  group('record', () {
    test('first action of a kind earns its badge once', () {
      var (m, o) = RewardsLedger.record({}, RewardAction.note, day1);
      expect(o.badges.map((b) => b.id), ['first_note']);
      (m, o) = RewardsLedger.record(m, RewardAction.note, day1);
      expect(o.badges, isEmpty);
    });

    test('the third action of the day meets the goal exactly once', () {
      var m = <String, dynamic>{};
      final outcomes = <RewardOutcome>[];
      for (final a in [RewardAction.task, RewardAction.taskDone, RewardAction.note, RewardAction.note]) {
        final (next, o) = RewardsLedger.record(m, a, day1);
        m = next;
        outcomes.add(o);
      }
      expect(outcomes.map((o) => o.count), [1, 2, 3, 4]);
      expect(outcomes.map((o) => o.goalJustMet), [false, false, true, false]);
      expect(outcomes[2].badges.map((b) => b.id), contains('goal_1'));
      expect(RewardsLedger(m).goalDays, 1);
    });

    test('the count starts over on a new day', () {
      final (m, _) = RewardsLedger.record({}, RewardAction.note, day1);
      final (_, o) = RewardsLedger.record(m, RewardAction.note, day2);
      expect(o.count, 1);
    });

    test('five different features earn Polymath', () {
      var m = <String, dynamic>{};
      RewardOutcome? last;
      for (final a in [RewardAction.note, RewardAction.task, RewardAction.taskDone, RewardAction.event, RewardAction.pin, RewardAction.trip]) {
        final (next, o) = RewardsLedger.record(m, a, day1);
        m = next;
        last = o;
        if (o.badges.any((b) => b.id == 'polymath')) break;
      }
      expect(last!.action, RewardAction.trip, reason: 'taskDone counts as the same feature as task');
    });
  });

  test('streak badges are awarded up to the current streak, once', () {
    var (m, fresh) = RewardsLedger.awardStreak({}, 8, day1);
    expect(fresh.map((b) => b.id), ['streak_3', 'streak_7']);
    (m, fresh) = RewardsLedger.awardStreak(m, 9, day1);
    expect(fresh, isEmpty);
  });

  test('merge unites badges and keeps the furthest progress', () {
    final a = {
      'v': 1,
      'welcomed': true,
      'badges': {'first_note': '2026-11-10'},
      'day': '2026-11-14',
      'count': 2,
      'goalDays': 3,
      'streakSeen': '2026-11-14',
      'used': ['note'],
    };
    final b = {
      'v': 1,
      'welcomed': false,
      'badges': {'first_note': '2026-11-12', 'first_task': '2026-11-13'},
      'day': '2026-11-13',
      'count': 5,
      'goalDays': 4,
      'streakSeen': '2026-11-13',
      'used': ['task'],
    };
    final l = RewardsLedger(RewardsLedger.merge(a, b));
    expect(l.badges, {'first_note': '2026-11-10', 'first_task': '2026-11-13'});
    expect(l.welcomed, isTrue);
    expect(l.goalDays, 4);
    expect(l.streakSeen, '2026-11-14');
    expect(l.countOn('2026-11-14'), 2);
    expect(l.used, {'note', 'task'});
  });

  group('streak moment', () {
    test('lights the last days of the streak up to today', () {
      // Saturday 14 Nov 2026, weeks starting Monday, a 3-day streak: Thu, Fri, Sat.
      final m = StreakMoment.of(streak: 3, longest: 3, firstDay: false, freezeUsed: false, freezesLeft: 0, firstDayOfWeek: 1, now: day1);
      expect(m.todayIndex, 5);
      expect(m.week, [false, false, false, true, true, true, false]);
      expect(m.weekLetters.first, 'M');
    });

    test('a lapsed streak reads as a restart', () {
      final m = StreakMoment.of(streak: 1, longest: 12, firstDay: false, freezeUsed: false, freezesLeft: 0, firstDayOfWeek: 7, now: day1);
      expect(m.restarted, isTrue);
      expect(m.weekLetters.first, 'S');
      expect(m.line, contains('12 days'));
    });
  });

  test('assistant work runs quietly', () async {
    final seen = <RewardAction>[];
    final sub = RewardBus.stream.listen(seen.add);
    RewardBus.quietly(() => RewardBus.emit(RewardAction.note));
    RewardBus.emit(RewardAction.task);
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    expect(seen, [RewardAction.task]);
  });
}
