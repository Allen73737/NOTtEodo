import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';
import 'package:notteodo/core/rewards/cards_ceremony.dart';
import 'package:notteodo/core/rewards/editorial_ceremony.dart';
import 'package:notteodo/core/rewards/reward_bus.dart';
import 'package:notteodo/core/rewards/reward_ceremony.dart';
import 'package:notteodo/core/rewards/rewards_ledger.dart';
import 'package:notteodo/core/rewards/rewards_widgets.dart';

final _moment = StreakMoment.of(
  streak: 7,
  longest: 7,
  firstDay: false,
  freezeUsed: false,
  freezesLeft: 1,
  firstDayOfWeek: 1,
  now: DateTime(2026, 11, 14),
);
const _goal = GoalMoment(count: 3, goal: 3, goalDays: 1, streak: 7);
final _badge = Badges.byId('streak_7')!;
const _outcome = RewardOutcome(action: RewardAction.note, count: 2, goal: 3, goalJustMet: false, goalDays: 0, badges: []);

Future<void> _playThrough(WidgetTester tester, Widget page, {required bool dark, Size size = const Size(390, 844)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    child: MaterialApp(
      theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
      home: Stack(children: [const Scaffold(), page]),
    ),
  ));
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(tester.takeException(), isNull);
}

void main() {
  tearDown(() => EditorialMode.active = false);

  for (final dark in [false, true]) {
    final mode = dark ? 'dark' : 'light';

    group('cards ceremonies ($mode)', () {
      testWidgets('streak', (t) => _playThrough(t, CardsStreakPage(moment: _moment), dark: dark));
      testWidgets('welcome on a small phone', (t) => _playThrough(
            t,
            CardsStreakPage(
              moment: StreakMoment.of(streak: 1, longest: 1, firstDay: true, freezeUsed: false, freezesLeft: 0, firstDayOfWeek: 1),
            ),
            dark: dark,
            size: const Size(320, 568),
          ));
      testWidgets('badge', (t) => _playThrough(t, CardsBadgePage(badge: _badge, reward: '+1 streak freeze earned'), dark: dark));
      testWidgets('goal', (t) => _playThrough(t, const CardsGoalPage(moment: _goal), dark: dark));
      testWidgets('goal on a small phone', (t) => _playThrough(t, const CardsGoalPage(moment: _goal), dark: dark, size: const Size(320, 568)));
      testWidgets('badge on a small phone', (t) => _playThrough(t, CardsBadgePage(badge: _badge, reward: '+1 streak freeze earned'), dark: dark, size: const Size(320, 568)));
      testWidgets('progress toast', (t) => _playThrough(t, Stack(children: [CardsProgressToast(outcome: _outcome, onDone: () {})]), dark: dark));
    });

    group('editorial ceremonies ($mode)', () {
      testWidgets('streak', (t) => _playThrough(t, EditorialStreakPage(moment: _moment), dark: dark));
      testWidgets('streak on a small phone', (t) => _playThrough(t, EditorialStreakPage(moment: _moment), dark: dark, size: const Size(320, 568)));
      testWidgets('badge', (t) => _playThrough(t, EditorialBadgePage(badge: _badge, reward: '+1 streak freeze earned'), dark: dark));
      testWidgets('goal', (t) => _playThrough(t, const EditorialGoalPage(moment: _goal), dark: dark));
      testWidgets('progress toast', (t) => _playThrough(t, Stack(children: [EditorialProgressToast(outcome: _outcome, onDone: () {})]), dark: dark));
    });
  }

  testWidgets('badge shelf renders in both views', (t) async {
    await _playThrough(t, const Material(child: BadgeShelf()), dark: false);
    EditorialMode.active = true;
    await _playThrough(t, const Material(child: SingleChildScrollView(child: BadgeShelf())), dark: false);
  });

  testWidgets('daily goal orb renders', (t) => _playThrough(t, const Material(child: Center(child: DailyGoalOrb())), dark: true));
}
