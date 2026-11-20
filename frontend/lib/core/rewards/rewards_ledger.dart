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

  /// What the badge counts toward when it is earned by reaching [goal]: an action name
  /// (lifetime total), `streak`, `goalDays`, `features` or `habitStreak`. Null for
  /// badges earned by a single moment.
  final String? metric;
  final int goal;

  const BadgeDef(this.id, this.title, this.line, this.icon, {this.tier = 0, this.metric, this.goal = 0});
}

abstract final class Badges {
  static const firstLight = BadgeDef('first_light', 'First Light', 'You opened your sanctuary for the very first time.', LucideIcons.sunrise, tier: 1);
  static const comeback = BadgeDef('comeback', 'The Comeback', 'You came back after a break. That is the hardest part.', LucideIcons.rotateCcw, tier: 1);
  static const iceShield = BadgeDef('ice_shield', 'Ice Shield', 'A streak freeze kept your streak alive.', LucideIcons.snowflake, tier: 1);

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
    // Daily goal
    BadgeDef('goal_1', 'A Day Well Kept', 'You met your daily goal for the first time.', LucideIcons.target, tier: 1, metric: 'goalDays', goal: 1),
    BadgeDef('goal_7', 'Seven Good Days', 'Seven days with the daily goal met.', LucideIcons.award, tier: 2, metric: 'goalDays', goal: 7),
    BadgeDef('goal_30', 'Thirty Good Days', 'Thirty days with the daily goal met.', LucideIcons.trophy, tier: 3, metric: 'goalDays', goal: 30),
    BadgeDef('goal_100', 'Hundred Good Days', 'One hundred days with the daily goal met.', LucideIcons.medal, tier: 3, metric: 'goalDays', goal: 100),
    // Breadth
    BadgeDef('polymath', 'Polymath', 'Five different parts of the app, put to use.', LucideIcons.layers, tier: 2, metric: 'features', goal: 5),
    BadgeDef('renaissance', 'Renaissance', 'Every part of the app, put to use.', LucideIcons.sparkles, tier: 3, metric: 'features', goal: 10),
    // Day streak
    BadgeDef('streak_3', 'Spark Ignited', 'Three days in a row.', LucideIcons.flame, tier: 1, metric: 'streak', goal: 3),
    BadgeDef('streak_7', 'Flame Keeper', 'A full week, unbroken.', LucideIcons.flame, tier: 2, metric: 'streak', goal: 7),
    BadgeDef('streak_14', 'Iron Will', 'Two weeks without a gap.', LucideIcons.shield, tier: 2, metric: 'streak', goal: 14),
    BadgeDef('streak_30', 'Sanctuary Master', 'A whole month, every day.', LucideIcons.crown, tier: 3, metric: 'streak', goal: 30),
    BadgeDef('streak_50', 'Half-Century', 'Fifty days in a row.', LucideIcons.star, tier: 3, metric: 'streak', goal: 50),
    BadgeDef('streak_100', 'Centurion', 'One hundred days in a row.', LucideIcons.gem, tier: 3, metric: 'streak', goal: 100),
    BadgeDef('streak_200', 'Evergreen', 'Two hundred days in a row.', LucideIcons.infinity, tier: 3, metric: 'streak', goal: 200),
    BadgeDef('streak_365', 'A Year Unbroken', 'Every day for a whole year.', LucideIcons.sunMoon, tier: 3, metric: 'streak', goal: 365),
    comeback,
    iceShield,
    // Notes
    BadgeDef('notes_10', 'Ten Pages', 'Ten notes written.', LucideIcons.notebookPen, tier: 1, metric: 'note', goal: 10),
    BadgeDef('notes_50', 'Full Notebook', 'Fifty notes written.', LucideIcons.library, tier: 2, metric: 'note', goal: 50),
    BadgeDef('notes_250', 'Archivist', 'Two hundred and fifty notes written.', LucideIcons.archive, tier: 3, metric: 'note', goal: 250),
    // Tasks
    BadgeDef('done_10', 'Momentum', 'Ten tasks done.', LucideIcons.listChecks, tier: 1, metric: 'taskDone', goal: 10),
    BadgeDef('done_50', 'Closer', 'Fifty tasks done.', LucideIcons.zap, tier: 2, metric: 'taskDone', goal: 50),
    BadgeDef('done_250', 'Unstoppable', 'Two hundred and fifty tasks done.', LucideIcons.rocket, tier: 3, metric: 'taskDone', goal: 250),
    BadgeDef('done_1000', 'Summit', 'A thousand tasks done.', LucideIcons.mountain, tier: 3, metric: 'taskDone', goal: 1000),
    // Habits
    BadgeDef('kept_10', 'Ritual Keeper', 'Habits kept ten times.', LucideIcons.sprout, tier: 1, metric: 'habitDone', goal: 10),
    BadgeDef('kept_50', 'Second Nature', 'Habits kept fifty times.', LucideIcons.trees, tier: 2, metric: 'habitDone', goal: 50),
    BadgeDef('kept_250', 'Iron Routine', 'Habits kept two hundred and fifty times.', LucideIcons.anchor, tier: 3, metric: 'habitDone', goal: 250),
    BadgeDef('habit_streak_7', 'Steady Hand', 'One habit kept seven days running.', LucideIcons.repeat, tier: 1, metric: 'habitStreak', goal: 7),
    BadgeDef('habit_streak_30', 'Rooted', 'One habit kept thirty days running.', LucideIcons.trees, tier: 3, metric: 'habitStreak', goal: 30),
    // Journal
    BadgeDef('journal_7', 'A Week in Words', 'Seven journal entries.', LucideIcons.feather, tier: 1, metric: 'journal', goal: 7),
    BadgeDef('journal_30', 'A Month of Pages', 'Thirty journal entries.', LucideIcons.scrollText, tier: 2, metric: 'journal', goal: 30),
    BadgeDef('journal_100', 'Memoirist', 'One hundred journal entries.', LucideIcons.bookMarked, tier: 3, metric: 'journal', goal: 100),
    // Money, plans and the rest
    BadgeDef('expense_25', 'Bookkeeper', 'Twenty-five expenses logged.', LucideIcons.receipt, tier: 1, metric: 'expense', goal: 25),
    BadgeDef('expense_100', 'Treasurer', 'One hundred expenses logged.', LucideIcons.landmark, tier: 2, metric: 'expense', goal: 100),
    BadgeDef('event_10', 'Planner', 'Ten plans on the calendar.', LucideIcons.calendarCheck, tier: 1, metric: 'event', goal: 10),
    BadgeDef('event_50', 'Keeper of Time', 'Fifty plans on the calendar.', LucideIcons.hourglass, tier: 2, metric: 'event', goal: 50),
    BadgeDef('trip_3', 'Globetrotter', 'Three trips planned.', LucideIcons.globe, tier: 2, metric: 'trip', goal: 3),
    BadgeDef('outfit_10', 'Stylist', 'Ten looks in the wardrobe.', LucideIcons.shirt, tier: 1, metric: 'outfit', goal: 10),
    BadgeDef('pin_25', "Curator's Eye", 'Twenty-five pins of inspiration.', LucideIcons.palette, tier: 1, metric: 'pin', goal: 25),
    BadgeDef('shopping_25', 'List Maker', 'Twenty-five items listed.', LucideIcons.shoppingCart, tier: 1, metric: 'shopping', goal: 25),
    // Moments
    BadgeDef('early_bird', 'Early Bird', 'Something done before seven in the morning.', LucideIcons.coffee, tier: 1),
    BadgeDef('night_owl', 'Night Owl', 'Something done after eleven at night.', LucideIcons.moon, tier: 1),
    BadgeDef('weekend', 'Weekend Keeper', 'Your daily goal, met on a weekend.', LucideIcons.calendarDays, tier: 1),
    BadgeDef('perfect_day', 'Ten in a Day', 'Ten things done in a single day.', LucideIcons.sparkles, tier: 2),
  ];

  static final Map<String, BadgeDef> _byId = {for (final b in all) b.id: b};
  static BadgeDef? byId(String id) => _byId[id];

  static const streakMilestones = [3, 7, 14, 30, 50, 100, 200, 365];
  static const goalMilestones = [1, 7, 30, 100];

  /// Badges earned by reaching a lifetime total of one kind of action.
  static final List<BadgeDef> counted = [for (final b in all) if (b.metric != null && RewardAction.values.any((a) => a.name == b.metric)) b];
}

