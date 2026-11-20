import 'package:intl/intl.dart';

/// One day as the notifications see it.
class DayPicture {
  final DateTime day;

  /// The app was opened on this day (so the streak is already safe).
  final bool active;
  final int goalCount;
  final int goal;

  /// Open tasks already late by the start of this day.
  final List<String> overdue;

  /// Open tasks due this day, with their time when they have one.
  final List<(String, DateTime?)> due;

  /// Habits due this day and not done yet.
  final List<String> habitsLeft;

  /// The unfinished habit with the longest run going, and that run.
  final String? habitAtRisk;
  final int habitAtRiskStreak;

  final List<(String, DateTime)> events;
  final bool journaled;

  /// A streak that broke today and can still be won back by doing [repairGoal] things.
  final int? repairLost;
  final int repairGoal;

  /// The morning line Nodo wrote for this day, used instead of the plain agenda.
  final String? morningLine;

  const DayPicture({
    required this.day,
    this.active = false,
    this.goalCount = 0,
    this.goal = 3,
    this.overdue = const [],
    this.due = const [],
    this.habitsLeft = const [],
    this.habitAtRisk,
    this.habitAtRiskStreak = 0,
    this.events = const [],
    this.journaled = false,
    this.repairLost,
    this.repairGoal = 6,
    this.morningLine,
  });

  bool get empty => overdue.isEmpty && due.isEmpty && habitsLeft.isEmpty && events.isEmpty;
}

/// What stays the same across days: who the person is and where they stand.
class NudgeContext {
  final String name;
  final int streak;
  final int freezes;
  final double? budget;
  final double monthSpend;
  final String currency;

  /// The badge nearest to being earned, as (title, now, goal).
  final (String, int, int)? nextBadge;

  /// One sentence about the last seven days, for the Sunday recap.
  final String? weekHeadline;

  const NudgeContext({
    this.name = '',
    this.streak = 0,
    this.freezes = 0,
    this.budget,
    this.monthSpend = 0,
    this.currency = '',
    this.nextBadge,
    this.weekHeadline,
  });
}

/// A habit with a time of day, for reminders at that time.
class HabitCue {
  final String id;
  final String title;
  final int hour;
  final int minute;

  /// The current run, counting up to yesterday.
  final int streak;

  /// Days (0 = today, 1 = tomorrow) it is due and not yet done.
  final Set<int> pending;

  const HabitCue({required this.id, required this.title, required this.hour, required this.minute, this.streak = 0, this.pending = const {}});
}

/// A notification ready to schedule. [target] is a deep link the app understands
/// (tasks, habits, planner, journal, expenses, capture, home); [tag] is the short
/// label shown beside the app name.
class Nudge {
  final DateTime at;
  final String title;
  final String body;
  final String target;
  final String tag;

  const Nudge(this.at, this.title, this.body, {this.target = 'home', this.tag = 'Today'});

  @override
  String toString() => '${DateFormat('EEE HH:mm').format(at)}  $title — $body';
}

/// Writes the day's notifications from what is actually going on, so every one says
/// something true and useful: the agenda in the morning, the overdue task or the habit
/// about to slip during the day, the streak when it is at stake, and a recap at night.
/// A slot with nothing worth saying is left silent rather than filled with filler.
abstract final class NudgePlanner {
  static List<Nudge> forDay(DayPicture d, NudgeContext c, List<DateTime> times) {
    if (times.isEmpty) return const [];
    final slots = [...times]..sort();
    final out = <Nudge>[];
    final used = <String>{};

    void add(Nudge? n, [String? topic]) {
      if (n == null || out.any((o) => o.title == n.title)) return;
      if (topic != null) used.add(topic);
      out.add(n);
    }

    add(_morning(d, c, slots.first));
    if (slots.length == 1) return out;

    final middle = slots.sublist(1, slots.length - 1);
    final repair = d.repairLost;
    if (repair != null && middle.isNotEmpty) {
      final left = d.repairGoal - d.goalCount;
      if (left > 0) {
        add(
          Nudge(middle.first, 'Win back your $repair-day streak', '$left more thing${left == 1 ? '' : 's'} today and it is yours again. A note, a task or a habit all count.',
              target: 'capture', tag: 'Streak repair'),
          'repair',
        );
      }
    }
    for (final at in middle.skip(used.contains('repair') ? 1 : 0)) {
      final streakAtStake = !d.active && c.streak >= 2 && at.hour >= 16 && !used.contains('streak');
      if (streakAtStake) {
        add(_streakGuard(d, c, at), 'streak');
        continue;
      }
      for (final topic in const ['overdue', 'due', 'habit', 'event', 'goal', 'budget', 'badge']) {
        if (used.contains(topic)) continue;
        final n = _topic(topic, d, c, at);
        if (n != null) {
          add(n, topic);
          break;
        }
      }
    }
    add(_evening(d, c, slots.last));
    return out;
  }

