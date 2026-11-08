import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notteodo/app/theme/app_dark_theme.dart';
import 'package:notteodo/app/theme/app_theme.dart';
import 'package:notteodo/core/state/bin_state.dart';
import 'package:notteodo/core/state/sanctuary_state.dart';
import 'package:notteodo/features/expenses/presentation/expenses_editorial_view.dart';
import 'package:notteodo/features/habits/presentation/habits_editorial_view.dart';
import 'package:notteodo/features/home/presentation/home_editorial_view.dart';
import 'package:notteodo/features/journal/presentation/journal_editorial_view.dart';
import 'package:notteodo/features/moodboard/presentation/moodboard_editorial_view.dart';
import 'package:notteodo/features/notes/presentation/notes_editorial_view.dart';
import 'package:notteodo/features/planner/presentation/planner_editorial_view.dart';
import 'package:notteodo/features/shopping/presentation/shopping_editorial_view.dart';
import 'package:notteodo/features/tasks/presentation/tasks_editorial_view.dart';
import 'package:notteodo/features/travel/presentation/travel_editorial_view.dart';
import 'package:notteodo/features/wardrobe/presentation/wardrobe_editorial_view.dart';

import 'support/fixtures.dart';

Future<void> _show(WidgetTester tester, ProviderContainer c, Widget view, {bool dark = false, double textScale = 1}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppDarkTheme.darkTheme,
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(body: view),
    ),
  ));
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  final views = <String, Widget>{
    'home': HomeEditorialView(onOpenModule: (_) {}),
    'notes': const NotesEditorialView(),
    'tasks': const TasksEditorialView(),
    'planner': const PlannerEditorialView(),
    'wardrobe': const WardrobeEditorialView(),
    'expenses': const ExpensesEditorialView(),
    'travel': const TravelEditorialView(),
    'journal': const JournalEditorialView(),
    'moodboard': const MoodboardEditorialView(),
    'habits': const HabitsEditorialView(),
    'shopping': const ShoppingEditorialView(),
  };

  group('every editorial view renders with data, both themes, large text', () {
    for (final e in views.entries) {
      for (final (dark, scale) in [(false, 1.0), (true, 1.0), (false, 1.6)]) {
        testWidgets('${e.key} · ${dark ? 'dark' : 'light'} · text ×$scale', (tester) async {
          final c = ProviderContainer();
          addTearDown(c.dispose);
          seedEverything(c);
          await _show(tester, c, e.value, dark: dark, textScale: scale);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  testWidgets('tasks: typing a line adds a task, tapping its circle completes it', (tester) async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await _show(tester, c, const TasksEditorialView());

    await tester.enterText(find.byType(TextField).first, 'Water the plants');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(const Duration(milliseconds: 400));
    expect(c.read(tasksProvider).single.title, 'Water the plants');
    expect(find.text('Water the plants'), findsOneWidget);

    await tester.tap(find.text('○'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(c.read(tasksProvider).single.completed, isTrue);
  });

  testWidgets('tasks: swiping left deletes into the Bin', (tester) async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.read(tasksProvider.notifier).addTask(title: 'Throwaway');
    await _show(tester, c, const TasksEditorialView());

    await tester.drag(find.text('Throwaway'), const Offset(-300, 0));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(c.read(tasksProvider), isEmpty);
    expect(c.read(binProvider).single.title, 'Throwaway');
  });

  testWidgets('habits: tapping a counted habit adds one each time', (tester) async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.read(habitsProvider.notifier).addHabit(title: 'Water', time: '', target: 2, unit: 'glasses');
    await _show(tester, c, const HabitsEditorialView());

    await tester.tap(find.text('Water'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('1 of 2 glasses'), findsOneWidget);
    await tester.tap(find.text('Water'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(c.read(habitsProvider).single.completedToday, isTrue);
  });

  testWidgets('notes: a checklist line can be ticked in the reader', (tester) async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final note = c.read(notesProvider.notifier).addNote(title: 'Packing', space: '', tag: '', excerpt: '', content: '- [ ] Socks\n- [x] Charger');
    await _show(tester, c, NoteReader(noteId: note.id));

    await tester.tap(find.text('Socks'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(c.read(notesProvider).single.content, '- [x] Socks\n- [x] Charger');
  });

  test('shopping lines parse quantity, store and price', () {
    final p = ShoppingEditorialView.parseLine('Eggs x6 @ Market 40');
    expect([p.name, p.quantity, p.store, p.price], ['Eggs', 6, 'Market', 40]);
    final plain = ShoppingEditorialView.parseLine('Milk');
    expect([plain.name, plain.quantity, plain.store, plain.price], ['Milk', 1, '', 0]);
  });

  test('note tags combine the tag field and #hashtags; links are found', () {
    final n = NoteItem(id: 'n', title: 't', space: '', tag: 'Work', excerpt: '', content: 'Plan #q4 with #Design and [[Roadmap]]');
    expect(noteTags(n), ['work', 'q4', 'design']);
    expect(noteLinks(n.content), ['Roadmap']);
  });

  test('on this day finds last year\'s entry and last month\'s', () {
    final now = DateTime(2026, 11, 8);
    final entries = [
      MemoirItem(id: 'a', title: 'Last year', duration: '', excerpt: '', createdAt: DateTime(2025, 11, 8)),
      MemoirItem(id: 'b', title: 'Last month', duration: '', excerpt: '', createdAt: DateTime(2026, 10, 8)),
      MemoirItem(id: 'c', title: 'Yesterday', duration: '', excerpt: '', createdAt: DateTime(2026, 11, 7)),
    ];
    expect(onThisDay(entries, now).map((m) => m.title), ['Last year', 'Last month']);
  });
}
