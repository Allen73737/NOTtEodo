import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/bento_pod.dart';

class SanctuaryTimeline extends StatelessWidget {
  const SanctuaryTimeline({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;

    final List<Map<String, String>> logs = [
      {'time': '09:15 AM', 'title': 'Voice Reflection Recorded', 'desc': 'Goa Beach Villa Reservation Thoughts', 'icon': 'mic', 'color': '0xFFE8927C'},
      {'time': '11:30 AM', 'title': 'Note Saved in Academic Space', 'desc': 'Computer Networks Unit 1 Subnetting', 'icon': 'file', 'color': '0xFFEAB368'},
      {'time': '02:45 PM', 'title': 'Wax-Stamp Task Completed', 'desc': 'Finalize Computer Networks revision', 'icon': 'check', 'color': '0xFF86CBB0'},
      {'time': '06:00 PM', 'title': '18-Day Habit Streak Achieved', 'desc': 'Morning Reflection & Green Tea', 'icon': 'flame', 'color': '0xFF9EBFDB'},
    ];

    return BentoPod(
      style: PodTextureStyle.glass,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('SANCTUARY TIMELINE & LIFE LOG', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.secondary)),
              Text('TODAY', style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.bold, color: subtextColor)),
            ],
          ),
          const SizedBox(height: 14),

          Column(
            children: logs.map((log) {
              final color = Color(int.parse(log['color']!));
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
                          child: Icon(
                            log['icon'] == 'mic' ? LucideIcons.mic : (log['icon'] == 'file' ? LucideIcons.fileText : (log['icon'] == 'check' ? LucideIcons.check : LucideIcons.flame)),
                            size: 14,
                            color: color,
                          ),
                        ),
                        Container(width: 2, height: 24, color: AppColors.outlineVariant),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(log['title']!, style: GoogleFonts.bodoniModa(fontSize: 13, fontWeight: FontWeight.bold, color: primaryTextColor)),
                              Text(log['time']!, style: GoogleFonts.dmSans(fontSize: 10, color: subtextColor)),
                            ],
                          ),
                          Text(log['desc']!, style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
