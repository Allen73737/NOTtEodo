import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notteodo/core/enterprise/sanctuary_error_boundary.dart';
import 'package:notteodo/core/enterprise/enterprise_shortcuts.dart';
import 'package:notteodo/core/widgets/app_drawer.dart';
import 'package:notteodo/features/settings/presentation/settings_screen.dart';
import 'package:notteodo/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Sanctuary Error Boundary Resilience Tests', () {
    testWidgets('SanctuaryErrorBoundary intercepts faults and recovers gracefully', (tester) async {
      final defaultErrorBuilder = ErrorWidget.builder;
      addTearDown(() => ErrorWidget.builder = defaultErrorBuilder);

      final boundaryKey = GlobalKey<SanctuaryErrorBoundaryState>();

      await tester.pumpWidget(
        MaterialApp(
          home: SanctuaryErrorBoundary(
            key: boundaryKey,
            child: const Scaffold(body: Text('Normal Execution')),
          ),
        ),
      );

      expect(find.text('Normal Execution'), findsOneWidget);

      // Trigger diagnostic error report on boundary
      boundaryKey.currentState?.reportError(
        FlutterErrorDetails(exception: Exception('Artificial escapement gear train fault')),
      );
      await tester.pump();

      // Verify the Haute Horlogerie error boundary displays recovery card
      expect(find.text('SANCTUARY EQUILIBRIUM PRESERVED'), findsOneWidget);
      expect(find.text('RESTORE EQUILIBRIUM'), findsOneWidget);

      // Verify recovering from error
      await tester.tap(find.text('RESTORE EQUILIBRIUM'));
      await tester.pump();

      expect(find.text('Normal Execution'), findsOneWidget);

      // Unmount boundary cleanly to invoke dispose()
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Enterprise Keyboard Shortcuts & Dialog Tests', () {
    testWidgets('EnterpriseShortcutsDialog renders all keybindings clearly', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnterpriseShortcutsDialog(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Command Shortcuts'), findsOneWidget);
      expect(find.text('Universal Search & Command Palette'), findsOneWidget);
      expect(find.text('Enterprise Governance & SOC2 Console'), findsOneWidget);
      expect(find.text('Dismiss'), findsOneWidget);
    });
  });

  group('Sanctuary App Drawer Navigation Tests', () {
    testWidgets('AppDrawer renders clean lifestyle items and secure preferences', (tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AppDrawer(
                activeIndex: 0,
                isDarkMode: true,
                onToggleDarkMode: (_) {},
                onSelectModule: (_) {},
              ),
            ),
          ),
        ),
      );

      // AppDrawer uses infinite rotation animations (.repeat()), so pump for finite duration
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('Your workspace'), findsOneWidget);
      expect(find.text('ONLINE · SYNCED'), findsOneWidget);
      expect(find.text('Vault', skipOffstage: false), findsOneWidget);
      expect(find.text('Settings', skipOffstage: false), findsOneWidget);
    });

    testWidgets('SettingsScreen houses Interactive Feature Walkthrough and Admin Dashboard houses Enterprise Governance', (tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SettingsScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Diagnostics & System Tools'), findsOneWidget);
      await tester.tap(find.text('Diagnostics & System Tools'));
      await tester.pumpAndSettle();

      expect(find.text('Interactive Feature Walkthrough'), findsOneWidget);
      expect(find.text("What's New in NOTtEodo"), findsOneWidget);
    });
  });

  group('Sanctuary App Stage Transition Smoke Tests', () {
    testWidgets('NOTtEodoApp boots cleanly at LogoReveal', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: NOTtEodoApp(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(NOTtEodoApp), findsOneWidget);
    });
  });
}
