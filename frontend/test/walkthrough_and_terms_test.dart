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
    testWidgets('1. AppFeatureWalkthroughModal walks every step with how-to lists and actions', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool dismissed = false;
      int? opened;
      await tester.pumpWidget(
        wrapWithScope(
          AppFeatureWalkthroughModal(
            onDismiss: () => dismissed = true,
            onNavigateModule: (i) => opened = i,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));

      const steps = AppFeatureWalkthroughModal.steps;
      expect(steps.length, greaterThanOrEqualTo(10));
      expect(find.text('Welcome to NOTtEodo'), findsOneWidget);
      expect(find.text('Tour  1 of ${steps.length}', findRichText: true), findsOneWidget);
      expect(find.text('How to use it'), findsOneWidget);

      // Walk forward through every step; each shows its headline and how-to list.
      await tester.tap(find.text('Start the tour'));
      await tester.pump(const Duration(milliseconds: 600));
      for (var i = 1; i < steps.length - 1; i++) {
        expect(find.text(steps[i].headline), findsOneWidget, reason: 'step $i');
        expect(find.text(steps[i].howTo.first), findsOneWidget, reason: 'step $i');
        await tester.tap(find.text('Next: ${steps[i + 1].chapter}'));
        await tester.pump(const Duration(milliseconds: 600));
      }
      expect(find.text('You are all set'), findsOneWidget);

      // Jump back to Notes with its progress bar, then use its Try it button.
      await tester.tap(find.bySemanticsLabel('Go to Notes'));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Notes that stay organised'), findsOneWidget);
      await tester.tap(find.text('Try it: Open Notes'));
      expect(opened, 1);
      expect(dismissed, isTrue);
    });

    testWidgets('2. TermsConditionsSubpage renders sovereign charter and export actions', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(wrapWithScope(const TermsConditionsSubpage()));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Terms & Conditions'), findsOneWidget);
      expect(find.text('The sovereign user charter'), findsOneWidget);
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
      expect(find.text('Sign in'), findsOneWidget);
      expect(find.text('Create account'), findsOneWidget);
      expect(find.text('Sign in to NOTtEodo'), findsOneWidget);
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
      expect(find.text('Add expense'), findsOneWidget);
      expect(find.text('Split'), findsOneWidget);
      expect(find.text('Export'), findsOneWidget);
      expect(find.text('Per day until month end'), findsOneWidget);
      expect(find.text('Subscriptions'), findsOneWidget);

      // Open Split Bill modal
      await tester.tap(find.text('Split'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Group bill & tip splitter'), findsOneWidget);
      expect(find.text('Record My Share'), findsOneWidget);
      expect(find.text('Record Owed'), findsOneWidget);
    });
  });
}

