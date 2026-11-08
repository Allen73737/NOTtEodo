import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notteodo/core/state/app_settings.dart';
import 'package:notteodo/core/widgets/bento_pod.dart';
import 'package:notteodo/features/settings/presentation/settings_subpages.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Card Style Architecture State Tests', () {
    test('AppSettings defaults to editorial cardStyle and supports copyWith & JSON', () {
      const settings = AppSettings();
      expect(settings.cardStyle, equals('editorial'));

      final bento = settings.copyWith(cardStyle: 'bento');
      expect(bento.cardStyle, equals('bento'));

      final json = bento.toJson();
      expect(json['cardStyle'], equals('bento'));

      final fromJson = AppSettings.fromJson(json);
      expect(fromJson.cardStyle, equals('bento'));
    });

    test('AppSettingsNotifier updates cardStyle', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(appSettingsProvider).cardStyle, equals('editorial'));

      container.read(appSettingsProvider.notifier).setCardStyle('bento');
      expect(container.read(appSettingsProvider).cardStyle, equals('bento'));

      container.read(appSettingsProvider.notifier).setCardStyle('editorial');
      expect(container.read(appSettingsProvider).cardStyle, equals('editorial'));

      container.read(appSettingsProvider.notifier).setCardStyle('bento');
      expect(container.read(appSettingsProvider).cardStyle, equals('bento'));
    });
  });

  group('BentoPod Dynamic Architecture Widget Tests', () {
    testWidgets('BentoPod adapts smoothly between Bento and Editorial styles', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(appSettingsProvider.notifier).setCardStyle('bento');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: Center(
                child: BentoPod(
                  child: Text('Curated Entry'),
                ),
              ),
            ),
          ),
        ),
      );

      // 1. Initial Bento mode: AnimatedContainer has rounded 20px corners
      expect(find.text('Curated Entry'), findsOneWidget);
      AnimatedContainer containerWidget = tester.widget(find.byType(AnimatedContainer));
      BoxDecoration decor = containerWidget.decoration as BoxDecoration;
      expect((decor.borderRadius as BorderRadius).topLeft.x, equals(20.0));
      expect(decor.boxShadow?.isNotEmpty, isTrue);

      // 2. Switch to Swiss Minimalist Editorial mode
      container.read(appSettingsProvider.notifier).setCardStyle('editorial');
      await tester.pumpAndSettle();

      containerWidget = tester.widget(find.byType(AnimatedContainer));
      decor = containerWidget.decoration as BoxDecoration;
      // Editorial has no surface: no radius, fill, border or shadow.
      expect((decor.borderRadius as BorderRadius).topLeft.x, equals(0.0));
      expect(decor.color, equals(Colors.transparent));
      expect(decor.border, isNull);
      expect(decor.boxShadow?.isEmpty, isTrue);
    });
  });

  group('DisplaySettingsSubpage Card Architecture UI Tests', () {
    testWidgets('DisplaySettingsSubpage renders Card Architecture options and responds to tap', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: DisplaySettingsSubpage(),
          ),
        ),
      );

      expect(find.text('Card & List Architecture'), findsOneWidget);
      expect(find.text('Bento Pods'), findsOneWidget);
      expect(find.text('Editorial'), findsOneWidget);

      // Editorial is the default; switch to Bento and back.
      await tester.ensureVisible(find.text('Bento Pods'));
      await tester.tap(find.text('Bento Pods'));
      await tester.pumpAndSettle();

      expect(container.read(appSettingsProvider).cardStyle, equals('bento'));

      await tester.ensureVisible(find.text('Editorial'));
      await tester.tap(find.text('Editorial'));
      await tester.pumpAndSettle();

      expect(container.read(appSettingsProvider).cardStyle, equals('editorial'));
    });
  });
}