/// A level from lifetime experience: ten points per hands-on action and a bonus per
/// badge, weighted by its tier. Each level needs a hundred points more than the last.
class RewardLevel {
  final int level;
  final int xp;
  final int start;
  final int next;

  const RewardLevel._(this.level, this.xp, this.start, this.next);

  static const titles = [
    'Newcomer', 'Apprentice', 'Note-taker', 'Organiser', 'Artisan', 'Adept',
    'Curator', 'Virtuoso', 'Master', 'Grandmaster', 'Luminary', 'Legend',
  ];

  static int startOf(int level) => 50 * (level - 1) * level;

  factory RewardLevel.of(int xp) {
    var level = 1;
    while (xp >= startOf(level + 1)) {
      level++;
    }
    return RewardLevel._(level, xp, startOf(level), startOf(level + 1));
  }

  String get title => titles[(level - 1).clamp(0, titles.length - 1)];
  String get nextTitle => titles[level.clamp(0, titles.length - 1)];
  int get toNext => next - xp;
  double get progress => ((xp - start) / (next - start)).clamp(0.0, 1.0);
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

  /// Set when this action took the user up a level.
  final RewardLevel? levelUp;

  /// A broken streak can be won back today; this is the streak that was lost.
  final int? repairLost;

  /// Set when this action won the lost streak back.
  final int? repaired;

