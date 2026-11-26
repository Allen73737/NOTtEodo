import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notteodo/core/editorial/daily_edition_masthead.dart';
import 'package:notteodo/core/editorial/editorial_marginalia.dart';
import 'package:notteodo/core/luxury/monogram_wax_seal.dart';
import 'package:notteodo/core/motion/oxblood_focus_luminescence.dart';
import 'package:notteodo/core/motion/pinch_view_switcher.dart';
import 'package:notteodo/core/state/app_settings.dart';

void main() {
  group('Editorial Luxury Enhancements Test Suite', () {
    testWidgets('DailyEditionMasthead renders in cards and editorial view', (tester) async {
      // Cards view
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DailyEditionMasthead(isEditorial: false),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DailyEditionMasthead), findsOneWidget);
      expect(find.textContaining('ISSUE NO.'), findsOneWidget);

      // Tap to expand
      await tester.tap(find.byType(DailyEditionMasthead));
      await tester.pumpAndSettle();

      // Editorial view
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DailyEditionMasthead(isEditorial: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DailyEditionMasthead), findsOneWidget);
      expect(find.textContaining('NOTtEodo'), findsOneWidget);
    });

    testWidgets('EditorialMarginalia displays gutter markings properly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EditorialMarginalia(
              gutterLabel: '09:30',
              romanIndex: 'I',
              isUrgent: true,
              trailingNote: 'Priority',
              child: Text('Deep Reading Session'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Deep Reading Session'), findsOneWidget);
      expect(find.text('Priority'), findsOneWidget);
    });

    testWidgets('PinchViewSwitcher wraps child without layout disruption', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PinchViewSwitcher(
                child: Center(child: Text('Content inside switcher')),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Content inside switcher'), findsOneWidget);
    });

    testWidgets('OxbloodFocusLuminescence renders focused and dimmed states', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                OxbloodFocusLuminescence(
                  isFocused: true,
                  isEditorial: true,
                  child: Text('Active Note Line'),
                ),
                OxbloodFocusLuminescence(
                  isFocused: false,
                  child: Text('Inactive Note Line'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Active Note Line'), findsOneWidget);
      expect(find.text('Inactive Note Line'), findsOneWidget);
    });

    testWidgets('MonogrammedWaxSeal stamps with monogram and animation', (tester) async {
      var completed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MonogrammedWaxSeal(
              size: 80,
              isEditorial: false,
              onComplete: () => completed = true,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.byType(MonogrammedWaxSeal), findsOneWidget);
      expect(find.text('N'), findsOneWidget);
      expect(completed, isTrue);
    });

    test('UiPrefs default dailyEdition is false and pinchToSwitchView is true', () {
      final defaultPrefs = UiPrefs.of(const AppSettings());
      expect(defaultPrefs.dailyEdition, isFalse);
      expect(defaultPrefs.pinchToSwitchView, isTrue);
    });
  });
}
