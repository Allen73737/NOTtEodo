import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/editorial/editorial_kit.dart';
import '../../../core/services/local_store.dart';
import '../../../core/state/app_settings.dart';
import '../../../core/state/sanctuary_state.dart';
import '../../../core/utils/date_labels.dart';
import '../../../core/services/sanctuary_supabase_service.dart';
import '../../../core/widgets/daily_wisdom_focus_card.dart';
import '../../../core/widgets/entry_editor.dart';
import '../../../core/widgets/evening_zen_review_dialog.dart';
import '../../../core/widgets/executive_dossier_dialog.dart';
import '../../../core/widgets/focus_dial_modal.dart';
import '../../../core/widgets/omni_capture_modal.dart';
import '../../../core/widgets/scoped_ai_dialog.dart';
import '../../../core/widgets/voice_studio_modal.dart';
import '../../journal/presentation/journal_editorial_view.dart' show onThisDay, MemoirReader;
import '../../notes/presentation/notes_editorial_view.dart' show NoteReader;

/// A section of the editorial front page, in the order it can appear.
enum HomeSection { momentum, agenda, habits, tools, money, maxim, notes, journal, travel }

extension on HomeSection {
  String get label => switch (this) {
        HomeSection.momentum => 'Momentum',
        HomeSection.agenda => 'Agenda',
        HomeSection.tools => 'Tools',
        HomeSection.maxim => 'Thought for the day',
        HomeSection.habits => 'Habits',
        HomeSection.money => 'Money',
        HomeSection.notes => 'Recent notes',
        HomeSection.journal => 'Journal',
        HomeSection.travel => 'Next trip',
      };
}

/// Which front-page sections show, and in what order; remembered on this device.
class HomeLayout {
  static const _key = 'editorial_home';
  static const defaults = [HomeSection.momentum, HomeSection.agenda, HomeSection.habits, HomeSection.tools, HomeSection.money, HomeSection.maxim, HomeSection.notes];

  static List<HomeSection> load() {
    final raw = LocalStore().readMap(_key)?['sections'];
    if (raw is! List) return defaults;
    final byName = HomeSection.values.asNameMap();
    return [for (final n in raw) if (byName[n] != null) byName[n]!];
  }

  static void save(List<HomeSection> sections) => LocalStore().writeMap(_key, {'sections': sections.map((s) => s.name).toList()});
}

/// The editorial front page: today's date and greeting, then a few short sections —
/// what is on today, habits, money, recent notes — each a handful of lines with a link
/// to its module. "Arrange" chooses which sections appear and in what order.
class HomeEditorialView extends ConsumerStatefulWidget {
  /// Opens a module by its shell index (1 Notes, 2 Tasks, 3 Planner, 5 Expenses, 6 Travel, 7 Journal, 9 Habits).
  final ValueChanged<int> onOpenModule;

  /// Opens sign-in, offered when nothing is backed up yet.
  final VoidCallback? onSignIn;

  const HomeEditorialView({super.key, required this.onOpenModule, this.onSignIn});

  @override
  ConsumerState<HomeEditorialView> createState() => _HomeEditorialViewState();
}

class _HomeEditorialViewState extends ConsumerState<HomeEditorialView> {
  late List<HomeSection> _sections = HomeLayout.load();

