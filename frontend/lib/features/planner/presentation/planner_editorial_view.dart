import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/editorial/editorial_kit.dart';
import '../../../core/motion/motion.dart';
import '../../../core/state/sanctuary_state.dart';
import '../../../core/utils/date_labels.dart';
import '../../../core/widgets/entry_editor.dart';

/// The planner as a week of days and one day's agenda: events by time, then the tasks
/// due and the habits to do. Everything with a date lives here, whichever module it is from.
class PlannerEditorialView extends ConsumerStatefulWidget {
  const PlannerEditorialView({super.key});

  @override
  ConsumerState<PlannerEditorialView> createState() => _PlannerEditorialViewState();
}

class _PlannerEditorialViewState extends ConsumerState<PlannerEditorialView> {
  DateTime _day = _today();

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  DateTime get _weekStart => _day.subtract(Duration(days: _day.weekday - 1));

  void _shiftWeek(int weeks) => setState(() => _day = DateTime(_day.year, _day.month, _day.day + 7 * weeks));

  @override
  Widget build(BuildContext context) {
    final ed = Ed.of(context);
    final events = ref.watch(eventsProvider);
    final tasks = ref.watch(tasksProvider);
    final habits = ref.watch(habitsProvider);
    final today = _today();

    bool busy(DateTime d) => events.any((e) => DateLabels.isSameDay(e.startsAt, d)) || tasks.any((t) => !t.completed && t.isDueOn(d));

    final dayEvents = events.where((e) => DateLabels.isSameDay(e.startsAt, _day)).toList()..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    final dayTasks = tasks.where((t) => t.isDueOn(_day)).toList()..sort((a, b) => a.dueAt!.compareTo(b.dueAt!));
    final dayHabits = _day.isAfter(today) || DateLabels.isSameDay(_day, today) ? habits.where((h) => h.isDueOn(_day)).toList() : <HabitItem>[];
    final count = dayEvents.length + dayTasks.where((t) => !t.completed).length;

    final week = [for (var i = 0; i < 7; i++) _weekStart.add(Duration(days: i))];

    return EditorialPage(
      kicker: DateFormat('MMMM y').format(_day),
      title: DateLabels.isSameDay(_day, today) ? 'Today' : DateFormat('EEEE d').format(_day),
      standfirst: count == 0 ? 'Nothing planned.' : '$count ${count == 1 ? 'thing' : 'things'} planned.',
      actionLabel: 'New event',
      onAction: () => openEntryEditor(context, EntryKind.event, initialDate: _day.add(const Duration(hours: 9))),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  EditorialAction(label: '←', muted: true, onTap: () => _shiftWeek(-1)),
                  const SizedBox(width: 8),
                  for (final d in week)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: DateLabels.isSameDay(d, _day),
                        label: DateFormat('EEEE d MMMM').format(d),
                        excludeSemantics: true,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _day = d);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              children: [
                                Text(DateFormat('E').format(d).substring(0, 1), style: ed.meta.copyWith(fontSize: 12, color: ed.faint)),
                                const SizedBox(height: 4),
                                AnimatedDefaultTextStyle(
                                  duration: Motion.standard,
                                  style: ed.entry.copyWith(
                                    fontWeight: DateLabels.isSameDay(d, _day) ? FontWeight.w700 : FontWeight.w400,
                                    color: DateLabels.isSameDay(d, _day)
                                        ? ed.accent
                                        : (DateLabels.isSameDay(d, today) ? ed.ink : ed.muted),
                                  ),
                                  child: Text('${d.day}'),
                                ),
                                const SizedBox(height: 2),
                                Text(busy(d) ? '·' : ' ', style: ed.meta.copyWith(color: ed.accent, height: 0.8)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  EditorialAction(label: '→', muted: true, onTap: () => _shiftWeek(1)),
                ],
              ),
              if (!DateLabels.isSameDay(_day, today))
                EditorialAction(label: 'Back to today', muted: true, onTap: () => setState(() => _day = today)),
            ],
          ),
        ),
        if (dayEvents.isEmpty && dayTasks.isEmpty && dayHabits.isEmpty)
          SliverToBoxAdapter(
            child: EditorialEmpty(
              title: 'An open day.',
              message: 'Add an event, or give a task a date and it appears here.',
              actionLabel: 'Add an event  →',
              onAction: () => openEntryEditor(context, EntryKind.event, initialDate: _day.add(const Duration(hours: 9))),
            ),
          ),
        if (dayEvents.isNotEmpty) ...[
          SliverToBoxAdapter(child: EditorialSectionLabel('Schedule', count: dayEvents.length)),
          SliverList.builder(
            itemCount: dayEvents.length,
            itemBuilder: (context, i) {
              final e = dayEvents[i];
              final n = ref.read(eventsProvider.notifier);
              return EditorialEntry(
                key: ValueKey(e.id),
                id: e.id,
                leading: DateFormat('HH:mm').format(e.startsAt),
                title: e.title,
                meta: ['until ${DateFormat('HH:mm').format(e.endsAt)}', if (e.notes.isNotEmpty) e.notes].join('  ·  '),
                onTap: () => openEntryEditor(context, EntryKind.event, editing: e),
                onLongPress: () => showEditorialMenu(context, title: e.title, items: [
                  EditorialMenuItem('Edit', () => openEntryEditor(context, EntryKind.event, editing: e)),
                  EditorialMenuItem('Delete', () => n.deleteEvent(e.id), destructive: true),
                ]),
                onSwipeLeft: EditorialSwipe(label: 'Delete', removes: true, onSwipe: () => n.deleteEvent(e.id)),
              );
            },
          ),
        ],
        if (dayTasks.isNotEmpty) ...[
          SliverToBoxAdapter(child: EditorialSectionLabel('Due', count: dayTasks.length)),
          SliverList.builder(
            itemCount: dayTasks.length,
            itemBuilder: (context, i) {
              final t = dayTasks[i];
              final n = ref.read(tasksProvider.notifier);
              return EditorialEntry(
                key: ValueKey(t.id),
                id: t.id,
                leading: t.completed ? '●' : '○',
                leadingColor: t.completed ? ed.faint : ed.muted,
                title: t.title,
                meta: DateLabels.time(t.dueAt!),
                done: t.completed,
                onLeadingTap: () => n.toggleTask(t.id),
                onTap: () => openEntryEditor(context, EntryKind.task, editing: t),
                onSwipeRight: EditorialSwipe(label: t.completed ? 'Undo' : 'Done', onSwipe: () => n.toggleTask(t.id)),
                onSwipeLeft: t.completed ? null : EditorialSwipe(label: 'Tomorrow', onSwipe: () => n.moveToTomorrow(t.id, now: _day)),
              );
            },
          ),
        ],
        if (dayHabits.isNotEmpty) ...[
          SliverToBoxAdapter(child: EditorialSectionLabel('Habits', count: dayHabits.length)),
          SliverList.builder(
            itemCount: dayHabits.length,
            itemBuilder: (context, i) {
              final h = dayHabits[i];
              final done = h.isDoneOn(_day);
              return EditorialEntry(
                key: ValueKey('h-${h.id}'),
                id: 'h-${h.id}',
                leading: done ? '●' : '○',
                leadingColor: done ? ed.accent : ed.muted,
                title: h.title,
                meta: h.time,
                onLeadingTap: DateLabels.isSameDay(_day, today) ? () => ref.read(habitsProvider.notifier).bump(h.id, by: done ? -1 : 1) : null,
              );
            },
          ),
        ],
      ],
    );
  }
}
