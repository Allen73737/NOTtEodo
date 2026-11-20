import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../rewards/rewards_ledger.dart';
import '../rewards/weekly_recap.dart';
import '../state/app_settings.dart';
import '../state/sanctuary_state.dart';
import '../utils/date_labels.dart';
import 'daily_engagement_service.dart';
import 'groq_ai_service.dart';
import 'local_store.dart';
import 'nudge_planner.dart';
import 'reminder_service.dart';
import 'widget_sync_service.dart';

/// Keeps the scheduled notifications in step with the person's day.
///
/// It tells [DailyEngagementService] how to see a day (tasks, habits, plans, goal,
/// streak) and reschedules whenever the app comes back to the foreground or that data
/// changes, so tonight's notification knows today was already kept and tomorrow's
/// knows what is due. Changes are gathered for a few seconds before rescheduling.
///
/// It also schedules reminders at each habit's own time, keeps the home-screen widget's
/// level line current and, when cloud AI is on, asks Nodo to write the next morning's
/// notification from the same facts (falling back to the plain agenda).
class NudgeHost extends ConsumerStatefulWidget {
  final Widget child;
  const NudgeHost({super.key, required this.child});

  @override
  ConsumerState<NudgeHost> createState() => _NudgeHostState();
}

class _NudgeHostState extends ConsumerState<NudgeHost> with WidgetsBindingObserver {
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    DailyEngagementService.source = _picture;
    _schedule(const Duration(seconds: 4));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    if (DailyEngagementService.source == _picture) DailyEngagementService.source = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _schedule(const Duration(seconds: 2));
  }

  void _schedule(Duration after) {
    _debounce?.cancel();
    _debounce = Timer(after, () {
      if (!mounted) return;
      final s = ref.read(appSettingsProvider);
      DailyEngagementService().rescheduleFrom(s);
      DailyEngagementService().scheduleHabitReminders(_habitCues(), enabled: s.remindersEnabled);
      _syncWidget(s);
      _askNodoForMorning(s);
    });
  }

  List<HabitCue> _habitCues() {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    return [
      for (final h in ref.read(habitsProvider))
        if (!isSampleId(h.id))
          if (ReminderService.parseHabitTime(h.time) case final t?)
            HabitCue(
              id: h.id,
              title: h.title,
              hour: t.hour,
              minute: t.minute,
              streak: h.streakAt(now),
              pending: {
                if (h.isDueOn(now) && !h.isDoneOn(now)) 0,
                if (h.isDueOn(tomorrow)) 1,
              },
            ),
    ];
  }

  void _syncWidget(AppSettings s) {
    final ledger = RewardsLedger(s.rewards);
    final level = ledger.level;
    final next = ledger.nextUp(streak: s.activeStreak, limit: 1);
    final line = next.isEmpty
        ? 'Level ${level.level} · ${level.title}'
        : 'Level ${level.level} · ${next.first.$3 - next.first.$2} more to ${next.first.$1.title}';
    WidgetSyncService.saveProgress(line);
  }

  // --- Nodo's morning line ---------------------------------------------------------

  static const _nodoKey = 'nudges.nodoMorning';

  /// The next morning that has not been notified yet.
  DateTime _nextMorningDay(AppSettings s) {
    final now = DateTime.now();
    final parts = s.morningBriefingTime.split(':');
    final at = DateTime(now.year, now.month, now.day, int.tryParse(parts.first) ?? 9, int.tryParse(parts.length > 1 ? parts[1] : '') ?? 30);
    final day = now.isBefore(at) ? now : now.add(const Duration(days: 1));
    return DateTime(day.year, day.month, day.day);
  }

  String? _cachedLine(DateTime day) {
    final m = LocalStore().readMap(_nodoKey);
    return m != null && m['day'] == DateLabels.dayKey(day) ? m['line'] as String? : null;
  }

  bool _asking = false;

  /// Asks Nodo for one sentence about the coming morning, at most three times a day and
  /// only when the facts behind it changed. Runs only with cloud AI on and signed in.
  Future<void> _askNodoForMorning(AppSettings s) async {
    if (_asking || !s.dailyEngagementNotifications || !GroqAiService().isConfigured) return;
    final day = _nextMorningDay(s);
    final (d, c) = _picture(day, useNodo: false);
    final facts = _facts(d, c);
    final key = DateLabels.dayKey(day);
    final stored = LocalStore().readMap(_nodoKey) ?? const {};
    final today = DateLabels.dayKey(DateTime.now());
    final asked = stored['askedOn'] == today ? (stored['asks'] as num?)?.toInt() ?? 0 : 0;
    if ((stored['day'] == key && stored['facts'] == facts.hashCode) || asked >= 3) return;
    _asking = true;
    try {
      final result = await GroqAiService().ask(
        query: 'Write the body of my morning notification for ${DateFormat.EEEE().format(day)}. '
            'One or two short sentences, under 150 characters, warm and specific, using only these facts. '
            'No greeting (the title already greets me), no emojis, no quotation marks, nothing invented.\n$facts',
        scope: 'Morning notification',
      );
      final line = _clean(result.answer);
      LocalStore().writeMap(_nodoKey, {
        'day': key,
        'facts': facts.hashCode,
        'line': result.isOfflineFallback ? null : line,
        'askedOn': today,
        'asks': asked + 1,
      });
      if (!result.isOfflineFallback && line != null && mounted) {
        DailyEngagementService().rescheduleFrom(ref.read(appSettingsProvider));
      }
    } catch (_) {
      // The plain agenda is used instead.
    } finally {
      _asking = false;
    }
  }

  static String _facts(DayPicture d, NudgeContext c) => [
        if (c.name.isNotEmpty) 'Name: ${c.name}',
        'Day streak: ${c.streak}',
        if (d.events.isNotEmpty) 'Plans: ${d.events.map((e) => '${e.$1} at ${e.$2.hour.toString().padLeft(2, '0')}:${e.$2.minute.toString().padLeft(2, '0')}').join('; ')}',
        if (d.due.isNotEmpty) 'Tasks due: ${d.due.map((t) => t.$1).take(5).join('; ')}',
        if (d.overdue.isNotEmpty) 'Overdue: ${d.overdue.take(3).join('; ')}',
        if (d.habitsLeft.isNotEmpty) 'Habits: ${d.habitsLeft.take(5).join('; ')}',
        if (d.habitAtRisk != null && d.habitAtRiskStreak >= 2) 'Longest habit run: ${d.habitAtRisk}, ${d.habitAtRiskStreak} days',
        if (d.empty) 'Nothing scheduled.',
      ].join('\n');

  /// One tidy line from the reply, or null if it is unusable.
  static String? _clean(String raw) {
    var t = raw.trim().split('\n').firstWhere((l) => l.trim().isNotEmpty, orElse: () => '').trim();
    t = t.replaceAll(RegExp(r'^["“”\x27]+|["“”\x27]+$'), '').trim();
    if (t.length < 12) return null;
    return t.length > 180 ? '${t.substring(0, 177).trimRight()}…' : t;
  }

  (DayPicture, NudgeContext) _picture(DateTime day, {bool useNodo = true}) {
    final s = ref.read(appSettingsProvider);
    final now = DateTime.now();
    final start = DateTime(day.year, day.month, day.day);
    final isToday = DateLabels.isSameDay(start, now);
    final cutoff = isToday ? now : start;

    final open = ref.read(tasksProvider).where((t) => !t.completed && !isSampleId(t.id) && t.dueAt != null);
    final overdue = [for (final t in open) if (t.dueAt!.isBefore(cutoff)) t]..sort((a, b) => a.dueAt!.compareTo(b.dueAt!));
    final due = [
      for (final t in open)
        if (t.isDueOn(start) && !t.dueAt!.isBefore(cutoff)) (t.title, _timed(t.dueAt!) ? t.dueAt : null),
    ];

    final habits = [for (final h in ref.read(habitsProvider)) if (!isSampleId(h.id) && h.isDueOn(start) && !h.isDoneOn(start)) h];
    final atRisk = habits.isEmpty ? null : habits.reduce((a, b) => a.streakAt(now) >= b.streakAt(now) ? a : b);

    final events = [
      for (final e in ref.read(eventsProvider))
        if (!isSampleId(e.id) && DateLabels.isSameDay(e.startsAt, start) && e.startsAt.isAfter(cutoff)) (e.title, e.startsAt),
    ]..sort((a, b) => a.$2.compareTo(b.$2));

    final ledger = RewardsLedger(s.rewards);
    final key = DateLabels.dayKey(start);
    final bestHabit = ref.read(habitsProvider).fold(0, (p, h) => h.streakAt(now) > p ? h.streakAt(now) : p);
    final next = ledger.nextUp(streak: s.activeStreak, habitStreak: bestHabit, limit: 1);

    return (
      DayPicture(
        day: start,
        active: s.lastActiveDate == key,
        goalCount: ledger.countOn(key),
        goal: RewardsLedger.dailyGoal,
        overdue: [for (final t in overdue) t.title],
        due: due,
        habitsLeft: [for (final h in habits) h.title],
        habitAtRisk: atRisk?.title,
        habitAtRiskStreak: atRisk?.streakAt(now) ?? 0,
        events: events,
        journaled: ref.read(journalProvider).any((j) => DateLabels.isSameDay(j.createdAt, start)),
        repairLost: ledger.repairOffer(key),
        repairGoal: RewardsLedger.repairActions,
        morningLine: useNodo ? _cachedLine(start) : null,
      ),
      NudgeContext(
        name: s.displayName.trim().split(RegExp(r'\s+')).first,
        streak: s.activeStreak,
        freezes: s.streakFreezesCount,
        budget: s.monthlyBudget,
        monthSpend: ref.read(expensesProvider).spendInMonth(now),
        currency: s.currencySymbol,
        nextBadge: next.isEmpty ? null : (next.first.$1.title, next.first.$2, next.first.$3),
        weekHeadline: start.weekday == DateTime.sunday
            ? WeeklyRecap.compute(
                now: now,
                tasks: ref.read(tasksProvider),
                habits: ref.read(habitsProvider),
                journal: ref.read(journalProvider),
                notes: ref.read(notesProvider),
                expenses: ref.read(expensesProvider).expenses,
                ledger: ledger,
              ).headline
            : null,
      ),
    );
  }

  /// Tasks saved without a time sit at midnight; those read as "due today", not "at 12:00 AM".
  static bool _timed(DateTime t) => t.hour != 0 || t.minute != 0;

  @override
  Widget build(BuildContext context) {
    void changed(_, __) => _schedule(const Duration(seconds: 3));
    ref.listen(tasksProvider, changed);
    ref.listen(habitsProvider, changed);
    ref.listen(eventsProvider, changed);
    ref.listen(journalProvider, changed);
    ref.listen(appSettingsProvider.select((s) => (s.lastActiveDate, s.activeStreak, RewardsLedger(s.rewards).countOn(DateLabels.dayKey(DateTime.now())))), changed);
    return widget.child;
  }
}
