import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../enterprise/audit_ledger_engine.dart';
import '../services/local_store.dart';
import '../utils/date_labels.dart';
import '../widgets/app_toast_engine.dart';
import 'sanctuary_state.dart';

/// What kind of thing a bin entry holds; decides where it is restored to.
enum BinKind { note, task, expense, shopping, outfit, habit, trip, memoir, event, pin }

extension BinKindLabel on BinKind {
  String get label => switch (this) {
        BinKind.note => 'Note',
        BinKind.task => 'Task',
        BinKind.expense => 'Expense',
        BinKind.shopping => 'Shopping',
        BinKind.outfit => 'Outfit',
        BinKind.habit => 'Habit',
        BinKind.trip => 'Trip',
        BinKind.memoir => 'Journal',
        BinKind.event => 'Event',
        BinKind.pin => 'Pin',
      };

  /// Name of the place the item lives, for filters and messages.
  String get plural => switch (this) {
        BinKind.note => 'Notes',
        BinKind.task => 'Tasks',
        BinKind.expense => 'Expenses',
        BinKind.shopping => 'Shopping',
        BinKind.outfit => 'Wardrobe',
        BinKind.habit => 'Habits',
        BinKind.trip => 'Travel',
        BinKind.memoir => 'Journal',
        BinKind.event => 'Planner',
        BinKind.pin => 'Moodboard',
      };

  /// Module index of the shell screen the item lives in.
  int get moduleIndex => switch (this) {
        BinKind.note => 1,
        BinKind.task => 2,
        BinKind.expense => 5,
        BinKind.shopping => 10,
        BinKind.outfit => 4,
        BinKind.habit => 9,
        BinKind.trip => 6,
        BinKind.memoir => 7,
        BinKind.event => 3,
        BinKind.pin => 8,
      };
}

/// A deleted item, kept with its original position so a restore puts it exactly back.
class BinEntry {
  final String id;
  final BinKind kind;
  final String title;
  final String detail;
  final String meta;
  final DateTime deletedAt;
  final Object item;
  final int originalIndex;

  const BinEntry({
    required this.id,
    required this.kind,
    required this.title,
    required this.detail,
    required this.meta,
    required this.deletedAt,
    required this.item,
    required this.originalIndex,
  });

  factory BinEntry.note(NoteItem n, int index) => BinEntry(
        id: n.id,
        kind: BinKind.note,
        title: n.title,
        detail: n.excerpt,
        meta: n.space,
        deletedAt: DateTime.now(),
        item: n,
        originalIndex: index,
      );

  factory BinEntry.task(TaskItem t, int index) => BinEntry(
        id: t.id,
        kind: BinKind.task,
        title: t.title,
        detail: '${t.timeOfDay} · ${t.priority}',
        meta: t.space,
        deletedAt: DateTime.now(),
        item: t,
        originalIndex: index,
      );

  factory BinEntry.expense(ExpenseItem e, int index) => BinEntry(
        id: e.id,
        kind: BinKind.expense,
        title: e.title,
        detail: '₹${e.amount.toStringAsFixed(0)} · ${e.date}',
        meta: e.category,
        deletedAt: DateTime.now(),
        item: e,
        originalIndex: index,
      );

  factory BinEntry.shopping(ShoppingItem s, int index) => BinEntry(
        id: s.id,
        kind: BinKind.shopping,
        title: s.name,
        detail: '₹${s.price}',
        meta: s.store,
        deletedAt: DateTime.now(),
        item: s,
        originalIndex: index,
      );

  factory BinEntry.outfit(WardrobeOutfit o, int index) => BinEntry(
        id: o.id,
        kind: BinKind.outfit,
        title: o.title,
        detail: o.items,
        meta: o.tag,
        deletedAt: DateTime.now(),
        item: o,
        originalIndex: index,
      );

  factory BinEntry.habit(HabitItem h, int index) => BinEntry(
        id: h.id,
        kind: BinKind.habit,
        title: h.title,
        detail: '${h.streak} day streak',
        meta: h.time,
        deletedAt: DateTime.now(),
        item: h,
        originalIndex: index,
      );

  factory BinEntry.trip(TravelTrip t, int index) => BinEntry(
        id: t.id,
        kind: BinKind.trip,
        title: t.title,
        detail: t.date,
        meta: t.destination,
        deletedAt: DateTime.now(),
        item: t,
        originalIndex: index,
      );

  factory BinEntry.memoir(MemoirItem m, int index) => BinEntry(
        id: m.id,
        kind: BinKind.memoir,
        title: m.title,
        detail: m.excerpt,
        meta: m.mood,
        deletedAt: DateTime.now(),
        item: m,
        originalIndex: index,
      );

  factory BinEntry.event(PlannerEvent e, int index) => BinEntry(
        id: e.id,
        kind: BinKind.event,
        title: e.title,
        detail: DateLabels.dateTime(e.startsAt),
        meta: '${e.durationMinutes} min',
        deletedAt: DateTime.now(),
        item: e,
        originalIndex: index,
      );

