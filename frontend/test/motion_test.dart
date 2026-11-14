import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notteodo/app/theme/app_dark_theme.dart';
import 'package:notteodo/app/theme/app_theme.dart';
import 'package:notteodo/core/motion/motion.dart';
import 'package:notteodo/core/state/app_settings.dart';
import 'package:notteodo/main.dart';
import 'package:notteodo/core/rewards/rewards_ledger.dart';

/// Animations need a stream of frames; one long pump is a single frame.
Future<void> _settle(WidgetTester tester, [int frames = 30]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

double _opacityOf(WidgetTester tester, Finder finder) {
  final opacity = tester.widget<Opacity>(find.ancestor(of: finder, matching: find.byType(Opacity)).first);
  return opacity.opacity;
}

void main() {
  testWidgets('Reveal cascades visible children in and leaves them fully opaque', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(children: [for (var i = 0; i < 4; i++) Text('item $i')].revealed()),
      ),
    ));
    await tester.pump();
    expect(_opacityOf(tester, find.text('item 3')), lessThan(1));

    await _settle(tester);
    for (var i = 0; i < 4; i++) {
      expect(_opacityOf(tester, find.text('item $i')), 1.0);
    }
  });

  testWidgets('Reveal below the fold waits until it is scrolled into view', (tester) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Column(children: [
            SizedBox(height: 1500),
            Reveal(child: Text('deep')),
          ]),
        ),
      ),
    ));
    await _settle(tester);
    expect(_opacityOf(tester, find.text('deep', skipOffstage: false)), 0.0);

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -1400));
    await _settle(tester);
    expect(_opacityOf(tester, find.text('deep')), 1.0);
  });

  testWidgets('MotionPresence plays an exit before unmounting its child', (tester) async {
    Widget host(bool visible) => MaterialApp(
          home: Scaffold(body: MotionPresence(visible: visible, child: const Text('overlay'))),
        );

    await tester.pumpWidget(host(true));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('overlay'), findsOneWidget);

    await tester.pumpWidget(host(false));
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.text('overlay'), findsOneWidget, reason: 'still visible mid-exit');

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('overlay'), findsNothing);
  });

  testWidgets('MotionColumn animates removed rows out and new rows in', (tester) async {
    Widget host(List<String> ids) => MaterialApp(
          home: Scaffold(
            body: MotionColumn(children: [for (final id in ids) Text(id, key: ValueKey(id))]),
          ),
        );

    await tester.pumpWidget(host(['a', 'b', 'c']));
    await _settle(tester, 5);

    await tester.pumpWidget(host(['a', 'c', 'd']));
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.text('b'), findsOneWidget, reason: 'removed row lingers while it exits');
    expect(find.text('d'), findsOneWidget, reason: 'new row is mounted immediately');

    await _settle(tester, 20);
    expect(find.text('b'), findsNothing);
    expect(tester.getTopLeft(find.text('c')).dy, lessThan(tester.getTopLeft(find.text('d')).dy));
  });

  testWidgets('rapid module switching under motion stays error-free', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final shellKey = GlobalKey();
    Widget app(int index) => ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppDarkTheme.darkTheme,
            home: MainShellScreen(
              key: shellKey,
              isDarkMode: false,
              onToggleDarkMode: (_) {},
              onLogout: () {},
            ),
          ),
        );
    await tester.pumpWidget(app(0));
    await tester.pump(const Duration(milliseconds: 300));

    // Drive the shell through the bottom dock, faster than transitions can finish.
    for (final label in ['Notes', 'Tasks', 'Planner', 'Wardrobe', 'Home', 'Tasks', 'Notes']) {
      final target = find.text(label);
      if (target.evaluate().isEmpty) continue;
      await tester.tap(target.last, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 90));
    }
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('theme toggle washes through and lands on the new theme (cards view)', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    // A returning user: the logo reveal hands straight off to the shell.
    await tester.pumpWidget(ProviderScope(
      overrides: [
        appSettingsProvider.overrideWith((ref) => AppSettingsNotifier()
          ..completeOnboarding()
          ..setCardStyle('bento')
          // Already welcomed and shown today's streak, so no ceremony covers the shell.
          ..setRewards({'v': 1, 'welcomed': true, 'streakSeen': RewardsLedger.dayKey(DateTime.now())})),
      ],
      child: const NOTtEodoApp(),
    ));
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final before = Theme.of(tester.element(find.byType(MainShellScreen))).brightness;

    final toggle = find.byTooltip(before == Brightness.dark ? 'Switch to Light Mode' : 'Switch to Dark Mode');
    expect(toggle, findsOneWidget);
    await tester.tap(toggle);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(CustomPaint), findsWidgets);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final after = Theme.of(tester.element(find.byType(MainShellScreen))).brightness;
    expect(after, isNot(before));
    expect(tester.takeException(), isNull);
  });

  for (final width in [1024.0, 1280.0, 1440.0, 1920.0]) {
    testWidgets('desktop header keeps search, theme and profile on screen at ${width.toInt()}px', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(ProviderScope(
        overrides: [appSettingsProvider.overrideWith((ref) => AppSettingsNotifier()..setCardStyle('bento'))],
        child: MaterialApp(
          home: MainShellScreen(isDarkMode: false, onToggleDarkMode: (_) {}, onLogout: () {}),
        ),
      ));
      await _settle(tester, 20);

      final screen = Offset.zero & Size(width, 900);
      for (final control in [find.byTooltip('Switch to Dark Mode'), find.text('Search...'), find.text('N')]) {
        expect(control, findsWidgets);
        final rect = tester.getRect(control.first);
        expect(screen.contains(rect.topLeft) && screen.contains(rect.bottomRight - const Offset(1, 1)), isTrue,
            reason: '$control at $rect is outside the ${width.toInt()}px viewport');
      }
    });
  }

  for (final width in [390.0, 1024.0, 1440.0]) {
    testWidgets('editorial top line keeps menu, search, view and theme on screen at ${width.toInt()}px', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);

      var dark = false;
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: MainShellScreen(isDarkMode: false, onToggleDarkMode: (v) => dark = v, onLogout: () {}),
        ),
      ));
      await _settle(tester, 20);

      final screen = Offset.zero & Size(width, 900);
      final controls = [find.text('Search'), find.text('Aa'), find.text('☾'), if (width < 1024) find.text('Menu') else find.text('Contents')];
      for (final control in controls) {
        expect(control, findsWidgets);
        final rect = tester.getRect(control.first);
        expect(screen.contains(rect.topLeft) && screen.contains(rect.bottomRight - const Offset(1, 1)), isTrue,
            reason: '$control at $rect is outside the ${width.toInt()}px viewport');
      }
      await tester.tap(find.text('☾'));
      expect(dark, isTrue);
    });
  }
}
