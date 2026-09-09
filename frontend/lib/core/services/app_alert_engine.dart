import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../app/theme/app_colors.dart';

class ScheduledAlert {
  final String id;
  final String title;
  final String module;
  final DateTime scheduledTime;
  bool triggered;

  ScheduledAlert({
    required this.id,
    required this.title,
    required this.module,
    required this.scheduledTime,
    this.triggered = false,
  });
}

class AppAlertEngine {
  static final AppAlertEngine _instance = AppAlertEngine._internal();
  factory AppAlertEngine() => _instance;
  AppAlertEngine._internal();

  final List<ScheduledAlert> _alerts = [
    ScheduledAlert(
      id: '1',
      title: 'Submit Unit 1 Computer Networks Assignment',
      module: 'Tasks',
      scheduledTime: DateTime.now().add(const Duration(seconds: 5)),
    ),
    ScheduledAlert(
      id: '2',
      title: 'Studio Edit Linen Wardrobe Curation',
      module: 'Planner',
      scheduledTime: DateTime.now().add(const Duration(minutes: 30)),
    ),
  ];

  void scheduleAlert(String title, String module, DateTime time) {
    _alerts.add(ScheduledAlert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      module: module,
      scheduledTime: time,
    ));
  }

  void checkForTriggeredAlerts(BuildContext context) {
    final now = DateTime.now();
    for (final alert in _alerts) {
      if (!alert.triggered && now.isAfter(alert.scheduledTime)) {
        alert.triggered = true;
        _showInAppAlertBanner(context, alert);
      }
    }
  }

  void _showInAppAlertBanner(BuildContext context, ScheduledAlert alert) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF16282C),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
              child: const Icon(LucideIcons.bellRing, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'REMINDER ALARM · ${alert.module.toUpperCase()}',
                    style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondary, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    alert.title,
                    style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
