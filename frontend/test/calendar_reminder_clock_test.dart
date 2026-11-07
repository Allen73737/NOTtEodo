import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notteodo/app/theme/app_colors.dart';
import 'package:notteodo/app/theme/app_dark_theme.dart';
import 'package:notteodo/app/theme/app_theme.dart';
import 'package:notteodo/core/services/calendar_reminder_service.dart';
import 'package:notteodo/core/widgets/sanctuary_clock_picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CalendarReminderService Tests', () {
    test('buildGoogleCalendarUrl builds modern /r/eventedit URL with prefilled parameters', () {
      final start = DateTime.utc(2026, 11, 8, 10, 30);
      final end = DateTime.utc(2026, 11, 8, 11, 30);
      final uri = CalendarReminderService.buildGoogleCalendarUrl(
        title: 'Review Quarterly Strategy',
        startTime: start,
        endTime: end,
        description: 'Prepare obsidian notes and metrics audit',
        location: 'Kyoto Sanctuary',
      );

      expect(uri.host, equals('calendar.google.com'));
      expect(uri.path, equals('/calendar/u/0/r/eventedit'));
      expect(uri.queryParameters['text'], equals('Review Quarterly Strategy'));
      expect(uri.queryParameters['dates'], equals('20261108T103000Z/20261108T113000Z'));
      expect(uri.queryParameters['details'], equals('Prepare obsidian notes and metrics audit'));
      expect(uri.queryParameters['location'], equals('Kyoto Sanctuary'));
    });

    test('buildGoogleCalendarUrl defaults to 1 hour duration when endTime is omitted', () {
      final start = DateTime.utc(2026, 11, 8, 14, 0);
      final uri = CalendarReminderService.buildGoogleCalendarUrl(
        title: 'Focus Sprint',
        startTime: start,
      );

      expect(uri.queryParameters['dates'], equals('20261108T140000Z/20261108T150000Z'));
      expect(uri.queryParameters.containsKey('details'), isFalse);
      expect(uri.queryParameters.containsKey('location'), isFalse);
    });

    test('addToGoogleCalendar completes gracefully in test/mock environment', () async {
      final service = CalendarReminderService();
      final res = await service.addToGoogleCalendar(
        title: 'Design Review',
        startTime: DateTime.now().add(const Duration(hours: 2)),
      );
      expect(res, isTrue);
    });
  });

  group('Horological Clock Components Widget Tests', () {
    testWidgets('HorologicalMiniClockDial renders cleanly with hands positioned', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: HorologicalMiniClockDial(
                time: TimeOfDay(hour: 9, minute: 30),
                size: 44.0,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(HorologicalMiniClockDial), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('HorologicalClockBadge formats 9:30 AM and 18:45 PM properly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                HorologicalClockBadge(
                  time: TimeOfDay(hour: 9, minute: 30),
                  label: 'Morning Focus',
                ),
                HorologicalClockBadge(
                  time: TimeOfDay(hour: 18, minute: 45),
                  label: 'Evening Reflection',
                ),
                HorologicalClockBadge(
                  time: TimeOfDay(hour: 0, minute: 0),
                  label: 'Midnight Audit',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('MORNING FOCUS'), findsOneWidget);
      expect(find.text('9:30 AM'), findsOneWidget);

      expect(find.text('EVENING REFLECTION'), findsOneWidget);
      expect(find.text('6:45 PM'), findsOneWidget);

      expect(find.text('MIDNIGHT AUDIT'), findsOneWidget);
      expect(find.text('12:00 AM'), findsOneWidget);
    });

    test('AppTheme and AppDarkTheme timePickerTheme tokens adhere to sovereign terracotta palette', () {
      final lightTheme = AppTheme.lightTheme;
      final darkTheme = AppDarkTheme.darkTheme;

      expect(lightTheme.timePickerTheme.dialHandColor, equals(AppColors.secondary));
      expect(lightTheme.timePickerTheme.dialBackgroundColor, equals(const Color(0xFFF2ECE6)));

      expect(darkTheme.timePickerTheme.dialHandColor, equals(AppDarkColors.secondary));
      expect(darkTheme.timePickerTheme.dialBackgroundColor, equals(const Color(0xFF191614)));
      expect(darkTheme.timePickerTheme.backgroundColor, equals(const Color(0xFF0D0B0A)));
    });
  });
}

