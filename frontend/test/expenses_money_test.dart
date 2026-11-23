import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:notteodo/core/state/sanctuary_state.dart';

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
}