  /// The Sunday recap, an hour before the evening notification.
  static Nudge? weekly(NudgeContext c, DateTime evening) {
    final line = c.weekHeadline;
    if (line == null) return null;
    return Nudge(evening.subtract(const Duration(hours: 1)), 'Your week in NOTtEodo', '$line Tap to see how it compares.',
        target: 'recap', tag: 'Weekly recap');
  }

  /// Reminders at each habit's own time, today and tomorrow, skipping any already done.
  static List<Nudge> habitReminders(List<HabitCue> cues, DateTime now) {
    final out = <Nudge>[];
    final today = DateTime(now.year, now.month, now.day);
    for (final h in cues) {
      for (final offset in h.pending) {
        final day = today.add(Duration(days: offset));
        final at = DateTime(day.year, day.month, day.day, h.hour, h.minute);
        if (!at.isAfter(now)) continue;
        final run = offset == 0 ? h.streak : 0;
        out.add(Nudge(
          at,
          'Time for ${h.title}',
          run >= 2 ? 'Day ${run + 1} of your run is waiting. One tick keeps it going.' : 'One tick and today counts.',
          target: 'habits',
          tag: 'Habits',
        ));
      }
    }
    out.sort((a, b) => a.at.compareTo(b.at));
    return out;
  }

  /// The day after tomorrow, if the app stays closed: a single evening word.
  static Nudge away(NudgeContext c, DateTime at) {
    if (c.streak >= 2 && c.freezes > 0) {
      return Nudge(at, 'A streak freeze is holding your ${c.streak} days',
          'Come back today and they stay yours. Your notes and plans are right where you left them.',
          tag: 'Streak');
    }
    return Nudge(at, _hi(c, 'your notes are where you left them', 'Your notes are where you left them'),
        'Start a fresh streak today. One small thing is enough.',
        tag: 'Streak');
  }

  // --- Slots ------------------------------------------------------------------------

  static Nudge _morning(DayPicture d, NudgeContext c, DateTime at) {
    final greetings = c.name.isEmpty
        ? const ['Good morning', 'Morning', 'Here is your day']
        : ['Good morning, ${c.name}', 'Morning, ${c.name}', '${c.name}, here is your day'];
    final title = greetings[d.day.day % greetings.length];
    final line = d.morningLine;
    if (line != null && line.isNotEmpty) {
      return Nudge(at, title, line, target: d.due.isNotEmpty || d.overdue.isNotEmpty ? 'tasks' : 'home');
    }
    if (d.empty) {
      return Nudge(at, title, 'Nothing is scheduled. What is the one thing that would make today count?', target: 'capture');
    }
    final parts = <String>[];
    if (d.events.isNotEmpty) {
      final e = d.events.first;
      parts.add('${e.$1} at ${_time(e.$2)}${d.events.length > 1 ? ' and ${_more(d.events.length - 1, 'plan')}' : ''}');
    }
    if (d.due.isNotEmpty) {
      parts.add('${_count(d.due.length, 'task')} due, starting with ${_q(d.due.first.$1)}');
    }
    if (d.overdue.isNotEmpty) parts.add('${d.overdue.length} overdue');
    if (d.habitsLeft.isNotEmpty) parts.add(_count(d.habitsLeft.length, 'habit'));
    return Nudge(at, title, '${_cap(_join(parts))}.', target: d.due.isNotEmpty || d.overdue.isNotEmpty ? 'tasks' : (d.events.isNotEmpty ? 'planner' : 'habits'));
  }

