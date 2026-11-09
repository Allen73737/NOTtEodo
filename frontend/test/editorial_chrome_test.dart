import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notteodo/app/theme/app_dark_theme.dart';
import 'package:notteodo/app/theme/app_theme.dart';
import 'package:notteodo/core/editorial/editorial_chrome.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';
import 'package:notteodo/core/editorial/view_style_chooser.dart';
import 'package:notteodo/core/state/app_settings.dart';
import 'package:notteodo/core/state/bin_state.dart';
import 'package:notteodo/core/state/sanctuary_state.dart';
import 'package:notteodo/core/widgets/homescreen/aesthetic_widget_models.dart';
import 'package:notteodo/core/widgets/homescreen/editorial_home_widget.dart';
import 'package:notteodo/features/bin/presentation/bin_editorial_view.dart';
import 'package:notteodo/features/settings/presentation/look_and_feel_page.dart';
import 'package:notteodo/features/settings/presentation/settings_editorial_view.dart';

import 'support/fixtures.dart';

Future<void> _show(WidgetTester tester, ProviderContainer c, Widget child, {bool dark = false}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(
      theme: editorialTheme(AppTheme.lightTheme),
      darkTheme: editorialTheme(AppDarkTheme.darkTheme),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(body: child),
    ),
  ));
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  tearDown(() => EditorialMode.active = false);

  group('edBox', () {
    test('is an ordinary BoxDecoration in the card view', () {
      EditorialMode.active = false;
      final d = edBox(color: Colors.white, border: Border.all(), boxShadow: const [BoxShadow(blurRadius: 4)]);
      expect(d.color, Colors.white);
      expect(d.border, isNotNull);
      expect(d.boxShadow, isNotEmpty);
    });

    test('drops card surfaces, borders and shadows in the editorial view', () {
      EditorialMode.active = true;
      final card = edBox(
        color: const Color(0xFFFFFFFF),
        border: Border.all(color: const Color(0xFFE8E3D8)),
        boxShadow: const [BoxShadow(blurRadius: 8)],
        borderRadius: BorderRadius.circular(20),
      );
      expect(card.color, isNull);
      expect(card.border, isNull);
      expect(card.boxShadow, isNull);
      final darkCard = edBox(color: const Color(0xFF0A0A0A));
      expect(darkCard.color, isNull);
      final tint = edBox(color: const Color(0xFFD9725B).withValues(alpha: 0.1));
      expect(tint.color, isNull);
    });

    test('keeps meaningful colour: accent fills, circles and photos', () {
      EditorialMode.active = true;
      expect(edBox(color: const Color(0xFFD9725B)).color, const Color(0xFFD9725B));
      final dot = edBox(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: Colors.grey));
      expect(dot.color, isNull);
      expect(dot.border, isNotNull);
      expect(edBox(border: Border.all(color: const Color(0xFFD9725B))).border, isNotNull);
    });
  });

  group('preferences sync', () {
    test('device-only settings never leave the device', () {
      final row = AppSettingsNotifier.syncRow(const AppSettings(vaultPin: '1234', isAdminSession: true, avatarCustomPath: '/data/me.jpg'));
      expect(row.containsKey('vaultPin'), isFalse);
      expect(row.containsKey('isAdminSession'), isFalse);
      expect(row.containsKey('avatarCustomPath'), isFalse);
      expect(row['id'], AppSettingsNotifier.syncKey);
      final cloudAvatar = AppSettingsNotifier.syncRow(const AppSettings(avatarCustomPath: 'https://res.cloudinary.com/x.jpg'));
      expect(cloudAvatar['avatarCustomPath'], 'https://res.cloudinary.com/x.jpg');
    });

    test('a fresh install takes the synced streak and look', () {
      final local = const AppSettings().toJson();
      final remote = {
        ...const AppSettings(activeStreak: 42, longestStreak: 50, lastActiveDate: '2026-11-08', cardStyle: 'bento').toJson(),
        'id': 'preferences',
      };
      final merged = AppSettings.fromJson(AppSettingsNotifier.mergeSynced(local, remote));
      expect(merged.activeStreak, 42);
      expect(merged.longestStreak, 50);
      expect(merged.cardStyle, 'bento');
    });

    test('a more recent local streak is not overwritten, and the vault PIN stays', () {
      final local = const AppSettings(activeStreak: 3, lastActiveDate: '2026-11-09', longestStreak: 3, vaultPin: '9999').toJson();
      final remote = {
        ...const AppSettings(activeStreak: 40, lastActiveDate: '2026-10-01', longestStreak: 40, vaultPin: '0000').toJson(),
        'id': 'preferences',
      };
      final merged = AppSettings.fromJson(AppSettingsNotifier.mergeSynced(local, remote));
      expect(merged.activeStreak, 3);
      expect(merged.longestStreak, 40);
      expect(merged.vaultPin, '9999');
    });
  });

  test('UI preferences have sensible defaults and round-trip', () {
    const p = UiPrefs({});
    expect([p.accent, p.textScaleFactor, p.headline, p.density, p.swipeActions, p.confirmDeletes], ['terracotta', 1.0, 'classic', 'comfortable', true, false]);
    expect(p.dock, [0, 1, 2, 3]);
    final s = AppSettings.fromJson(const AppSettings(ui: {'accent': 'olive', 'dock': [0, 9, 5, 2]}).toJson());
    expect(UiPrefs.of(s).accent, 'olive');
    expect(UiPrefs.of(s).dock, [0, 9, 5, 2]);
  });

  testWidgets('style chooser shows both views and applies the choice', (tester) async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await _show(tester, c, const ViewStyleChooser());
    expect(find.text('Editorial'), findsWidgets);
    expect(find.text('Cards'), findsWidgets);
    await tester.tap(find.text('Cards').first);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Use Cards'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final dark in [false, true]) {
    testWidgets('chrome, settings, look & feel and bin render · ${dark ? 'dark' : 'light'}', (tester) async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      EditorialMode.active = true;
      seedEverything(c);
      c.read(tasksProvider.notifier).deleteTask(c.read(tasksProvider).first.id);
      for (final w in <Widget>[
        Column(children: [
          EditorialTopBar(activeIndex: 2, onMenu: () {}, onBack: () {}, onSearch: () {}, onAsk: () {}, isDark: dark, onToggleDark: (_) {}),
          const Spacer(),
          EditorialDock(activeIndex: 2, onSelect: (_) {}, onAdd: () {}, onMore: () {}),
        ]),
        EditorialDrawer(activeIndex: 1, onSelect: (_) {}, isDark: dark, onToggleDark: (_) {}, onLogout: () {}),
        const SettingsEditorialView(),
        const LookAndFeelPage(),
        BinEditorialView(onOpenModule: (_) {}),
      ]) {
        await _show(tester, c, w, dark: dark);
        expect(tester.takeException(), isNull);
      }
      expect(c.read(binProvider), isNotEmpty);
    });
  }

  testWidgets('dock shows the four places chosen in settings', (tester) async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.read(appSettingsProvider.notifier).setUi('dock', [0, 9, 5, 7]);
    await _show(tester, c, Align(alignment: Alignment.bottomCenter, child: EditorialDock(activeIndex: 0, onSelect: (_) {}, onAdd: () {}, onMore: () {})));
    for (final word in ['Today', 'Habits', 'Money', 'Journal']) {
      expect(find.text(word), findsOneWidget);
    }
  });

  testWidgets('editorial home-screen widgets render for every type and size', (tester) async {
    for (final type in AestheticWidgetType.values) {
      for (final size in WidgetGridSize.values) {
        await tester.pumpWidget(MaterialApp(
          home: Center(child: EditorialHomeWidget(config: AestheticWidgetConfig(id: 'x', type: type, size: size, editorial: true))),
        ));
        expect(tester.takeException(), isNull, reason: '${type.name} ${size.name}');
      }
    }
  });
}
