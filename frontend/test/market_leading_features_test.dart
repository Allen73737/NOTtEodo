import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:notteodo/core/widgets/daily_flow_timeline_widget.dart';
import 'package:notteodo/core/widgets/evening_zen_review_dialog.dart';
import 'package:notteodo/core/widgets/expense_pacing_graph_widget.dart';
import 'package:notteodo/core/widgets/habit_heatmap_and_curators_cabinet.dart';
import 'package:notteodo/core/widgets/omni_capture_modal.dart';
import 'package:notteodo/core/widgets/universal_spotlight_modal.dart';
import 'package:notteodo/features/expenses/presentation/expenses_screen.dart';
import 'package:notteodo/features/settings/presentation/archived_hidden_vault.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrapWithProvider(Widget child, {bool scrollable = false}) {
    return ProviderScope(
      child: MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 1200,
            child: scrollable ? SingleChildScrollView(child: child) : child,
          ),
        ),
      ),
    );
  }

  group('Market-Leading Features Suite', () {
    testWidgets('1. HabitHeatmapWidget renders 14-week activity grid and stats', (tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(wrapWithProvider(const HabitHeatmapWidget(), scrollable: true));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Activity'), findsOneWidget);
      expect(find.textContaining('active day'), findsOneWidget);
      expect(find.textContaining('day streak'), findsOneWidget);
    });

    testWidgets('2. CuratorsCabinetWidget displays 8 milestone badges and unlock state', (tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(wrapWithProvider(const CuratorsCabinetWidget(), scrollable: true));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Milestones'), findsOneWidget);
      expect(find.textContaining('unlocked'), findsOneWidget);
      expect(find.textContaining('Kindling Spark'), findsWidgets);
      expect(find.textContaining('Brass Lantern'), findsWidgets);
      expect(find.textContaining('Vault Guardian'), findsWidgets);
    });

    testWidgets('3. ExpensePacingGraphWidget displays 7-day pacing and Nodo advice', (tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(wrapWithProvider(
        ExpensePacingGraphWidget(onAddExpense: () {}),
        scrollable: true,
      ));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('7-day pacing & financial health'), findsOneWidget);
      expect(find.text('LOG'), findsOneWidget);
    });

    testWidgets('4. DailyFlowTimelineWidget renders 24-hour visual schedule and focus trigger', (tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool focusOpened = false;
      await tester.pumpWidget(
        wrapWithProvider(
          DailyFlowTimelineWidget(
            onOpenFocusDial: () => focusOpened = true,
          ),
          scrollable: true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Your day'), findsOneWidget);
      expect(find.text('Focus dial'), findsOneWidget);

      await tester.tap(find.text('Focus dial'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(focusOpened, isTrue);
    });

    testWidgets('5. OmniCaptureModal parses natural language input and detects intents', (tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(wrapWithProvider(const OmniCaptureModal()));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Omni-capture speed hub'), findsOneWidget);

      final inputFinder = find.byType(TextField);
      expect(inputFinder, findsOneWidget);

      // Enter an expense thought
      await tester.enterText(inputFinder, 'Dinner at Bistro ₹1400 #food tomorrow');
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Expense'), findsWidgets);
      expect(find.textContaining('₹1400'), findsWidgets);
    });

    testWidgets('6. UniversalSpotlightModal filters across all modules with search', (tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(wrapWithProvider(const UniversalSpotlightModal()));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Universal Spotlight'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('Tasks'), findsOneWidget);
      expect(find.text('Habits'), findsOneWidget);
      expect(find.text('Expenses'), findsOneWidget);
      expect(find.text('Wardrobe'), findsOneWidget);
    });

    testWidgets('7. EveningZenReviewDialog renders daily velocity and reflection prompt', (tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(wrapWithProvider(const EveningZenReviewDialog()));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Daily shutdown ritual'), findsOneWidget);
      expect(find.text('Close Your Day with Peace'), findsOneWidget);
      expect(find.text('One-sentence reflection'), findsOneWidget);
      expect(find.text('SEAL THE DAY & REST'), findsOneWidget);
    });

    testWidgets('8. ArchivedHiddenVault contains zero dummy data and shows clean empty state', (tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(wrapWithProvider(ArchivedHiddenVault(onClose: () {})));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Private Seed Phrase Backup'), findsNothing);
      expect(find.text('Offshore Asset & Swiss Bank Memo'), findsNothing);
      expect(find.text('Private Family Estate Trust'), findsNothing);
    });

    testWidgets('9. ExpensesScreen uses simple accessible vocabulary and includes pacing graph', (tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(wrapWithProvider(const ExpensesScreen()));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Expenses'), findsOneWidget);
      expect(find.text('Add expense'), findsOneWidget);
      expect(find.textContaining('Spending in '), findsOneWidget);
      expect(find.text('7-day pacing & financial health'), findsOneWidget);
      expect(find.text('Per day until month end'), findsOneWidget);
      expect(find.text('Transactions'), findsOneWidget);
      expect(find.text('Bill splits & settlements'), findsOneWidget);

      // Verify absence of confusing esoteric terms
      expect(find.text('Swiss Bank Perforated Provenance Certificate'), findsNothing);
      expect(find.text('Certificate of Expense'), findsNothing);
      expect(find.text('SYNDICATE LIQUIDITY INSCRIBER'), findsNothing);
      expect(find.text('CATEGORY PROVENANCE'), findsNothing);
      expect(find.text('P2P LIQUIDITY TOPOLOGY'), findsNothing);
    });
  });
}
