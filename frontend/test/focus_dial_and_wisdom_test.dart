import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notteodo/core/luxury/breguet_hands_tracker.dart';
import 'package:notteodo/core/widgets/focus_dial_modal.dart';
import 'package:notteodo/core/widgets/daily_wisdom_focus_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Feature 3: Watchmaker Focus Dial (Breguet Hands) Tests', () {
    testWidgets('BreguetHandsTracker renders properly across progress values in light & dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          home: const Scaffold(
            body: Column(
              children: [
                BreguetHandsTracker(progress: 0.0, size: 80, centerCaption: 'START'),
                BreguetHandsTracker(progress: 0.5, size: 100, isRunning: true, centerCaption: 'FLOW'),
                BreguetHandsTracker(progress: 1.0, size: 120, timeRemainingText: '00:00'),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(BreguetHandsTracker), findsNWidgets(3));
      expect(find.text('START'), findsOneWidget);
      expect(find.text('FLOW'), findsOneWidget);
      expect(find.text('00:00'), findsOneWidget);
    });

    testWidgets('FocusDialModal renders complete interactive controls and Breguet dial', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool toggleTapped = false;
      bool resetTapped = false;
      bool soundTapped = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FocusDialModal(
                focusLeft: const Duration(minutes: 20, seconds: 30),
                focusTotal: const Duration(minutes: 25),
                isRunning: true,
                onToggle: () => toggleTapped = true,
                onReset: () => resetTapped = true,
                onOpenSoundSelector: () => soundTapped = true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('WATCHMAKER FOCUS DIAL'), findsOneWidget);
      expect(find.text('RUNNING'), findsOneWidget);
      expect(find.text('20:30'), findsOneWidget);
      expect(find.byType(BreguetHandsTracker), findsOneWidget);

      // Tap play/pause
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(toggleTapped, isTrue);

      // Tap reset
      await tester.tap(find.byTooltip('Reset Session'));
      await tester.pump();
      expect(resetTapped, isTrue);

      // Tap sound
      await tester.tap(find.byTooltip('Focus Soundtracks'));
      await tester.pump();
      expect(soundTapped, isTrue);
    });
  });

  group('Feature 4: Curated Daily Wisdom & Focus Maxim Card Tests', () {
    testWidgets('DailyWisdomFocusCard renders theme, maxim, reflection question and actions', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool journalTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DailyWisdomFocusCard(
                onReflectInJournal: () => journalTapped = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('DAILY WISDOM & FOCUS'), findsOneWidget);
      expect(find.text('TODAY\'S QUESTION'), findsOneWidget);
      expect(find.text('Next Insight'), findsOneWidget);
      expect(find.text('Journal This'), findsOneWidget);

      // Tap Next Insight button
      await tester.tap(find.text('Next Insight'));
      await tester.pumpAndSettle();

      // Tap Journal This button
      await tester.tap(find.text('Journal This'));
      await tester.pumpAndSettle();
      expect(journalTapped, isTrue);
    });

    testWidgets('DailyWisdomFocusCard does not overflow on small 320px screen', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DailyWisdomFocusCard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
