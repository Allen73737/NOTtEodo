import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- DATA MODELS ---

class NoteItem {
  final String id;
  final String title;
  final String space;
  final String tag;
  final String date;
  final String excerpt;
  final bool isPinned;

  const NoteItem({
    required this.id,
    required this.title,
    required this.space,
    required this.tag,
    required this.date,
    required this.excerpt,
    this.isPinned = false,
  });

  NoteItem copyWith({
    String? id,
    String? title,
    String? space,
    String? tag,
    String? date,
    String? excerpt,
    bool? isPinned,
  }) {
    return NoteItem(
      id: id ?? this.id,
      title: title ?? this.title,
      space: space ?? this.space,
      tag: tag ?? this.tag,
      date: date ?? this.date,
      excerpt: excerpt ?? this.excerpt,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}

class TaskItem {
  final String id;
  final String title;
  final String priority;
  final String space;
  final String timeOfDay; // Morning, Afternoon, Evening, Later
  final bool completed;

  const TaskItem({
    required this.id,
    required this.title,
    required this.priority,
    required this.space,
    required this.timeOfDay,
    this.completed = false,
  });

  bool get isCompleted => completed;
  String get timeSlot => timeOfDay;

  TaskItem copyWith({
    String? id,
    String? title,
    String? priority,
    String? space,
    String? timeOfDay,
    bool? completed,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      priority: priority ?? this.priority,
      space: space ?? this.space,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      completed: completed ?? this.completed,
    );
  }
}

class ExpenseItem {
  final String id;
  final String title;
  final double amount;
  final String category;
  final String date;

  const ExpenseItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
  });
}

class SettlementItem {
  final String id;
  final String from;
  final String to;
  final String amount;
  final bool settled;

  const SettlementItem({
    required this.id,
    required this.from,
    required this.to,
    required this.amount,
    this.settled = false,
  });

  bool get isSettled => settled;

  SettlementItem copyWith({
    String? id,
    String? from,
    String? to,
    String? amount,
    bool? settled,
  }) {
    return SettlementItem(
      id: id ?? this.id,
      from: from ?? this.from,
      to: to ?? this.to,
      amount: amount ?? this.amount,
      settled: settled ?? this.settled,
    );
  }
}

class HabitItem {
  final String id;
  final String title;
  final String time;
  final int streak;
  final bool completedToday;

  const HabitItem({
    required this.id,
    required this.title,
    required this.time,
    required this.streak,
    this.completedToday = false,
  });

  HabitItem copyWith({
    String? id,
    String? title,
    String? time,
    int? streak,
    bool? completedToday,
  }) {
    return HabitItem(
      id: id ?? this.id,
      title: title ?? this.title,
      time: time ?? this.time,
      streak: streak ?? this.streak,
      completedToday: completedToday ?? this.completedToday,
    );
  }
}

class ShoppingItem {
  final String id;
  final String name;
  final String store;
  final int price;
  final bool checked;

  const ShoppingItem({
    required this.id,
    required this.name,
    required this.store,
    required this.price,
    this.checked = false,
  });

  bool get isChecked => checked;

  ShoppingItem copyWith({
    String? id,
    String? name,
    String? store,
    int? price,
    bool? checked,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      store: store ?? this.store,
      price: price ?? this.price,
      checked: checked ?? this.checked,
    );
  }
}

class WardrobeOutfit {
  final String id;
  final String title;
  final String items;
  final String weather;
  final String fabric;
  final String tag;

  const WardrobeOutfit({
    required this.id,
    required this.title,
    required this.items,
    required this.weather,
    required this.fabric,
    required this.tag,
  });

  String get category => items;
  String get vibe => tag;
  List<String> get tags => [fabric, tag];
  String get previewIcon => 'shirt';
}

class TravelTrip {
  final String id;
  final String title;
  final String flight;
  final String destination;
  final String date;
  final List<String> packingList;
  final List<bool> packingChecked;

  const TravelTrip({
    required this.id,
    required this.title,
    required this.flight,
    required this.destination,
    required this.date,
    required this.packingList,
    required this.packingChecked,
  });

