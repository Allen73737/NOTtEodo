import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notteodo/main.dart';
import 'package:notteodo/core/state/app_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Marketing Showcase & Viewport Verification', () {
    testWidgets('renders Bento Mode at 1080x2400 (FHD+) cleanly without overflow', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appSettingsProvider.overrideWith((ref) => AppSettingsNotifier()
              ..setCardStyle('bento')),
          ],
          child: MaterialApp(
            home: MainShellScreen(
              isDarkMode: true,
              onToggleDarkMode: (_) {},
              onLogout: () {},
            ),
          ),
        ),
      );
      for (var f = 0; f < 10; f++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byType(MainShellScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders Swiss Editorial Mode at 1080x2400 (FHD+) cleanly without overflow', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appSettingsProvider.overrideWith((ref) => AppSettingsNotifier()
              ..setCardStyle('editorial')),
          ],
          child: MaterialApp(
            home: MainShellScreen(
              isDarkMode: false,
              onToggleDarkMode: (_) {},
              onLogout: () {},
            ),
          ),
        ),
      );
      for (var f = 0; f < 10; f++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byType(MainShellScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

