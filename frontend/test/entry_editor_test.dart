import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures.dart';
import 'package:notteodo/core/state/sanctuary_state.dart';
import 'package:notteodo/core/widgets/entry_editor.dart';
import 'package:notteodo/features/auth/presentation/onboarding_screen.dart';
import 'package:notteodo/main.dart';

Future<void> _pumpFrames(WidgetTester tester, [int n = 20]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('expense editor validates, then saves a real expense', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final c = ProviderContainer();
    addTearDown(c.dispose);
    var closed = false;
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        home: Scaffold(body: EntryEditor(kind: EntryKind.expense, onClose: () => closed = true)),
      ),
    ));
    await _pumpFrames(tester);

    await tester.tap(find.text('Save Expense'));
    await _pumpFrames(tester, 5);
    expect(find.text('Give it a title'), findsOneWidget);
    expect(find.text('Enter an amount'), findsOneWidget);
    expect(closed, isFalse);

    final before = c.read(expensesProvider).expenses.length;
    await tester.enterText(find.byType(TextFormField).first, 'Train tickets');
    await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '640');
    await tester.tap(find.text('Transport'));
    await tester.tap(find.text('Save Expense'));
    await _pumpFrames(tester, 5);

    expect(closed, isTrue);
    final expenses = c.read(expensesProvider).expenses;
    expect(expenses.length, before + 1);
    final saved = expenses.firstWhere((e) => e.title == 'Train tickets');
    expect(saved.amount, 640);
    expect(saved.category, 'Transport');
  });

  testWidgets('editing a task changes it in place', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final c = ProviderContainer();
    addTearDown(c.dispose);
    seedEverything(c);
    final task = c.read(tasksProvider).first;
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        home: Scaffold(body: EntryEditor(kind: EntryKind.task, editing: task, onClose: () {})),
      ),
    ));
    await _pumpFrames(tester);

    await tester.enterText(find.byType(TextFormField).first, 'Renamed task');
    await tester.tap(find.text('Save changes'));
    await _pumpFrames(tester, 5);

    final updated = c.read(tasksProvider).firstWhere((t) => t.id == task.id);
    expect(updated.title, 'Renamed task');
    expect(c.read(tasksProvider).length, greaterThanOrEqualTo(3));
  });

  testWidgets('a first launch goes through onboarding', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const ProviderScope(child: NOTtEodoApp()));
    // Let the logo reveal play out.
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
