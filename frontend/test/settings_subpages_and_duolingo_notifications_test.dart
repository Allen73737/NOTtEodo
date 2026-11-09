import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notteodo/core/widgets/app_toast_engine.dart';
import 'package:notteodo/core/widgets/sanctuary_animated_notification.dart';
import 'package:notteodo/features/settings/presentation/about_notteodo_subpage.dart';
import 'package:notteodo/features/settings/presentation/help_support_subpage.dart';
import 'package:notteodo/features/settings/presentation/privacy_safety_subpage.dart';
import 'package:notteodo/features/settings/presentation/terms_conditions_subpage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrapWithScaffold(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: child,
        ),
      ),
    );
  }

  group('Settings Dedicated Subpages & Duolingo Notifications', () {
    testWidgets('HelpSupportSubpage renders with 18 FAQs and interactive filters', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(wrapWithScaffold(const HelpSupportSubpage()));
      await tester.pumpAndSettle();

      // Verify title & count
      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('18 TOPICS FOUND'), findsOneWidget);

      // Verify search field exists
      expect(find.byType(TextField), findsOneWidget);

      // Search for "Streak"
      await tester.enterText(find.byType(TextField), 'Streak');
      await tester.pumpAndSettle();

      // Verify streak FAQ matches
      expect(find.textContaining('Daily Streak'), findsWidgets);

      // Tap an FAQ card to expand
      final streakQuestion = find.textContaining('How does the Daily Streak work');
      expect(streakQuestion, findsOneWidget);
      await tester.tap(streakQuestion);
      await tester.pumpAndSettle();

      // Verify expanded answer is visible
      expect(find.textContaining('Your streak increments every calendar day'), findsOneWidget);
      expect(find.text('Copy Answer'), findsOneWidget);

      // Clear search
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();

      // Filter by "AI Companion" category tab
      final aiTab = find.text('AI Companion');
      expect(aiTab, findsOneWidget);
      await tester.tap(aiTab);
      await tester.pumpAndSettle();

      expect(find.textContaining('Nodo'), findsWidgets);
    });

    testWidgets('PrivacySafetySubpage renders local-first architecture and security guarantees', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(wrapWithScaffold(const PrivacySafetySubpage()));
      await tester.pumpAndSettle();

      expect(find.text('Privacy & Data Safety'), findsOneWidget);
      expect(find.text('GUARANTEED PRIVATE'), findsOneWidget);
      expect(find.text('ON-DEVICE SECURITY TELEMETRY'), findsOneWidget);
      expect(find.text('Local SQLite Database'), findsOneWidget);
      expect(find.text('Export Full Archive'), findsOneWidget);
      expect(find.text('Permanently Erase All Data'), findsOneWidget);
    });

    testWidgets('AboutNotteodoSubpage renders craftsmanship, specifications, and version', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(wrapWithScaffold(const AboutNotteodoSubpage()));
      await tester.pumpAndSettle();

      expect(find.text('About NOTtEodo'), findsOneWidget);
      expect(find.text('NOTtEodo'), findsOneWidget);
      expect(find.text('v2.5.0 · Production Edition'), findsOneWidget);
      expect(find.text('Watchmaker Focus Dial'), findsOneWidget);
      expect(find.text('Nodo AI Companion'), findsOneWidget);
      expect(find.text('Client Framework'), findsOneWidget);
      expect(find.text('Flutter 3.x Engine'), findsOneWidget);
    });

    testWidgets('SanctuaryAnimatedNotificationCard renders Duolingo-style dynamic mascot and progress bar', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: AppToastOverlay(
            child: Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    AppToastEngine().notify(
                      title: '🔥 Streak Saved!',
                      message: 'Day 5 locked in with flawless momentum.',
                      actionLabel: 'Check In',
                    );
                  },
                  child: const Text('Trigger Streak Toast'),
                ),
              ),
            ),
          ),
        ),
      );

      // Trigger notification
      await tester.tap(find.text('Trigger Streak Toast'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(SanctuaryAnimatedNotificationCard), findsOneWidget);
      expect(find.text('🔥 Streak Saved!'), findsOneWidget);
      expect(find.text('STREAK MOMENTUM'), findsOneWidget);
      expect(find.text('CHECK IN'), findsOneWidget);

      // Verify mascot 🔥 appears
      expect(find.text('🔥'), findsWidgets);

      // Settle
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(SanctuaryAnimatedNotificationCard), findsOneWidget);
    });

    testWidgets('TermsConditionsSubpage renders sovereign user charter and actions', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(wrapWithScaffold(const TermsConditionsSubpage()));
      await tester.pumpAndSettle();

      expect(find.text('Terms & Conditions'), findsOneWidget);
      expect(find.text('THE SOVEREIGN USER CHARTER'), findsOneWidget);
      expect(find.text('Copy Summary'), findsOneWidget);
      expect(find.text('Export Archive'), findsOneWidget);

      // Verify charter clauses are present
      expect(find.textContaining('Absolute Data Ownership'), findsOneWidget);
      expect(find.textContaining('Zero Subscriptions'), findsOneWidget);
      expect(find.textContaining('Zero-Knowledge Encryption'), findsOneWidget);
    });
  });
}