  const RewardOutcome({
    required this.action,
    required this.count,
    required this.goal,
    required this.goalJustMet,
    required this.goalDays,
    required this.badges,
    this.levelUp,
    this.repairLost,
    this.repaired,
  });
}

/// Read and update the rewards map stored in `AppSettings.rewards`.
///
/// Shape: `badges` {id: day earned}, `day`/`count` today's progress, `goalDays`,
/// `used` features ever touched, `totals` {action: lifetime count}, `days` and
/// `frozen` (days the app was opened, and days a streak freeze or repair covered),
/// `broken` and `repair` (a streak lost today and the offer to win it back),
/// `repairedMonth` (the month a repair was last used), `welcomed`,
/// `streakSeen` (last day the streak screen was shown) and `v` (the map's version:
/// 1 once seeded, 2 once lifetime totals were counted).
class RewardsLedger {
  static const int version = 2;

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
  Map<String, int> get totals => ((m['totals'] as Map?) ?? const {}).map((k, v) => MapEntry('$k', (v as num?)?.toInt() ?? 0));
  int totalOf(String action) => totals[action] ?? 0;
  bool get upgraded => ((m['v'] as num?)?.toInt() ?? 0) >= version;

  static String monthKey(DateTime d) => DateFormat('yyyy-MM').format(d);
  static Set<String> _days(Object? v) => ((v as List?) ?? const []).map((e) => '$e').toSet();
  Set<String> get activeDays => _days(m['days']);
  Set<String> get frozenDays => _days(m['frozen']);

  /// Doing this many things on the day a streak breaks wins it back, once a month.
  static const int repairActions = dailyGoal * 2;

  /// The streak that can still be won back on [day], if any.
  int? repairOffer(String day) {
    final r = m['repair'];
    if (r is! Map || r['day'] != day) return null;
    return (r['lost'] as num?)?.toInt();
  }

  int get xp =>
      totals.values.fold(0, (p, n) => p + n) * 10 +
      earned.fold(0, (p, b) => p + 25 * (b.tier + 1));
  RewardLevel get level => RewardLevel.of(xp);

  /// How far along a counted badge is, as (now, goal); null for one-off moments.
  (int, int)? progress(BadgeDef b, {int streak = 0, int habitStreak = 0}) {
    final metric = b.metric;
    if (metric == null) return null;
    final now = switch (metric) {
      'streak' => streak,
      'goalDays' => goalDays,
      'features' => used.length,
      'habitStreak' => habitStreak,
      _ => totalOf(metric),
    };
    return (now.clamp(0, b.goal), b.goal);
  }

