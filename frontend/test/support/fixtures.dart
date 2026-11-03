import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notteodo/core/state/sanctuary_state.dart';

/// The app now starts empty, so tests that need content add three items to every
/// module through the same notifier methods the UI uses.
void seedEverything(ProviderContainer c) {
  final now = DateTime.now();
  for (var i = 1; i <= 3; i++) {
    c.read(notesProvider.notifier).addNote(title: 'Note $i', space: 'General Space', tag: 'tag$i', excerpt: 'Body $i');
    c.read(tasksProvider.notifier).addTask(title: 'Task $i', dueAt: now.add(Duration(days: i)));
    c.read(expensesProvider.notifier).addExpense(title: 'Expense $i', amount: 100.0 * i, category: 'Food & Dining');
    c.read(shoppingProvider.notifier).addItem(name: 'Item $i', store: 'Store', price: 10 * i);
    c.read(wardrobeProvider.notifier).addOutfit(title: 'Outfit $i', items: 'Shirt, jeans');
    c.read(habitsProvider.notifier).addHabit(title: 'Habit $i', time: '08:00 AM');
    c.read(travelProvider.notifier).addTrip(title: 'Trip $i', flight: 'AI 10$i', destination: 'City $i');
    c.read(journalProvider.notifier).addMemoir(title: 'Entry $i', excerpt: 'A day $i');
    c.read(eventsProvider.notifier).addEvent(title: 'Event $i', startsAt: now.add(Duration(days: i, hours: 2)));
    c.read(moodboardProvider.notifier).addPin(title: 'Pin $i', imageUrl: 'https://example.com/$i.jpg');
  }
}
