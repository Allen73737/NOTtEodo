import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:notteodo/core/state/app_settings.dart';
import 'package:notteodo/core/state/sanctuary_state.dart';
import 'package:notteodo/features/expenses/presentation/expenses_screen.dart';

void main() {
  late ProviderContainer c;
  late ExpensesNotifier expenses;

  setUp(() {
    c = ProviderContainer();
    expenses = c.read(expensesProvider.notifier);
  });
  tearDown(() => c.dispose());

  test('settlements are saved as numbers and shown in the chosen currency', () {
    expenses.addSettlement(from: 'Alex', to: 'You', amount: '33.33');
    final s = c.read(expensesProvider).settlements.first;
    expect(s.amount, '33.33');
    expect(s.display(r'$'), r'$33.33');
    expect(s.display('₹'), '₹33.33');
  });

  test('settlements saved with a sign before still read correctly', () {
    const old = SettlementItem(id: 'x', from: 'Sam', to: 'You', amount: '₹1200');
    expect(old.value, 1200);
    expect(old.display('€'), '€1,200');
  });

  test('editing an expense can turn monthly repeating on and off', () {
    final e = expenses.addExpense(title: 'Rent', amount: 900);
    expenses.updateExpense(e.id, recurring: true);
    expect(c.read(expensesProvider).expenses.single.recurring, isTrue);
    expenses.updateExpense(e.id, title: 'Rent (flat)');
    expect(c.read(expensesProvider).expenses.single.recurring, isTrue);
    expenses.updateExpense(e.id, recurring: false);
    expect(c.read(expensesProvider).expenses.single.recurring, isFalse);
  });

  group('cards view on a small phone', () {
    Future<void> pump(WidgetTester tester, ProviderContainer c) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: const Scaffold(body: ExpensesScreen()),
        ),
      ));
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('uses the currency from Settings and no made-up budget', (tester) async {
      c.read(appSettingsProvider.notifier).setCurrency(r'$');
      expenses.addExpense(title: 'Coffee', amount: 4);
      await pump(tester, c);
      expect(find.text('No monthly budget yet'), findsOneWidget);
      expect(find.textContaining('₹'), findsNothing);
      expect(find.textContaining(r'$4'), findsWidgets);
    });

    for (final (label, open) in <(String, Finder Function())>[
      ('Add expense', () => find.text('Add expense')),
      ('Export', () => find.text('Export')),
      ('Split', () => find.byTooltip('Split Bill Calculator')),
      ('Add split balance', () => find.byTooltip('Add Split Balance')),
      ('Subscriptions', () => find.text('Subscriptions')),
    ]) {
      testWidgets('$label opens cleanly', (tester) async {
        expenses.addExpense(title: 'Rent', amount: 1200, recurring: true);
        final errors = <String>[];
        final previous = FlutterError.onError;
        FlutterError.onError = (d) {
          errors.add(d.exceptionAsString().split('\n').first);
          if (const bool.fromEnvironment('DUMP')) debugPrint('=====DUMP $d');
        };
        await pump(tester, c);
        final target = open();
        await tester.ensureVisible(target.first);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(target.first, warnIfMissed: false);
        for (var i = 0; i < 12; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        final err = tester.takeException();
        FlutterError.onError = previous;
        if (err != null) errors.add('$err');
        expect(errors, isEmpty, reason: errors.join('\n'));
      });
    }
  });
}
