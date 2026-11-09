import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/editorial/editorial_kit.dart';
import '../../../core/motion/motion.dart';
import '../../../core/services/ai_copilot_service.dart';
import '../../../core/services/calendar_reminder_service.dart';
import '../../../core/services/nlp_date_parser.dart';
import '../../../core/state/sanctuary_state.dart';
import '../../../core/utils/date_labels.dart';
import '../../../core/widgets/app_toast_engine.dart';
import '../../../core/widgets/entry_editor.dart';
import '../../../core/widgets/evening_zen_review_dialog.dart';
import '../../../core/widgets/floating_voice_ai_widget.dart' show quickCaptureTitle;
import '../../../core/widgets/sanctuary_clock_picker.dart';

/// Tasks as a page of text: today, upcoming, anytime and done. Type a line to add a
/// task ("call mom tomorrow 5pm" sets the due time), tap the circle to finish it, tap
/// the task to see its steps, swipe right to finish, left to delete, hold for more.
class TasksEditorialView extends ConsumerStatefulWidget {
  const TasksEditorialView({super.key});

  @override
  ConsumerState<TasksEditorialView> createState() => _TasksEditorialViewState();
}

class _TasksEditorialViewState extends ConsumerState<TasksEditorialView> {
  static const _tabs = ['Today', 'Upcoming', 'Anytime', 'Done'];
  String _tab = 'Today';
  String _query = '';
  String? _expanded;
  bool _arranging = false;

  TasksNotifier get _tasks => ref.read(tasksProvider.notifier);

  void _add(String text) {
    final due = NlpDateParser.parse(text);
    final title = due == null ? text : quickCaptureTitle(text);
    _tasks.addTask(title: title, dueAt: due);
    if (due != null) {
      AppToastEngine().notify(title: 'Added', message: '$title · ${DateLabels.dateTime(due)}');
    }
  }

  void _toggle(TaskItem t) {
    HapticFeedback.lightImpact();
    _tasks.toggleTask(t.id);
  }

