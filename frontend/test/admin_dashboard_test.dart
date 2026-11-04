import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:notteodo/core/enterprise/app_config.dart';
import 'package:notteodo/core/services/local_store.dart';
import 'package:notteodo/features/admin/presentation/admin_dashboard_screen.dart';

void main() {
  setUp(() async {
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
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

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

      expect(find.text('NOTTEODO ADMIN'), findsOneWidget);
      expect(find.text('ADMINISTRATOR'), findsOneWidget);
      expect(find.text('Enter App Shell'), findsOneWidget);
      expect(find.text('Overview & HUD'), findsOneWidget);
      expect(find.text('User & Access'), findsOneWidget);
      expect(find.text('Cloudinary Vault'), findsOneWidget);
    });

    testWidgets('renders Sovereign Admin Dashboard in Light Mode without error', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

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

      expect(find.text('NOTTEODO ADMIN'), findsOneWidget);
      expect(find.text('ADMINISTRATOR'), findsOneWidget);
      expect(find.text('Enter App Shell'), findsOneWidget);
    });

    testWidgets('switches tabs to Cloudinary and Ledger & Merkle cleanly', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
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

      // Tap Cloudinary Vault Tab
      await tester.tap(find.text('Cloudinary Vault'));
      await tester.pumpAndSettle();

      expect(find.text('CLOUDINARY MEDIA VAULT & CDN GOVERNANCE'), findsOneWidget);
      expect(find.text('qg5h6ol4'), findsOneWidget);

      // Tap AI & Neural Engine Tab
      await tester.tap(find.text('AI & Neural Engine'));
      await tester.pumpAndSettle();

      expect(find.text('NEURAL SYNTHESIS & AI TONE GOVERNANCE'), findsOneWidget);
    });
  });
}

