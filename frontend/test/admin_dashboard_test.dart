import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notteodo/core/services/sanctuary_supabase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:notteodo/core/enterprise/app_config.dart';
import 'package:notteodo/core/services/local_store.dart';
import 'package:notteodo/features/admin/presentation/admin_dashboard_screen.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStore().init();
  });

  group('Admin access', () {
    test('no admin credential ships in the app', () {
      // Admin rights come from the server's app_admins table via is_app_admin().
      expect(AppConfig.adminEmail.contains('@'), isFalse);
    });

    test('signed out, the app never claims admin rights', () async {
      expect(await SanctuarySupabaseService().isAppAdmin(), isFalse);
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

    testWidgets('renders perfectly on narrow mobile viewport with operating guide', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
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

      // Verify Operating Guide & Hub Navigator
      expect(find.text('Sovereign Admin Operating Guide'), findsOneWidget);
      expect(find.text('01 Overview'), findsOneWidget);
      expect(find.text('02 Users & Roles'), findsOneWidget);
      expect(find.text('07 Feedback'), findsOneWidget);

      // Tap expand guide
      await tester.tap(find.text('Expand Guide'));
      await tester.pumpAndSettle();

      expect(find.text('Zero-Secret Client Architecture'), findsOneWidget);
      expect(find.text('Local-First Offline Outbox'), findsOneWidget);
      expect(find.text('Tamper-Evident SHA-256 Audit Ledger'), findsOneWidget);

      // Verify metric tiles
      expect(find.text('SYSTEM STATUS'), findsOneWidget);
      expect(find.text('TOTAL RECORDS'), findsOneWidget);
      expect(find.text('ENCRYPTED SLOTS'), findsOneWidget);

      // Navigate to Users tab using quick jump pill
      await tester.tap(find.text('02 Users & Roles'));
      await tester.pumpAndSettle();

      expect(find.text('USER MANAGEMENT & SUB-ADMIN DELEGATION'), findsOneWidget);
      expect(find.text('SUB-ADMIN INVITATION LINKS'), findsOneWidget);
    });
  });
}

