import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../platform/browser_bridge.dart';
import '../state/sanctuary_state.dart';
import '../utils/date_labels.dart';
import '../widgets/app_toast_engine.dart';
import 'local_store.dart';

/// What the reminder loop needs to read each tick.
class ReminderSources {
  final List<TaskItem> Function() tasks;
  final List<PlannerEvent> Function() events;
  final List<HabitItem> Function() habits;
  final bool Function() enabled;

  /// Items that already have a device (alarm) reminder, by id. The in-app alert is skipped
  /// for an item whose device reminder fires at the same moment, so it never rings twice.
  final Map<String, DateTime> Function() deviceReminders;

  const ReminderSources({
    required this.tasks,
    required this.events,
    required this.habits,
    required this.enabled,
    this.deviceReminders = _none,
  });

  static Map<String, DateTime> _none() => const {};
}

/// Something due right now.
@immutable
class DueReminder {
  final String key;
  final String title;
  final String body;

  const DueReminder(this.key, this.title, this.body);
}

/// Checks every [interval] for due tasks, starting events and habits whose time has come,
/// and alerts once per item: as a system notification when allowed, otherwise in-app.
class ReminderService {
  static final ReminderService _instance = ReminderService._internal();
  factory ReminderService() => _instance;
  ReminderService._internal();

  static const String _firedKey = 'reminders.fired';
  static const Duration interval = Duration(seconds: 30);

  /// How long before an event starts it is announced.
  static const Duration eventLead = Duration(minutes: 10);

  Timer? _timer;
  ReminderSources? _sources;

  void start(ReminderSources sources) {
    _sources = sources;
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => tick());
    tick();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Set<String> get _fired => ((LocalStore().readMap(_firedKey)?['keys'] as List?) ?? const []).map((e) => '$e').toSet();

  void _remember(Set<String> keys) {
    // Only today's and yesterday's keys matter; keep the list from growing forever.
    final keep = keys.toList();
    LocalStore().writeMap(_firedKey, {'keys': keep.length > 500 ? keep.sublist(keep.length - 500) : keep});
  }

  void tick([DateTime? at]) {
    final s = _sources;
    if (s == null || !s.enabled()) return;
    final now = at ?? DateTime.now();
    final fired = _fired;
    final due = dueAt(now, tasks: s.tasks(), events: s.events(), habits: s.habits(), deviceReminders: s.deviceReminders())
        .where((r) => !fired.contains(r.key))
        .toList();
    if (due.isEmpty) return;
    for (final r in due) {
      if (!showSystemNotification(r.title, r.body)) {
        AppToastEngine().notify(title: r.title, message: r.body, type: ToastType.alert);
      }
      fired.add(r.key);
    }
    _remember(fired);
  }

  static HabitClock? parseHabitTime(String label) {
    for (final pattern in const ['h:mm a', 'hh:mm a', 'H:mm']) {
      try {
        final d = DateFormat(pattern).parseStrict(label.trim().toUpperCase());
        return HabitClock(d.hour, d.minute);
      } catch (_) {}
    }
    return null;
  }

  /// Everything that should be announced at [now]. Pure, so it can be tested directly.
  static List<DueReminder> dueAt(
    DateTime now, {
    required List<TaskItem> tasks,
    required List<PlannerEvent> events,
    required List<HabitItem> habits,
    Map<String, DateTime> deviceReminders = const {},
  }) {
    final out = <DueReminder>[];
    bool coveredByDevice(String id, DateTime at) {
      final device = deviceReminders[id];
      return device != null && device.difference(at).abs() <= const Duration(minutes: 15);
    }
    // Only alert for things that became due recently, not a backlog from weeks ago.
    final window = now.subtract(const Duration(hours: 12));

    for (final t in tasks) {
      final due = t.dueAt;
      if (t.completed || due == null || coveredByDevice(t.id, due)) continue;
      if (!due.isAfter(now) && due.isAfter(window)) {
        out.add(DueReminder('task:${t.id}:${due.toIso8601String()}', 'Task due', t.title));
      }
    }

    for (final e in events) {
      final announceAt = e.startsAt.subtract(eventLead);
      if (coveredByDevice(e.id, announceAt)) continue;
      if (!announceAt.isAfter(now) && e.startsAt.isAfter(now.subtract(const Duration(minutes: 1)))) {
        out.add(DueReminder('event:${e.id}:${e.startsAt.toIso8601String()}', 'Starting at ${DateLabels.time(e.startsAt)}', e.title));
      }
    }

    final today = DateLabels.dayKey(now);
    for (final h in habits) {
      final t = parseHabitTime(h.time);
      if (t == null || h.isDoneOn(now)) continue;
      final at = DateTime(now.year, now.month, now.day, t.hour, t.minute);
      if (!at.isAfter(now) && now.difference(at) < const Duration(hours: 2)) {
        out.add(DueReminder('habit:${h.id}:$today', 'Habit reminder', h.title));
      }
    }
    return out;
  }
}

/// A habit's time of day (hour and minute).
@immutable
class HabitClock {
  final int hour;
  final int minute;
  const HabitClock(this.hour, this.minute);
}
