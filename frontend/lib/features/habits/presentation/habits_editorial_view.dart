import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/editorial/editorial_kit.dart';
import '../../../core/editorial/editorial_mode.dart';
import '../../../core/state/sanctuary_state.dart';
import '../../../core/utils/date_labels.dart';
import '../../../core/motion/transitions.dart';
import '../../../core/services/streak_achievement_service.dart';
import '../../../core/widgets/entry_editor.dart';
import '../../../core/widgets/habit_heatmap_and_curators_cabinet.dart';
import 'habit_rewards_sheet.dart';

const _weekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
const _weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// "Every day", "Weekdays", "Mon, Wed, Fri"…
String scheduleLabel(Set<int> weekdays) {
  if (weekdays.isEmpty || weekdays.length == 7) return 'Every day';
  if (weekdays.length == 5 && weekdays.containsAll(const [1, 2, 3, 4, 5])) return 'Weekdays';
  if (weekdays.length == 2 && weekdays.containsAll(const [6, 7])) return 'Weekends';
  return (weekdays.toList()..sort()).map((d) => _weekdayNames[d - 1]).join(', ');
}

/// Habits as a daily checklist. Tap the mark to log today (counted habits add one per
/// tap), swipe right to log, left to skip the day, hold for target, days and pause.
/// Each habit shows its last seven days as a row of dots and its streak.
class HabitsEditorialView extends ConsumerWidget {
  const HabitsEditorialView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ed = Ed.of(context);
    final habits = ref.watch(habitsProvider);
    final n = ref.read(habitsProvider.notifier);
    final now = DateTime.now();
    final today = habits.where((h) => h.isDueOn(now)).toList();
    final resting = habits.where((h) => !h.paused && !h.isDueOn(now)).toList();
    final paused = habits.where((h) => h.paused).toList();
    final done = today.where((h) => h.isDoneOn(now)).length;

    void log(HabitItem h) {
      final completed = n.bump(h.id, by: h.isCounted || !h.isDoneOn(now) ? 1 : -1);
      if (!completed) return;
      HapticFeedback.mediumImpact();
      StreakAchievementService.checkAndUpdateStreak(ref, null);
      final updated = ref.read(habitsProvider).where((x) => x.id == h.id).firstOrNull;
      // Every finished day gets its small reward moment, as in the card view.
      if (updated != null && context.mounted && EditorialMode.celebrate) {
        showSanctuaryDialog(context: context, builder: (_) => HabitRewardsSheet(habitTitle: updated.title, streakDays: updated.streak));
      }
    }

    Future<void> setTarget(HabitItem h) async {
      final raw = await showEditorialPrompt(
        context,
        title: 'Times per day',
        hint: '1 for yes/no, or e.g. 8',
        initial: '${h.target}',
        keyboard: TextInputType.number,
      );
      final value = int.tryParse(raw ?? '');
      if (value == null || value < 1) return;
      String unit = h.unit;
      if (value > 1 && context.mounted) {
        unit = await showEditorialPrompt(context, title: 'Counted in…', hint: 'glasses, pages, km', initial: h.unit) ?? h.unit;
      }
      n.updateHabit(h.id, target: value, unit: value > 1 ? unit : '');
    }

    Future<void> setDays(HabitItem h) async {
      final picked = await showModalBottomSheet<Set<int>>(
        context: context,
        backgroundColor: ed.paper,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => _DayPicker(initial: h.weekdays),
      );
      if (picked != null) n.updateHabit(h.id, weekdays: picked.length == 7 ? <int>{} : picked);
    }

    void menu(HabitItem h) {
      showEditorialMenu(context, title: h.title, subtitle: '${scheduleLabel(h.weekdays)}  ·  best streak ${h.bestStreak}', items: [
        EditorialMenuItem('Edit name and time', () => openEntryEditor(context, EntryKind.habit, editing: h)),
        EditorialMenuItem(h.isCounted ? 'Change daily target (${h.target})' : 'Count it instead (e.g. 8 glasses)', () => setTarget(h)),
        EditorialMenuItem('Choose days', () => setDays(h)),
        if (!h.paused) EditorialMenuItem(h.isSkippedOn(now) ? 'Undo skip' : 'Skip today', () => n.toggleSkip(h.id)),
        EditorialMenuItem(h.paused ? 'Resume' : 'Pause', () => n.setPaused(h.id, !h.paused)),
        EditorialMenuItem('Delete', () => n.deleteHabit(h.id), destructive: true),
      ]);
    }

