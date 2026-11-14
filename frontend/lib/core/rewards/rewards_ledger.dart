import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'reward_bus.dart';

/// A badge the user can earn. [tier] (0–3) picks the medal finish in the card view.
class BadgeDef {
  final String id;
  final String title;
  final String line;
  final IconData icon;
  final int tier;

  const BadgeDef(this.id, this.title, this.line, this.icon, {this.tier = 0});
}

abstract final class Badges {
  static const firstLight = BadgeDef('first_light', 'First Light', 'You opened your sanctuary for the very first time.', LucideIcons.sunrise, tier: 1);

  static const all = <BadgeDef>[
    firstLight,
    BadgeDef('first_note', 'First Ink', 'Your first note is on the page.', LucideIcons.penLine),
    BadgeDef('first_task', 'First Intention', 'Your first task is set.', LucideIcons.listTodo),
    BadgeDef('first_done', 'First Tick', 'Your first task, done.', LucideIcons.checkCheck),
    BadgeDef('first_event', 'First Appointment', 'Your first plan is on the calendar.', LucideIcons.calendarDays),
    BadgeDef('first_habit', 'First Ritual', 'Your first habit has begun.', LucideIcons.repeat),
    BadgeDef('first_journal', 'First Page', 'Your first journal entry is written.', LucideIcons.bookOpen),
    BadgeDef('first_expense', 'First Ledger', 'Your first expense is recorded.', LucideIcons.wallet),
    BadgeDef('first_trip', 'First Voyage', 'Your first trip is planned.', LucideIcons.plane),
    BadgeDef('first_outfit', 'First Look', 'Your first outfit is in the wardrobe.', LucideIcons.shirt),
    BadgeDef('first_pin', 'First Pin', 'Your first inspiration is pinned.', LucideIcons.pin),
    BadgeDef('first_shopping', 'First Wish', 'Your first item is on the list.', LucideIcons.shoppingBag),
    BadgeDef('goal_1', 'A Day Well Kept', 'You met your daily goal for the first time.', LucideIcons.target, tier: 1),
    BadgeDef('goal_7', 'Seven Good Days', 'Seven days with the daily goal met.', LucideIcons.award, tier: 2),
    BadgeDef('goal_30', 'Thirty Good Days', 'Thirty days with the daily goal met.', LucideIcons.trophy, tier: 3),
    BadgeDef('polymath', 'Polymath', 'Five different parts of the app, put to use.', LucideIcons.layers, tier: 2),
    BadgeDef('streak_3', 'Spark Ignited', 'Three days in a row.', LucideIcons.flame, tier: 1),
    BadgeDef('streak_7', 'Flame Keeper', 'A full week, unbroken.', LucideIcons.flame, tier: 2),
    BadgeDef('streak_14', 'Iron Will', 'Two weeks without a gap.', LucideIcons.shield, tier: 2),
    BadgeDef('streak_30', 'Sanctuary Master', 'A whole month, every day.', LucideIcons.crown, tier: 3),
    BadgeDef('streak_100', 'Centurion', 'One hundred days in a row.', LucideIcons.gem, tier: 3),
  ];

  static final Map<String, BadgeDef> _byId = {for (final b in all) b.id: b};
  static BadgeDef? byId(String id) => _byId[id];

  static const streakMilestones = [3, 7, 14, 30, 100];
  static const goalMilestones = [1, 7, 30];
}

/// The part of the app an action belongs to (completing a task is still "tasks").
String rewardFeature(RewardAction a) => switch (a) {
      RewardAction.taskDone => 'task',
      RewardAction.habitDone => 'habit',
      _ => a.name,
    };

/// The badge for doing [a] for the first time, if there is one.
String? firstBadgeFor(RewardAction a) => switch (a) {
      RewardAction.taskDone => 'first_done',
      RewardAction.habitDone => null,
      _ => 'first_${a.name}',
    };

/// Short past-tense label used in progress toasts, e.g. "Note saved".
String rewardActionLabel(RewardAction a) => switch (a) {
      RewardAction.note => 'Note saved',
      RewardAction.task => 'Task added',
      RewardAction.taskDone => 'Task completed',
      RewardAction.event => 'Plan added',
      RewardAction.habit => 'Habit started',
      RewardAction.habitDone => 'Habit kept',
      RewardAction.journal => 'Entry written',
      RewardAction.expense => 'Expense logged',
      RewardAction.trip => 'Trip planned',
      RewardAction.outfit => 'Look saved',
      RewardAction.pin => 'Pin added',
      RewardAction.shopping => 'Item listed',
    };

/// What recording one action changed.
class RewardOutcome {
  final RewardAction action;
  final int count;
  final int goal;
  final bool goalJustMet;
  final int goalDays;
  final List<BadgeDef> badges;

  const RewardOutcome({
    required this.action,
    required this.count,
    required this.goal,
    required this.goalJustMet,
    required this.goalDays,
    required this.badges,
  });
}

/// Read and update the rewards map stored in `AppSettings.rewards`.
///
/// Shape: `badges` {id: day earned}, `day`/`count` today's progress, `goalDays`,
/// `used` features ever touched, `welcomed`, `streakSeen` (last day the streak
/// screen was shown) and `v` (set once the map has been seeded).
class RewardsLedger {
  static const int dailyGoal = 3;

  final Map<String, dynamic> m;
  const RewardsLedger(this.m);

