import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notteodo/core/brand/notteodo_app_icon.dart';
import 'package:notteodo/core/widgets/app_toast_engine.dart';
import 'package:notteodo/core/widgets/sanctuary_animated_notification.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NOTtEodo Master App Icon Verification', () {
    testWidgets('renders NotteodoAppIcon with default size and squircle styling', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: NotteodoAppIcon(size: 48, withGlow: true),
            ),
          ),
        ),
      );

      expect(find.byType(NotteodoAppIcon), findsOneWidget);
    });

    testWidgets('renders NotteodoAppIcon.small and NotteodoAppIcon.large presets', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                NotteodoAppIcon.small(withGlow: true),
                NotteodoAppIcon.medium(),
                NotteodoAppIcon.large(withGlow: true),
                NotteodoAppIcon.hero(),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(NotteodoAppIcon), findsNWidgets(4));
    });
  });

  group('Sanctuary Luxury Animated Notification HUD Tests', () {
    testWidgets('renders AppToastOverlay and displays animated notification card upon notify', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: AppToastOverlay(
            child: Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    AppToastEngine().notifyAnimated(
                      title: 'Sanctuary Verification',
                      message: 'Haute horlogerie precision timing verified.',
                      type: ToastType.success,
                      actionLabel: 'Undo',
                      onAction: () {},
                    );
                  },
                  child: const Text('Trigger Notification'),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(SanctuaryAnimatedNotificationCard), findsNothing);

      // Tap the button to trigger notification
      await tester.tap(find.text('Trigger Notification'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SanctuaryAnimatedNotificationCard), findsOneWidget);
      expect(find.text('Sanctuary Verification'), findsOneWidget);
      expect(find.text('Haute horlogerie precision timing verified.'), findsOneWidget);
      expect(find.text('UNDO'), findsOneWidget);

      // Let animation settle completely into view
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(SanctuaryAnimatedNotificationCard), findsOneWidget);

      // Tap UNDO action to trigger dismiss and callback
      await tester.tap(find.text('UNDO'));
      await tester.pumpAndSettle();
      expect(find.byType(SanctuaryAnimatedNotificationCard), findsNothing);
    });
  });
}