  factory BinEntry.pin(MoodboardPin p, int index) => BinEntry(
        id: p.id,
        kind: BinKind.pin,
        title: p.title,
        detail: p.note,
        meta: p.date,
        deletedAt: DateTime.now(),
        item: p,
        originalIndex: index,
      );

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'deletedAt': deletedAt.toIso8601String(),
        'index': originalIndex,
        'item': (item as dynamic).toJson(),
      };

  /// Rebuilds an entry from storage through the same factories used on delete.
  static BinEntry? fromJson(Map<String, dynamic> j) {
    final kind = BinKind.values.asNameMap()[j['kind']];
    final raw = j['item'];
    if (kind == null || raw is! Map) return null;
    final data = Map<String, dynamic>.from(raw);
    final index = (j['index'] as num?)?.toInt() ?? 0;
    final entry = switch (kind) {
      BinKind.note => BinEntry.note(NoteItem.fromJson(data), index),
      BinKind.task => BinEntry.task(TaskItem.fromJson(data), index),
      BinKind.expense => BinEntry.expense(ExpenseItem.fromJson(data), index),
      BinKind.shopping => BinEntry.shopping(ShoppingItem.fromJson(data), index),
      BinKind.outfit => BinEntry.outfit(WardrobeOutfit.fromJson(data), index),
      BinKind.habit => BinEntry.habit(HabitItem.fromJson(data), index),
      BinKind.trip => BinEntry.trip(TravelTrip.fromJson(data), index),
      BinKind.memoir => BinEntry.memoir(MemoirItem.fromJson(data), index),
      BinKind.event => BinEntry.event(PlannerEvent.fromJson(data), index),
      BinKind.pin => BinEntry.pin(MoodboardPin.fromJson(data), index),
    };
    return BinEntry(
      id: entry.id,
      kind: entry.kind,
      title: entry.title,
      detail: entry.detail,
      meta: entry.meta,
      deletedAt: DateTime.tryParse(j['deletedAt'] as String? ?? '') ?? DateTime.now(),
      item: entry.item,
      originalIndex: index,
    );
  }

  /// Days left before the entry is cleared automatically.
  int daysLeft(DateTime now) => (BinNotifier.retention - now.difference(deletedAt)).inDays.clamp(0, 30);
}

/// Holds everything deleted across the app for [retention], newest first.
class BinNotifier extends StateNotifier<List<BinEntry>> {
  BinNotifier(this._ref) : super(_load());

  final Ref _ref;
  static const Duration retention = Duration(days: 30);
  static const String storageKey = 'bin';

  /// Stored entries, minus anything past [retention].
  static List<BinEntry> _load() {
    final now = DateTime.now();
    final stored = LocalStore().readList<BinEntry?>(storageKey, BinEntry.fromJson) ?? const [];
    return stored.whereType<BinEntry>().where((e) => now.difference(e.deletedAt) < retention).toList();
  }

  @override
  set state(List<BinEntry> value) {
    super.state = value;
    LocalStore().writeList(storageKey, value.map((e) => e.toJson()).toList(), notify: false);
  }

  /// Moves a just-deleted item into the bin and offers an immediate undo.
  void stash(BinEntry entry) {
    final now = DateTime.now();
    state = [
      entry,
      ...state.where((e) => e.id != entry.id && now.difference(e.deletedAt) < retention),
    ];
    AppToastEngine().notify(
      title: 'Moved to Bin',
      message: '"${entry.title}" can be restored for 30 days.',
      type: ToastType.info,
      actionLabel: 'Undo',
      onAction: () => restore(entry.id),
    );
  }

  /// Puts an entry back where it came from.
  void restore(String id) {
    final entry = _find(id);
    if (entry == null) return;
    state = state.where((e) => e.id != id).toList();

    switch (entry.kind) {
      case BinKind.note:
        _ref.read(notesProvider.notifier).restoreNote(entry.item as NoteItem, entry.originalIndex);
      case BinKind.task:
        _ref.read(tasksProvider.notifier).restoreTask(entry.item as TaskItem, entry.originalIndex);
      case BinKind.expense:
        _ref.read(expensesProvider.notifier).restoreExpense(entry.item as ExpenseItem, entry.originalIndex);
      case BinKind.shopping:
        _ref.read(shoppingProvider.notifier).restoreItem(entry.item as ShoppingItem, entry.originalIndex);
      case BinKind.outfit:
        _ref.read(wardrobeProvider.notifier).restoreOutfit(entry.item as WardrobeOutfit, entry.originalIndex);
      case BinKind.habit:
        _ref.read(habitsProvider.notifier).restoreAt(entry.item as HabitItem, entry.originalIndex);
      case BinKind.trip:
        _ref.read(travelProvider.notifier).restoreAt(entry.item as TravelTrip, entry.originalIndex);
      case BinKind.memoir:
        _ref.read(journalProvider.notifier).restoreAt(entry.item as MemoirItem, entry.originalIndex);
      case BinKind.event:
        _ref.read(eventsProvider.notifier).restoreAt(entry.item as PlannerEvent, entry.originalIndex);
      case BinKind.pin:
        _ref.read(moodboardProvider.notifier).restoreAt(entry.item as MoodboardPin, entry.originalIndex);
    }

    AuditLedgerEngine().recordEvent(actorId: 'CURATOR', action: 'RESTORE_FROM_BIN', resource: id);
  }

  /// Deletes an entry for good.
  void purge(String id) {
    state = state.where((e) => e.id != id).toList();
    AuditLedgerEngine().recordEvent(actorId: 'CURATOR', action: 'PURGE_FROM_BIN', resource: id);
  }

  void restoreAll() {
    for (final entry in [...state]) {
      restore(entry.id);
    }
  }

  void empty() {
    if (state.isEmpty) return;
    state = const [];
    AuditLedgerEngine().recordEvent(actorId: 'CURATOR', action: 'EMPTY_BIN', resource: 'bin');
  }

  BinEntry? _find(String id) {
    for (final e in state) {
      if (e.id == id) return e;
    }
    return null;
  }
}

final binProvider = StateNotifierProvider<BinNotifier, List<BinEntry>>((ref) => BinNotifier(ref));
