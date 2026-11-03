import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures.dart';
import 'package:notteodo/core/state/bin_state.dart';
import 'package:notteodo/core/state/sanctuary_state.dart';
import 'package:notteodo/core/widgets/app_toast_engine.dart';
import 'package:notteodo/features/bin/presentation/bin_screen.dart';

void main() {
  late ProviderContainer container;
  setUp(() {
    container = ProviderContainer();
    seedEverything(container);
  });
  tearDown(() => container.dispose());

  test('deleting a task moves it to the Bin and offers Undo', () async {
    final toasts = <AppToastItem>[];
    final sub = AppToastEngine().toastStream.listen(toasts.add);
    addTearDown(sub.cancel);

    final tasks = container.read(tasksProvider);
    final victim = tasks[1];
    container.read(tasksProvider.notifier).deleteTask(victim.id);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(tasksProvider).any((t) => t.id == victim.id), isFalse);
    final bin = container.read(binProvider);
    expect(bin.single.id, victim.id);
    expect(bin.single.kind, BinKind.task);
    expect(toasts.last.actionLabel, 'Undo');

    // Undo from the toast restores it to exactly where it was.
    toasts.last.onAction!();
    expect(container.read(tasksProvider)[1].id, victim.id);
    expect(container.read(binProvider), isEmpty);
  });

  test('restore puts items back at their original position across modules', () {
    final notes = container.read(notesProvider);
    final middle = notes[1];
    container.read(notesProvider.notifier).deleteNote(middle.id);
    container.read(binProvider.notifier).restore(middle.id);
    expect(container.read(notesProvider).map((n) => n.id).toList(), notes.map((n) => n.id).toList());
  });

  test('every deletable kind lands in the Bin', () {
    container.read(notesProvider.notifier).deleteNote(container.read(notesProvider).first.id);
    container.read(tasksProvider.notifier).deleteTask(container.read(tasksProvider).first.id);
    container.read(expensesProvider.notifier).deleteExpense(container.read(expensesProvider).expenses.first.id);
    container.read(shoppingProvider.notifier).deleteItem(container.read(shoppingProvider).first.id);
    container.read(wardrobeProvider.notifier).removeOutfit(container.read(wardrobeProvider).first.id);
    container.read(habitsProvider.notifier).deleteHabit(container.read(habitsProvider).first.id);
    container.read(travelProvider.notifier).deleteTrip(container.read(travelProvider).first.id);
    container.read(journalProvider.notifier).deleteMemoir(container.read(journalProvider).first.id);
    container.read(eventsProvider.notifier).deleteEvent(container.read(eventsProvider).first.id);
    container.read(moodboardProvider.notifier).deletePin(container.read(moodboardProvider).first.id);

    expect(container.read(binProvider).map((e) => e.kind).toSet(), BinKind.values.toSet());

    // And every kind goes back where it came from.
    container.read(binProvider.notifier).restoreAll();
    expect(container.read(binProvider), isEmpty);
    expect(container.read(moodboardProvider), hasLength(3));
    expect(container.read(habitsProvider), hasLength(3));
  });

  test('purge and empty remove entries for good', () {
    final shopping = container.read(shoppingProvider);
    container.read(shoppingProvider.notifier).deleteItem(shopping[0].id);
    container.read(shoppingProvider.notifier).deleteItem(shopping[1].id);
    expect(container.read(binProvider), hasLength(2));

    container.read(binProvider.notifier).purge(shopping[0].id);
    expect(container.read(binProvider).single.id, shopping[1].id);

    container.read(binProvider.notifier).empty();
    expect(container.read(binProvider), isEmpty);
    expect(container.read(shoppingProvider).length, shopping.length - 2);
  });

  test('entries report days left out of the 30-day retention', () {
    container.read(tasksProvider.notifier).deleteTask(container.read(tasksProvider).first.id);
    final entry = container.read(binProvider).single;
    expect(entry.daysLeft(DateTime.now()), anyOf(29, 30));
    expect(entry.daysLeft(DateTime.now().add(const Duration(days: 31))), 0);
  });

  for (final size in const [Size(390, 844), Size(1440, 900)]) {
    for (final dark in [false, true]) {
      testWidgets('a full Bin board renders and restores · ${size.width.toInt()}px · ${dark ? 'dark' : 'light'}',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);

        final c = ProviderContainer();
        addTearDown(c.dispose);
        seedEverything(c);
        for (final n in [...c.read(notesProvider)]) {
          c.read(notesProvider.notifier).deleteNote(n.id);
        }
        for (final t in [...c.read(tasksProvider)]) {
          c.read(tasksProvider.notifier).deleteTask(t.id);
        }
        c.read(wardrobeProvider.notifier).removeOutfit(c.read(wardrobeProvider).first.id);
        c.read(expensesProvider.notifier).deleteExpense(c.read(expensesProvider).expenses.first.id);

        int? opened;
        await tester.pumpWidget(UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
            home: Scaffold(body: BinScreen(onOpenModule: (i) => opened = i)),
          ),
        ));
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        expect(tester.takeException(), isNull);
        final before = c.read(binProvider).length;
        expect(find.text('Restore'), findsWidgets);

        await tester.tap(find.text('Restore').first);
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        expect(c.read(binProvider).length, before - 1);
        expect(tester.takeException(), isNull);
        expect(opened, isNull);
      });
    }
  }
}