  Future<void> _remind(TaskItem t) async {
    final now = DateTime.now();
    final base = t.dueAt ?? now;
    final picked = await showSanctuaryClockPicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(t.dueAt ?? now.add(const Duration(hours: 1))),
      helpText: 'REMIND ME AT',
    );
    if (picked == null) return;
    var at = DateTime(base.year, base.month, base.day, picked.hour, picked.minute);
    final movedToTomorrow = !at.isAfter(now);
    if (movedToTomorrow) at = at.add(const Duration(days: 1));
    await CalendarReminderService().scheduleDeviceReminder(id: t.id, title: t.title, scheduledTime: at, body: t.notes.isEmpty ? null : t.notes);
    AppToastEngine().notify(
      title: 'Reminder set',
      message: '${DateLabels.dateTime(at)}${movedToTomorrow ? ' (that time already passed today)' : ''}',
    );
  }

  Future<void> _addStep(TaskItem t) async {
    final step = await showEditorialPrompt(context, title: 'Add a step', hint: 'e.g. Book the van');
    if (step != null && step.isNotEmpty) {
      _tasks.addSubtask(t.id, step);
      setState(() => _expanded = t.id);
    }
  }

  /// Asks the AI for steps and adds them, showing the task opened.
  Future<void> _breakDown(TaskItem t) async {
    AppToastEngine().notify(title: 'Thinking…', message: 'Breaking "${t.title}" into steps.');
    final steps = await AiCopilotService().breakdownTask(t.title);
    if (!mounted || steps.isEmpty) return;
    for (final step in steps.take(8)) {
      _tasks.addSubtask(t.id, step);
    }
    setState(() => _expanded = t.id);
  }

  void _menu(TaskItem t) {
    showEditorialMenu(
      context,
      title: t.title,
      subtitle: _meta(t, DateTime.now()),
      items: [
        EditorialMenuItem(t.completed ? 'Mark as not done' : 'Mark as done', () => _toggle(t)),
        EditorialMenuItem('Edit', () => openEntryEditor(context, EntryKind.task, editing: t)),
        if (!t.completed) EditorialMenuItem('Move to tomorrow', () => _tasks.moveToTomorrow(t.id)),
        EditorialMenuItem('Add a step', () => _addStep(t)),
        if (!t.completed) EditorialMenuItem('Break it into steps (AI)', () => _breakDown(t)),
        EditorialMenuItem('Copy text', () => copyToClipboard(
              [t.title, if (t.notes.trim().isNotEmpty) t.notes.trim(), for (final s in t.subtasks) '${s.done ? '✓' : '–'} ${s.title}'].join('\n'),
              what: 'Task',
            )),
        if (!t.completed) EditorialMenuItem('Remind me…', () => _remind(t)),
        EditorialMenuItem('Delete', () => _tasks.deleteTask(t.id), destructive: true),
      ],
    );
  }

  String _meta(TaskItem t, DateTime now) {
    final parts = <String>[
      if (t.dueAt != null) t.isOverdue(now) ? 'Overdue · ${DateLabels.dateTime(t.dueAt!)}' : DateLabels.dateTime(t.dueAt!, now: now),
      if (t.subtasks.isNotEmpty) '${t.subtasksDone} of ${t.subtasks.length} steps',
      if (t.repeat != TaskRepeat.none) t.repeat.label,
      if (t.space.isNotEmpty && t.space != 'General Space') t.space,
    ];
    return parts.join('  ·  ');
  }

  bool _isHigh(TaskItem t) => t.priority.toLowerCase().contains('high') || t.priority.toLowerCase().contains('urgent');

  bool _matches(TaskItem t) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return t.title.toLowerCase().contains(q) || t.notes.toLowerCase().contains(q) || t.subtasks.any((s) => s.title.toLowerCase().contains(q));
  }

  /// Groups for the current tab, in display order.
  List<(String, List<TaskItem>)> _groups(List<TaskItem> all, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final open = all.where((t) => !t.completed && _matches(t)).toList();
    int byDue(TaskItem a, TaskItem b) => a.dueAt!.compareTo(b.dueAt!);

    switch (_tab) {
      case 'Today':
        final overdue = open.where((t) => t.dueAt != null && t.dueAt!.isBefore(today)).toList()..sort(byDue);
        final dueToday = open.where((t) => t.dueAt != null && !t.dueAt!.isBefore(today) && t.dueAt!.isBefore(tomorrow)).toList()
          ..sort(byDue);
        final doneToday = all.where((t) => t.completed && _matches(t) && t.completedAt != null && !t.completedAt!.isBefore(today)).toList();
        // Undated tasks are listed too, so a task added here without a time stays in view.
        final undated = open.where((t) => t.dueAt == null).toList();
        return [('Overdue', overdue), ('Today', dueToday), ('Anytime', undated), ('Finished today', doneToday)];
      case 'Upcoming':
        final later = open.where((t) => t.dueAt != null && !t.dueAt!.isBefore(tomorrow)).toList()..sort(byDue);
        final byDay = <String, List<TaskItem>>{};
        for (final t in later) {
          byDay.putIfAbsent(DateLabels.relative(t.dueAt!, now: now), () => []).add(t);
        }
        return [for (final e in byDay.entries) (e.key, e.value)];
      case 'Anytime':
        return [('No date', open.where((t) => t.dueAt == null).toList())];
      default:
        final done = all.where((t) => t.completed && _matches(t)).toList()
          ..sort((a, b) => (b.completedAt ?? b.createdAt).compareTo(a.completedAt ?? a.createdAt));
        return [('Done', done)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final ed = Ed.of(context);
    final all = ref.watch(tasksProvider);
    final now = DateTime.now();
    final groups = _groups(all, now).where((g) => g.$2.isNotEmpty).toList();
    final open = all.where((t) => !t.completed).length;
    final overdue = all.where((t) => t.isOverdue(DateTime(now.year, now.month, now.day))).length;

    final standfirst = open == 0
        ? 'Nothing open. Enjoy the quiet.'
        : '$open open${overdue > 0 ? ', $overdue overdue' : ''}.';

    return EditorialPage(
      kicker: DateLabels.long(now),
      title: 'Tasks',
      standfirst: standfirst,
      actionLabel: 'New',
      onAction: () => openEntryEditor(context, EntryKind.task),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EditorialAddLine(hint: 'Add a task — "call mom tomorrow 5pm"', onAdd: _add),
              EditorialSearch(hint: 'Search tasks', onChanged: (v) => setState(() => _query = v)),
              if (DateTime.now().hour >= 17)
                EditorialAction(label: 'Close the day  →', muted: true, onTap: () => EveningZenReviewDialog.show(context)),
              EditorialTabs(options: _tabs, selected: _tab, onSelected: (t) => setState(() {
                _tab = t;
                _arranging = false;
              })),
            ],
          ),
        ),
        if (groups.isEmpty)
          SliverToBoxAdapter(
            child: EditorialEmpty(
              title: _query.isNotEmpty ? 'No matches.' : _emptyTitle(),
              message: _query.isNotEmpty ? 'Try fewer words.' : 'Add one above, or write it in plain words with a time.',
            ),
          ),
        for (final (label, items) in groups) ...[
          SliverToBoxAdapter(
            child: EditorialSectionLabel(
              label,
              count: items.length,
              actionLabel: _tab == 'Anytime' && items.length > 1 ? (_arranging ? 'Finish' : 'Arrange') : null,
              onAction: () => setState(() => _arranging = !_arranging),
            ),
          ),
          if (_arranging && _tab == 'Anytime')
            SliverReorderableList(
              itemCount: items.length,
              onReorder: (from, to) {
                final ids = items.map((t) => t.id).toList();
                final moved = ids.removeAt(from);
                ids.insert(to > from ? to - 1 : to, moved);
                _tasks.reorderSubset(ids);
              },
              itemBuilder: (context, i) => ReorderableDragStartListener(
                key: ValueKey('arr-${items[i].id}'),
                index: i,
                child: ColoredBox(
                  color: ed.paper,
                  child: EditorialEntry(id: items[i].id, title: items[i].title, leading: '≡', meta: _meta(items[i], now)),
                ),
              ),
            )
          else
            SliverList.builder(
              itemCount: items.length,
              itemBuilder: (context, i) => _entry(items[i], now, ed),
            ),
        ],
      ],
    );
  }

  String _emptyTitle() => switch (_tab) {
        'Today' => 'A clear day.',
        'Upcoming' => 'Nothing scheduled ahead.',
        'Anytime' => 'No undated tasks.',
        _ => 'Nothing finished yet.',
      };

  Widget _entry(TaskItem t, DateTime now, Ed ed) {
    final expanded = _expanded == t.id;
    return EditorialEntry(
      key: ValueKey(t.id),
      id: t.id,
      title: t.title,
      meta: _meta(t, now),
      leading: t.completed ? '●' : '○',
      leadingColor: t.completed ? ed.faint : (_isHigh(t) || t.isOverdue(now) ? ed.accent : ed.muted),
      done: t.completed,
      onLeadingTap: () => _toggle(t),
      onTap: () => setState(() => _expanded = expanded ? null : t.id),
      onLongPress: () => _menu(t),
      onSwipeRight: EditorialSwipe(label: t.completed ? 'Undo' : 'Done', onSwipe: () => _toggle(t)),
      onSwipeLeft: EditorialSwipe(label: 'Delete', removes: true, onSwipe: () => _tasks.deleteTask(t.id)),
      below: expanded ? _Steps(task: t) : null,
    );
  }
}

/// A task's notes and steps, shown under it when tapped.
class _Steps extends ConsumerWidget {
  final TaskItem task;

  const _Steps({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ed = Ed.of(context);
    final n = ref.read(tasksProvider.notifier);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (task.notes.trim().isNotEmpty)
            Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(task.notes.trim(), style: ed.body.copyWith(color: ed.muted))),
          for (final s in task.subtasks)
            Semantics(
              checked: s.done,
              label: s.title,
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  n.toggleSubtask(task.id, s.id);
                },
                onLongPress: () => n.removeSubtask(task.id, s.id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 26, child: Text(s.done ? '✓' : '–', style: ed.meta.copyWith(color: s.done ? ed.accent : ed.muted))),
                      Expanded(
                        child: AnimatedDefaultTextStyle(
                          duration: Motion.standard,
                          style: ed.meta.copyWith(
                            fontSize: 15,
                            color: s.done ? ed.faint : ed.ink,
                            decoration: s.done ? TextDecoration.lineThrough : null,
                            decorationColor: ed.faint,
                          ),
                          child: Text(s.title),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          EditorialAddLine(hint: 'Add a step', onAdd: (v) => n.addSubtask(task.id, v)),
        ],
      ),
    );
  }
}
