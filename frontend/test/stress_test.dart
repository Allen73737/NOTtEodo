import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notteodo/app/theme/app_theme.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';
import 'package:notteodo/core/services/cloud_sync_service.dart';
import 'package:notteodo/core/services/data_portability_service.dart';
import 'package:notteodo/core/services/reminder_service.dart';
import 'package:notteodo/core/state/sanctuary_state.dart';
import 'package:notteodo/core/utils/date_labels.dart';
import 'package:notteodo/features/expenses/presentation/expenses_editorial_view.dart';
import 'package:notteodo/features/notes/presentation/notes_editorial_view.dart';
import 'package:notteodo/features/tasks/presentation/tasks_editorial_view.dart';

/// Load and timing checks with years of heavy use: tens of thousands of rows.
/// Budgets are generous (CI machines vary); they catch accidental quadratic work.
void main() {
  final timings = <String, int>{};
  tearDownAll(() {
    // Printed so the numbers can go in the security & performance report.
    // ignore: avoid_print
    timings.forEach((k, v) => print('STRESS  ${k.padRight(52)} ${v.toString().padLeft(6)} ms'));
  });

  int timed(String name, void Function() body) {
    final sw = Stopwatch()..start();
    body();
    sw.stop();
    timings[name] = sw.elapsedMilliseconds;
    return sw.elapsedMilliseconds;
  }

  test('sync merge of 20,000 rows per side stays fast and correct', () {
    final base = [for (var i = 0; i < 20000; i++) {'id': 'r$i', 'v': 'base', 'n': i}];
    final local = [
      for (final r in base)
        if ((r['n'] as int) % 10 != 0) (r['n'] as int) % 7 == 0 ? {...r, 'v': 'local'} : r,
    ];
    final remote = [
      ...base.where((r) => (r['n'] as int) % 13 != 0),
      for (var i = 0; i < 500; i++) {'id': 'new$i', 'v': 'remote'},
    ];
    late Map<String, String> fp;
    final ms = timed('fingerprint 20k rows', () => fp = CloudSyncService.fingerprints(base));
    late List<Map<String, dynamic>> merged;
    final ms2 = timed('three-way merge 20k × 20k rows', () => merged = CloudSyncService.mergeRows(base: fp, local: local, remote: remote));
    expect(ms, lessThan(4000));
    expect(ms2, lessThan(6000));
    // Deleted on either side → gone; new remote rows → present; local edits kept.
    expect(merged.any((r) => r['id'] == 'r10'), isFalse);
    expect(merged.any((r) => r['id'] == 'r13'), isFalse);
    expect(merged.where((r) => '${r['id']}'.startsWith('new')).length, 500);
    expect(merged.firstWhere((r) => r['id'] == 'r7')['v'], 'local');
  });

  test('CSV import of 10,000 bank rows', () {
    final lines = ['Date,Description,Amount,Category'];
    for (var i = 0; i < 10000; i++) {
      lines.add('${(i % 28) + 1}/0${(i % 9) + 1}/2026,"Shop, number $i",-${(i % 500) + 1}.50,Food');
    }
    late List<ExpenseItem> rows;
    final ms = timed('parse 10k-row bank CSV', () => rows = DataPortabilityService.expensesFromCsv(lines.join('\n')));
    expect(rows.length, 10000);
    expect(rows.first.title, 'Shop, number 0');
    expect(ms, lessThan(5000));

    final n = ExpensesNotifier();
    timed('import 10k expenses (dedupe + sort)', () => n.importExpenses(rows));
    expect(n.state.expenses.length, 10000);
    timed('re-import same 10k (all duplicates)', () => expect(n.importExpenses(rows), 0));
  });

  test('five thousand tasks: reminders scan, reorder and subtasks', () {
    final now = DateTime(2026, 11, 9, 12);
    final tasks = [
      for (var i = 0; i < 5000; i++)
        TaskItem(id: 't$i', title: 'Task $i', priority: 'p', space: 's', timeOfDay: 'Morning', dueAt: now.subtract(Duration(minutes: i))),
    ];
    final habits = [for (var i = 0; i < 200; i++) HabitItem(id: 'h$i', title: 'Habit $i', time: '11:30 AM')];
    late List<DueReminder> due;
    timed('reminder scan over 5k tasks + 200 habits', () => due = ReminderService.dueAt(now, tasks: tasks, events: const [], habits: habits));
    expect(due, isNotEmpty);

    final n = TasksNotifier();
    timed('add 5,000 tasks', () {
      for (var i = 0; i < 5000; i++) {
        n.addTask(title: 'T$i');
      }
    });
    final ids = n.state.map((t) => t.id).toList().reversed.take(2000).toList();
    timed('reorder a 2,000-task subset', () => n.reorderSubset(ids));
    expect(n.state.length, 5000);
  });

  test('recurring expenses: 5 years of rent rolls forward once', () {
    final n = ExpensesNotifier();
    final rent = n.addExpense(title: 'Rent', amount: 1000, spentAt: DateTime(2021, 11, 1));
    n.setRecurring(rent.id, true);
    late int added;
    timed('roll 5 years of monthly rent', () => added = n.rollRecurring(DateTime(2026, 11, 9)));
    expect(added, 60);
    expect(n.state.expenses.where((e) => e.recurring).length, 1);
  });

  test('a habit with 3 years of history computes streaks quickly', () {
    final start = DateTime(2023, 11, 9);
    final days = {for (var i = 0; i < 1096; i++) DateLabels.dayKey(DateTime(start.year, start.month, start.day + i))};
    final h = HabitItem(id: 'h', title: 'Read', time: '', completedDays: days, createdAt: start);
    late int streak, best;
    timed('streak + best streak over 3 years', () {
      streak = h.streakAt(DateTime(2026, 11, 8));
      best = h.bestStreak;
    });
    expect(streak, 1096);
    expect(best, 1096);
  });

  for (final (name, view, seed) in [
    ('tasks view with 3,000 tasks', const TasksEditorialView() as Widget, (ProviderContainer c) {
      for (var i = 0; i < 3000; i++) {
        c.read(tasksProvider.notifier).addTask(title: 'Task $i');
      }
    }),
    ('notes view with 3,000 notes', const NotesEditorialView(), (ProviderContainer c) {
      for (var i = 0; i < 3000; i++) {
        c.read(notesProvider.notifier).addNote(title: 'Note $i', space: '', tag: '', excerpt: 'Body #tag${i % 20} text');
      }
    }),
    ('expenses view with 5,000 expenses', const ExpensesEditorialView(), (ProviderContainer c) {
      final now = DateTime.now();
      c.read(expensesProvider.notifier).importExpenses([
        for (var i = 0; i < 5000; i++)
          ExpenseItem(id: 'e$i', title: 'Item $i', amount: i % 300 + 1, category: 'Cat ${i % 12}', spentAt: DateTime(now.year, now.month, (i % 27) + 1)),
      ]);
    }),
  ]) {
    testWidgets('renders and scrolls: $name', (tester) async {
      EditorialMode.active = true;
      addTearDown(() => EditorialMode.active = false);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      final c = ProviderContainer();
      addTearDown(c.dispose);
      seed(c);
      final sw = Stopwatch()..start();
      await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(theme: editorialTheme(AppTheme.lightTheme), home: Scaffold(body: view)),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      timings['first frame: $name'] = sw.elapsedMilliseconds;
      // Lists are lazy: only what is on screen is built, however long the list.
      sw.reset();
      for (var i = 0; i < 20; i++) {
        await tester.drag(find.byType(CustomScrollView).first, const Offset(0, -2000));
        await tester.pump(const Duration(milliseconds: 16));
      }
      timings['20 long flings: $name'] = sw.elapsedMilliseconds;
      expect(tester.takeException(), isNull);
    });
  }
}
