import 'package:flutter_test/flutter_test.dart';
import 'package:notteodo/core/state/sanctuary_state.dart';
import 'package:notteodo/core/utils/date_labels.dart';

void main() {
  final monday = DateTime(2026, 11, 2); // a Monday

  group('habits', () {
    test('a counted habit is done once the target is reached', () {
      final n = HabitsNotifier();
      final h = n.addHabit(title: 'Water', time: '08:00 AM', target: 3, unit: 'glasses');
      expect(n.bump(h.id, on: monday), isFalse);
      expect(n.bump(h.id, on: monday), isFalse);
      expect(n.bump(h.id, on: monday), isTrue);
      final saved = n.state.single;
      expect(saved.countOn(monday), 3);
      expect(saved.isDoneOn(monday), isTrue);
      n.bump(h.id, by: -1, on: monday);
      expect(n.state.single.isDoneOn(monday), isFalse);
    });

    test('days it is not scheduled on, and skipped days, keep the streak alive', () {
      // Due Mon/Wed/Fri; done Mon and Wed, Thu is a rest day, Fri skipped.
      final h = HabitItem(
        id: 'h',
        title: 'Gym',
        time: '07:00 AM',
        weekdays: const {1, 3, 5},
        completedDays: {DateLabels.dayKey(monday), DateLabels.dayKey(monday.add(const Duration(days: 2)))},
        skippedDays: {DateLabels.dayKey(monday.add(const Duration(days: 4)))},
        createdAt: monday,
      );
      expect(h.streakAt(monday.add(const Duration(days: 5))), 2);
      expect(h.bestStreak, 2);
    });

    test('a missed due day breaks the streak', () {
      final h = HabitItem(
        id: 'h',
        title: 'Read',
        time: '09:00 PM',
        completedDays: {DateLabels.dayKey(monday)},
        createdAt: monday,
      );
      expect(h.streakAt(monday.add(const Duration(days: 2))), 0);
    });

    test('new fields round-trip through JSON and old rows still load', () {
      final h = HabitItem(id: 'h', title: 'Walk', time: '06:00 PM', target: 5, unit: 'km', weekdays: const {6, 7}, paused: true);
      final back = HabitItem.fromJson(h.toJson());
      expect([back.target, back.unit, back.weekdays, back.paused], [5, 'km', {6, 7}, true]);
      final legacy = HabitItem.fromJson({'id': 'x', 'title': 'Old', 'time': '08:00 AM', 'completedDays': []});
      expect([legacy.target, legacy.weekdays.isEmpty, legacy.paused], [1, true, false]);
    });
  });

  group('tasks', () {
    test('subtasks can be added, ticked and removed', () {
      final n = TasksNotifier();
      final t = n.addTask(title: 'Move house');
      n.addSubtask(t.id, 'Book van');
      n.addSubtask(t.id, 'Pack books');
      final sub = n.state.single.subtasks.first;
      n.toggleSubtask(t.id, sub.id);
      expect(n.state.single.subtasksDone, 1);
      n.removeSubtask(t.id, sub.id);
      expect(n.state.single.subtasks.map((s) => s.title), ['Pack books']);
      expect(TaskItem.fromJson(n.state.single.toJson()).subtasks.single.title, 'Pack books');
    });

    test('move to tomorrow keeps the time of day', () {
      final n = TasksNotifier();
      final t = n.addTask(title: 'Call', dueAt: DateTime(2026, 11, 2, 15, 30));
      n.moveToTomorrow(t.id, now: DateTime(2026, 11, 2, 18));
      expect(n.state.single.dueAt, DateTime(2026, 11, 3, 15, 30));
    });

    test('reordering a filtered subset leaves other items in their slots', () {
      final n = TasksNotifier();
      final c = n.addTask(title: 'c');
      final b = n.addTask(title: 'b');
      final a = n.addTask(title: 'a'); // state: a, b, c
      n.reorderSubset([c.id, a.id]); // drag c above a, b not visible
      expect(n.state.map((t) => t.title), ['c', 'b', 'a']);
      expect(b.title, 'b');
    });
  });

  group('expenses', () {
    test('a recurring expense gains one copy per missed month', () {
      final n = ExpensesNotifier();
      final rent = n.addExpense(title: 'Rent', amount: 1000, spentAt: DateTime(2026, 8, 31));
      n.setRecurring(rent.id, true);
      // Sep 30 (clamped to the month's last day) and Oct 31 are due by Nov 8; Nov 30 is not.
      expect(n.rollRecurring(DateTime(2026, 11, 8)), 2);
      final rents = n.state.expenses.where((e) => e.title == 'Rent').toList();
      expect(rents.map((e) => e.spentAt), [DateTime(2026, 10, 31), DateTime(2026, 9, 30), DateTime(2026, 8, 31)]);
      expect(rents.where((e) => e.recurring).length, 1);
      expect(rents.first.recurring, isTrue);
      expect(n.rollRecurring(DateTime(2026, 11, 8)), 0);
    });
  });

  group('wardrobe, shopping, travel, moodboard', () {
    test('wear log drives cost per wear', () {
      final n = WardrobeNotifier();
      final o = n.addOutfit(title: 'Linen suit');
      n.setCost(o.id, 300);
      n.toggleWorn(o.id, on: monday);
      n.toggleWorn(o.id, on: monday.add(const Duration(days: 1)));
      expect(n.state.single.costPerWear, 150);
      n.toggleWorn(o.id, on: monday);
      expect(n.state.single.timesWorn, 1);
    });

    test('shopping quantity multiplies the line total', () {
      final n = ShoppingNotifier();
      final i = n.addItem(name: 'Eggs', store: 'Market', price: 12);
      n.setQuantity(i.id, 6);
      expect(n.state.single.lineTotal, 72);
    });

    test('itinerary entries sort by day, undated last; trips know their days', () {
      final n = TravelNotifier();
      final t = n.addTrip(title: 'Lisbon', flight: '', destination: 'Lisbon', startDate: monday, endDate: monday.add(const Duration(days: 3)));
      n.addItineraryEntry(t.id, 'Pack snacks');
      n.addItineraryEntry(t.id, 'Tram 28', day: monday.add(const Duration(days: 1)));
      n.addItineraryEntry(t.id, 'Arrive', day: monday);
      expect(n.state.single.itinerary.map((e) => e.text), ['Arrive', 'Tram 28', 'Pack snacks']);
      expect(n.state.single.covers(monday.add(const Duration(days: 3))), isTrue);
      expect(n.state.single.covers(monday.add(const Duration(days: 4))), isFalse);
    });

    test('pins move between boards', () {
      final n = MoodboardNotifier();
      final p = n.addPin(title: 'Terracotta', imageUrl: '');
      expect(n.state.single.boardLabel, 'Unsorted');
      n.moveToBoard(p.id, ' Kitchen ');
      expect(MoodboardPin.fromJson(n.state.single.toJson()).board, 'Kitchen');
    });
  });
}
