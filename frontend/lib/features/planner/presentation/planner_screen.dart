import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/bento_pod.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  int _selectedHour = 10;
  bool _calendarSynced = false;

  final Map<int, String> _schedule = {
    8: 'Morning Reflection & Green Tea',
    10: 'Computer Networks — Unit 1 Study Session',
    14: 'Design Review: Editorial Glass Bento Grid',
    18: 'Studio Wardrobe Outfit Selection',
  };

  void _syncWithSystemCalendar() {
    setState(() {
      _calendarSynced = !_calendarSynced;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        content: Text(_calendarSynced ? '📅 Bi-directional sync enabled with Google Calendar / Apple iCal!' : 'Calendar sync disabled.'),
      ),
    );
  }

  void _showNewEventModal(BuildContext context, bool isDark) {
    final titleCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF000000) : AppColors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isDark ? const Color(0xFF1E1E1E) : AppColors.outlineVariant),
        ),
        title: Text(
          'Schedule Event at $_selectedHour:00',
          style: GoogleFonts.bodoniModa(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTextPrimary : AppColors.primary,
          ),
        ),
        content: TextField(
          controller: titleCtrl,
          style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.primary),
          decoration: InputDecoration(
            labelText: 'Event Title',
            labelStyle: TextStyle(color: isDark ? Colors.white70 : AppColors.onSurfaceVariant),
            filled: true,
            fillColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white70 : AppColors.primary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFFE8927C) : AppColors.primary,
              foregroundColor: isDark ? Colors.black : Colors.white,
            ),
            onPressed: () {
              if (titleCtrl.text.isNotEmpty) {
                setState(() {
                  _schedule[_selectedHour] = titleCtrl.text;
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save Event', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TIME-RIBBON & SCHEDULE DIAL', style: AppTypography.labelSm),
                    const SizedBox(height: 4),
                    Text(
                      'Planner & Dial',
                      style: GoogleFonts.bodoniModa(fontSize: 28, fontWeight: FontWeight.bold, color: primaryTextColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onPressed: () => _showNewEventModal(context, isDark),
                icon: const Icon(LucideIcons.plus, size: 16, color: Colors.white),
                label: Text('+ New Event', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // System Calendar Sync Bar
          BentoPod(
            style: PodTextureStyle.glass,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.calendarCheck, size: 20, color: AppColors.secondary),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('NATIVE SYSTEM CALENDAR SYNC', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: primaryTextColor)),
                        Text('Google Calendar & Apple iCal', style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor)),
                      ],
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _calendarSynced ? AppColors.secondary : primaryTextColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _syncWithSystemCalendar,
                  icon: Icon(_calendarSynced ? LucideIcons.check : LucideIcons.refreshCw, size: 12, color: _calendarSynced ? AppColors.secondary : primaryTextColor),
                  label: Text(_calendarSynced ? 'Synced' : 'Sync Calendar', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, color: _calendarSynced ? AppColors.secondary : primaryTextColor)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Hourglass Dial Nodes Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(14, (i) {
                final hour = i + 7; // 7 AM to 8 PM
                final isSelected = _selectedHour == hour;
                final hasEvent = _schedule.containsKey(hour);

                return GestureDetector(
                  onTap: () => setState(() => _selectedHour = hour),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.secondary : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isSelected ? AppColors.secondary : (isDark ? const Color(0xFF2E2E2E) : AppColors.outlineVariant)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$hour:00',
                          style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : primaryTextColor),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? Colors.white : (hasEvent ? AppColors.secondary : Colors.transparent),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 24),

          // Active Schedule Ribbon Node Card
          BentoPod(
            style: PodTextureStyle.paper,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('SCHEDULE NODE · $_selectedHour:00', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.secondary)),
                    Text('AUGUST 24, 2026', style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor)),
                  ],
                ),
                const SizedBox(height: 12),

                Text(
                  _schedule[_selectedHour] ?? 'No scheduled event for $_selectedHour:00. Tap + New Event to schedule.',
                  style: GoogleFonts.bodoniModa(fontSize: 22, fontWeight: FontWeight.bold, color: primaryTextColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