  /// The locked badges closest to being earned, nearest first.
  List<(BadgeDef, int, int)> nextUp({int streak = 0, int habitStreak = 0, int limit = 3}) {
    final out = <(BadgeDef, int, int)>[];
    for (final b in Badges.all) {
      if (has(b.id)) continue;
      final p = progress(b, streak: streak, habitStreak: habitStreak);
      if (p == null || p.$1 <= 0) continue;
      out.add((b, p.$1, p.$2));
    }
    out.sort((a, b) => (b.$2 / b.$3).compareTo(a.$2 / a.$3));
    return out.take(limit).toList();
  }

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
    Map<String, int> totals = const {},
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
    return upgrade({
      ...m,
      'v': 1,
      'welcomed': m['welcomed'] == true || !newUser,
      'badges': badges,
      'used': {...RewardsLedger(m).used, ...alreadyUsed.map(rewardFeature)}.toList(),
    }, totals: totals, now: now);
  }

  /// Marks [now] as a day the app was opened. The first time, the current streak is
  /// filled in backwards so the calendar starts with the run already going.
  static Map<String, dynamic> markActive(Map<String, dynamic> m, DateTime now, {required int streak}) {
    final ledger = RewardsLedger(m);
    final days = ledger.activeDays;
    final today = dayKey(now);
    if (days.contains(today)) return m;
    if (days.isEmpty) {
      for (var i = 1; i < streak; i++) {
        days.add(dayKey(now.subtract(Duration(days: i))));
      }
    }
    days.add(today);
    final sorted = days.toList()..sort();
    return {...m, 'days': sorted.length > 400 ? sorted.sublist(sorted.length - 400) : sorted};
  }

  /// Records the days between [lastActive] and [now] as covered (by a freeze or repair).
  static Map<String, dynamic> cover(Map<String, dynamic> m, String lastActive, DateTime now) {
    final from = DateTime.tryParse(lastActive);
    if (from == null) return m;
    final frozen = RewardsLedger(m).frozenDays;
    final today = DateTime(now.year, now.month, now.day);
    for (var d = DateTime(from.year, from.month, from.day).add(const Duration(days: 1)); d.isBefore(today); d = d.add(const Duration(days: 1))) {
      frozen.add(dayKey(d));
    }
    final sorted = frozen.toList()..sort();
    return {...m, 'frozen': sorted.length > 120 ? sorted.sublist(sorted.length - 120) : sorted};
  }

  /// Notes that a [streak]-day run ended today after [lastActive]. If the run was worth
  /// keeping and no repair was used this month, today's offer to win it back is made.
  static Map<String, dynamic> noteBreak(Map<String, dynamic> m, {required int streak, required String lastActive, required DateTime now}) {
    final next = {...m, 'broken': {'streak': streak, 'day': dayKey(now), 'last': lastActive}};
    if (streak < 3 || m['repairedMonth'] == monthKey(now)) return next;
    return {...next, 'repair': {'day': dayKey(now), 'lost': streak}};
  }

  /// Counts lifetime totals once from what the user already has, and quietly awards the
  /// counted badges they have already reached, so nothing celebrates old work.
  static Map<String, dynamic> upgrade(Map<String, dynamic> m, {required Map<String, int> totals, required DateTime now}) {
    final ledger = RewardsLedger(m);
    if (ledger.upgraded) return m;
    final today = dayKey(now);
    final merged = {...ledger.totals};
    totals.forEach((k, v) {
      if (v > (merged[k] ?? 0)) merged[k] = v;
    });
    final badges = {...ledger.badges};
    for (final b in Badges.counted) {
      if ((merged[b.metric] ?? 0) >= b.goal) badges.putIfAbsent(b.id, () => today);
    }
    for (final b in Badges.all.where((b) => b.metric == 'features')) {
      if (ledger.used.length >= b.goal) badges.putIfAbsent(b.id, () => today);
    }
    return {...m, 'v': version, 'totals': merged, 'badges': badges};
  }

  /// Counts [a] toward today's goal and its lifetime total, and awards any badges it
  /// unlocks. [habitStreak] is the current run of the habit just kept, if any.
  static (Map<String, dynamic>, RewardOutcome) record(Map<String, dynamic> m, RewardAction a, DateTime now, {int habitStreak = 0}) {
    final ledger = RewardsLedger(m);
    final levelBefore = ledger.level.level;
    final today = dayKey(now);
    final count = ledger.countOn(today) + 1;
    final badges = {...ledger.badges};
    final used = {...ledger.used, rewardFeature(a)};
    final totals = {...ledger.totals, a.name: ledger.totalOf(a.name) + 1};
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
    for (final b in Badges.all) {
      final reached = switch (b.metric) {
        'features' => used.length >= b.goal,
        'habitStreak' => habitStreak >= b.goal,
        final String metric when metric == a.name => totals[metric]! >= b.goal,
        _ => false,
      };
      if (reached) award(b.id);
    }
    final hour = now.hour;
    if (hour >= 4 && hour < 7) award('early_bird');
    if (hour >= 23 || hour < 4) award('night_owl');
    if (count >= 10) award('perfect_day');

    final goalJustMet = count == dailyGoal;
    var goalDays = ledger.goalDays;
    if (goalJustMet) {
      goalDays++;
      for (final g in Badges.goalMilestones) {
        if (goalDays >= g) award('goal_$g');
      }
      if (now.weekday >= DateTime.saturday) award('weekend');
    }

    var next = <String, dynamic>{
      ...m,
      'day': today,
      'count': count,
      'goalDays': goalDays,
      'badges': badges,
      'used': used.toList(),
      'totals': totals,
    };
    final repairLost = ledger.repairOffer(today);
    int? repaired;
    if (repairLost != null && count >= repairActions) {
      repaired = repairLost;
      final broken = m['broken'];
      next = {...next, 'repairedMonth': monthKey(now)}..remove('repair');
      if (broken is Map && broken['last'] is String) next = cover(next, broken['last'] as String, now);
    }
    final level = RewardsLedger(next).level;
    return (
      next,
      RewardOutcome(
        action: a,
        count: count,
        goal: dailyGoal,
        goalJustMet: goalJustMet,
        goalDays: goalDays,
        badges: fresh,
        levelUp: level.level > levelBefore ? level : null,
        repairLost: repaired == null ? repairLost : null,
        repaired: repaired,
      ),
    );
  }

  /// Awards a one-off badge such as [Badges.comeback]; returns the map and whether it is new.
  static (Map<String, dynamic>, bool) awardOnce(Map<String, dynamic> m, BadgeDef b, DateTime now) {
    final ledger = RewardsLedger(m);
    if (ledger.has(b.id)) return (m, false);
    return ({...m, 'badges': {...ledger.badges, b.id: dayKey(now)}}, true);
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
    final totals = {...ly.totals};
    lx.totals.forEach((k, v) {
      if (v > (totals[k] ?? 0)) totals[k] = v;
    });
    final vx = (x['v'] as num?)?.toInt(), vy = (y['v'] as num?)?.toInt();
    return {
      ...y,
      ...x,
      'v': vx == null ? vy : (vy == null || vx >= vy ? vx : vy),
      'totals': totals,
      'welcomed': lx.welcomed || ly.welcomed,
      'streakSeen': later(lx.streakSeen, ly.streakSeen),
      'goalDays': lx.goalDays > ly.goalDays ? lx.goalDays : ly.goalDays,
      'day': day,
      'count': count,
      'badges': badges,
      'used': {...lx.used, ...ly.used}.toList(),
      'days': ({...lx.activeDays, ...ly.activeDays}.toList()..sort()),
      'frozen': ({...lx.frozenDays, ...ly.frozenDays}.toList()..sort()),
      if (x['repairedMonth'] != null || y['repairedMonth'] != null)
        'repairedMonth': later('${x['repairedMonth'] ?? ''}', '${y['repairedMonth'] ?? ''}'),
    };
  }
}
