import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:notteodo/core/widgets/app_feature_walkthrough.dart';
import 'package:notteodo/features/auth/presentation/signin_screen.dart';
import 'package:notteodo/features/expenses/presentation/expenses_screen.dart';
import 'package:notteodo/features/settings/presentation/terms_conditions_subpage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrapWithScope(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(body: child),
      ),
    );
  }

  group('Walkthrough, Terms & Uncluttered Login Suite', () {
    testWidgets('1. AppFeatureWalkthroughModal renders 7 detailed steps and interactive navigation', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool dismissed = false;
      await tester.pumpWidget(
        wrapWithScope(
          AppFeatureWalkthroughModal(
            onDismiss: () => dismissed = true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Step 1: Command Center
      expect(find.text('01 · COMMAND CENTER'), findsOneWidget);
      expect(find.text('Homescreen & Morning Briefing'), findsOneWidget);
      expect(find.textContaining('DAILY SANCTUARY'), findsOneWidget);
      expect(find.text('Open Homescreen'), findsOneWidget);
      expect(find.textContaining('Tap the wax seal stamp each evening'), findsOneWidget);

      // Tap Next
      await tester.tap(find.text('Next Feature'));
      await tester.pump(const Duration(milliseconds: 300));

      // Step 2: Dual Visual Architecture
      expect(find.text('02 · ADAPTIVE PRESENTATION'), findsOneWidget);
      expect(find.text('Dual Visual Architecture'), findsOneWidget);
      expect(find.text('BENTO & EDITORIAL'), findsOneWidget);
      expect(find.text('Explore Swiss Editorial'), findsOneWidget);

      // Tap Next
      await tester.tap(find.text('Next Feature'));
      await tester.pump(const Duration(milliseconds: 300));

      // Step 3: Omni-Capture
      expect(find.text('03 · SMART CAPTURE'), findsOneWidget);
      expect(find.text('Omni-Capture Speed Hub'), findsOneWidget);
      expect(find.text('Launch Omni-Capture'), findsOneWidget);

      // Tap Next
      await tester.tap(find.text('Next Feature'));
      await tester.pump(const Duration(milliseconds: 300));

      // Step 4: Notes & 3D Moodboards
      expect(find.text('04 · CREATIVE CANVAS'), findsOneWidget);
      expect(find.text('Notes, Vault & 3D Moodboards'), findsOneWidget);
      expect(find.text('View Notes & Moodboards'), findsOneWidget);

      // Tap Next
      await tester.tap(find.text('Next Feature'));
      await tester.pump(const Duration(milliseconds: 300));

      // Step 5: Expenses & Split Bills
      expect(find.text('05 · FINANCIAL LEDGER'), findsOneWidget);
      expect(find.text('Powerful Expense Tracking & Split Bills'), findsOneWidget);
      expect(find.text('Open Financial Ledger'), findsOneWidget);

      // Tap Next
      await tester.tap(find.text('Next Feature'));
      await tester.pump(const Duration(milliseconds: 300));

      // Step 6: Nodo & Audio Studio
      expect(find.text('06 · INTELLIGENT ASSISTANT'), findsOneWidget);
      expect(find.text('Nodo Companion & Native Audio Studio'), findsOneWidget);
      expect(find.text('Meet Nodo Assistant'), findsOneWidget);

      // Tap Next
      await tester.tap(find.text('Next Feature'));
      await tester.pump(const Duration(milliseconds: 300));

      // Step 7: Android System
      expect(find.text('07 · SYSTEM INTEGRATION'), findsOneWidget);
      expect(find.text('Android Shortcuts & Aesthetic Widgets'), findsOneWidget);
      expect(find.text('Open Settings & Widgets'), findsOneWidget);

      // Complete Tour
      await tester.tap(find.text('Complete Sanctuary Tour'));
      expect(dismissed, isTrue);
    });

    testWidgets('2. TermsConditionsSubpage renders sovereign charter and export actions', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(wrapWithScope(const TermsConditionsSubpage()));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Terms & Conditions'), findsOneWidget);
      expect(find.text('THE SOVEREIGN USER CHARTER'), findsOneWidget);
      expect(find.text('Copy Summary'), findsOneWidget);
      expect(find.text('Export Archive'), findsOneWidget);
      expect(find.textContaining('100% Local-First'), findsWidgets);
      expect(find.textContaining('Zero Subscriptions'), findsWidgets);
    });

    testWidgets('3. SignInScreen renders uncluttered cards layout with terms and privacy links', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        wrapWithScope(
          SignInScreen(
            onAuthenticated: () {},
          ),
        ),
      );
      // Step frames without infinite settle
      for (var f = 0; f < 10; f++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('NOTtEodo'), findsOneWidget);
      expect(find.text('SIGN IN'), findsOneWidget);
      expect(find.text('CREATE ACCOUNT'), findsOneWidget);
      expect(find.text('UNLOCK SANCTUARY'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Explore offline as guest'), findsOneWidget);

      // Verify Terms & Conditions and Privacy Policy links
      expect(find.text('Terms & Conditions'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
    });

    testWidgets('4. ExpensesScreen renders Split Bill, Export, and Subscriptions controls', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(wrapWithScope(const ExpensesScreen()));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Expenses'), findsOneWidget);
      expect(find.text('Add Expense'), findsOneWidget);
      expect(find.text('Split'), findsOneWidget);
      expect(find.text('Export'), findsOneWidget);
      expect(find.text('DAILY ALLOWANCE'), findsOneWidget);
      expect(find.text('SUBSCRIPTIONS'), findsOneWidget);

      // Open Split Bill modal
      await tester.tap(find.text('Split'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('GROUP BILL & TIP SPLITTER'), findsOneWidget);
      expect(find.text('Record My Share'), findsOneWidget);
      expect(find.text('Record Owed'), findsOneWidget);
    });
  });
}

