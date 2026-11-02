import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notteodo/app/theme/app_dark_theme.dart';
import 'package:notteodo/app/theme/app_theme.dart';
import 'package:notteodo/main.dart';

/// Renders every module of the app shell at phone, tablet and desktop widths in
/// both themes, letting entrance animations run, and fails on any framework
/// error (overflows, bad parent data, exceptions in build/paint).
void main() {
  const viewports = <String, Size>{
    'phone': Size(390, 844),
    'small-phone': Size(360, 740),
    'tablet': Size(820, 1180),
    'desktop': Size(1440, 900),
  };
  const moduleCount = int.fromEnvironment('MODULES', defaultValue: 15);
  final culpritPattern = RegExp(r'(\w+):file:///\S+?/frontend/lib/(\S+)');

  for (final entry in viewports.entries) {
    for (final dark in [false, true]) {
      testWidgets('all modules render cleanly · ${entry.key} · ${dark ? 'dark' : 'light'}', (tester) async {
        tester.view.physicalSize = entry.value;
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
          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                darkTheme: AppDarkTheme.darkTheme,
                themeMode: dark ? ThemeMode.dark : ThemeMode.light,
                home: MainShellScreen(
                  key: ValueKey('shell-$module'),
                  isDarkMode: dark,
                  onToggleDarkMode: (_) {},
                  onLogout: () {},
                  initialIndex: module,
                ),
              ),
            ),
          );
          // Step through entrance choreography without waiting on ambient loops.
          for (var f = 0; f < 15; f++) {
            await tester.pump(const Duration(milliseconds: 100));
          }
          final err = tester.takeException();
          if (err != null) failures.add('module $module: $err');
        }

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 2));
        tester.takeException();
        FlutterError.onError = previous;

        expect(failures, isEmpty, reason: '\n${failures.join('\n')}');
      });
    }
  }
}