  String _greeting(DateTime now) {
    if (now.hour < 5) return 'Still up';
    if (now.hour < 12) return 'Good morning';
    if (now.hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _arrange() async {
    final result = await showModalBottomSheet<List<HomeSection>>(
      context: context,
      backgroundColor: Ed.of(context).paper,
      elevation: 0,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ArrangeSheet(initial: _sections),
    );
    if (result != null) {
      HomeLayout.save(result);
      setState(() => _sections = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ed = Ed.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final name = ref.watch(appSettingsProvider.select((s) => s.displayName)).trim().split(' ').first;

    final tasks = ref.watch(tasksProvider);
    final events = ref.watch(eventsProvider);
    final habits = ref.watch(habitsProvider);
    final dueToday = tasks.where((t) => !t.completed && t.dueAt != null && t.dueAt!.isBefore(today.add(const Duration(days: 1)))).toList()
      ..sort((a, b) => a.dueAt!.compareTo(b.dueAt!));
    final eventsToday = events.where((e) => DateLabels.isSameDay(e.startsAt, now) && e.endsAt.isAfter(now)).toList();
    final habitsLeft = habits.where((h) => h.isDueOn(now) && !h.isDoneOn(now)).toList();

    final summary = <String>[
      if (eventsToday.isNotEmpty) '${eventsToday.length} ${eventsToday.length == 1 ? 'event' : 'events'}',
      if (dueToday.isNotEmpty) '${dueToday.length} ${dueToday.length == 1 ? 'task' : 'tasks'} due',
      if (habitsLeft.isNotEmpty) '${habitsLeft.length} ${habitsLeft.length == 1 ? 'habit' : 'habits'} to do',
    ];

    return EditorialPage(
      kicker: DateFormat('EEEE d MMMM').format(now),
      title: name.isEmpty ? '${_greeting(now)}.' : '${_greeting(now)}, $name.',
      standfirst: summary.isEmpty ? 'Nothing pressing today.' : '${summary.join(', ')}.',
      slivers: [
        if (widget.onSignIn != null && SanctuarySupabaseService().currentUser == null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: EditorialAction(label: 'Everything is on this phone only. Sign in to back it up  →', onTap: widget.onSignIn),
            ),
          ),
        for (final s in _sections) SliverToBoxAdapter(child: _section(s, now, ed, dueToday, eventsToday, habitsLeft)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 32),
            child: EditorialAction(label: 'Arrange this page', muted: true, onTap: _arrange),
          ),
        ),
      ],
    );
  }

  Widget _more(String label, int module) => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: EditorialAction(label: '$label  →', muted: true, onTap: () => widget.onOpenModule(module)),
      );

