import 'package:flutter_test/flutter_test.dart';
import 'package:notteodo/core/services/daily_engagement_service.dart';
import 'package:notteodo/core/services/nudge_planner.dart';

void main() {
  // Friday 20 Nov 2026.
  DateTime at(int h, [int m = 0, int day = 20]) => DateTime(2026, 11, day, h, m);
  final slots = [at(9, 30), at(12, 30), at(15, 30), at(18, 30), at(21, 30)];
  const ana = NudgeContext(name: 'Ana', streak: 12, freezes: 1, currency: '€');

  test('the morning lists the real agenda', () {
    final d = DayPicture(
      day: at(0),
      active: true,
      due: [('File taxes', null), ('Send invoice', at(15))],
      overdue: ['Call landlord'],
      habitsLeft: ['Read', 'Stretch'],
      events: [('Standup', at(10))],
    );
    final morning = NudgePlanner.forDay(d, ana, slots).first;
    expect(morning.title, contains('Ana'));
    expect(morning.body, contains('Standup at 10:00'));
    expect(morning.body, contains('2 tasks due, starting with “File taxes”'));
    expect(morning.body, contains('1 overdue'));
    expect(morning.body, contains('2 habits'));
    expect(morning.target, 'tasks');
  });

  test('daytime slots cover different things, most pressing first', () {
    final d = DayPicture(
      day: at(0),
      active: true,
      goalCount: 1,
      overdue: ['Call landlord'],
      due: [('File taxes', null)],
      habitsLeft: ['Read'],
      habitAtRisk: 'Read',
      habitAtRiskStreak: 9,
    );
    final plan = NudgePlanner.forDay(d, ana, slots);
    expect(plan[1].title, '“Call landlord” is overdue');
    expect(plan[2].title, '“File taxes” is due today');
    expect(plan[3].title, 'Keep your 9-day Read run');
    expect(plan.map((n) => n.title).toSet().length, plan.length, reason: 'no repeats');
  });

  test('a day already kept never warns about the streak', () {
    final d = DayPicture(day: at(0), active: true, goalCount: 4);
    final plan = NudgePlanner.forDay(d, ana, slots);
    expect(plan.any((n) => n.tag == 'Streak'), isFalse);
    expect(plan.last.title, 'Day 12, kept');
  });

  test('a day not yet opened guards the streak in the evening', () {
    final d = DayPicture(day: at(0, 0, 21), due: [('Dentist forms', null)]);
    final plan = NudgePlanner.forDay(d, ana, [for (final s in slots) s.add(const Duration(days: 1))]);
    expect(plan.where((n) => n.title == 'Keep your 12-day streak'), hasLength(1));
    expect(plan.last.title, 'Your 12-day streak ends at midnight');
    expect(plan.last.body, contains('only 1'));
  });

  test('quiet days stay quiet instead of sending filler', () {
    final d = DayPicture(day: at(0), active: true, goalCount: 3, journaled: true);
    final plan = NudgePlanner.forDay(d, const NudgeContext(streak: 4), slots);
    expect(plan.length, 2, reason: 'just the morning and the evening');
  });

  test('budget and nearly earned badges get a word when they matter', () {
    final d = DayPicture(day: at(0), active: true, goalCount: 3, journaled: true);
    const c = NudgeContext(streak: 4, budget: 500, monthSpend: 460, currency: '€', nextBadge: ('Ten Pages', 8, 10));
    final titles = NudgePlanner.forDay(d, c, slots).map((n) => n.title).toList();
    expect(titles, contains('92% of your monthly budget used'));
    expect(titles, contains('2 more to earn “Ten Pages”'));
  });

  test('the plan covers the rest of today, tomorrow and one word after', () {
    final now = at(13);
    final plan = DailyEngagementService.personalPlan(
      now: now,
      see: (day) => (DayPicture(day: day, active: day.day == 20, goalCount: day.day == 20 ? 1 : 0), ana),
      cadenceHours: 3,
      morningTimeStr: '09:30',
      eveningTimeStr: '21:30',
    );
    expect(plan.every((n) => n.at.isAfter(now)), isTrue);
    expect(plan.where((n) => n.at.day == 20).any((n) => n.tag == 'Streak'), isFalse);
    expect(plan.where((n) => n.at.day == 21).any((n) => n.title == 'Your 12-day streak ends at midnight'), isTrue);
    expect(plan.last.at.day, 22);
    expect(plan.last.title, contains('streak freeze'));
  });
}