    Widget entry(HabitItem h, {bool active = true}) {
      final isDone = h.isDoneOn(now);
      final count = h.countOn(now);
      final streak = h.streakAt(now);
      final meta = [
        if (h.isCounted) '$count of ${h.target}${h.unit.isEmpty ? '' : ' ${h.unit}'}',
        if (streak > 0) '$streak-day streak',
        if (h.weekdays.isNotEmpty) scheduleLabel(h.weekdays),
        if (h.time.isNotEmpty) h.time,
        if (h.isSkippedOn(now)) 'Skipped today',
      ].join('  ·  ');
      return EditorialEntry(
        key: ValueKey(h.id),
        id: h.id,
        title: h.title,
        meta: meta,
        leading: !active ? '–' : (isDone ? '●' : (h.isCounted && count > 0 ? '◐' : '○')),
        leadingColor: isDone ? ed.accent : ed.muted,
        done: false,
        onLeadingTap: active ? () => log(h) : null,
        onTap: active ? () => log(h) : null,
        onLongPress: () => menu(h),
        onSwipeRight: active ? EditorialSwipe(label: h.isCounted ? '+1' : (isDone ? 'Undo' : 'Done'), onSwipe: () => log(h)) : null,
        onSwipeLeft: active
            ? EditorialSwipe(label: h.isCounted && count > 0 ? '−1' : 'Skip', onSwipe: () {
                if (h.isCounted && count > 0) {
                  n.bump(h.id, by: -1);
                } else {
                  n.toggleSkip(h.id);
                }
              })
            : null,
        below: _Week(habit: h, now: now),
      );
    }

    return EditorialPage(
      kicker: DateLabels.long(now),
      title: 'Habits',
      standfirst: today.isEmpty
          ? (habits.isEmpty ? 'Small things, done often.' : 'Nothing due today.')
          : (done == today.length ? 'All $done done today. Well kept.' : '$done of ${today.length} done today.'),
      actionLabel: 'New',
      onAction: () => openEntryEditor(context, EntryKind.habit),
      slivers: [
        if (habits.isEmpty)
          SliverToBoxAdapter(
            child: EditorialEmpty(
              title: 'Begin with one.',
              message: 'Pick something small enough to do on a bad day. Hold a habit later to count it, choose its days or pause it.',
              actionLabel: 'Add a habit  →',
              onAction: () => openEntryEditor(context, EntryKind.habit),
            ),
          ),
        if (today.isNotEmpty) ...[
          SliverToBoxAdapter(child: EditorialSectionLabel('Today', count: today.length)),
          SliverList.builder(itemCount: today.length, itemBuilder: (_, i) => entry(today[i])),
        ],
        if (resting.isNotEmpty) ...[
          const SliverToBoxAdapter(child: EditorialSectionLabel('Not today')),
          SliverList.builder(itemCount: resting.length, itemBuilder: (_, i) => entry(resting[i], active: resting[i].isScheduledOn(now))),
        ],
        if (habits.isNotEmpty) ...[
          const SliverToBoxAdapter(child: EditorialSectionLabel('The long view')),
          const SliverToBoxAdapter(child: HabitHeatmapWidget()),
        ],
        if (paused.isNotEmpty) ...[
          const SliverToBoxAdapter(child: EditorialSectionLabel('Paused')),
          SliverList.builder(itemCount: paused.length, itemBuilder: (_, i) => entry(paused[i], active: false)),
        ],
      ],
    );
  }
}

/// The last seven days as letters: ink when done, faint when missed, hidden when not due.
class _Week extends StatelessWidget {
  final HabitItem habit;
  final DateTime now;

  const _Week({required this.habit, required this.now});

  @override
  Widget build(BuildContext context) {
    final ed = Ed.of(context);
    final days = [for (var i = 6; i >= 0; i--) DateTime(now.year, now.month, now.day - i)];
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Semantics(
        label: 'Last 7 days: ${days.where(habit.isDoneOn).length} done',
        excludeSemantics: true,
        child: Row(
          children: [
            for (final d in days)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    Text(_weekdayLetters[d.weekday - 1], style: ed.meta.copyWith(fontSize: 11, color: ed.faint)),
                    const SizedBox(height: 2),
                    Text(
                      habit.isDoneOn(d) ? '●' : (habit.isScheduledOn(d) && !habit.isSkippedOn(d) ? '·' : ' '),
                      style: ed.meta.copyWith(color: habit.isDoneOn(d) ? ed.accent : ed.faint, fontSize: 13),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DayPicker extends StatefulWidget {
  final Set<int> initial;

  const _DayPicker({required this.initial});

  @override
  State<_DayPicker> createState() => _DayPickerState();
}

class _DayPickerState extends State<_DayPicker> {
  late final Set<int> _days = widget.initial.isEmpty ? {1, 2, 3, 4, 5, 6, 7} : {...widget.initial};

  @override
  Widget build(BuildContext context) {
    final ed = Ed.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Which days?', style: ed.title),
            const SizedBox(height: 4),
            Text(scheduleLabel(_days), style: ed.meta),
            const SizedBox(height: 16),
            Wrap(
              spacing: 6,
              children: [
                for (var d = 1; d <= 7; d++)
                  Semantics(
                    button: true,
                    selected: _days.contains(d),
                    label: _weekdayNames[d - 1],
                    excludeSemantics: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() {
                        if (!_days.remove(d)) _days.add(d);
                      }),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: ed.entry.copyWith(
                              color: _days.contains(d) ? ed.accent : ed.faint,
                              fontWeight: _days.contains(d) ? FontWeight.w700 : FontWeight.w400,
                            ),
                            child: Text(_weekdayNames[d - 1].substring(0, 2)),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                EditorialAction(label: 'Cancel', muted: true, onTap: () => Navigator.pop(context)),
                const Spacer(),
                EditorialAction(label: 'Save', onTap: _days.isEmpty ? null : () => Navigator.pop(context, _days)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
