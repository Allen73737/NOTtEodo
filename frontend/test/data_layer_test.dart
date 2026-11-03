import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures.dart';
import 'package:notteodo/core/security/device_key_store.dart';
import 'package:notteodo/core/services/cloud_sync_service.dart';
import 'package:notteodo/core/services/data_portability_service.dart';
import 'package:notteodo/core/services/ics_export.dart';
import 'package:notteodo/core/services/local_knowledge_index.dart';
import 'package:notteodo/core/services/local_store.dart';
import 'package:notteodo/core/services/nlp_date_parser.dart';
import 'package:notteodo/core/services/reminder_service.dart';
import 'package:notteodo/core/state/app_settings.dart';
import 'package:notteodo/core/state/bin_state.dart';
import 'package:notteodo/core/state/sanctuary_state.dart';
import 'package:notteodo/core/utils/date_labels.dart';
import 'package:notteodo/core/widgets/floating_voice_ai_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A fresh, initialised on-device store for each test.
Future<void> _freshStore([Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
  LocalStore().resetForTest();
  await LocalStore().init(deviceKeys: MemoryDeviceKeyStore(), pbkdf2Iterations: 1000);
}

void main() {
  group('persistence', () {
    setUp(() => _freshStore());
    tearDown(() => LocalStore().resetForTest());

    test('first launch shows samples; edits survive a restart', () {
      final first = ProviderContainer();
      expect(first.read(notesProvider).every((n) => isSampleId(n.id)), isTrue);

      final note = first.read(notesProvider.notifier).addNote(title: 'Groceries', space: '', tag: '', excerpt: '', content: 'Milk, eggs');
      first.read(notesProvider.notifier).updateNote(note.id, title: 'Groceries list');
      first.dispose();

      final second = ProviderContainer();
      addTearDown(second.dispose);
      final restored = second.read(notesProvider).firstWhere((n) => n.id == note.id);
      expect(restored.title, 'Groceries list');
      expect(restored.body, 'Milk, eggs');
      expect(restored.space, 'General Space');
    });

    test('new ids are UUIDs', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final t = c.read(tasksProvider.notifier).addTask(title: 'x');
      expect(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$').hasMatch(t.id), isTrue);
    });

    test('an emptied module stays empty after restart', () {
      final first = ProviderContainer();
      removeAllSamples(first);
      first.dispose();

      final second = ProviderContainer();
      addTearDown(second.dispose);
      expect(second.read(notesProvider), isEmpty);
      expect(second.read(expensesProvider).expenses, isEmpty);
      expect(second.read(moodboardProvider), isEmpty);
    });

    test('the Bin survives a restart and still restores', () {
      final first = ProviderContainer();
      seedEverything(first);
      final trip = first.read(travelProvider).first;
      first.read(travelProvider.notifier).deleteTrip(trip.id);
      first.dispose();

      final second = ProviderContainer();
      addTearDown(second.dispose);
      final entry = second.read(binProvider).single;
      expect(entry.kind, BinKind.trip);
      second.read(binProvider.notifier).restore(entry.id);
      expect(second.read(travelProvider).any((t) => t.id == trip.id), isTrue);
    });

    test('settings persist across containers', () {
      final first = ProviderContainer();
      first.read(appSettingsProvider.notifier)
        ..setThemeMode(ThemeMode.dark)
        ..setCurrency('€')
        ..setMonthlyBudget(1200)
        ..setAutoLockMinutes(15);
      first.dispose();

      final second = ProviderContainer();
      addTearDown(second.dispose);
      final s = second.read(appSettingsProvider);
      expect(s.themeMode, ThemeMode.dark);
      expect(s.currencySymbol, '€');
      expect(s.monthlyBudget, 1200);
      expect(s.autoLockMinutes, 15);
      // Theme is mirrored unencrypted for the lock screen; nothing else is.
      expect(LocalStore().readPublic(), {'themeMode': 'dark', 'reducedMotion': false});
    });

    test('backup export → erase → import restores every module', () async {
      final c = ProviderContainer();
      c.read(eventsProvider.notifier).addEvent(title: 'Dentist', startsAt: DateTime(2026, 11, 3, 9));
      final backup = DataPortabilityService.buildBackupJson();
      final eventCount = c.read(eventsProvider).length;
      c.dispose();

      await LocalStore().eraseAll();
      final counts = await DataPortabilityService.importBackupJson(backup);
      expect(counts['events'], eventCount);

      final after = ProviderContainer();
      addTearDown(after.dispose);
      expect(after.read(eventsProvider).map((e) => e.title), contains('Dentist'));
    });

    test('import rejects files that are not backups', () async {
      expect(() => DataPortabilityService.importBackupJson('nope'), throwsFormatException);
      expect(() => DataPortabilityService.importBackupJson('{"format":"other"}'), throwsFormatException);
    });
  });

  group('habits', () {
    final now = DateTime(2026, 11, 1, 12);
    String key(int daysAgo) => DateLabels.dayKey(now.subtract(Duration(days: daysAgo)));

    test('streak counts back from today, or from yesterday if today is not done yet', () {
      expect(HabitItem(id: 'h', title: 't', time: '8:00 AM', completedDays: {key(0), key(1), key(2)}).streakAt(now), 3);
      expect(HabitItem(id: 'h', title: 't', time: '8:00 AM', completedDays: {key(1), key(2)}).streakAt(now), 2);
      expect(HabitItem(id: 'h', title: 't', time: '8:00 AM', completedDays: {key(2), key(3)}).streakAt(now), 0);
    });

    test('best streak finds the longest run', () {
      final h = HabitItem(id: 'h', title: 't', time: '8:00 AM', completedDays: {key(0), key(5), key(6), key(7), key(8)});
      expect(h.bestStreak, 4);
    });

    test('toggling a past day fixes a missed check-in', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final h = c.read(habitsProvider.notifier).addHabit(title: 'Read', time: '9:00 PM');
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      c.read(habitsProvider.notifier).toggleHabit(h.id, on: yesterday);
      expect(c.read(habitsProvider).firstWhere((x) => x.id == h.id).isDoneOn(yesterday), isTrue);
    });
  });

  group('tasks', () {
    test('completing a repeating task schedules the next one', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final due = DateTime(2026, 11, 2, 9);
      final t = c.read(tasksProvider.notifier).addTask(title: 'Water plants', dueAt: due, repeat: TaskRepeat.weekly);
      c.read(tasksProvider.notifier).toggleTask(t.id);

      final all = c.read(tasksProvider).where((x) => x.title == 'Water plants').toList();
      expect(all, hasLength(2));
      expect(all.firstWhere((x) => x.id == t.id).completed, isTrue);
      final next = all.firstWhere((x) => x.id != t.id);
      expect(next.completed, isFalse);
      expect(next.dueAt, DateTime(2026, 11, 9, 9));
    });
  });

  group('natural-language dates', () {
    final now = DateTime(2026, 11, 1, 10, 0); // a Sunday

    test('days and times', () {
      expect(NlpDateParser.tryParse('tomorrow at 3pm', now: now), DateTime(2026, 11, 2, 15));
      expect(NlpDateParser.tryParse('fri 9:30', now: now), DateTime(2026, 11, 6, 9, 30));
      expect(NlpDateParser.tryParse('next monday', now: now), DateTime(2026, 11, 2, 9));
      expect(NlpDateParser.tryParse('tonight', now: now), DateTime(2026, 11, 1, 20));
      expect(NlpDateParser.tryParse('call mom 3pm nov 4', now: now), DateTime(2026, 11, 4, 15));
      expect(NlpDateParser.tryParse('2026-12-24 18:00', now: now), DateTime(2026, 12, 24, 18));
    });

    test('relative offsets and bare times', () {
      expect(NlpDateParser.tryParse('in 2 hours', now: now), DateTime(2026, 11, 1, 12));
      expect(NlpDateParser.tryParse('in 3 days', now: now), DateTime(2026, 11, 4, 10));
      expect(NlpDateParser.tryParse('9am', now: now), DateTime(2026, 11, 2, 9)); // already past today
      expect(NlpDateParser.tryParse('noon', now: now), DateTime(2026, 11, 1, 12));
    });

    test('a past month/day rolls into next year; nonsense is null', () {
      expect(NlpDateParser.tryParse('jan 5', now: now), DateTime(2027, 1, 5, 9));
      expect(NlpDateParser.tryParse('buy milk', now: now), isNull);
    });

    test('quick capture strips the date words from the title', () {
      expect(quickCaptureTitle('call mom tomorrow at 5pm'), 'Call mom');
      expect(quickCaptureTitle('remind me to pay rent on friday'), 'Pay rent');
      expect(quickCaptureTitle('tomorrow'), 'tomorrow');
    });
  });

  group('reminders', () {
    final now = DateTime(2026, 11, 1, 18, 0);

    test('due tasks, imminent events and habit times are announced', () {
      final due = ReminderService.dueAt(
        now,
        tasks: [
          TaskItem(id: 'a', title: 'Due now', priority: 'p', space: 's', timeOfDay: 'Evening', dueAt: now.subtract(const Duration(minutes: 1))),
          TaskItem(id: 'b', title: 'Later', priority: 'p', space: 's', timeOfDay: 'Evening', dueAt: now.add(const Duration(hours: 1))),
          TaskItem(id: 'c', title: 'Done', priority: 'p', space: 's', timeOfDay: 'Evening', completed: true, dueAt: now),
          TaskItem(id: 'd', title: 'Ancient', priority: 'p', space: 's', timeOfDay: 'Evening', dueAt: now.subtract(const Duration(days: 3))),
        ],
        events: [
          PlannerEvent(id: 'e', title: 'Call', startsAt: now.add(const Duration(minutes: 5))),
          PlannerEvent(id: 'f', title: 'Tomorrow', startsAt: now.add(const Duration(days: 1))),
        ],
        habits: [
          HabitItem(id: 'h', title: 'Stretch', time: '05:30 PM'),
          HabitItem(id: 'i', title: 'Done', time: '05:30 PM', completedDays: {DateLabels.dayKey(now)}),
        ],
      );
      expect(due.map((r) => r.body), unorderedEquals(['Due now', 'Call', 'Stretch']));
    });

    test('habit times parse in 12- and 24-hour forms', () {
      expect(ReminderService.parseHabitTime('07:30 AM')?.hour, 7);
      expect(ReminderService.parseHabitTime('10:00 PM')?.hour, 22);
      expect(ReminderService.parseHabitTime('18:15')?.minute, 15);
      expect(ReminderService.parseHabitTime('whenever'), isNull);
    });
  });

  group('sync merge', () {
    test('union by id, local wins on a clash', () {
      final merged = CloudSyncService.mergeById(
        local: [
          {'id': '1', 'v': 'local'},
          {'id': '2', 'v': 'local'},
        ],
        remote: [
          {'id': '2', 'v': 'remote'},
          {'id': '3', 'v': 'remote'},
        ],
      );
      expect(merged.map((r) => '${r['id']}:${r['v']}'), ['1:local', '2:local', '3:remote']);
    });
  });

  group('exports', () {
    test('ics has one event per item and escapes text', () {
      final ics = IcsExport.build(
        events: [PlannerEvent(id: 'e1', title: 'Lunch; with, Sam', startsAt: DateTime.utc(2026, 11, 3, 12))],
        tasks: [TaskItem(id: 't1', title: 'Pay', priority: 'p', space: 's', timeOfDay: 'Morning', dueAt: DateTime.utc(2026, 11, 4, 9), repeat: TaskRepeat.monthly)],
        trips: [TravelTrip(id: 'tr', title: 'Goa', flight: '', destination: 'GOI', startDate: DateTime(2026, 12, 1), endDate: DateTime(2026, 12, 5), packingList: const [], packingChecked: const [])],
        now: DateTime.utc(2026, 11, 1),
      );
      expect('BEGIN:VEVENT'.allMatches(ics).length, 3);
      expect(ics, contains(r'SUMMARY:Lunch\; with\, Sam'));
      expect(ics, contains('RRULE:FREQ=MONTHLY'));
      expect(ics, contains('DTEND;VALUE=DATE:20261206'));
      expect(ics.endsWith('END:VCALENDAR\r\n'), isTrue);
    });

    test('csv quotes cells that need it', () {
      final csv = DataPortabilityService.expensesCsv([
        ExpenseItem(id: 'x', title: 'Dinner, "fancy"', amount: 12.5, category: 'Food', spentAt: DateTime(2026, 11, 1)),
      ]);
      expect(csv.split('\r\n')[1], '2026-11-01,"Dinner, ""fancy""",Food,12.50,');
    });
  });

  group('assistant retrieval', () {
    test('ranks title matches first and skips private journal entries', () {
      final matches = LocalKnowledgeIndex.search(
        'subnet masks',
        notes: [
          NoteItem(id: '1', title: 'Subnet masks cheat sheet', space: 's', tag: 't', excerpt: '', content: 'CIDR'),
          NoteItem(id: '2', title: 'Networks', space: 's', tag: 't', excerpt: '', content: 'about subnet ranges'),
        ],
        tasks: const [],
        events: const [],
        trips: const [],
        journal: [MemoirItem(id: 'm', title: 'Subnet diary', duration: '', excerpt: 'secret', isPrivate: true)],
        expenses: const [],
      );
      expect(matches.map((m) => m.title), ['Subnet masks cheat sheet', 'Networks']);
    });
  });
}
