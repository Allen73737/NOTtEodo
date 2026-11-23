import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notteodo/app/theme/app_dark_theme.dart';
import 'package:notteodo/app/theme/app_theme.dart';
import 'package:notteodo/core/editorial/editorial_chrome.dart';
import 'package:notteodo/core/editorial/editorial_kit.dart';
import 'package:notteodo/core/state/app_settings.dart';
import 'package:notteodo/core/widgets/card_kit.dart';
import 'package:notteodo/main.dart';

import 'support/fixtures.dart';

/// A monkey test: on every module, in both view styles, on a small phone with large
/// text, tap each action, link, button and list row in turn — and press-and-hold
/// each editorial row — with a fresh app each time, failing on any framework error:
/// an overflowing dialog, a crash in a sheet or menu.
void main() {
  const moduleCount = int.fromEnvironment('MODULES', defaultValue: 15);
  const firstModule = int.fromEnvironment('FROM', defaultValue: 0);
  const maxTaps = int.fromEnvironment('TAPS', defaultValue: 25);
  const styles = String.fromEnvironment('STYLES', defaultValue: 'bento,editorial');
  final culpritPattern = RegExp(r'(\w+):file:///\S+?/frontend/lib/(\S+)');

  Finder tappables() => find.descendant(
        of: find.byKey(const ValueKey('page')),
        matching: find.byWidgetPredicate((w) =>
            w is CardAction ||
            w is CardLink ||
            (w is EditorialAction && w.onTap != null) ||
            w is EditorialIconButton ||
            (w is EditorialEntry && (w.onTap != null || w.onLongPress != null)) ||
            (w is IconButton && w.onPressed != null) ||
            (w is ButtonStyleButton && w.onPressed != null) ||
            (w is InkWell && w.onTap != null)),
      );

  for (final style in styles.split(',')) {
    for (var module = firstModule; module < moduleCount; module++) {
      testWidgets('$style · module $module · tap every action', (tester) async {
        tester.view.physicalSize = const Size(360, 740);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final failures = <String>{};
        var step = '';
        final previous = FlutterError.onError;
        FlutterError.onError = (details) {
          final text = details.toString();
          // Network images in fixtures cannot load in tests; that is not a UI bug.
          if (text.contains('NetworkImageLoadException') || text.contains('HTTP request failed')) return;
          final match = culpritPattern.firstMatch(text);
          final where = match == null ? '' : ' <- ${match.group(1)!.trim()} @ ${match.group(2)}';
          failures.add('$step: ${details.exceptionAsString().split('\n').first}$where');
          if (const bool.fromEnvironment('DUMP')) debugPrint('=====DUMP $step\n$details');
        };

        Future<ProviderContainer> launch() async {
          final c = ProviderContainer();
          seedEverything(c);
          c.read(appSettingsProvider.notifier).setCardStyle(style);
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: c,
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                darkTheme: AppDarkTheme.darkTheme,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.3)),
                  child: child!,
                ),
                home: KeyedSubtree(
                  key: const ValueKey('page'),
                  child: MainShellScreen(isDarkMode: false, onToggleDarkMode: (_) {}, onLogout: () {}, initialIndex: module),
                ),
              ),
            ),
          );
          for (var f = 0; f < 12; f++) {
            await tester.pump(const Duration(milliseconds: 100));
          }
          return c;
        }

        var c = await launch();
        final count = tappables().evaluate().length.clamp(0, maxTaps);
        for (var i = 0; i < count; i++) {
          if (i > 0) {
            await tester.pumpWidget(const SizedBox());
            await tester.pump(const Duration(milliseconds: 300));
            c.dispose();
            c = await launch();
          }
          final all = tappables();
          if (i >= all.evaluate().length) break;
          final element = all.evaluate().elementAt(i);
          // Found fresh on each use: entrance animations rebuild rows, and lazily
          // built lists change length while scrolling.
          final target = all.at(i);
          final w = element.widget;
          final text = find
              .descendant(of: target, matching: find.byType(Text))
              .evaluate()
              .map((e) => (e.widget as Text).data ?? '')
              .where((t) => t.isNotEmpty)
              .take(1)
              .join();
          // Editorial rows open on tap but hide their menu behind a long press; hold those.
          final hold = w is EditorialEntry && w.onLongPress != null;
          step =
              '$style module $module ${hold ? 'hold' : 'tap'} $i (${w is CardAction ? 'action "${w.label}"' : w is CardLink ? 'link "${w.label}"' : w is EditorialAction ? 'action "${w.label}"' : w is EditorialIconButton ? 'icon ${w.label}' : w is IconButton ? 'icon ${w.tooltip ?? ''}' : '${w.runtimeType} "$text"'})';
          try {
            await tester.ensureVisible(target);
            await tester.pump(const Duration(milliseconds: 200));
            if (hold) {
              await tester.longPress(target, warnIfMissed: false);
            } else {
              await tester.tap(target, warnIfMissed: false);
            }
            for (var f = 0; f < 10; f++) {
              await tester.pump(const Duration(milliseconds: 100));
            }
          } on RangeError {
            // The list got shorter while scrolling: a test artefact, not an app bug.
          } catch (e) {
            if ('$e'.contains('Found 0 widgets')) continue;
            failures.add('$step: $e');
          }
          final err = tester.takeException();
          if (err != null) failures.add('$step: $err');
        }

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 2));
        tester.takeException();
        c.dispose();
        FlutterError.onError = previous;
        expect(failures, isEmpty, reason: '\n${failures.join('\n')}');
      });
    }
  }
}