  static Nudge _streakGuard(DayPicture d, NudgeContext c, DateTime at) {
    final waiting = d.due.isNotEmpty
        ? '${_q(d.due.first.$1)} is waiting too.'
        : d.habitsLeft.isNotEmpty
            ? '${_q(d.habitsLeft.first)} is still to do.'
            : 'A moment is all it takes.';
    return Nudge(at, 'Keep your ${c.streak}-day streak', 'Open NOTtEodo today to keep it going. $waiting', tag: 'Streak');
  }

  static Nudge? _evening(DayPicture d, NudgeContext c, DateTime at) {
    if (!d.active) {
      if (c.streak < 2) {
        return d.empty ? null : Nudge(at, 'Pick up where you left off', '${_cap(_waitingLine(d))}.', target: 'tasks', tag: 'Evening');
      }
      final cover = c.freezes > 0
          ? 'A streak freeze would cover today, but you have only ${c.freezes}. Keep it yourself with a quick visit.'
          : 'Open NOTtEodo for a moment to keep it.';
      return Nudge(at, 'Your ${c.streak}-day streak ends at midnight', cover, tag: 'Streak');
    }
    final repair = d.repairLost;
    if (repair != null && d.goalCount < d.repairGoal) {
      final left = d.repairGoal - d.goalCount;
      return Nudge(at, 'Last chance for your $repair-day streak', '$left more thing${left == 1 ? '' : 's'} before midnight wins it back.',
          target: 'capture', tag: 'Streak repair');
    }
    if (d.goalCount < d.goal) {
      final left = d.goal - d.goalCount;
      return Nudge(at, '$left more for today\'s goal',
          'You are at ${d.goalCount} of ${d.goal}. A quick note, a ticked task or a kept habit all count.',
          target: 'capture', tag: 'Daily goal');
    }
    final tomorrow = <String>[
      if (d.due.isNotEmpty) '${_count(d.due.length, 'task')} still open',
      if (d.habitsLeft.isNotEmpty) '${_count(d.habitsLeft.length, 'habit')} left',
    ];
    if (!d.journaled && tomorrow.isEmpty) {
      return Nudge(at, 'Day ${c.streak}, kept', 'You did ${d.goalCount} things today. How was it? One line in your journal is enough.',
          target: 'journal', tag: 'Evening');
    }
    return Nudge(
      at,
      'Day ${c.streak}, kept',
      'You did ${d.goalCount} things today${tomorrow.isEmpty ? '. Rest well.' : '. ${_cap(_join(tomorrow))}: carry them over or let them go.'}',
      target: tomorrow.isEmpty ? 'home' : 'tasks',
      tag: 'Evening',
    );
  }