  TravelTrip copyWith({
    String? id,
    String? title,
    String? flight,
    String? destination,
    String? date,
    List<String>? packingList,
    List<bool>? packingChecked,
  }) {
    return TravelTrip(
      id: id ?? this.id,
      title: title ?? this.title,
      flight: flight ?? this.flight,
      destination: destination ?? this.destination,
      date: date ?? this.date,
      packingList: packingList ?? this.packingList,
      packingChecked: packingChecked ?? this.packingChecked,
    );
  }
}

class MemoirItem {
  final String id;
  final String title;
  final String date;
  final String duration;
  final String excerpt;
  final String mood;

  const MemoirItem({
    required this.id,
    required this.title,
    required this.date,
    required this.duration,
    required this.excerpt,
    this.mood = 'Reflective',
  });
}

// --- RIVERPOD NOTIFIERS & PROVIDERS ---

// 1. NOTES
class NotesNotifier extends StateNotifier<List<NoteItem>> {
  NotesNotifier()
      : super([
          const NoteItem(
            id: 'n1',
            title: 'Computer Networks — Unit 1',
            space: 'Academic Space',
            tag: 'PDF · 4 Files',
            date: 'Aug 24, 2026',
            excerpt: 'OSI 7 Layer Reference Model, TCP/IP Suite, and Subnet Masking derivations.',
            isPinned: true,
          ),
          const NoteItem(
            id: 'n2',
            title: 'Goa Trip Villa & Flights 2026',
            space: 'Travel Space',
            tag: 'Doc · Booking',
            date: 'Aug 22, 2026',
            excerpt: 'Flight tickets IX-382, Villa reservation in Anjuna, and expense split log.',
          ),
          const NoteItem(
            id: 'n3',
            title: 'Minimal Editorial Bento Grid System',
            space: 'Design Space',
            tag: 'Design · Stitch',
            date: 'Aug 20, 2026',
            excerpt: 'Bodoni Moda typography pairings, glassmorphism tokens, and wax stamp textures.',
          ),
        ]);

  void addNote({required String title, required String space, required String tag, required String excerpt}) {
    final newNote = NoteItem(
      id: 'n_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      space: space.isEmpty ? 'General Space' : space,
      tag: tag.isEmpty ? 'Note' : tag,
      date: 'Just now',
      excerpt: excerpt,
    );
    state = [newNote, ...state];
  }

  void deleteNote(String id) {
    state = state.where((n) => n.id != id).toList();
  }

  void removeNote(String id) => deleteNote(id);

  void togglePin(String id) {
    state = state.map((n) => n.id == id ? n.copyWith(isPinned: !n.isPinned) : n).toList();
  }
}

final notesProvider = StateNotifierProvider<NotesNotifier, List<NoteItem>>((ref) {
  return NotesNotifier();
});

// 2. TASKS
class TasksNotifier extends StateNotifier<List<TaskItem>> {
  TasksNotifier()
      : super([
          const TaskItem(
            id: 't1',
            title: 'Finalize Computer Networks Unit 1 revision notes',
            priority: 'High Priority',
            space: 'Academic Space',
            timeOfDay: 'Morning',
            completed: true,
          ),
          const TaskItem(
            id: 't2',
            title: 'Review Goa Trip 2026 expense splits with Rahul',
            priority: 'Medium Priority',
            space: 'Travel Space',
            timeOfDay: 'Afternoon',
            completed: false,
          ),
          const TaskItem(
            id: 't3',
            title: 'Curate College Casual outfit for Tuesday',
            priority: 'Low Priority',
            space: 'Wardrobe Space',
            timeOfDay: 'Evening',
            completed: false,
          ),
        ]);

  void addTask({
    required String title,
    String priority = 'Medium Priority',
    String space = 'General Space',
    String? timeOfDay,
    String? timeSlot,
  }) {
    final finalTime = timeSlot ?? timeOfDay ?? 'Morning';
    final newTask = TaskItem(
      id: 't_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      priority: priority,
      space: space,
      timeOfDay: finalTime,
      completed: false,
    );
    state = [newTask, ...state];
  }

  void toggleTask(String id) {
    state = state.map((t) => t.id == id ? t.copyWith(completed: !t.completed) : t).toList();
  }

  void deleteTask(String id) {
    state = state.where((t) => t.id != id).toList();
  }

  void removeTask(String id) => deleteTask(id);
}

final tasksProvider = StateNotifierProvider<TasksNotifier, List<TaskItem>>((ref) {
  return TasksNotifier();
});

