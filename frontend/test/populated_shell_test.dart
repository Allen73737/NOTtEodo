import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notteodo/app/theme/app_dark_theme.dart';
import 'package:notteodo/app/theme/app_theme.dart';
import 'package:notteodo/core/state/app_settings.dart';
import 'package:notteodo/core/state/sanctuary_state.dart';
import 'package:notteodo/main.dart';

import 'support/fixtures.dart';

/// Every module of the shell with real-looking content — long titles, long bodies,
/// big amounts, many items, a budget that is overrun — on a small phone, in both
/// view styles and both themes, with large text. Fails on any framework error
/// (overflow, bad layout, exception in build).
void main() {
  const moduleCount = int.fromEnvironment('MODULES', defaultValue: 15);
  final culpritPattern = RegExp(r'(\w+):file:///\S+?/frontend/lib/(\S+)');
  const long = 'A very long title that keeps going well past the width of a small phone screen';

  void seedHeavy(ProviderContainer c) {
    seedEverything(c);
    final now = DateTime.now();
    final notes = c.read(notesProvider.notifier);
    final a = notes.addNote(title: long, space: 'Travel Space', tag: 'trip', excerpt: List.filled(40, 'word').join(' '));
    final b = notes.addNote(title: 'Checklist', space: 'Personal Space', tag: '', excerpt: '', content: '# Heading\n- [ ] one\n- [x] two\n**bold** text');
    notes.groupTogether(a.id, b.id, newName: 'A group with a fairly long name too');
    c.read(tasksProvider.notifier).addTask(title: long, dueAt: now.subtract(const Duration(days: 2)));
    final ex = c.read(expensesProvider.notifier);
    ex.addExpense(title: long, amount: 98765432.5, category: 'Imported bank category', note: long);
    final rent = ex.addExpense(title: 'Rent', amount: 1200, category: 'General', spentAt: now);
    ex.setRecurring(rent.id, true);
    ex.addSettlement(from: 'Someone with a long name', to: 'You', amount: '1234.56');
    c.read(appSettingsProvider.notifier).setMonthlyBudget(500);
    c.read(habitsProvider.notifier).addHabit(title: long, time: '07:00 AM', target: 8, unit: 'glasses');
    c.read(travelProvider.notifier).addTrip(title: 'Trip 1', flight: 'AI 999', destination: long);
    c.read(journalProvider.notifier).addMemoir(title: long, excerpt: List.filled(80, 'line').join('\n'));
    c.read(eventsProvider.notifier).addEvent(title: long, startsAt: now.add(const Duration(hours: 1)));
    c.read(shoppingProvider.notifier).addItem(name: long, store: 'A store with a long name', price: 1234567);
  }

  for (final style in ['bento', 'editorial']) {
    for (final dark in [false, true]) {
      testWidgets('populated modules render cleanly · $style · ${dark ? 'dark' : 'light'} · small phone, text ×1.3', (tester) async {
        tester.view.physicalSize = const Size(360, 740);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final failures = <String>{};
        var module = 0;
        final previous = FlutterError.onError;
        FlutterError.onError = (details) {
          final match = culpritPattern.firstMatch(details.toString());
          final where = match == null ? '' : ' <- ${match.group(1)!.trim()} @ ${match.group(2)}';
          failures.add('module $module: ${details.exceptionAsString().split('\n').first}$where');
          if (const bool.fromEnvironment('DUMP')) debugPrint('=====DUMP module $module\n$details');
        };

        for (module = 0; module < moduleCount; module++) {
          final c = ProviderContainer();
          seedHeavy(c);
          c.read(appSettingsProvider.notifier).setCardStyle(style);
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: c,
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                darkTheme: AppDarkTheme.darkTheme,
                themeMode: dark ? ThemeMode.dark : ThemeMode.light,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.3)),
                  child: child!,
                ),
                home: MainShellScreen(
                  key: ValueKey('shell-$style-$module'),
                  isDarkMode: dark,
                  onToggleDarkMode: (_) {},
                  onLogout: () {},
                  initialIndex: module,
                ),
              ),
            ),
          );
          for (var f = 0; f < 15; f++) {
            await tester.pump(const Duration(milliseconds: 100));
          }
          // Scroll the page to the end so content below the fold is laid out too.
          final scrollables = find.byType(Scrollable);
          if (scrollables.evaluate().isNotEmpty) {
            try {
              await tester.drag(scrollables.first, const Offset(0, -3000), warnIfMissed: false);
              for (var f = 0; f < 6; f++) {
                await tester.pump(const Duration(milliseconds: 100));
              }
            } catch (_) {}
          }
          final err = tester.takeException();
          if (err != null) failures.add('module $module: $err');
          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(milliseconds: 500));
          tester.takeException();
          c.dispose();
        }

        await tester.pump(const Duration(seconds: 2));
        tester.takeException();
        FlutterError.onError = previous;

        expect(failures, isEmpty, reason: '\n${failures.join('\n')}');
      });
    }
  }
}
