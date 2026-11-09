import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../enterprise/audit_ledger_engine.dart';
import '../services/local_store.dart';
import '../services/widget_sync_service.dart';
import '../utils/date_labels.dart';
import 'app_settings.dart';
import 'bin_state.dart';

const _uuid = Uuid();

/// New ids are UUIDs so they line up with the cloud schema.
String newId() => _uuid.v4();

/// Ids of the demo content shown on first launch start with this, so it can be removed in one go.
const String samplePrefix = 'sample-';

bool isSampleId(String id) => id.startsWith(samplePrefix);

DateTime _readDate(Object? v, [DateTime? fallback]) =>
    (v is String ? DateTime.tryParse(v) : null) ?? fallback ?? DateTime.now();

DateTime? _readDateOrNull(Object? v) => v is String ? DateTime.tryParse(v) : null;

// Date helpers

// --- DATA MODELS ---

class NoteItem {
  final String id;
  final String title;
  final String space;
  final String tag;
  final String excerpt;
  final String content;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  NoteItem({
    required this.id,
    required this.title,
    required this.space,
    required this.tag,
    required this.excerpt,
    this.content = '',
    this.isPinned = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? createdAt ?? DateTime.now();

  /// Display label of the last edit.
  String get date => DateLabels.relative(updatedAt);

  /// Full text used for search and the editor.
  String get body => content.isNotEmpty ? content : excerpt;

  NoteItem copyWith({
    String? title,
    String? space,
    String? tag,
    String? excerpt,
    String? content,
    bool? isPinned,
    DateTime? updatedAt,
  }) {
    return NoteItem(
      id: id,
      title: title ?? this.title,
      space: space ?? this.space,
      tag: tag ?? this.tag,
      excerpt: excerpt ?? this.excerpt,
      content: content ?? this.content,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'space': space,
        'tag': tag,
        'excerpt': excerpt,
        'content': content,
        'isPinned': isPinned,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory NoteItem.fromJson(Map<String, dynamic> j) => NoteItem(
        id: j['id'] as String,
        title: j['title'] as String? ?? 'Untitled Note',
        space: j['space'] as String? ?? 'General Space',
        tag: j['tag'] as String? ?? 'Note',
        excerpt: j['excerpt'] as String? ?? '',
        content: j['content'] as String? ?? '',
        isPinned: j['isPinned'] as bool? ?? false,
        createdAt: _readDate(j['createdAt']),
        updatedAt: _readDate(j['updatedAt'], _readDate(j['createdAt'])),
      );
}

/// How often a task comes back after it is completed.
enum TaskRepeat { none, daily, weekly, monthly }

extension TaskRepeatLabel on TaskRepeat {
  String get label => switch (this) {
        TaskRepeat.none => 'Does not repeat',
        TaskRepeat.daily => 'Daily',
        TaskRepeat.weekly => 'Weekly',
        TaskRepeat.monthly => 'Monthly',
      };

  DateTime advance(DateTime from) => switch (this) {
        TaskRepeat.none => from,
        TaskRepeat.daily => from.add(const Duration(days: 1)),
        TaskRepeat.weekly => from.add(const Duration(days: 7)),
        TaskRepeat.monthly => DateTime(from.year, from.month + 1, from.day, from.hour, from.minute),
      };
}

/// One step of a task, ticked off on its own.
class Subtask {
  final String id;
  final String title;
  final bool done;

  const Subtask({required this.id, required this.title, this.done = false});

  Subtask copyWith({String? title, bool? done}) => Subtask(id: id, title: title ?? this.title, done: done ?? this.done);

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'done': done};

  factory Subtask.fromJson(Map<String, dynamic> j) =>
      Subtask(id: j['id'] as String? ?? newId(), title: j['title'] as String? ?? '', done: j['done'] as bool? ?? false);
}

class TaskItem {
  final String id;
  final String title;
  final String priority;
  final String space;
  final String timeOfDay; // Morning, Afternoon, Evening, Later
  final bool completed;
  final String notes;
  final DateTime? dueAt;
  final TaskRepeat repeat;
  final DateTime createdAt;
  final DateTime? completedAt;
  final List<Subtask> subtasks;

  TaskItem({
    required this.id,
    required this.title,
    required this.priority,
    required this.space,
    required this.timeOfDay,
    this.completed = false,
    this.notes = '',
    this.dueAt,
    this.repeat = TaskRepeat.none,
    DateTime? createdAt,
    this.completedAt,
    this.subtasks = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isCompleted => completed;

  int get subtasksDone => subtasks.where((s) => s.done).length;
  String get timeSlot => timeOfDay;

  bool isOverdue(DateTime now) => !completed && dueAt != null && dueAt!.isBefore(now);

  bool isDueOn(DateTime day) => dueAt != null && DateLabels.isSameDay(dueAt!, day);

  TaskItem copyWith({
    String? id,
    String? title,
    String? priority,
    String? space,
    String? timeOfDay,
    bool? completed,
    String? notes,
    DateTime? dueAt,
    bool clearDueAt = false,
    TaskRepeat? repeat,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    List<Subtask>? subtasks,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      priority: priority ?? this.priority,
      space: space ?? this.space,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      completed: completed ?? this.completed,
      notes: notes ?? this.notes,
      dueAt: clearDueAt ? null : (dueAt ?? this.dueAt),
      repeat: repeat ?? this.repeat,
      createdAt: createdAt,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      subtasks: subtasks ?? this.subtasks,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'priority': priority,
        'space': space,
        'timeOfDay': timeOfDay,
        'completed': completed,
        'notes': notes,
        'dueAt': dueAt?.toIso8601String(),
        'repeat': repeat.name,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        if (subtasks.isNotEmpty) 'subtasks': subtasks.map((s) => s.toJson()).toList(),
      };

  factory TaskItem.fromJson(Map<String, dynamic> j) => TaskItem(
        id: j['id'] as String,
        title: j['title'] as String? ?? 'Untitled Task',
        priority: j['priority'] as String? ?? 'Medium Priority',
        space: j['space'] as String? ?? 'General Space',
        timeOfDay: j['timeOfDay'] as String? ?? 'Morning',
        completed: j['completed'] as bool? ?? false,
        notes: j['notes'] as String? ?? '',
        dueAt: _readDateOrNull(j['dueAt']),
        repeat: TaskRepeat.values.asNameMap()[j['repeat']] ?? TaskRepeat.none,
        createdAt: _readDate(j['createdAt']),
        completedAt: _readDateOrNull(j['completedAt']),
        subtasks: _readList(j['subtasks'], Subtask.fromJson),
      );
}

List<T> _readList<T>(Object? raw, T Function(Map<String, dynamic>) fromJson) =>
    raw is List ? raw.whereType<Map>().map((e) => fromJson(Map<String, dynamic>.from(e))).toList() : <T>[];

class ExpenseItem {
  final String id;
  final String title;
  final double amount;
  final String category;
  final String note;
  final DateTime spentAt;

  /// Comes back every month (rent, subscriptions). Later months are added by
  /// [ExpensesNotifier.rollRecurring]; only the newest copy keeps the flag.
  final bool recurring;

  ExpenseItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    this.note = '',
    DateTime? spentAt,
    this.recurring = false,
  }) : spentAt = spentAt ?? DateTime.now();

  /// "Aug 24" this year, with the year added otherwise.
  String get date => DateLabels.short(spentAt);

  /// Always includes the year.
  String get dateLong => DateLabels.long(spentAt);

  ExpenseItem copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    String? note,
    DateTime? spentAt,
    bool? recurring,
  }) {
    return ExpenseItem(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      note: note ?? this.note,
      spentAt: spentAt ?? this.spentAt,
      recurring: recurring ?? this.recurring,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'category': category,
        'note': note,
        'spentAt': spentAt.toIso8601String(),
        if (recurring) 'recurring': true,
      };

  factory ExpenseItem.fromJson(Map<String, dynamic> j) => ExpenseItem(
        id: j['id'] as String,
        title: j['title'] as String? ?? 'Expense',
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
        category: j['category'] as String? ?? 'General',
        note: j['note'] as String? ?? '',
        spentAt: _readDate(j['spentAt']),
        recurring: j['recurring'] as bool? ?? false,
      );
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

  Map<String, dynamic> toJson() => {'id': id, 'from': from, 'to': to, 'amount': amount, 'settled': settled};

  factory SettlementItem.fromJson(Map<String, dynamic> j) => SettlementItem(
        id: j['id'] as String,
        from: j['from'] as String? ?? '',
        to: j['to'] as String? ?? '',
        amount: j['amount'] as String? ?? '0',
        settled: j['settled'] as bool? ?? false,
      );
}

class HabitItem {
  final String id;
  final String title;
  final String time;

  /// Calendar days the habit was done, as `yyyy-MM-dd` keys. For counted habits a day
  /// lands here once its count reaches [target].
  final Set<String> completedDays;
  final DateTime createdAt;

  /// How many times a day counts as done ("8 glasses"). 1 is a plain yes/no habit.
  final int target;

  /// Word shown after the count, e.g. "glasses". Empty for yes/no habits.
  final String unit;

  /// Progress per day for counted habits, keyed like [completedDays].
  final Map<String, int> counts;

  /// Days of the week it is due (1 = Monday … 7 = Sunday). Empty means every day.
  final Set<int> weekdays;

  /// Days deliberately skipped: they neither count nor break the streak.
  final Set<String> skippedDays;

  /// Paused habits keep their history but drop out of today and never remind.
  final bool paused;

  HabitItem({
    required this.id,
    required this.title,
    required this.time,
    Set<String>? completedDays,
    DateTime? createdAt,
    this.target = 1,
    this.unit = '',
    this.counts = const {},
    this.weekdays = const {},
    this.skippedDays = const {},
    this.paused = false,
  })  : completedDays = completedDays ?? const {},
        createdAt = createdAt ?? DateTime.now();

  bool isDoneOn(DateTime day) => completedDays.contains(DateLabels.dayKey(day));

  bool get completedToday => isDoneOn(DateTime.now());

  bool get isCounted => target > 1;

  int countOn(DateTime day) {
    final key = DateLabels.dayKey(day);
    return isCounted ? (counts[key] ?? 0) : (completedDays.contains(key) ? 1 : 0);
  }

  bool isScheduledOn(DateTime day) => weekdays.isEmpty || weekdays.contains(day.weekday);

  bool isSkippedOn(DateTime day) => skippedDays.contains(DateLabels.dayKey(day));

  /// Active, scheduled for [day] and not skipped.
  bool isDueOn(DateTime day) => !paused && isScheduledOn(day) && !isSkippedOn(day);

  /// A day that was not done but was not due either: it keeps a streak alive without adding to it.
  bool _restDay(DateTime day) => !isDoneOn(day) && (!isScheduledOn(day) || isSkippedOn(day));

  /// Consecutive due days done, ending today (or yesterday, if today is not done yet).
  int streakAt(DateTime now) {
    var day = DateTime(now.year, now.month, now.day);
    if (!isDoneOn(day)) day = day.subtract(const Duration(days: 1));
    final start = DateTime(createdAt.year, createdAt.month, createdAt.day);
    var count = 0;
    while (true) {
      if (isDoneOn(day)) {
        count++;
      } else if (day.isBefore(start) || !_restDay(day)) {
        break;
      }
      day = DateTime(day.year, day.month, day.day - 1);
    }
    return count;
  }

  int get streak => streakAt(DateTime.now());

  int get bestStreak {
    final days = completedDays.map(DateLabels.parseDayKey).whereType<DateTime>().toList()..sort();
    if (days.isEmpty) return 0;
    var best = 0, run = 0;
    var day = days.first;
    final last = days.last;
    while (!day.isAfter(last)) {
      if (isDoneOn(day)) {
        run++;
        if (run > best) best = run;
      } else if (!_restDay(day)) {
        run = 0;
      }
      day = DateTime(day.year, day.month, day.day + 1);
    }
    return best;
  }

  HabitItem copyWith({
    String? title,
    String? time,
    Set<String>? completedDays,
    int? target,
    String? unit,
    Map<String, int>? counts,
    Set<int>? weekdays,
    Set<String>? skippedDays,
    bool? paused,
  }) {
    return HabitItem(
      id: id,
      title: title ?? this.title,
      time: time ?? this.time,
      completedDays: completedDays ?? this.completedDays,
      createdAt: createdAt,
      target: target ?? this.target,
      unit: unit ?? this.unit,
      counts: counts ?? this.counts,
      weekdays: weekdays ?? this.weekdays,
      skippedDays: skippedDays ?? this.skippedDays,
      paused: paused ?? this.paused,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'time': time,
        'completedDays': completedDays.toList()..sort(),
        'createdAt': createdAt.toIso8601String(),
        if (target > 1) 'target': target,
        if (unit.isNotEmpty) 'unit': unit,
        if (counts.isNotEmpty) 'counts': counts,
        if (weekdays.isNotEmpty) 'weekdays': weekdays.toList()..sort(),
        if (skippedDays.isNotEmpty) 'skippedDays': skippedDays.toList()..sort(),
        if (paused) 'paused': true,
      };

  factory HabitItem.fromJson(Map<String, dynamic> j) => HabitItem(
        id: j['id'] as String,
        title: j['title'] as String? ?? 'Habit',
        time: j['time'] as String? ?? '08:00 AM',
        completedDays: ((j['completedDays'] as List?) ?? const []).map((e) => e.toString()).toSet(),
        createdAt: _readDate(j['createdAt']),
        target: (j['target'] as num?)?.toInt() ?? 1,
        unit: j['unit'] as String? ?? '',
        counts: ((j['counts'] as Map?) ?? const {}).map((k, v) => MapEntry('$k', (v as num?)?.toInt() ?? 0)),
        weekdays: ((j['weekdays'] as List?) ?? const []).map((e) => (e as num).toInt()).toSet(),
        skippedDays: ((j['skippedDays'] as List?) ?? const []).map((e) => e.toString()).toSet(),
        paused: j['paused'] as bool? ?? false,
      );
}

class ShoppingItem {
  final String id;
  final String name;
  final String store;
  final int price;
  final bool checked;
  final String? url;
  final int quantity;

  const ShoppingItem({
    required this.id,
    required this.name,
    required this.store,
    required this.price,
    this.checked = false,
    this.url,
    this.quantity = 1,
  });

  int get lineTotal => price * quantity;

  bool get isChecked => checked;

  ShoppingItem copyWith({
    String? id,
    String? name,
    String? store,
    int? price,
    bool? checked,
    String? url,
    int? quantity,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      store: store ?? this.store,
      price: price ?? this.price,
      checked: checked ?? this.checked,
      url: url ?? this.url,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'store': store,
        'price': price,
        'checked': checked,
        'url': url,
        if (quantity != 1) 'quantity': quantity,
      };

  factory ShoppingItem.fromJson(Map<String, dynamic> j) => ShoppingItem(
        id: j['id'] as String,
        name: j['name'] as String? ?? 'Item',
        store: j['store'] as String? ?? '',
        price: (j['price'] as num?)?.toInt() ?? 0,
        checked: j['checked'] as bool? ?? false,
        url: j['url'] as String?,
        quantity: (j['quantity'] as num?)?.toInt() ?? 1,
      );
}

class WardrobeOutfit {
  final String id;
  final String title;
  final String items;
  final String weather;
  final String fabric;
  final String tag;
  final String? imageUrl;

  /// Days it was worn (`yyyy-MM-dd`), oldest first.
  final List<String> wornDays;

  /// What it cost, for cost-per-wear. 0 when unknown.
  final double cost;

  const WardrobeOutfit({
    required this.id,
    required this.title,
    required this.items,
    required this.weather,
    required this.fabric,
    required this.tag,
    this.imageUrl,
    this.wornDays = const [],
    this.cost = 0,
  });

  int get timesWorn => wornDays.length;

  DateTime? get lastWorn => wornDays.isEmpty ? null : DateLabels.parseDayKey(wornDays.last);

  /// Cost divided by wears, or null when either is unknown.
  double? get costPerWear => cost > 0 && wornDays.isNotEmpty ? cost / wornDays.length : null;

  String get category => items;
  String get vibe => tag;
  List<String> get tags => [fabric, tag];
  String get previewIcon => 'shirt';

  WardrobeOutfit copyWith({
    String? title,
    String? items,
    String? weather,
    String? fabric,
    String? tag,
    String? imageUrl,
    List<String>? wornDays,
    double? cost,
  }) {
    return WardrobeOutfit(
      id: id,
      title: title ?? this.title,
      items: items ?? this.items,
      weather: weather ?? this.weather,
      fabric: fabric ?? this.fabric,
      tag: tag ?? this.tag,
      imageUrl: imageUrl ?? this.imageUrl,
      wornDays: wornDays ?? this.wornDays,
      cost: cost ?? this.cost,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'items': items,
        'weather': weather,
        'fabric': fabric,
        'tag': tag,
        'imageUrl': imageUrl,
        if (wornDays.isNotEmpty) 'wornDays': wornDays,
        if (cost > 0) 'cost': cost,
      };

  factory WardrobeOutfit.fromJson(Map<String, dynamic> j) => WardrobeOutfit(
        id: j['id'] as String,
        title: j['title'] as String? ?? 'Outfit',
        items: j['items'] as String? ?? '',
        weather: j['weather'] as String? ?? '',
        fabric: j['fabric'] as String? ?? '',
        tag: j['tag'] as String? ?? '',
        imageUrl: j['imageUrl'] as String?,
        wornDays: ((j['wornDays'] as List?) ?? const []).map((e) => e.toString()).toList(),
        cost: (j['cost'] as num?)?.toDouble() ?? 0,
      );
}

/// One line of a trip's plan, optionally pinned to a day.
class ItineraryEntry {
  final String id;
  final String text;
  final DateTime? day;

  const ItineraryEntry({required this.id, required this.text, this.day});

  Map<String, dynamic> toJson() => {'id': id, 'text': text, 'day': day?.toIso8601String()};

  factory ItineraryEntry.fromJson(Map<String, dynamic> j) =>
      ItineraryEntry(id: j['id'] as String? ?? newId(), text: j['text'] as String? ?? '', day: _readDateOrNull(j['day']));
}

class TravelTrip {
  final String id;
  final String title;
  final String flight;
  final String destination;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> packingList;
  final List<bool> packingChecked;
  final List<ItineraryEntry> itinerary;

  /// Planned spend. Actual spend is read from Expenses dated within the trip.
  final double budget;

  const TravelTrip({
    required this.id,
    required this.title,
    required this.flight,
    required this.destination,
    this.startDate,
    this.endDate,
    required this.packingList,
    required this.packingChecked,
    this.itinerary = const [],
    this.budget = 0,
  });

  /// Whether [day] falls inside the trip (inclusive), when dates are set.
  bool covers(DateTime day) {
    final start = startDate;
    if (start == null) return false;
    final end = endDate ?? start;
    final d = DateTime(day.year, day.month, day.day);
    return !d.isBefore(DateTime(start.year, start.month, start.day)) && !d.isAfter(DateTime(end.year, end.month, end.day));
  }

  String get date => startDate == null ? 'Dates not set' : DateLabels.range(startDate!, endDate);

  bool isUpcoming(DateTime now) => startDate != null && !startDate!.isBefore(DateTime(now.year, now.month, now.day));

  TravelTrip copyWith({
    String? id,
    String? title,
    String? flight,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    bool clearDates = false,
    List<String>? packingList,
    List<bool>? packingChecked,
    List<ItineraryEntry>? itinerary,
    double? budget,
  }) {
    return TravelTrip(
      id: id ?? this.id,
      title: title ?? this.title,
      flight: flight ?? this.flight,
      destination: destination ?? this.destination,
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
      packingList: packingList ?? this.packingList,
      packingChecked: packingChecked ?? this.packingChecked,
      itinerary: itinerary ?? this.itinerary,
      budget: budget ?? this.budget,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'flight': flight,
        'destination': destination,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'packingList': packingList,
        'packingChecked': packingChecked,
        if (itinerary.isNotEmpty) 'itinerary': itinerary.map((e) => e.toJson()).toList(),
        if (budget > 0) 'budget': budget,
      };

  factory TravelTrip.fromJson(Map<String, dynamic> j) {
    final list = ((j['packingList'] as List?) ?? const []).map((e) => e.toString()).toList();
    final checked = ((j['packingChecked'] as List?) ?? const []).map((e) => e == true).toList();
    // Keep the two lists the same length even if stored data drifted.
    while (checked.length < list.length) {
      checked.add(false);
    }
    return TravelTrip(
      id: j['id'] as String,
      title: j['title'] as String? ?? 'Trip',
      flight: j['flight'] as String? ?? '',
      destination: j['destination'] as String? ?? '',
      startDate: _readDateOrNull(j['startDate']),
      endDate: _readDateOrNull(j['endDate']),
      packingList: list,
      packingChecked: checked.sublist(0, list.length),
      itinerary: _readList(j['itinerary'], ItineraryEntry.fromJson),
      budget: (j['budget'] as num?)?.toDouble() ?? 0,
    );
  }
}

class MemoirItem {
  final String id;
  final String title;
  final String duration;
  final String excerpt;
  final String mood;
  final DateTime createdAt;
  final String? audioPath;

  /// Kept out of the journal list; shown only in the PIN-protected vault.
  final bool isPrivate;

  MemoirItem({
    required this.id,
    required this.title,
    required this.duration,
    required this.excerpt,
    this.mood = 'Reflective',
    this.audioPath,
    DateTime? createdAt,
    this.isPrivate = false,
  }) : createdAt = createdAt ?? DateTime.now();

  String get date => DateLabels.relative(createdAt);

  MemoirItem copyWith({String? title, String? excerpt, String? mood, String? audioPath, bool? isPrivate}) {
    return MemoirItem(
      id: id,
      title: title ?? this.title,
      duration: duration,
      excerpt: excerpt ?? this.excerpt,
      mood: mood ?? this.mood,
      audioPath: audioPath ?? this.audioPath,
      createdAt: createdAt,
      isPrivate: isPrivate ?? this.isPrivate,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'duration': duration,
        'excerpt': excerpt,
        'mood': mood,
        'audioPath': audioPath,
        'createdAt': createdAt.toIso8601String(),
        'isPrivate': isPrivate,
      };

  factory MemoirItem.fromJson(Map<String, dynamic> j) => MemoirItem(
        id: j['id'] as String,
        title: j['title'] as String? ?? 'Entry',
        duration: j['duration'] as String? ?? '',
        excerpt: j['excerpt'] as String? ?? '',
        mood: j['mood'] as String? ?? 'Reflective',
        audioPath: j['audioPath'] as String?,
        createdAt: _readDate(j['createdAt']),
        isPrivate: j['isPrivate'] as bool? ?? false,
      );
}

class PlannerEvent {
  final String id;
  final String title;
  final DateTime startsAt;
  final int durationMinutes;
  final String notes;

  const PlannerEvent({
    required this.id,
    required this.title,
    required this.startsAt,
    this.durationMinutes = 60,
    this.notes = '',
  });

  DateTime get endsAt => startsAt.add(Duration(minutes: durationMinutes));

  PlannerEvent copyWith({String? title, DateTime? startsAt, int? durationMinutes, String? notes}) {
    return PlannerEvent(
      id: id,
      title: title ?? this.title,
      startsAt: startsAt ?? this.startsAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'startsAt': startsAt.toIso8601String(),
        'durationMinutes': durationMinutes,
        'notes': notes,
      };

  factory PlannerEvent.fromJson(Map<String, dynamic> j) => PlannerEvent(
        id: j['id'] as String,
        title: j['title'] as String? ?? 'Event',
        startsAt: _readDate(j['startsAt']),
        durationMinutes: (j['durationMinutes'] as num?)?.toInt() ?? 60,
        notes: j['notes'] as String? ?? '',
      );
}

class MoodboardPin {
  final String id;
  final String title;
  final String imageUrl;
  final String note;
  final DateTime createdAt;

  /// Collection the pin belongs to. Empty means "Unsorted".
  final String board;

  /// Optional source web page.
  final String link;

  MoodboardPin({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.note,
    DateTime? createdAt,
    this.board = '',
    this.link = '',
  }) : createdAt = createdAt ?? DateTime.now();

  String get date => DateLabels.long(createdAt);

  String get boardLabel => board.trim().isEmpty ? 'Unsorted' : board.trim();

  MoodboardPin copyWith({String? title, String? imageUrl, String? note, String? board, String? link}) => MoodboardPin(
        id: id,
        title: title ?? this.title,
        imageUrl: imageUrl ?? this.imageUrl,
        note: note ?? this.note,
        createdAt: createdAt,
        board: board ?? this.board,
        link: link ?? this.link,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'imageUrl': imageUrl,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
        if (board.isNotEmpty) 'board': board,
        if (link.isNotEmpty) 'link': link,
      };

  factory MoodboardPin.fromJson(Map<String, dynamic> j) => MoodboardPin(
        id: j['id'] as String,
        title: j['title'] as String? ?? 'Pin',
        imageUrl: j['imageUrl'] as String? ?? '',
        note: j['note'] as String? ?? '',
        createdAt: _readDate(j['createdAt']),
        board: j['board'] as String? ?? '',
        link: j['link'] as String? ?? '',
      );
}

// --- PERSISTENCE BASE ---

/// A list notifier whose every state change is written to [LocalStore].
///
/// The first launch (nothing stored yet) starts from [seed]; after that the stored
/// list wins, including an empty one.
abstract class PersistedListNotifier<T> extends StateNotifier<List<T>> {
  final String storageKey;
  final T Function(Map<String, dynamic>) _fromJson;

  PersistedListNotifier(this.storageKey, T Function(Map<String, dynamic>) fromJson, List<T> Function() seed)
      : _fromJson = fromJson,
        super(LocalStore().readList(storageKey, fromJson) ?? seed());

  Map<String, dynamic> encode(T item);

  @override
  set state(List<T> value) {
    super.state = value;
    // Encoding the whole list is the costly part of a write; skip it when storage is closed.
    if (LocalStore().isReady) LocalStore().writeList(storageKey, value.map(encode).toList());
  }

  /// Re-reads the list after sync or import replaced it underneath us.
  void reloadFromStore() {
    final stored = LocalStore().readList(storageKey, _fromJson);
    if (stored != null) super.state = stored;
  }

  /// Puts an item back (e.g. from the Bin) at [index], clamped to the list.
  void restoreAt(T item, int index) {
    state = [...state]..insert(index.clamp(0, state.length), item);
  }

  /// Removes the item with [id] and hands it to [toBin] with its old position.
  T? removeById(String id, {BinEntry Function(T item, int index)? toBin, Ref? ref}) {
    final index = state.indexWhere((e) => encode(e)['id'] == id);
    if (index < 0) return null;
    final item = state[index];
    state = [...state]..removeAt(index);
    if (toBin != null && ref != null) ref.read(binProvider.notifier).stash(toBin(item, index));
    return item;
  }

  /// Re-orders the items in [ids] (e.g. a filtered list after a drag) into that order.
  /// Every other item, and the slots these occupy, stay where they were.
  void reorderSubset(List<String> ids) {
    final wanted = ids.toSet();
    final byId = {for (final e in state) encode(e)['id'] as String: e};
    final queue = [for (final id in ids) if (byId[id] != null) byId[id] as T];
    if (queue.length != wanted.length) return;
    var next = 0;
    state = [
      for (final e in state)
        if (wanted.contains(encode(e)['id'])) queue[next++] else e,
    ];
  }

  /// Replaces the item with [id] by `change(item)`.
  void edit(String id, T Function(T item) change) {
    state = [for (final e in state) encode(e)['id'] == id ? change(e) : e];
  }

  /// Drops first-launch demo content.
  void removeSamples() {
    final kept = state.where((e) => !isSampleId(encode(e)['id'] as String)).toList();
    if (kept.length != state.length) state = kept;
  }
}

// --- RIVERPOD NOTIFIERS & PROVIDERS ---

// 1. NOTES
class NotesNotifier extends PersistedListNotifier<NoteItem> {
  /// Optional so the notifier can still be built standalone (e.g. in tests); deletions
  /// only reach the Bin when created through [notesProvider].
  final Ref? _ref;

  NotesNotifier([this._ref]) : super('notes', NoteItem.fromJson, _seed);

  static List<NoteItem> _seed() => const [];

  @override
  Map<String, dynamic> encode(NoteItem item) => item.toJson();

  static String _excerptOf(String content) {
    final flat = content.replaceAll(RegExp(r'\s+'), ' ').trim();
    return flat.length <= 140 ? flat : '${flat.substring(0, 137)}...';
  }

  NoteItem addNote({
    required String title,
    required String space,
    required String tag,
    required String excerpt,
    String content = '',
  }) {
    final body = content.isNotEmpty ? content : excerpt;
    final newNote = NoteItem(
      id: newId(),
      title: title,
      space: space.isEmpty ? 'General Space' : space,
      tag: tag.isEmpty ? 'Note' : tag,
      excerpt: _excerptOf(body),
      content: body,
    );
    state = [newNote, ...state];

    AuditLedgerEngine().recordEvent(
      actorId: 'CURATOR',
      action: 'CREATE_NOTE',
      resource: newNote.id,
      metadata: {'title': newNote.title, 'space': newNote.space},
    );
    return newNote;
  }

  void updateNote(String id, {String? title, String? space, String? tag, String? content}) {
    state = state.map((n) {
      if (n.id != id) return n;
      return n.copyWith(
        title: title,
        space: space,
        tag: tag,
        content: content,
        excerpt: content != null ? _excerptOf(content) : null,
        updatedAt: DateTime.now(),
      );
    }).toList();
    AuditLedgerEngine().recordEvent(actorId: 'CURATOR', action: 'UPDATE_NOTE', resource: id);
  }

  void deleteNote(String id) {
    final index = state.indexWhere((n) => n.id == id);
    if (index < 0) return;
    final note = state[index];
    state = [...state]..removeAt(index);
    _ref?.read(binProvider.notifier).stash(BinEntry.note(note, index));

    AuditLedgerEngine().recordEvent(
      actorId: 'CURATOR',
      action: 'DELETE_NOTE',
      resource: id,
    );
  }

  void removeNote(String id) => deleteNote(id);

  /// Puts a note back from the Bin at its original position.
  void restoreNote(NoteItem note, int index) {
    state = [...state]..insert(index.clamp(0, state.length), note);
  }

  void togglePin(String id) {
    state = state.map((n) => n.id == id ? n.copyWith(isPinned: !n.isPinned) : n).toList();
  }
}

final notesProvider = StateNotifierProvider<NotesNotifier, List<NoteItem>>((ref) {
  return NotesNotifier(ref);
});

// 2. TASKS
class TasksNotifier extends PersistedListNotifier<TaskItem> {
  final Ref? _ref;

  TasksNotifier([this._ref]) : super('tasks', TaskItem.fromJson, _seed);

  static List<TaskItem> _seed() => const [];

  @override
  Map<String, dynamic> encode(TaskItem item) => item.toJson();

  static String _slotFor(DateTime? due) {
    if (due == null) return 'Later';
    if (due.hour < 12) return 'Morning';
    if (due.hour < 17) return 'Afternoon';
    return 'Evening';
  }

  Timer? _widgetTimer;

  /// Sends the open count, streak and next three tasks to the home-screen widget.
  /// Batched: a burst of edits (an import, quick ticking) sends one update.
  void _syncWidget() {
    _widgetTimer?.cancel();
    _widgetTimer = Timer(const Duration(milliseconds: 400), () {
      try {
        // Next three open tasks by due date (undated last), in one pass: no sort, no allocation per compare.
        final next = <TaskItem>[];
        var pending = 0;
        int rank(TaskItem t) => t.dueAt?.millisecondsSinceEpoch ?? 1 << 62;
        for (final t in state) {
          if (t.completed) continue;
          pending++;
          if (next.length < 3 || rank(t) < rank(next.last)) {
            next.add(t);
            next.sort((a, b) => rank(a).compareTo(rank(b)));
            if (next.length > 3) next.removeLast();
          }
        }
        final streak = (LocalStore().readMap('settings')?['activeStreak'] as num?)?.toInt() ?? 1;
        WidgetSyncService.updateValues(streak: streak, pendingTasks: pending, nextTasks: [for (final t in next) t.title]);
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _widgetTimer?.cancel();
    super.dispose();
  }

  TaskItem addTask({
    required String title,
    String priority = 'Medium Priority',
    String space = 'General Space',
    String? timeOfDay,
    String? timeSlot,
    String notes = '',
    DateTime? dueAt,
    TaskRepeat repeat = TaskRepeat.none,
  }) {
    final finalTime = timeSlot ?? timeOfDay ?? (dueAt != null ? _slotFor(dueAt) : 'Morning');
    final newTask = TaskItem(
      id: newId(),
      title: title,
      priority: priority,
      space: space,
      timeOfDay: finalTime,
      notes: notes,
      dueAt: dueAt,
      repeat: repeat,
    );
    state = [newTask, ...state];

    AuditLedgerEngine().recordEvent(
      actorId: 'CURATOR',
      action: 'CREATE_TASK',
      resource: newTask.id,
      metadata: {'title': newTask.title, 'priority': newTask.priority},
    );
    _syncWidget();
    return newTask;
  }

  void updateTask(
    String id, {
    String? title,
    String? priority,
    String? space,
    String? timeOfDay,
    String? notes,
    DateTime? dueAt,
    bool clearDueAt = false,
    TaskRepeat? repeat,
  }) {
    state = state
        .map((t) => t.id == id
            ? t.copyWith(
                title: title,
                priority: priority,
                space: space,
                timeOfDay: timeOfDay,
                notes: notes,
                dueAt: dueAt,
                clearDueAt: clearDueAt,
                repeat: repeat,
              )
            : t)
        .toList();
    AuditLedgerEngine().recordEvent(actorId: 'CURATOR', action: 'UPDATE_TASK', resource: id);
  }

  /// Completing a repeating task also schedules its next occurrence.
  void toggleTask(String id) {
    final index = state.indexWhere((t) => t.id == id);
    if (index < 0) return;
    final task = state[index];
    final nowDone = !task.completed;
    final next = [...state];
    next[index] = nowDone
        ? task.copyWith(completed: true, completedAt: DateTime.now())
        : task.copyWith(completed: false, clearCompletedAt: true);

    if (nowDone && task.repeat != TaskRepeat.none) {
      final base = task.dueAt ?? DateTime.now();
      next.insert(
        index,
        task.copyWith(
          id: newId(),
          completed: false,
          clearCompletedAt: true,
          dueAt: task.repeat.advance(base),
        ),
      );
    }
    state = next;

    AuditLedgerEngine().recordEvent(
      actorId: 'CURATOR',
      action: nowDone ? 'COMPLETE_TASK' : 'UNCOMPLETE_TASK',
      resource: id,
    );
    _syncWidget();
  }

  void deleteTask(String id) {
    final index = state.indexWhere((t) => t.id == id);
    if (index < 0) return;
    final task = state[index];
    state = [...state]..removeAt(index);
    _ref?.read(binProvider.notifier).stash(BinEntry.task(task, index));

    AuditLedgerEngine().recordEvent(
      actorId: 'CURATOR',
      action: 'DELETE_TASK',
      resource: id,
    );
    _syncWidget();
  }

  void removeTask(String id) => deleteTask(id);

  void addSubtask(String taskId, String title) {
    if (title.trim().isEmpty) return;
    edit(taskId, (t) => t.copyWith(subtasks: [...t.subtasks, Subtask(id: newId(), title: title.trim())]));
  }

  void toggleSubtask(String taskId, String subtaskId) {
    edit(taskId, (t) => t.copyWith(subtasks: [for (final s in t.subtasks) s.id == subtaskId ? s.copyWith(done: !s.done) : s]));
  }

  void removeSubtask(String taskId, String subtaskId) {
    edit(taskId, (t) => t.copyWith(subtasks: t.subtasks.where((s) => s.id != subtaskId).toList()));
  }

  /// Moves a task to tomorrow, keeping its time of day (9:00 when it had none).
  void moveToTomorrow(String id, {DateTime? now}) {
    final today = now ?? DateTime.now();
    edit(id, (t) {
      final due = t.dueAt;
      return t.copyWith(dueAt: DateTime(today.year, today.month, today.day + 1, due?.hour ?? 9, due?.minute ?? 0));
    });
  }

  /// Puts a task back from the Bin at its original position.
  void restoreTask(TaskItem task, int index) {
    state = [...state]..insert(index.clamp(0, state.length), task);
  }
}

final tasksProvider = StateNotifierProvider<TasksNotifier, List<TaskItem>>((ref) {
  return TasksNotifier(ref);
});

// 3. EXPENSES
class ExpensesState {
  final List<ExpenseItem> expenses;
  final List<SettlementItem> settlements;

  const ExpensesState({required this.expenses, required this.settlements});

  List<ExpenseItem> get items => expenses;
  double get totalSpend => expenses.fold(0.0, (sum, e) => sum + e.amount);

  /// Spend inside the calendar month containing [now].
  double spendInMonth(DateTime now) => expenses
      .where((e) => e.spentAt.year == now.year && e.spentAt.month == now.month)
      .fold(0.0, (sum, e) => sum + e.amount);

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
  final Ref? _ref;

  static const String expensesKey = 'expenses';
  static const String settlementsKey = 'settlements';

  ExpensesNotifier([this._ref])
      : super(ExpensesState(
          expenses: LocalStore().readList(expensesKey, ExpenseItem.fromJson) ?? _seedExpenses(),
          settlements: LocalStore().readList(settlementsKey, SettlementItem.fromJson) ?? _seedSettlements(),
        ));

  static List<ExpenseItem> _seedExpenses() => const [];

  static List<SettlementItem> _seedSettlements() => const [];

  @override
  set state(ExpensesState value) {
    final prev = super.state;
    super.state = value;
    if (!identical(prev.expenses, value.expenses)) {
      LocalStore().writeList(expensesKey, value.expenses.map((e) => e.toJson()).toList());
    }
    if (!identical(prev.settlements, value.settlements)) {
      LocalStore().writeList(settlementsKey, value.settlements.map((s) => s.toJson()).toList());
    }
  }

  void reloadFromStore() {
    super.state = ExpensesState(
      expenses: LocalStore().readList(expensesKey, ExpenseItem.fromJson) ?? state.expenses,
      settlements: LocalStore().readList(settlementsKey, SettlementItem.fromJson) ?? state.settlements,
    );
  }

  void removeSamples() {
    state = state.copyWith(
      expenses: state.expenses.where((e) => !isSampleId(e.id)).toList(),
      settlements: state.settlements.where((s) => !isSampleId(s.id)).toList(),
    );
  }

  ExpenseItem addExpense({
    required String title,
    required double amount,
    String category = 'General',
    bool isClippedToWardrobe = false,
    String note = '',
    DateTime? spentAt,
    bool recurring = false,
  }) {
    final newExpense = ExpenseItem(
      id: newId(),
      title: title,
      amount: amount,
      category: category,
      note: note,
      spentAt: spentAt,
      recurring: recurring,
    );
    final sorted = [newExpense, ...state.expenses]..sort((a, b) => b.spentAt.compareTo(a.spentAt));
    state = state.copyWith(expenses: sorted);

    AuditLedgerEngine().recordEvent(
      actorId: 'CURATOR',
      action: 'RECORD_EXPENSE',
      resource: newExpense.id,
      metadata: {'title': newExpense.title, 'amount': newExpense.amount, 'category': newExpense.category},
    );
    return newExpense;
  }

  void updateExpense(String id, {String? title, double? amount, String? category, String? note, DateTime? spentAt}) {
    final updated = state.expenses
        .map((e) => e.id == id ? e.copyWith(title: title, amount: amount, category: category, note: note, spentAt: spentAt) : e)
        .toList()
      ..sort((a, b) => b.spentAt.compareTo(a.spentAt));
    state = state.copyWith(expenses: updated);
  }

  void deleteExpense(String id) {
    final index = state.expenses.indexWhere((e) => e.id == id);
    if (index < 0) return;
    final expense = state.expenses[index];
    state = state.copyWith(expenses: [...state.expenses]..removeAt(index));
    _ref?.read(binProvider.notifier).stash(BinEntry.expense(expense, index));
  }

  /// Puts an expense back from the Bin at its original position.
  void restoreExpense(ExpenseItem expense, int index) {
    state = state.copyWith(
      expenses: [...state.expenses]..insert(index.clamp(0, state.expenses.length), expense),
    );
  }

  /// Adds many expenses at once (e.g. from a CSV), skipping rows already present with
  /// the same day, title and amount. Returns how many were added.
  int importExpenses(List<ExpenseItem> rows) {
    String key(ExpenseItem e) => '${DateLabels.dayKey(e.spentAt)}|${e.title.toLowerCase()}|${e.amount.toStringAsFixed(2)}';
    final seen = {for (final e in state.expenses) key(e)};
    final fresh = [for (final e in rows) if (seen.add(key(e))) e];
    if (fresh.isEmpty) return 0;
    state = state.copyWith(expenses: [...fresh, ...state.expenses]..sort((a, b) => b.spentAt.compareTo(a.spentAt)));
    return fresh.length;
  }

  void setRecurring(String id, bool recurring) {
    state = state.copyWith(expenses: [for (final e in state.expenses) e.id == id ? e.copyWith(recurring: recurring) : e]);
  }

  /// Adds a copy of each recurring expense for every month since its newest copy, up to
  /// [at] (default now), on the same day of the month. The newest copy carries the
  /// recurring flag on. Returns how many were added.
  int rollRecurring([DateTime? at]) {
    final now = at ?? DateTime.now();
    final next = <ExpenseItem>[];
    var added = 0;
    for (final e in state.expenses) {
      if (!e.recurring) {
        next.add(e);
        continue;
      }
      var latest = e;
      for (var months = 1;; months++) {
        final due = _sameDayInMonth(e.spentAt, months);
        if (due.isAfter(now)) break;
        next.add(latest.copyWith(recurring: false));
        latest = e.copyWith(id: newId(), spentAt: due);
        added++;
      }
      next.add(latest);
    }
    if (added == 0) return 0;
    state = state.copyWith(expenses: next..sort((a, b) => b.spentAt.compareTo(a.spentAt)));
    return added;
  }

  static DateTime _sameDayInMonth(DateTime from, int months) {
    final lastDay = DateTime(from.year, from.month + months + 1, 0).day;
    return DateTime(from.year, from.month + months, from.day.clamp(1, lastDay), from.hour, from.minute);
  }

  void toggleSettlement(String id) {
    state = state.copyWith(
      settlements: state.settlements.map((s) => s.id == id ? s.copyWith(settled: !s.settled) : s).toList(),
    );
  }

  void addSettlement({required String from, required String to, required String amount}) {
    final newSettlement = SettlementItem(
      id: newId(),
      from: from,
      to: to,
      amount: amount.startsWith('₹') ? amount : '₹$amount',
      settled: false,
    );
    state = state.copyWith(settlements: [newSettlement, ...state.settlements]);
  }

  void deleteSettlement(String id) {
    state = state.copyWith(settlements: state.settlements.where((s) => s.id != id).toList());
  }
}

final expensesProvider = StateNotifierProvider<ExpensesNotifier, ExpensesState>((ref) {
  return ExpensesNotifier(ref);
});

// 4. HABITS
class HabitsNotifier extends PersistedListNotifier<HabitItem> {
  final Ref? _ref;

  HabitsNotifier([this._ref]) : super('habits', HabitItem.fromJson, _seed);

static List<HabitItem> _seed() => const [];

  @override
  Map<String, dynamic> encode(HabitItem item) => item.toJson();

  /// Marks today done/undone. Returns true when it was just completed.
  bool toggleHabit(String id, {DateTime? on}) {
    final key = DateLabels.dayKey(on ?? DateTime.now());
    var justCompleted = false;
    state = state.map((h) {
      if (h.id != id) return h;
      final days = {...h.completedDays};
      if (days.contains(key)) {
        days.remove(key);
      } else {
        days.add(key);
        justCompleted = true;
      }
      return h.copyWith(completedDays: days);
    }).toList();
    return justCompleted;
  }

  HabitItem addHabit({
    required String title,
    required String time,
    int target = 1,
    String unit = '',
    Set<int> weekdays = const {},
  }) {
    final newHabit = HabitItem(id: newId(), title: title, time: time, target: target, unit: unit, weekdays: weekdays);
    state = [...state, newHabit];
    return newHabit;
  }

  void updateHabit(String id, {String? title, String? time, int? target, String? unit, Set<int>? weekdays}) {
    state = state
        .map((h) => h.id == id ? h.copyWith(title: title, time: time, target: target, unit: unit, weekdays: weekdays) : h)
        .toList();
  }

  /// Adds [by] (may be negative) to a counted habit's tally for the day; a yes/no habit
  /// is simply marked done or not done. Returns true when this step completed the day.
  bool bump(String id, {int by = 1, DateTime? on}) {
    final day = on ?? DateTime.now();
    final habit = state.where((h) => h.id == id).firstOrNull;
    if (habit == null || by == 0) return false;
    if (!habit.isCounted) {
      final done = habit.isDoneOn(day);
      if (by > 0 == done) return false;
      return toggleHabit(id, on: day);
    }
    final key = DateLabels.dayKey(day);
    final before = habit.counts[key] ?? 0;
    final after = (before + by).clamp(0, habit.target * 10);
    final days = {...habit.completedDays};
    if (after >= habit.target) {
      days.add(key);
    } else {
      days.remove(key);
    }
    edit(id, (h) => h.copyWith(counts: {...h.counts, key: after}, completedDays: days));
    return before < habit.target && after >= habit.target;
  }

  /// Skips (or un-skips) a day: it neither counts nor breaks the streak.
  void toggleSkip(String id, {DateTime? on}) {
    final key = DateLabels.dayKey(on ?? DateTime.now());
    edit(id, (h) {
      final skipped = {...h.skippedDays};
      if (!skipped.remove(key)) skipped.add(key);
      return h.copyWith(skippedDays: skipped);
    });
  }

  void setPaused(String id, bool paused) => edit(id, (h) => h.copyWith(paused: paused));

  void deleteHabit(String id) => removeById(id, toBin: BinEntry.habit, ref: _ref);
}

final habitsProvider = StateNotifierProvider<HabitsNotifier, List<HabitItem>>((ref) {
  return HabitsNotifier(ref);
});

// 5. SHOPPING
class ShoppingNotifier extends PersistedListNotifier<ShoppingItem> {
  final Ref? _ref;

  ShoppingNotifier([this._ref]) : super('shopping', ShoppingItem.fromJson, _seed);

  static List<ShoppingItem> _seed() => const [];

  @override
  Map<String, dynamic> encode(ShoppingItem item) => item.toJson();

  ShoppingItem addItem({required String name, required String store, required int price, String? url}) {
    final newItem = ShoppingItem(id: newId(), name: name, store: store, price: price, checked: false, url: url);
    state = [...state, newItem];
    return newItem;
  }

  void addShoppingItem({required String name, required String store, required double price, String? url}) {
    addItem(name: name, store: store, price: price.toInt(), url: url);
  }

  void updateItem(String id, {String? name, String? store, int? price, String? url}) {
    state = state.map((i) => i.id == id ? i.copyWith(name: name, store: store, price: price, url: url) : i).toList();
  }

  void toggleItem(String id) {
    state = state.map((i) => i.id == id ? i.copyWith(checked: !i.checked) : i).toList();
  }

  void setQuantity(String id, int quantity) => edit(id, (i) => i.copyWith(quantity: quantity.clamp(1, 999)));

  void toggleShoppingItem(String id) => toggleItem(id);

  void deleteItem(String id) {
    final index = state.indexWhere((i) => i.id == id);
    if (index < 0) return;
    final item = state[index];
    state = [...state]..removeAt(index);
    _ref?.read(binProvider.notifier).stash(BinEntry.shopping(item, index));
  }

  /// Puts a shopping item back from the Bin at its original position.
  void restoreItem(ShoppingItem item, int index) {
    state = [...state]..insert(index.clamp(0, state.length), item);
  }

  void removeShoppingItem(String id) => deleteItem(id);

  List<ShoppingItem> convertCheckedToExpenses(WidgetRef ref) {
    final checkedItems = state.where((i) => i.checked).toList();
    for (final item in checkedItems) {
      ref.read(expensesProvider.notifier).addExpense(
            title: item.quantity > 1 ? '${item.name} ×${item.quantity}' : item.name,
            amount: item.lineTotal.toDouble(),
            category: 'Shopping',
          );
    }
    state = state.where((i) => !i.checked).toList();
    return checkedItems;
  }
}

final shoppingProvider = StateNotifierProvider<ShoppingNotifier, List<ShoppingItem>>((ref) {
  return ShoppingNotifier(ref);
});

// 6. WARDROBE
class WardrobeNotifier extends PersistedListNotifier<WardrobeOutfit> {
  final Ref? _ref;

  WardrobeNotifier([this._ref]) : super('wardrobe', WardrobeOutfit.fromJson, _seed);

  static List<WardrobeOutfit> _seed() => const [];

  @override
  Map<String, dynamic> encode(WardrobeOutfit item) => item.toJson();

  WardrobeOutfit addOutfit({
    required String title,
    String? items,
    String? weather,
    String? fabric,
    String? tag,
    String? category,
    String? vibe,
    List<String>? tags,
    String? previewIcon,
    String? imageUrl,
  }) {
    final newOutfit = WardrobeOutfit(
      id: newId(),
      title: title,
      items: category ?? items ?? 'Curated Ensemble',
      weather: weather ?? 'Mild · 22°C',
      fabric: fabric ?? (tags != null && tags.isNotEmpty ? tags.first : 'Linen'),
      tag: vibe ?? tag ?? (tags != null && tags.length > 1 ? tags[1] : 'Casual'),
      imageUrl: imageUrl,
    );
    state = [newOutfit, ...state];
    return newOutfit;
  }

  void updateOutfit(String id, {String? title, String? items, String? weather, String? fabric, String? tag, String? imageUrl}) {
    state = state
        .map((o) => o.id == id ? o.copyWith(title: title, items: items, weather: weather, fabric: fabric, tag: tag, imageUrl: imageUrl) : o)
        .toList();
  }

  void removeOutfit(String id) {
    final index = state.indexWhere((o) => o.id == id);
    if (index < 0) return;
    final outfit = state[index];
    state = [...state]..removeAt(index);
    _ref?.read(binProvider.notifier).stash(BinEntry.outfit(outfit, index));
  }

  /// Logs (or un-logs) wearing the outfit on [on], default today.
  void toggleWorn(String id, {DateTime? on}) {
    final key = DateLabels.dayKey(on ?? DateTime.now());
    edit(id, (o) {
      final days = [...o.wornDays];
      if (!days.remove(key)) days.add(key);
      days.sort();
      return o.copyWith(wornDays: days);
    });
  }

  void setCost(String id, double cost) => edit(id, (o) => o.copyWith(cost: cost < 0 ? 0 : cost));

  /// Puts an outfit back from the Bin at its original position.
  void restoreOutfit(WardrobeOutfit outfit, int index) {
    state = [...state]..insert(index.clamp(0, state.length), outfit);
  }
}

final wardrobeProvider = StateNotifierProvider<WardrobeNotifier, List<WardrobeOutfit>>((ref) {
  return WardrobeNotifier(ref);
});

// 7. TRAVEL
class TravelNotifier extends PersistedListNotifier<TravelTrip> {
  final Ref? _ref;

  TravelNotifier([this._ref]) : super('travel', TravelTrip.fromJson, _seed);

  static List<TravelTrip> _seed() => const [];

  @override
  Map<String, dynamic> encode(TravelTrip item) => item.toJson();

  TravelTrip addTrip({
    required String title,
    required String flight,
    required String destination,
    String? date,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final newTrip = TravelTrip(
      id: newId(),
      title: title,
      flight: flight,
      destination: destination,
      startDate: startDate,
      endDate: endDate,
      packingList: const ['Passport & Tickets', 'Travel Adapters', 'Toiletries Kit'],
      packingChecked: const [false, false, false],
    );
    final sorted = [newTrip, ...state]..sort(_byStart);
    state = sorted;
    return newTrip;
  }

  static int _byStart(TravelTrip a, TravelTrip b) {
    if (a.startDate == null) return b.startDate == null ? 0 : 1;
    if (b.startDate == null) return -1;
    return a.startDate!.compareTo(b.startDate!);
  }

  void updateTrip(
    String id, {
    String? title,
    String? flight,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    state = state
        .map((t) => t.id == id
            ? t.copyWith(title: title, flight: flight, destination: destination, startDate: startDate, endDate: endDate)
            : t)
        .toList()
      ..sort(_byStart);
  }

  void deleteTrip(String id) => removeById(id, toBin: BinEntry.trip, ref: _ref);

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

  void addItineraryEntry(String tripId, String text, {DateTime? day}) {
    if (text.trim().isEmpty) return;
    edit(tripId, (t) {
      final entries = [...t.itinerary, ItineraryEntry(id: newId(), text: text.trim(), day: day)];
      entries.sort((a, b) {
        if (a.day == null) return b.day == null ? 0 : 1;
        if (b.day == null) return -1;
        return a.day!.compareTo(b.day!);
      });
      return t.copyWith(itinerary: entries);
    });
  }

  void removeItineraryEntry(String tripId, String entryId) {
    edit(tripId, (t) => t.copyWith(itinerary: t.itinerary.where((e) => e.id != entryId).toList()));
  }

  void setBudget(String tripId, double budget) => edit(tripId, (t) => t.copyWith(budget: budget < 0 ? 0 : budget));

  void removePackingItem(String tripId, int itemIndex) {
    state = state.map((t) {
      if (t.id != tripId || itemIndex >= t.packingList.length) return t;
      return t.copyWith(
        packingList: [...t.packingList]..removeAt(itemIndex),
        packingChecked: [...t.packingChecked]..removeAt(itemIndex),
      );
    }).toList();
  }
}

final travelProvider = StateNotifierProvider<TravelNotifier, List<TravelTrip>>((ref) {
  return TravelNotifier(ref);
});

// 8. JOURNAL
class JournalNotifier extends PersistedListNotifier<MemoirItem> {
  final Ref? _ref;

  JournalNotifier([this._ref]) : super('journal', MemoirItem.fromJson, _seed);

  static List<MemoirItem> _seed() => const [];

  @override
  Map<String, dynamic> encode(MemoirItem item) => item.toJson();

  MemoirItem addMemoir({
    required String title,
    String duration = '',
    required String excerpt,
    String mood = 'Reflective',
    String? audioPath,
    bool isPrivate = false,
  }) {
    final newMemoir = MemoirItem(
      id: newId(),
      title: title,
      duration: duration,
      excerpt: excerpt,
      mood: mood,
      audioPath: audioPath,
      isPrivate: isPrivate,
    );
    state = [newMemoir, ...state];
    return newMemoir;
  }

  void updateMemoir(String id, {String? title, String? excerpt, String? mood, bool? isPrivate}) {
    state = state
        .map((m) => m.id == id ? m.copyWith(title: title, excerpt: excerpt, mood: mood, isPrivate: isPrivate) : m)
        .toList();
  }

  void deleteMemoir(String id) => removeById(id, toBin: BinEntry.memoir, ref: _ref);
}

final journalProvider = StateNotifierProvider<JournalNotifier, List<MemoirItem>>((ref) {
  return JournalNotifier(ref);
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

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'allocated': allocated, 'spent': spent};

  factory BudgetEnvelopeItem.fromJson(Map<String, dynamic> j) => BudgetEnvelopeItem(
        id: j['id'] as String,
        name: j['name'] as String? ?? 'Envelope',
        allocated: (j['allocated'] as num?)?.toDouble() ?? 0,
        spent: (j['spent'] as num?)?.toDouble() ?? 0,
      );
}

class BudgetEnvelopesNotifier extends PersistedListNotifier<BudgetEnvelopeItem> {
  BudgetEnvelopesNotifier() : super('envelopes', BudgetEnvelopeItem.fromJson, _seed);

  static List<BudgetEnvelopeItem> _seed() => const [];

  @override
  Map<String, dynamic> encode(BudgetEnvelopeItem item) => item.toJson();

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

  void addEnvelope({required String name, required double allocated}) {
    state = [...state, BudgetEnvelopeItem(id: newId(), name: name, allocated: allocated, spent: 0)];
  }

  void deleteEnvelope(String id) {
    state = state.where((e) => e.id != id).toList();
  }
}

final budgetEnvelopesProvider =
    StateNotifierProvider<BudgetEnvelopesNotifier, List<BudgetEnvelopeItem>>((ref) {
  return BudgetEnvelopesNotifier();
});

// 10. PLANNER EVENTS
class EventsNotifier extends PersistedListNotifier<PlannerEvent> {
  final Ref? _ref;

  EventsNotifier([this._ref]) : super('events', PlannerEvent.fromJson, _seed);

  static List<PlannerEvent> _seed() => const [];

  @override
  Map<String, dynamic> encode(PlannerEvent item) => item.toJson();

  List<PlannerEvent> on(DateTime day) =>
      state.where((e) => DateLabels.isSameDay(e.startsAt, day)).toList()..sort((a, b) => a.startsAt.compareTo(b.startsAt));

  PlannerEvent addEvent({required String title, required DateTime startsAt, int durationMinutes = 60, String notes = ''}) {
    final ev = PlannerEvent(id: newId(), title: title, startsAt: startsAt, durationMinutes: durationMinutes, notes: notes);
    state = [...state, ev]..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return ev;
  }

  void updateEvent(String id, {String? title, DateTime? startsAt, int? durationMinutes, String? notes}) {
    state = state
        .map((e) => e.id == id ? e.copyWith(title: title, startsAt: startsAt, durationMinutes: durationMinutes, notes: notes) : e)
        .toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  }

  void deleteEvent(String id) => removeById(id, toBin: BinEntry.event, ref: _ref);
}

final eventsProvider = StateNotifierProvider<EventsNotifier, List<PlannerEvent>>((ref) => EventsNotifier(ref));

// 11. MOODBOARD
class MoodboardNotifier extends PersistedListNotifier<MoodboardPin> {
  final Ref? _ref;

  MoodboardNotifier([this._ref]) : super('moodboard', MoodboardPin.fromJson, _seed);

  static List<MoodboardPin> _seed() => const [];

  @override
  Map<String, dynamic> encode(MoodboardPin item) => item.toJson();

  MoodboardPin addPin({required String title, required String imageUrl, String note = ''}) {
    final pin = MoodboardPin(id: newId(), title: title, imageUrl: imageUrl, note: note);
    state = [pin, ...state];
    return pin;
  }

  MoodboardPin? updatePin(String id, {String? title, String? imageUrl, String? note}) {
    MoodboardPin? updated;
    state = state.map((p) {
      if (p.id == id) {
        updated = p.copyWith(title: title, imageUrl: imageUrl, note: note);
        return updated!;
      }
      return p;
    }).toList();
    return updated;
  }

  void deletePin(String id) => removeById(id, toBin: BinEntry.pin, ref: _ref);

  void moveToBoard(String id, String board) => edit(id, (p) => p.copyWith(board: board.trim()));

  void setLink(String id, String link) => edit(id, (p) => p.copyWith(link: link.trim()));
}

final moodboardProvider = StateNotifierProvider<MoodboardNotifier, List<MoodboardPin>>((ref) => MoodboardNotifier(ref));

// --- WHOLE-APP DATA OPERATIONS ---

/// Storage keys of every synced/exported collection.
const List<String> dataCollections = [
  'notes',
  'tasks',
  ExpensesNotifier.expensesKey,
  ExpensesNotifier.settlementsKey,
  'habits',
  'shopping',
  'wardrobe',
  'travel',
  'journal',
  'envelopes',
  'events',
  'moodboard',
  AppSettingsNotifier.syncKey,
];

/// Re-reads every module from storage (after a cloud pull or a backup import).
void reloadAllFromStore(dynamic ref) {
  ref.read(appSettingsProvider.notifier).reloadFromStore();
  ref.read(notesProvider.notifier).reloadFromStore();
  ref.read(tasksProvider.notifier).reloadFromStore();
  ref.read(expensesProvider.notifier).reloadFromStore();
  ref.read(habitsProvider.notifier).reloadFromStore();
  ref.read(shoppingProvider.notifier).reloadFromStore();
  ref.read(wardrobeProvider.notifier).reloadFromStore();
  ref.read(travelProvider.notifier).reloadFromStore();
  ref.read(journalProvider.notifier).reloadFromStore();
  ref.read(budgetEnvelopesProvider.notifier).reloadFromStore();
  ref.read(eventsProvider.notifier).reloadFromStore();
  ref.read(moodboardProvider.notifier).reloadFromStore();
}

/// Removes the demo content seeded on first launch, leaving the user's own items.
void removeAllSamples(dynamic ref) {
  ref.read(notesProvider.notifier).removeSamples();
  ref.read(tasksProvider.notifier).removeSamples();
  ref.read(expensesProvider.notifier).removeSamples();
  ref.read(habitsProvider.notifier).removeSamples();
  ref.read(shoppingProvider.notifier).removeSamples();
  ref.read(wardrobeProvider.notifier).removeSamples();
  ref.read(travelProvider.notifier).removeSamples();
  ref.read(journalProvider.notifier).removeSamples();
  ref.read(budgetEnvelopesProvider.notifier).removeSamples();
  ref.read(eventsProvider.notifier).removeSamples();
  ref.read(moodboardProvider.notifier).removeSamples();
}

/// Rebuilds every module from storage, e.g. after the device data was erased.
/// Modules with nothing stored start again from their first-launch content.
void resetAllProviders(dynamic ref) {
  for (final p in [
    notesProvider,
    tasksProvider,
    expensesProvider,
    habitsProvider,
    shoppingProvider,
    wardrobeProvider,
    travelProvider,
    journalProvider,
    budgetEnvelopesProvider,
    eventsProvider,
    moodboardProvider,
    binProvider,
  ]) {
    ref.invalidate(p);
  }
}
