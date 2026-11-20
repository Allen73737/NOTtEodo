import 'package:flutter_test/flutter_test.dart';
import 'package:notteodo/core/rewards/reward_bus.dart';
import 'package:notteodo/core/rewards/rewards_ledger.dart';
import 'package:notteodo/core/rewards/weekly_recap.dart';
import 'package:notteodo/core/services/nudge_planner.dart';
import 'package:notteodo/core/state/sanctuary_state.dart';

void main() {
  // Sunday 22 Nov 2026.
  final sunday = DateTime(2026, 11, 22, 18);

  group('streak history', () {
    test('the first mark fills in the run already going', () {
      final m = RewardsLedger.markActive({}, sunday, streak: 4);
      expect(RewardsLedger(m).activeDays, {'2026-11-19', '2026-11-20', '2026-11-21', '2026-11-22'});
      expect(RewardsLedger.markActive(m, sunday, streak: 4), same(m));
    });

    test('a freeze covers the days in between', () {
      final m = RewardsLedger.cover({}, '2026-11-18', sunday);
      expect(RewardsLedger(m).frozenDays, {'2026-11-19', '2026-11-20', '2026-11-21'});
    });
  });

  group('streak repair', () {
    test('doing six things on the day it broke wins it back, once a month', () {
      var m = RewardsLedger.noteBreak({}, streak: 12, lastActive: '2026-11-19', now: sunday);
      expect(RewardsLedger(m).repairOffer('2026-11-22'), 12);
      RewardOutcome? o;
      final seen = <int?>[];
      for (var i = 0; i < RewardsLedger.repairActions; i++) {
        (m, o) = RewardsLedger.record(m, RewardAction.note, sunday);
        seen.add(o.repairLost);
      }
      expect(seen.first, 12, reason: 'progress shows what can be won back');
      expect(o!.repaired, 12);
      final l = RewardsLedger(m);
      expect(l.repairOffer('2026-11-22'), isNull);
      expect(l.frozenDays, containsAll(['2026-11-20', '2026-11-21']));
      // A second break in the same month gets no offer.
      final again = RewardsLedger.noteBreak(m, streak: 5, lastActive: '2026-11-24', now: DateTime(2026, 11, 26));
      expect(RewardsLedger(again).repairOffer('2026-11-26'), isNull);
    });

    test('short runs are not offered a repair', () {
      final m = RewardsLedger.noteBreak({}, streak: 2, lastActive: '2026-11-19', now: sunday);
      expect(RewardsLedger(m).repairOffer('2026-11-22'), isNull);
    });

    test('notifications push for the repair while it is open', () {
      final d = DayPicture(day: DateTime(2026, 11, 22), active: true, goalCount: 2, repairLost: 12);
      final slots = [for (final h in [9, 12, 15, 18, 21]) DateTime(2026, 11, 22, h, 30)];
      final plan = NudgePlanner.forDay(d, const NudgeContext(streak: 1), slots);
      expect(plan[1].title, 'Win back your 12-day streak');
      expect(plan.last.title, 'Last chance for your 12-day streak');
    });
  });

  test('the weekly recap counts the last seven days against the seven before', () {
    final tasks = [
      for (var i = 0; i < 4; i++) TaskItem(id: 't$i', title: 'T$i', priority: 'Low', space: 'Life', timeOfDay: 'Later', completed: true, completedAt: sunday.subtract(Duration(days: i))),
      TaskItem(id: 'old', title: 'Old', priority: 'Low', space: 'Life', timeOfDay: 'Later', completed: true, completedAt: sunday.subtract(const Duration(days: 9))),
    ];
    final habits = [HabitItem(id: 'h', title: 'Read', time: '9:00 PM', completedDays: {'2026-11-21', '2026-11-22', '2026-11-10'})];
    final r = WeeklyRecap.compute(
      now: sunday,
      tasks: tasks,
      habits: habits,
      journal: const [],
      notes: const [],
      expenses: const [],
      ledger: RewardsLedger(RewardsLedger.markActive({}, sunday, streak: 3)),
    );
    expect(r.week.tasksDone, 4);
    expect(r.last.tasksDone, 1);
    expect(r.week.habitsKept, 2);
    expect(r.week.activeDays, 3);
    expect(r.headline, '4 tasks done and habits kept 2 times. More than last week.');
    final n = NudgePlanner.weekly(NudgeContext(weekHeadline: r.headline), DateTime(2026, 11, 22, 21, 30))!;
    expect(n.at.hour, 20);
    expect(n.target, 'recap');
  });

  test('habit reminders come at each habit\'s own time, only while pending', () {
    final now = DateTime(2026, 11, 22, 8);
    final plan = NudgePlanner.habitReminders([
      const HabitCue(id: 'a', title: 'Stretch', hour: 7, minute: 0, pending: {0, 1}),
      const HabitCue(id: 'b', title: 'Read', hour: 21, minute: 0, streak: 9, pending: {0}),
    ], now);
    expect(plan.map((n) => n.toString()), [
      contains('Sun 21:00  Time for Read'),
      contains('Mon 07:00  Time for Stretch'),
    ]);
    expect(plan.first.body, contains('Day 10'));
  });

  test('Nodo\'s morning line replaces the plain agenda', () {
    final d = DayPicture(day: DateTime(2026, 11, 22), due: const [('File taxes', null)], morningLine: 'Taxes first, then a quiet Sunday.');
    final n = NudgePlanner.forDay(d, const NudgeContext(name: 'Ana'), [DateTime(2026, 11, 22, 9, 30)]).single;
    expect(n.body, 'Taxes first, then a quiet Sunday.');
    expect(n.title, contains('Ana'));
  });
}
