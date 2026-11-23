import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notteodo/app/theme/app_dark_theme.dart';
import 'package:notteodo/app/theme/app_theme.dart';
import 'package:notteodo/core/state/sanctuary_state.dart';
import 'package:notteodo/core/widgets/entry_editor.dart';

import 'support/fixtures.dart';

/// The add/edit form for every kind of entry, new and existing, on a small phone
/// with large text in both themes: it lays out, scrolls to the end, and an
/// existing one switches from reading to editing without a framework error.
void main() {
  Object? existing(ProviderContainer c, EntryKind k) => switch (k) {
        EntryKind.note => c.read(notesProvider).first,
        EntryKind.task => c.read(tasksProvider).first,
        EntryKind.event => c.read(eventsProvider).first,
        EntryKind.outfit => c.read(wardrobeProvider).first,
        EntryKind.expense => c.read(expensesProvider).expenses.first,
        EntryKind.trip => c.read(travelProvider).first,
        EntryKind.memoir => c.read(journalProvider).first,
        EntryKind.pin => c.read(moodboardProvider).first,
        EntryKind.habit => c.read(habitsProvider).first,
        EntryKind.shopping => c.read(shoppingProvider).first,
      };

  for (final kind in EntryKind.values) {
    for (final edit in [false, true]) {
      for (final dark in [false, true]) {
        testWidgets('${kind.label} · ${edit ? 'existing' : 'new'} · ${dark ? 'dark' : 'light'}', (tester) async {
          tester.view.physicalSize = const Size(360, 740);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final c = ProviderContainer();
          addTearDown(c.dispose);
          seedEverything(c);
          final errors = <String>[];
          final previous = FlutterError.onError;
          FlutterError.onError = (d) => errors.add(d.exceptionAsString().split('\n').first);
          addTearDown(() => FlutterError.onError = previous);

          await tester.pumpWidget(UncontrolledProviderScope(
            container: c,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              darkTheme: AppDarkTheme.darkTheme,
              themeMode: dark ? ThemeMode.dark : ThemeMode.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.3)),
                child: child!,
              ),
              home: Scaffold(
                body: EntryEditor(kind: kind, editing: edit ? existing(c, kind) : null, readFirst: edit, onClose: () {}),
              ),
            ),
          ));
          for (var i = 0; i < 12; i++) {
            await tester.pump(const Duration(milliseconds: 50));
          }

          if (edit) {
            final editButton = find.text('Edit');
            expect(editButton, findsWidgets, reason: 'an existing ${kind.label} opens read-first with an Edit button');
            await tester.tap(editButton.last);
            for (var i = 0; i < 8; i++) {
              await tester.pump(const Duration(milliseconds: 50));
            }
          }

          final scroll = find.byType(Scrollable);
          if (scroll.evaluate().isNotEmpty) {
            await tester.drag(scroll.first, const Offset(0, -2500), warnIfMissed: false);
            for (var i = 0; i < 6; i++) {
              await tester.pump(const Duration(milliseconds: 50));
            }
          }
          final err = tester.takeException();
          if (err != null) errors.add('$err');
          FlutterError.onError = previous;
          expect(errors, isEmpty, reason: errors.join('\n'));
        });
      }
    }
  }
}