// 3. EXPENSES
class ExpensesState {
  final List<ExpenseItem> expenses;
  final List<SettlementItem> settlements;

  const ExpensesState({required this.expenses, required this.settlements});

  List<ExpenseItem> get items => expenses;
  double get totalSpend => expenses.fold(0.0, (sum, e) => sum + e.amount);

  ExpensesState copyWith({
    List<ExpenseItem>? expenses,
    List<SettlementItem>? settlements,
  }) {
    return ExpensesState(
      expenses: expenses ?? this.expenses,
      settlements: settlements ?? this.settlements,
    );
  }
}

class ExpensesNotifier extends StateNotifier<ExpensesState> {
  ExpensesNotifier()
      : super(const ExpensesState(
          expenses: [
            ExpenseItem(id: 'e1', title: 'Organic Cotton Oxford Shirt', amount: 2400.0, category: 'Clothing', date: 'Aug 24'),
            ExpenseItem(id: 'e2', title: 'Artisan Pour-over Coffee & Pastry', amount: 380.0, category: 'Food & Dining', date: 'Aug 23'),
            ExpenseItem(id: 'e3', title: 'Goa Villa Reservation Deposit', amount: 8500.0, category: 'Travel & Stay', date: 'Aug 21'),
            ExpenseItem(id: 'e4', title: 'Field Notes Journal 3-Pack Refill', amount: 650.0, category: 'Study & Books', date: 'Aug 19'),
          ],
          settlements: [
            SettlementItem(id: 's1', from: 'Rahul', to: 'Allen', amount: '₹400', settled: false),
            SettlementItem(id: 's2', from: 'Arun', to: 'Allen', amount: '₹800', settled: false),
            SettlementItem(id: 's3', from: 'Joel', to: 'Allen', amount: '₹400', settled: true),
          ],
        ));

  void addExpense({
    required String title,
    required double amount,
    String category = 'General',
    bool isClippedToWardrobe = false,
  }) {
    final newExpense = ExpenseItem(
      id: 'e_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      amount: amount,
      category: category,
      date: 'Today',
    );
    state = state.copyWith(expenses: [newExpense, ...state.expenses]);
  }

  void toggleSettlement(String id) {
    state = state.copyWith(
      settlements: state.settlements.map((s) => s.id == id ? s.copyWith(settled: !s.settled) : s).toList(),
    );
  }
}

final expensesProvider = StateNotifierProvider<ExpensesNotifier, ExpensesState>((ref) {
  return ExpensesNotifier();
});

// 4. HABITS
class HabitsNotifier extends StateNotifier<List<HabitItem>> {
  HabitsNotifier()
      : super([
          const HabitItem(id: 'h1', title: 'Morning Botanical Tea & Reading', time: '07:30 AM', streak: 18, completedToday: true),
          const HabitItem(id: 'h2', title: '30-Minute Architecture Systems Study', time: '11:00 AM', streak: 12, completedToday: false),
          const HabitItem(id: 'h3', title: 'Evening Reflection & Vocal Memoir', time: '10:00 PM', streak: 21, completedToday: false),
        ]);

  bool toggleHabit(String id) {
    bool justCompleted = false;
    state = state.map((h) {
      if (h.id == id) {
        final nextState = !h.completedToday;
        if (nextState) justCompleted = true;
        return h.copyWith(
          completedToday: nextState,
          streak: nextState ? h.streak + 1 : (h.streak > 0 ? h.streak - 1 : 0),
        );
      }
      return h;
    }).toList();
    return justCompleted;
  }

  void addHabit({required String title, required String time}) {
    final newHabit = HabitItem(
      id: 'h_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      time: time,
      streak: 1,
      completedToday: false,
    );
    state = [...state, newHabit];
  }
}

final habitsProvider = StateNotifierProvider<HabitsNotifier, List<HabitItem>>((ref) {
  return HabitsNotifier();
});

// 5. SHOPPING
class ShoppingNotifier extends StateNotifier<List<ShoppingItem>> {
  ShoppingNotifier()
      : super([
          const ShoppingItem(id: 'sh1', name: 'Matcha Green Tea Powder', store: 'Organic Pantry', price: 850, checked: false),
          const ShoppingItem(id: 'sh2', name: 'Minimalist Notebook Refills', store: 'Stationery', price: 450, checked: true),
          const ShoppingItem(id: 'sh3', name: 'Linen Pillowcovers', store: 'Home Edit', price: 1200, checked: false),
        ]);

