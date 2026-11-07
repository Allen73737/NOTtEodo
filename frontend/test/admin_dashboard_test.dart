import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:notteodo/core/enterprise/app_config.dart';
import 'package:notteodo/core/services/local_store.dart';
import 'package:notteodo/features/admin/presentation/admin_dashboard_screen.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStore().init();
  });

  group('Sovereign Administrator Credentials & Gateway Verification', () {
    test('validates predefined sovereign admin credentials', () {
      expect(
        AppConfig.isSovereignAdminCredentials(
          'admin@notteodo.sanctuary',
          'Sanctuary@MasterKey2026!',
        ),
        isTrue,
      );
      // Case-insensitive email
      expect(
        AppConfig.isSovereignAdminCredentials(
          'ADMIN@NOTTEODO.SANCTUARY',
          'Sanctuary@MasterKey2026!',
        ),
        isTrue,
      );
      // Rejects invalid password
      expect(
        AppConfig.isSovereignAdminCredentials(
          'admin@notteodo.sanctuary',
          'WrongPassword123!',
        ),
        isFalse,
      );
      // Rejects wrong email
      expect(
        AppConfig.isSovereignAdminCredentials(
          'user@example.com',
          'Sanctuary@MasterKey2026!',
        ),
        isFalse,
      );
    });
  });

  group('Admin Dashboard Screen UI & Dual-Mode Verification', () {
    testWidgets('renders Sovereign Admin Dashboard in Dark Mode without error', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: AdminDashboardScreen(
              isDarkMode: true,
              onToggleDarkMode: (_) {},
              onEnterSanctuary: () {},
              onSignOut: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('NOTTEODO'), findsWidgets);
      expect(find.text('OWNER'), findsOneWidget);
      expect(find.text('App Shell'), findsOneWidget);
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Users & Sub-Admins'), findsOneWidget);
      expect(find.text('Cloud & Network'), findsOneWidget);
    });

    testWidgets('renders Sovereign Admin Dashboard in Light Mode without error', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.light(),
            home: AdminDashboardScreen(
              isDarkMode: false,
              onToggleDarkMode: (_) {},
              onEnterSanctuary: () {},
              onSignOut: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('NOTTEODO'), findsWidgets);
      expect(find.text('OWNER'), findsOneWidget);
      expect(find.text('App Shell'), findsOneWidget);
    });

    testWidgets('switches tabs to Cloudinary and Ledger & Merkle cleanly', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Verify Cloud & Network Tab (Index 2)
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: AdminDashboardScreen(
              key: const Key('admin_tab_cloudinary'),
              initialTabIndex: 2,
              isDarkMode: true,
              onToggleDarkMode: (_) {},
              onEnterSanctuary: () {},
              onSignOut: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('CLOUD & NETWORK HEALTH MONITOR'), findsOneWidget);
      expect(find.text('res.cloudinary.com/qg5h6ol4'), findsWidgets);

      // Verify Database & Vault Tab (Index 3)
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: AdminDashboardScreen(
              key: const Key('admin_tab_ledger'),
              initialTabIndex: 3,
              isDarkMode: true,
              onToggleDarkMode: (_) {},
              onEnterSanctuary: () {},
              onSignOut: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('DATABASE & LOCAL VAULT'), findsOneWidget);

      // Verify AI Engine Tab (Index 4)
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: AdminDashboardScreen(
              key: const Key('admin_tab_ai'),
              initialTabIndex: 4,
              isDarkMode: true,
              onToggleDarkMode: (_) {},
              onEnterSanctuary: () {},
              onSignOut: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('AI ENGINE & MODEL COMMAND'), findsOneWidget);

      // Verify User Feedback & Ideas Tab (Index 6)
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: AdminDashboardScreen(
              key: const Key('admin_tab_feedback'),
              initialTabIndex: 6,
              isDarkMode: true,
              onToggleDarkMode: (_) {},
              onEnterSanctuary: () {},
              onSignOut: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('USER VOICE & FEATURE SUGGESTIONS'), findsOneWidget);
    });
  });
}