  Widget _section(HomeSection s, DateTime now, Ed ed, List<TaskItem> dueToday, List<PlannerEvent> eventsToday, List<HabitItem> habitsLeft) {
    switch (s) {
      case HomeSection.momentum:
        final settings = ref.watch(appSettingsProvider);
        final tasks = ref.watch(tasksProvider);
        final habits = ref.watch(habitsProvider).where((h) => h.isDueOn(now)).toList();
        final today = DateTime(now.year, now.month, now.day);
        final doneTasks = tasks.where((t) => t.completed && t.completedAt != null && !t.completedAt!.isBefore(today)).length;
        final doneHabits = habits.where((h) => h.isDoneOn(now)).length;
        final total = doneTasks + dueToday.length + habits.length;
        final done = doneTasks + doneHabits;
        final streak = settings.activeStreak;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const EditorialSectionLabel('Momentum'),
            Text.rich(
              TextSpan(children: [
                TextSpan(text: '$streak', style: ed.figure.copyWith(color: ed.accent)),
                TextSpan(text: streak == 1 ? '  day in a row' : '  days in a row', style: ed.standfirst),
              ]),
            ),
            if (settings.longestStreak > streak) Text('Your best is ${settings.longestStreak}.', style: ed.meta),
            if (total > 0) ...[
              const SizedBox(height: 10),
              Text(done == total ? 'Everything for today is done.' : '$done of $total things done today.', style: ed.body),
              EditorialMeter(fraction: done / total),
            ],
          ],
        );
      case HomeSection.tools:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const EditorialSectionLabel('Tools'),
            Wrap(
              spacing: 22,
              children: [
                EditorialAction(label: 'Focus timer', onTap: () => FocusDialModal.show(context)),
                EditorialAction(label: 'Voice note', onTap: () => VoiceStudioModal.show(context, ref)),
                EditorialAction(label: 'Ask Nodo AI', onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => ScopedAiDialog(
                      contextScope: 'Global',
                      onClose: () => Navigator.of(ctx).pop(),
                    ),
                  );
                }),
                EditorialAction(label: 'Quick capture', onTap: () => OmniCaptureModal.show(context)),
                EditorialAction(label: now.hour < 15 ? 'Morning briefing' : 'Day so far', onTap: () => showExecutiveDossierDialog(context)),
                if (now.hour >= 17) EditorialAction(label: 'Close the day', onTap: () => EveningZenReviewDialog.show(context)),
              ],
            ),
          ],
        );
      case HomeSection.maxim:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const EditorialSectionLabel('Thought for the day'),
            DailyWisdomFocusCard(onReflectInJournal: () => openEntryEditor(context, EntryKind.memoir)),
          ],
        );
      case HomeSection.agenda:
        final tasks = ref.read(tasksProvider.notifier);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const EditorialSectionLabel('Agenda'),
            if (eventsToday.isEmpty && dueToday.isEmpty)
              Text('A clear day.', style: ed.standfirst)
            else ...[
              for (final e in eventsToday)
                EditorialEntry(
                  id: 'home-e-${e.id}',
                  leading: DateFormat('HH:mm').format(e.startsAt),
                  title: e.title,
                  meta: '${e.durationMinutes} min',
                  onTap: () => openEntryEditor(context, EntryKind.event, editing: e),
                ),
              for (final t in dueToday.take(6))
                EditorialEntry(
                  key: ValueKey('home-t-${t.id}'),
                  id: 'home-t-${t.id}',
                  leading: '○',
                  leadingColor: t.isOverdue(DateTime(now.year, now.month, now.day)) ? ed.accent : ed.muted,
                  title: t.title,
                  meta: t.isOverdue(DateTime(now.year, now.month, now.day)) ? 'Overdue · ${DateLabels.short(t.dueAt!)}' : DateLabels.time(t.dueAt!),
                  onLeadingTap: () => tasks.toggleTask(t.id),
                  onSwipeRight: EditorialSwipe(label: 'Done', onSwipe: () => tasks.toggleTask(t.id)),
                  onSwipeLeft: EditorialSwipe(label: 'Tomorrow', onSwipe: () => tasks.moveToTomorrow(t.id)),
                ),
            ],
            _more('All tasks', 2),
          ],
        );
      case HomeSection.habits:
        final habits = ref.watch(habitsProvider).where((h) => h.isDueOn(now)).toList();
        if (habits.isEmpty) return const SizedBox.shrink();
        final n = ref.read(habitsProvider.notifier);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EditorialSectionLabel('Habits', count: habits.length),
            Wrap(
              spacing: 18,
              runSpacing: 4,
              children: [
                for (final h in habits)
                  Semantics(
                    button: true,
                    checked: h.isDoneOn(now),
                    label: h.title,
                    excludeSemantics: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        n.bump(h.id, by: h.isCounted || !h.isDoneOn(now) ? 1 : -1);
                      },
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 44),
                        child: Align(
                          widthFactor: 1,
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 280),
                            style: ed.entry.copyWith(
                              color: h.isDoneOn(now) ? ed.faint : ed.ink,
                              decoration: h.isDoneOn(now) ? TextDecoration.lineThrough : null,
                              decorationColor: ed.faint,
                            ),
                            child: Text(h.isCounted ? '${h.title} ${h.countOn(now)}/${h.target}' : h.title),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            _more('Habits', 9),
          ],
        );
      case HomeSection.money:
        final settings = ref.watch(appSettingsProvider);
        final spent = ref.watch(expensesProvider).spendInMonth(now);
        final budget = settings.monthlyBudget;
        final fmt = NumberFormat.decimalPatternDigits(decimalDigits: 0);
        String money(double v) => '${settings.currencySymbol}${fmt.format(v)}';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const EditorialSectionLabel('Money'),
            EditorialFigure(
              value: money(spent),
              caption: budget == null ? 'spent in ${DateFormat('MMMM').format(now)}' : '${money((budget - spent).abs())} ${spent > budget ? 'over' : 'left of'} ${money(budget)}',
            ),
            if (budget != null && budget > 0) EditorialMeter(fraction: spent / budget, over: spent > budget),
            _more('Spending', 5),
          ],
        );
      case HomeSection.notes:
        final notes = [...ref.watch(notesProvider)]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const EditorialSectionLabel('Recent notes'),
            if (notes.isEmpty) Text('Nothing written yet.', style: ed.standfirst),
            for (final n in notes.take(3))
              EditorialEntry(
                id: 'home-n-${n.id}',
                title: n.title.isEmpty ? 'Untitled' : n.title,
                meta: n.date,
                onTap: () => pushEditorial(context, NoteReader(noteId: n.id)),
              ),
            _more('Notebook', 1),
          ],
        );
      case HomeSection.journal:
        final entries = ref.watch(journalProvider).where((m) => !m.isPrivate).toList();
        final memories = onThisDay(entries, now);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const EditorialSectionLabel('Journal'),
            if (memories.isEmpty)
              Text(
                entries.any((m) => DateLabels.isSameDay(m.createdAt, now)) ? 'You wrote today.' : 'Nothing written today yet.',
                style: ed.standfirst,
              )
            else
              for (final m in memories)
                EditorialEntry(
                  id: 'home-j-${m.id}',
                  title: m.title,
                  meta: 'On this day · ${DateLabels.long(m.createdAt)}',
                  onTap: () => pushEditorial(context, MemoirReader(memoirId: m.id)),
                ),
            _more('Journal', 7),
          ],
        );
      case HomeSection.travel:
        final next = ref.watch(travelProvider).where((t) => t.isUpcoming(now) || t.covers(now)).firstOrNull;
        if (next == null) return const SizedBox.shrink();
        final days = next.startDate!.difference(DateTime(now.year, now.month, now.day)).inDays;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const EditorialSectionLabel('Next trip'),
            EditorialEntry(
              id: 'home-trip-${next.id}',
              title: next.destination.isEmpty ? next.title : next.destination,
              meta: [next.date, if (days > 0) 'in $days days' else 'now'].join('  ·  '),
              onTap: () => widget.onOpenModule(6),
            ),
          ],
        );
    }
  }
}