  void addItem({required String name, required String store, required int price}) {
    final newItem = ShoppingItem(
      id: 'sh_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      store: store,
      price: price,
      checked: false,
    );
    state = [...state, newItem];
  }

  void addShoppingItem({required String name, required String store, required double price}) {
    addItem(name: name, store: store, price: price.toInt());
  }

  void toggleItem(String id) {
    state = state.map((i) => i.id == id ? i.copyWith(checked: !i.checked) : i).toList();
  }

  void toggleShoppingItem(String id) => toggleItem(id);

  void deleteItem(String id) {
    state = state.where((i) => i.id != id).toList();
  }

  void removeShoppingItem(String id) => deleteItem(id);

  List<ShoppingItem> convertCheckedToExpenses(WidgetRef ref) {
    final checkedItems = state.where((i) => i.checked).toList();
    for (final item in checkedItems) {
      ref.read(expensesProvider.notifier).addExpense(
            title: item.name,
            amount: item.price.toDouble(),
            category: 'Shopping',
          );
    }
    state = state.where((i) => !i.checked).toList();
    return checkedItems;
  }
}

final shoppingProvider = StateNotifierProvider<ShoppingNotifier, List<ShoppingItem>>((ref) {
  return ShoppingNotifier();
});

// 6. WARDROBE
class WardrobeNotifier extends StateNotifier<List<WardrobeOutfit>> {
  WardrobeNotifier()
      : super([
          const WardrobeOutfit(
            id: 'w1',
            title: 'Minimal Editorial Studio Look',
            items: 'Beige Linen Shirt · Olive Trousers · Leather Loafers',
            weather: 'Sunny · 24°C',
            fabric: 'Italian Linen',
            tag: 'College Casual',
          ),
          const WardrobeOutfit(
            id: 'w2',
            title: 'Evening Bistro & Promenade',
            items: 'Dark Navy Blazer · Raw Silk Scarf · Black Chelsea Boots',
            weather: 'Breeze · 18°C',
            fabric: 'Raw Silk',
            tag: 'Smart Formal',
          ),
          const WardrobeOutfit(
            id: 'w3',
            title: 'Goa Beach Resort Lookbook',
            items: 'Terracotta Short-Sleeve Linen · White Shorts · Sandals',
            weather: 'Tropical · 30°C',
            fabric: 'Heavy Denim',
            tag: 'Resort Vacation',
          ),
        ]);

  void addOutfit({
    required String title,
    String? items,
    String? weather,
    String? fabric,
    String? tag,
    String? category,
    String? vibe,
    List<String>? tags,
    String? previewIcon,
  }) {
    final newOutfit = WardrobeOutfit(
      id: 'w_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      items: category ?? items ?? 'Curated Ensemble',
      weather: weather ?? 'Mild · 22°C',
      fabric: fabric ?? (tags != null && tags.isNotEmpty ? tags.first : 'Linen'),
      tag: vibe ?? tag ?? (tags != null && tags.length > 1 ? tags[1] : 'Casual'),
    );
    state = [newOutfit, ...state];
  }

  void removeOutfit(String id) {
    state = state.where((o) => o.id != id).toList();
  }
}

final wardrobeProvider = StateNotifierProvider<WardrobeNotifier, List<WardrobeOutfit>>((ref) {
  return WardrobeNotifier();
});

// 7. TRAVEL
class TravelNotifier extends StateNotifier<List<TravelTrip>> {
  TravelNotifier()
      : super([
          const TravelTrip(
            id: 'tr1',
            title: 'Goa Beach Resort & Heritage Exploration 2026',
            flight: 'IX-382',
            destination: 'GOI (Goa)',
            date: 'Oct 12 - Oct 18, 2026',
            packingList: [
              'Linen Shirts & Swimwear',
              'Goa Villa Booking Confirmation PDF',
              'Sunscreen & Sunglasses',
              'Digital Camera & Memory Cards',
            ],
            packingChecked: [true, true, false, false],
          ),
          const TravelTrip(
            id: 'tr2',
            title: 'Tokyo & Kyoto Autumn Maple Leaf Expedition',
            flight: 'NH-828',
            destination: 'NRT (Tokyo)',
            date: 'Nov 04 - Nov 14, 2026',
            packingList: [
              'Heavy Trench Coat & Scarf',
              'JR Rail Pass Voucher',
              'Pocket WiFi Unit',
              'Walking Loafers',
            ],
            packingChecked: [false, false, false, false],
          ),
        ]);

