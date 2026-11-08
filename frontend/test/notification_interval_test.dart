import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notteodo/core/services/daily_engagement_service.dart';
import 'package:notteodo/core/state/app_settings.dart';
import 'package:notteodo/features/settings/presentation/settings_subpages.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Notification Cadence & AppSettings Tests', () {
    test('Default notification cadence is 3 hours with correct label', () {
      const settings = AppSettings();
      expect(settings.notificationCadenceHours, 3);
      expect(settings.notificationCadenceLabel, 'Every 3 Hours (Balanced)');
    });

    test('notificationCadenceLabel formats all presets accurately', () {
      expect(const AppSettings(notificationCadenceHours: 1).notificationCadenceLabel, 'Every 1 Hour');
      expect(const AppSettings(notificationCadenceHours: 2).notificationCadenceLabel, 'Every 2 Hours');
      expect(const AppSettings(notificationCadenceHours: 3).notificationCadenceLabel, 'Every 3 Hours (Balanced)');
      expect(const AppSettings(notificationCadenceHours: 4).notificationCadenceLabel, 'Every 4 Hours');
      expect(const AppSettings(notificationCadenceHours: 6).notificationCadenceLabel, 'Every 6 Hours');
      expect(const AppSettings(notificationCadenceHours: 12).notificationCadenceLabel, 'Twice Daily (12 Hours)');
      expect(const AppSettings(notificationCadenceHours: 24).notificationCadenceLabel, 'Once Daily');
      expect(const AppSettings(notificationCadenceHours: 0).notificationCadenceLabel, 'Once Daily');
      expect(const AppSettings(notificationCadenceHours: 8).notificationCadenceLabel, 'Every 8 Hours');
    });

    test('copyWith updates notificationCadenceHours', () {
      const initial = AppSettings(notificationCadenceHours: 3);
      final updated = initial.copyWith(notificationCadenceHours: 2);
      expect(updated.notificationCadenceHours, 2);
      expect(updated.notificationCadenceLabel, 'Every 2 Hours');
    });

    test('toJson and fromJson serialize notificationCadenceHours seamlessly', () {
      const original = AppSettings(notificationCadenceHours: 4);
      final json = original.toJson();
      expect(json['notificationCadenceHours'], 4);

      final revived = AppSettings.fromJson(json);
      expect(revived.notificationCadenceHours, 4);
      expect(revived.notificationCadenceLabel, 'Every 4 Hours');
    });
  });

  group('DailyEngagementService Schedule Calculations', () {
    final refTime = DateTime(2026, 11, 8, 8, 0); // 8:00 AM

    test('3-hour cadence schedules exactly 5 slots between 09:30 and 21:30', () {
      final times = DailyEngagementService.calculateScheduleTimes(
        referenceTime: refTime,
        cadenceHours: 3,
        morningTimeStr: '09:30',
        eveningTimeStr: '21:30',
      );

      expect(times.length, 5);
      expect(times[0].hour, 9);
      expect(times[0].minute, 30);
      expect(times[1].hour, 12);
      expect(times[1].minute, 30);
      expect(times[2].hour, 15);
      expect(times[2].minute, 30);
      expect(times[3].hour, 18);
      expect(times[3].minute, 30);
      expect(times[4].hour, 21);
      expect(times[4].minute, 30);
    });

    test('2-hour cadence schedules 7 slots between 09:30 and 21:30', () {
      final times = DailyEngagementService.calculateScheduleTimes(
        referenceTime: refTime,
        cadenceHours: 2,
        morningTimeStr: '09:30',
        eveningTimeStr: '21:30',
      );

      expect(times.length, 7);
      expect(times.first.hour, 9);
      expect(times.first.minute, 30);
      expect(times.last.hour, 21);
      expect(times.last.minute, 30);
    });

    test('Once Daily (24h) schedules only morning briefing', () {
      final times = DailyEngagementService.calculateScheduleTimes(
        referenceTime: refTime,
        cadenceHours: 24,
        morningTimeStr: '09:30',
        eveningTimeStr: '21:30',
      );

      expect(times.length, 1);
      expect(times[0].hour, 9);
      expect(times[0].minute, 30);
    });

    test('Quiet hours properly filters out notifications within sleep window', () {
      // Quiet hours: 22:00 to 07:00
      final times = DailyEngagementService.calculateScheduleTimes(
        referenceTime: refTime,
        cadenceHours: 4,
        morningTimeStr: '06:00', // Falls inside quiet hours (before 07:00)
        eveningTimeStr: '22:30', // Falls inside quiet hours (after 22:00)
        quietHoursEnabled: true,
        quietHoursStart: '22:00',
        quietHoursEnd: '07:00',
      );

      // Morning at 6:00 AM and evening at 22:30 PM should be excluded
      for (final t in times) {
        expect(t.hour >= 7 && (t.hour < 22 || (t.hour == 22 && t.minute == 0)), isTrue);
      }
    });
  });

  group('NotificationsSettingsSubpage Widget Tests', () {
    testWidgets('Renders Cadence / Interval selector and options', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: NotificationsSettingsSubpage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notification Cadence / Interval'), findsOneWidget);
      expect(find.text('1h'), findsOneWidget);
      expect(find.text('2h'), findsOneWidget);
      expect(find.text('3h (Default)'), findsOneWidget);
      expect(find.text('4h'), findsOneWidget);
      expect(find.text('6h'), findsOneWidget);
      expect(find.text('Twice Daily'), findsOneWidget);
      expect(find.text('Once Daily'), findsOneWidget);
    });
  });
}