class _ArrangeSheet extends StatefulWidget {
  final List<HomeSection> initial;

  const _ArrangeSheet({required this.initial});

  @override
  State<_ArrangeSheet> createState() => _ArrangeSheetState();
}

class _ArrangeSheetState extends State<_ArrangeSheet> {
  late final List<HomeSection> _shown = [...widget.initial];

  @override
  Widget build(BuildContext context) {
    final ed = Ed.of(context);
    final hidden = HomeSection.values.where((s) => !_shown.contains(s)).toList();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Arrange the front page', style: ed.title),
            const SizedBox(height: 4),
            Text('Drag to reorder. Tap a section to hide or show it.', style: ed.meta),
            const SizedBox(height: 12),
            ReorderableListView(
              shrinkWrap: true,
              buildDefaultDragHandles: false,
              physics: const NeverScrollableScrollPhysics(),
              onReorder: (from, to) => setState(() {
                final s = _shown.removeAt(from);
                _shown.insert(to > from ? to - 1 : to, s);
              }),
              proxyDecorator: (child, _, __) => Material(color: ed.paper, child: child),
              children: [
                for (var i = 0; i < _shown.length; i++)
                  ReorderableDragStartListener(
                    key: ValueKey(_shown[i]),
                    index: i,
                    child: EditorialEntry(
                      id: 'arr-${_shown[i].name}',
                      leading: '≡',
                      title: _shown[i].label,
                      onTap: () => setState(() => _shown.removeAt(i)),
                    ),
                  ),
              ],
            ),
            for (final s in hidden)
              EditorialEntry(
                id: 'hid-${s.name}',
                leading: '+',
                leadingColor: ed.accent,
                title: s.label,
                done: true,
                onTap: () => setState(() => _shown.add(s)),
              ),
            Row(
              children: [
                EditorialAction(label: 'Reset', muted: true, onTap: () => setState(() => _shown..clear()..addAll(HomeLayout.defaults))),
                const Spacer(),
                EditorialAction(label: 'Done', onTap: () => Navigator.pop(context, _shown)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