  void addTrip({required String title, required String flight, required String destination, required String date}) {
    final newTrip = TravelTrip(
      id: 'tr_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      flight: flight,
      destination: destination,
      date: date,
      packingList: ['Passport & Tickets', 'Travel Adapters', 'Toiletries Kit'],
      packingChecked: [false, false, false],
    );
    state = [newTrip, ...state];
  }

  void togglePackingItem(String tripId, int itemIndex) {
    state = state.map((t) {
      if (t.id == tripId) {
        final updatedChecked = List<bool>.from(t.packingChecked);
        if (itemIndex < updatedChecked.length) {
          updatedChecked[itemIndex] = !updatedChecked[itemIndex];
        }
        return t.copyWith(packingChecked: updatedChecked);
      }
      return t;
    }).toList();
  }

  void addPackingItem(String tripId, String item) {
    state = state.map((t) {
      if (t.id == tripId) {
        return t.copyWith(
          packingList: [...t.packingList, item],
          packingChecked: [...t.packingChecked, false],
        );
      }
      return t;
    }).toList();
  }
}

final travelProvider = StateNotifierProvider<TravelNotifier, List<TravelTrip>>((ref) {
  return TravelNotifier();
});

// 8. JOURNAL
class JournalNotifier extends StateNotifier<List<MemoirItem>> {
  JournalNotifier()
      : super([
          const MemoirItem(
            id: 'm1',
            title: 'Reflections on Systems Architecture Study',
            date: 'Aug 24, 2026',
            duration: '2:45',
            excerpt: 'Late night thoughts on OSI 7 layer abstraction vs real-world TCP/IP socket implementations.',
            mood: 'Reflective',
          ),
          const MemoirItem(
            id: 'm2',
            title: 'Goa Vacation Itinerary Brainstorming',
            date: 'Aug 21, 2026',
            duration: '1:18',
            excerpt: 'Voice notes detailing Anjuna villa preferences, sunset beach lounges, and scooter rentals.',
            mood: 'Adventurous',
          ),
        ]);

  void addMemoir({
    required String title,
    required String duration,
    required String excerpt,
    String mood = 'Reflective',
  }) {
    final newMemoir = MemoirItem(
      id: 'm_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      date: 'Today',
      duration: duration,
      excerpt: excerpt,
      mood: mood,
    );
    state = [newMemoir, ...state];
  }
}

final journalProvider = StateNotifierProvider<JournalNotifier, List<MemoirItem>>((ref) {
  return JournalNotifier();
});

// 9. LUXURY ENVELOPE BUDGETS
class BudgetEnvelopeItem {
  final String id;
  final String name;
  final double allocated;
  final double spent;

  const BudgetEnvelopeItem({
    required this.id,
    required this.name,
    required this.allocated,
    required this.spent,
  });

  double get remaining => (allocated - spent).clamp(0.0, double.infinity);
  double get fillRatio => allocated > 0 ? (remaining / allocated).clamp(0.0, 1.0) : 0.0;
}

class BudgetEnvelopesNotifier extends StateNotifier<List<BudgetEnvelopeItem>> {
  BudgetEnvelopesNotifier()
      : super([
          const BudgetEnvelopeItem(id: 'env_1', name: 'Artisanal Dining & Tea', allocated: 500, spent: 180),
          const BudgetEnvelopeItem(id: 'env_2', name: 'Haute Horlogerie & Books', allocated: 800, spent: 340),
          const BudgetEnvelopeItem(id: 'env_3', name: 'Sartorial Wardrobe', allocated: 600, spent: 120),
        ]);

  void addExpenseToEnvelope(String id, double amount) {
    state = state.map((env) {
      if (env.id == id) {
        return BudgetEnvelopeItem(
          id: env.id,
          name: env.name,
          allocated: env.allocated,
          spent: env.spent + amount,
        );
      }
      return env;
    }).toList();
  }
}

final budgetEnvelopesProvider =
    StateNotifierProvider<BudgetEnvelopesNotifier, List<BudgetEnvelopeItem>>((ref) {
  return BudgetEnvelopesNotifier();
});