  static Nudge? _topic(String topic, DayPicture d, NudgeContext c, DateTime at) {
    switch (topic) {
      case 'overdue':
        if (d.overdue.isEmpty) return null;
        final first = _q(d.overdue.first);
        return Nudge(
          at,
          d.overdue.length == 1 ? '$first is overdue' : '$first and ${_more(d.overdue.length - 1, 'other')} are overdue',
          'Ten minutes now takes it off your mind.',
          target: 'tasks',
          tag: 'Tasks',
        );
      case 'due':
        final left = [for (final t in d.due) if (t.$2 == null || t.$2!.isAfter(at.subtract(const Duration(minutes: 30)))) t];
        if (left.isEmpty) return null;
        final timed = left.where((t) => t.$2 != null).toList()..sort((a, b) => a.$2!.compareTo(b.$2!));
        final next = timed.isNotEmpty ? timed.first : left.first;
        return Nudge(
          at,
          left.length == 1 ? '${_q(next.$1)} is due today' : '${left.length} tasks left today',
          next.$2 != null ? 'Next up: ${_q(next.$1)} at ${_time(next.$2!)}.' : 'Next up: ${_q(next.$1)}.',
          target: 'tasks',
          tag: 'Tasks',
        );
      case 'habit':
        if (d.habitsLeft.isEmpty) return null;
        if (d.habitAtRisk != null && d.habitAtRiskStreak >= 2) {
          return Nudge(at, 'Keep your ${d.habitAtRiskStreak}-day ${d.habitAtRisk} run', 'It takes a minute, and the run keeps growing.',
              target: 'habits', tag: 'Habits');
        }
        return Nudge(
          at,
          d.habitsLeft.length == 1 ? 'Time for ${d.habitsLeft.first}' : '${d.habitsLeft.length} habits left today',
          d.habitsLeft.length == 1 ? 'One tick and today counts.' : '${_cap(_list(d.habitsLeft))}.',
          target: 'habits',
          tag: 'Habits',
        );
      case 'event':
        final soon = d.events.where((e) => e.$2.isAfter(at) && e.$2.difference(at).inMinutes <= 180).toList();
        if (soon.isEmpty) return null;
        return Nudge(at, '${soon.first.$1} at ${_time(soon.first.$2)}', 'Coming up in ${_until(at, soon.first.$2)}.', target: 'planner', tag: 'Plans');
      case 'goal':
        if (!d.active || d.goalCount >= d.goal || d.goalCount == 0) return null;
        final left = d.goal - d.goalCount;
        return Nudge(at, '$left more to reach today\'s goal', 'You are at ${d.goalCount} of ${d.goal}. Keep the day moving.', target: 'capture', tag: 'Daily goal');
      case 'budget':
        final budget = c.budget;
        if (budget == null || budget <= 0 || c.monthSpend < budget * 0.8) return null;
        final pct = (c.monthSpend / budget * 100).round();
        final left = budget - c.monthSpend;
        return Nudge(
          at,
          pct >= 100 ? 'Over your monthly budget' : '$pct% of your monthly budget used',
          left > 0
              ? '${c.currency}${left.toStringAsFixed(0)} left for the rest of ${DateFormat.MMMM().format(at)}.'
              : 'You are ${c.currency}${(-left).toStringAsFixed(0)} over this month.',
          target: 'expenses',
          tag: 'Money',
        );
      case 'badge':
        final b = c.nextBadge;
        if (b == null || b.$3 <= 0 || b.$2 / b.$3 < 0.6) return null;
        final left = b.$3 - b.$2;
        return Nudge(at, '$left more to earn ${_q(b.$1)}', 'You are ${b.$2} of ${b.$3} of the way there.', tag: 'Badges');
    }
    return null;
  }

  // --- Words -----------------------------------------------------------------------

  static String _waitingLine(DayPicture d) => _join([
        if (d.due.isNotEmpty) '${_count(d.due.length, 'task')} due today',
        if (d.overdue.isNotEmpty) '${d.overdue.length} overdue',
        if (d.habitsLeft.isNotEmpty) _count(d.habitsLeft.length, 'habit'),
      ]);

  static String _hi(NudgeContext c, String withName, String without) => c.name.isEmpty ? without : '${c.name}, $withName';
  static String _time(DateTime t) => DateFormat.jm().format(t);
  static String _q(String s) {
    final t = s.trim();
    return '“${t.length > 40 ? '${t.substring(0, 39)}…' : t}”';
  }

  static String _count(int n, String noun) => '$n $noun${n == 1 ? '' : 's'}';
  static String _more(int n, String noun) => '$n more ${noun == 'other' ? '' : noun}${n == 1 || noun == 'other' ? '' : 's'}'.trimRight();
  static String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
  static String _join(List<String> parts) => switch (parts.length) {
        0 => '',
        1 => parts.first,
        _ => '${parts.sublist(0, parts.length - 1).join(', ')} and ${parts.last}',
      };
  static String _list(List<String> items) =>
      items.length <= 3 ? _join(items) : '${items.take(2).join(', ')} and ${items.length - 2} more';
  static String _until(DateTime from, DateTime to) {
    final m = to.difference(from).inMinutes;
    if (m < 60) return '$m minutes';
    final h = m ~/ 60, r = m % 60;
    return r < 10 ? (h == 1 ? 'an hour' : '$h hours') : '$h h $r min';
  }
}