  static String dayKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  bool get seeded => m['v'] != null;
  bool get welcomed => m['welcomed'] == true;
  String get streakSeen => m['streakSeen'] as String? ?? '';
  int get goalDays => (m['goalDays'] as num?)?.toInt() ?? 0;
  Map<String, String> get badges => ((m['badges'] as Map?) ?? const {}).map((k, v) => MapEntry('$k', '$v'));
  Set<String> get used => ((m['used'] as List?) ?? const []).map((e) => '$e').toSet();
  bool has(String id) => badges.containsKey(id);

  /// Actions recorded on [day] (zero once the day has rolled over).
  int countOn(String day) => m['day'] == day ? (m['count'] as num?)?.toInt() ?? 0 : 0;

  List<BadgeDef> get earned => [for (final b in Badges.all) if (has(b.id)) b];

  /// First run after this feature ships: an existing user is not welcomed again, and
  /// keeps badges for what they have already done, so nothing fires for old work.
  static Map<String, dynamic> seed(
    Map<String, dynamic> m, {
    required bool newUser,
    required Set<RewardAction> alreadyUsed,
    required int milestoneReached,
    required DateTime now,
  }) {
    if (m['v'] != null) return m;
    final today = dayKey(now);
    final badges = <String, String>{...RewardsLedger(m).badges};
    if (!newUser) badges[Badges.firstLight.id] = today;
    for (final a in alreadyUsed) {
      final id = firstBadgeFor(a);
      if (id != null) badges.putIfAbsent(id, () => today);
    }
    for (final s in Badges.streakMilestones) {
      if (s <= milestoneReached) badges.putIfAbsent('streak_$s', () => today);
    }
    return {
      ...m,
      'v': 1,
      'welcomed': m['welcomed'] == true || !newUser,
      'badges': badges,
      'used': {...RewardsLedger(m).used, ...alreadyUsed.map(rewardFeature)}.toList(),
    };
  }

  /// Counts [a] toward today's goal and awards any badges it unlocks.
  static (Map<String, dynamic>, RewardOutcome) record(Map<String, dynamic> m, RewardAction a, DateTime now) {
    final ledger = RewardsLedger(m);
    final today = dayKey(now);
    final count = ledger.countOn(today) + 1;
    final badges = {...ledger.badges};
    final used = {...ledger.used, rewardFeature(a)};
    final fresh = <BadgeDef>[];

    void award(String id) {
      if (badges.containsKey(id)) return;
      final def = Badges.byId(id);
      if (def == null) return;
      badges[id] = today;
      fresh.add(def);
    }

    final first = firstBadgeFor(a);
    if (first != null) award(first);
    if (used.length >= 5) award('polymath');

    final goalJustMet = count == dailyGoal;
    var goalDays = ledger.goalDays;
    if (goalJustMet) {
      goalDays++;
      for (final g in Badges.goalMilestones) {
        if (goalDays >= g) award('goal_$g');
      }
    }

    final next = {
      ...m,
      'day': today,
      'count': count,
      'goalDays': goalDays,
      'badges': badges,
      'used': used.toList(),
    };
    return (
      next,
      RewardOutcome(action: a, count: count, goal: dailyGoal, goalJustMet: goalJustMet, goalDays: goalDays, badges: fresh),
    );
  }

  /// Awards streak badges up to [streak]; returns the map and the badges that are new.
  static (Map<String, dynamic>, List<BadgeDef>) awardStreak(Map<String, dynamic> m, int streak, DateTime now) {
    final badges = {...RewardsLedger(m).badges};
    final fresh = <BadgeDef>[];
    for (final s in Badges.streakMilestones) {
      final id = 'streak_$s';
      if (streak >= s && !badges.containsKey(id)) {
        badges[id] = dayKey(now);
        fresh.add(Badges.byId(id)!);
      }
    }
    return ({...m, 'badges': badges}, fresh);
  }

  /// Folds two copies of the map (this device and the synced row) together: badges and
  /// features are united, counters keep the higher value, flags stay set once set.
  static Map<String, dynamic> merge(Map? a, Map? b) {
    final x = (a ?? const {}).map((k, v) => MapEntry('$k', v));
    final y = (b ?? const {}).map((k, v) => MapEntry('$k', v));
    if (x.isEmpty) return y;
    if (y.isEmpty) return x;
    final lx = RewardsLedger(x), ly = RewardsLedger(y);
    final badges = {...ly.badges};
    lx.badges.forEach((id, day) {
      final other = badges[id];
      if (other == null || day.compareTo(other) < 0) badges[id] = day;
    });
    String later(String p, String q) => p.compareTo(q) >= 0 ? p : q;
    final dx = x['day'] as String? ?? '', dy = y['day'] as String? ?? '';
    final day = later(dx, dy);
    final count = [if (dx == day) lx.countOn(day), if (dy == day) ly.countOn(day)].fold(0, (p, q) => p > q ? p : q);
    return {
      ...y,
      ...x,
      'v': x['v'] ?? y['v'],
      'welcomed': lx.welcomed || ly.welcomed,
      'streakSeen': later(lx.streakSeen, ly.streakSeen),
      'goalDays': lx.goalDays > ly.goalDays ? lx.goalDays : ly.goalDays,
      'day': day,
      'count': count,
      'badges': badges,
      'used': {...lx.used, ...ly.used}.toList(),
    };
  }
}
