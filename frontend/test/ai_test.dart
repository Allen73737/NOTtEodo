import 'package:flutter_test/flutter_test.dart';
import 'package:notteodo/core/ai/smart_classifier.dart';
import 'package:notteodo/core/ai/smart_grouping.dart';
import 'package:notteodo/core/ai/spending_insights.dart';
import 'package:notteodo/core/ai/text_intelligence.dart';
import 'package:notteodo/core/state/sanctuary_state.dart';

ExpenseItem _x(String title, double amount, String category, DateTime at) =>
    ExpenseItem(id: '$title$at$amount', title: title, amount: amount, category: category, spentAt: at);

void main() {
  group('text intelligence', () {
    test('tokenises, drops stopwords and stems', () {
      expect(TextIntelligence.tokenize('Booking the flights for our trips'), ['book', 'flight', 'trip']);
    });

    test('detects topics in short texts', () {
      expect(TextIntelligence.topicsOf('Renew passport before the flight').first, 'Travel');
      expect(TextIntelligence.topicsOf('Pay rent and electricity bill').first, 'Money & bills');
    });
  });

  group('smart grouping', () {
    test('groups short tasks by meaning, not exact words', () {
      final tasks = [
        'Book flight to Lisbon', 'Renew passport', 'Pack luggage for the trip', 'Reserve hotel in Porto',
        'Prepare client presentation', 'Send project report to manager', 'Team meeting agenda',
        'Buy milk and eggs', 'Order groceries', 'Pick up parcel from the store',
      ];
      final groups = SmartGrouper.group(tasks);
      String groupOf(String t) => groups.firstWhere((g) => g.members.contains(tasks.indexOf(t))).label;

      expect(groupOf('Book flight to Lisbon'), groupOf('Renew passport'));
      expect(groupOf('Reserve hotel in Porto'), groupOf('Pack luggage for the trip'));
      expect(groupOf('Prepare client presentation'), groupOf('Team meeting agenda'));
      expect(groupOf('Buy milk and eggs'), groupOf('Order groceries'));
      expect(groupOf('Book flight to Lisbon'), isNot(groupOf('Team meeting agenda')));
      expect(groupOf('Book flight to Lisbon'), 'Travel');
      // Every item is placed exactly once.
      expect(groups.expand((g) => g.members).toList()..sort(), List.generate(tasks.length, (i) => i));
    });

    test('tiny inputs do not crash and stay together', () {
      expect(SmartGrouper.group(const []), isEmpty);
      expect(SmartGrouper.group(['one']).single.members, [0]);
    });

    test('groups 500 items quickly', () {
      final docs = [for (var i = 0; i < 500; i++) ['Gym workout $i', 'Client meeting $i', 'Buy groceries $i', 'Exam revision $i'][i % 4]];
      final sw = Stopwatch()..start();
      final groups = SmartGrouper.group(docs);
      expect(sw.elapsedMilliseconds, lessThan(3000));
      expect(groups.length, inInclusiveRange(4, 8));
    });
  });

  group('classifiers', () {
    test('expense categories: learns the user’s own labels, falls back to known merchants', () {
      final history = [
        ('Chai with Ravi', 'Food & Dining'), ('Chai at office', 'Food & Dining'), ('Morning chai', 'Food & Dining'),
        ('Cab to office', 'Transport'), ('Cab home', 'Transport'), ('Airport cab', 'Transport'),
      ];
      expect(ExpenseCategorizer.suggest('chai and samosa', history: history)!.value, 'Food & Dining');
      expect(ExpenseCategorizer.suggest('cab to the station', history: history)!.value, 'Transport');
      expect(ExpenseCategorizer.suggest('Swiggy dinner')!.value, 'Food & Dining');
      expect(ExpenseCategorizer.suggest('Netflix monthly')!.value, 'Bills');
      expect(ExpenseCategorizer.suggest('xyzzy'), isNull);
    });

    test('task triage reads urgency and due dates', () {
      final now = DateTime(2026, 11, 3, 9);
      expect(TaskTriage.priority('URGENT: fix the login bug', now: now)!.value, 'Urgent & Critical');
      expect(TaskTriage.priority('Submit tax return', now: now)!.value, 'High Priority');
      expect(TaskTriage.priority('Call Sam', dueAt: now.add(const Duration(hours: 3)), now: now)!.value, 'High Priority');
      expect(TaskTriage.priority('Maybe learn the ukulele someday', now: now)!.value, 'Low Priority');
      expect(TaskTriage.priority('Water the plants', now: now), isNull);
    });

    test('mood detection, negation-aware sentiment', () {
      expect(MoodSense.mood('So grateful for my friends today, felt really blessed')!.value, 'Grateful');
      expect(MoodSense.mood('Exhausted after a long week, I could barely keep my eyes open')!.value, 'Tired');
      expect(MoodSense.sentiment('I am happy'), greaterThan(0));
      expect(MoodSense.sentiment('I am not happy'), lessThan(0));
    });

    test('shopping aisles', () {
      expect(ShoppingAisles.aisleFor('Organic bananas'), 'Fruit & veg');
      expect(ShoppingAisles.aisleFor('Greek yogurt'), 'Dairy & eggs');
      expect(ShoppingAisles.aisleFor('Dish soap'), 'Household');
      expect(ShoppingAisles.aisleFor('Mystery item'), 'Other');
    });

    test('note tags and related notes', () {
      final corpus = ['Trip planning for Kyoto temples and ryokan', 'Weekly grocery list', 'Kyoto restaurant ideas'];
      final tags = NoteTagger.suggestTags('Kyoto itinerary: temples, gardens and the ryokan booking', corpus: corpus);
      expect(tags, isNotEmpty);
      expect(NoteTagger.related('Things to see in Kyoto', corpus).first, anyOf(0, 2));
    });
  });

  group('spending insights', () {
    test('forecasts overspend and spots subscriptions', () {
      final now = DateTime(2026, 11, 10);
      final xs = [
        for (var m = 8; m <= 11; m++) _x('Netflix', 649, 'Bills', DateTime(2026, m, 2)),
        _x('Rent', 2000, 'Bills', DateTime(2026, 11, 1)),
        _x('Dinner', 3000, 'Food & Dining', DateTime(2026, 11, 8)),
      ];
      final insights = SpendingInsights.analyze(xs, now: now, monthlyBudget: 10000, currency: '₹');
      expect(insights.any((i) => i.tone == InsightTone.warning && i.title.contains('overspend')), isTrue);
      expect(insights.any((i) => i.title.contains('recurring payment')), isTrue);
    });

    test('says so when on track', () {
      final now = DateTime(2026, 11, 20);
      final xs = [_x('Lunch', 100, 'Food & Dining', DateTime(2026, 11, 5))];
      final insights = SpendingInsights.analyze(xs, now: now, monthlyBudget: 10000);
      expect(insights.first.tone, InsightTone.good);
    });
  });
}
