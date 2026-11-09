import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../performance/sanctuary_motion_engine.dart';
import '../state/app_settings.dart';
import '../state/sanctuary_state.dart';
import '../utils/date_labels.dart';
import 'bento_pod.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';

/// 14-Week GitHub / Apple Health style Habit & Productivity Activity Heatmap Grid
class HabitHeatmapWidget extends ConsumerWidget {
  const HabitHeatmapWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? const Color(0xFFFAF7F0) : const Color(0xFF1C1917);
    final subtextColor = isDark ? const Color(0xFFA8A29E) : const Color(0xFF78716C);
    const terracotta = Color(0xFFD9725B);
    const gold = Color(0xFFD9725B);

    final settings = ref.watch(appSettingsProvider);
    final habits = ref.watch(habitsProvider);
    final tasks = ref.watch(tasksProvider);

    // Snaps start to Monday of 14 weeks ago
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    const totalWeeks = 14;
    final currentWeekMonday = today.subtract(Duration(days: today.weekday - 1));
    final startMonday = currentWeekMonday.subtract(const Duration(days: (totalWeeks - 1) * 7));
    const totalDays = totalWeeks * 7;

    // Map dayKey to completion count
    final Map<String, int> dayCompletions = {};
    for (final habit in habits) {
      for (final dateStr in habit.completedDays) {
        dayCompletions[dateStr] = (dayCompletions[dateStr] ?? 0) + 1;
      }
    }
    for (final task in tasks) {
      if (task.completed) {
        final taskDate = task.completedAt ?? task.dueAt ?? task.createdAt;
        final key = DateLabels.dayKey(taskDate);
        dayCompletions[key] = (dayCompletions[key] ?? 0) + 1;
      }
    }

    // Active day count
    int activeDays = 0;
    for (int i = 0; i < totalDays; i++) {
      final d = startMonday.add(Duration(days: i));
      if (d.isAfter(today)) continue;
      final k = DateLabels.dayKey(d);
      if ((dayCompletions[k] ?? 0) > 0) activeDays++;
    }

    return BentoPod(
      style: PodTextureStyle.glass,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: edBox(
                      color: terracotta.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.flame, size: 14, color: terracotta),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'DISCIPLINE HEATMAP',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: terracotta,
                    ),
                  ),
                ],
              ),
              Text(
                '$activeDays DAYS ACTIVE',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Horizontal scrollable 14-week grid with Day Labels
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Weekday Row Labels
                Padding(
                  padding: const EdgeInsets.only(right: 6, top: 1),
                  child: Column(
                    children: [
                      _weekdayLabel('M', subtextColor),
                      _weekdayLabel('T', Colors.transparent),
                      _weekdayLabel('W', subtextColor),
                      _weekdayLabel('T', Colors.transparent),
                      _weekdayLabel('F', subtextColor),
                      _weekdayLabel('S', Colors.transparent),
                      _weekdayLabel('S', subtextColor),
                    ],
                  ),
                ),
                // 14 Calendar Week Columns (Mon-Sun)
                ...List.generate(totalWeeks, (col) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: Column(
                      children: List.generate(7, (row) {
                        final dayIndex = (col * 7) + row;
                        final day = startMonday.add(Duration(days: dayIndex));
                        final key = DateLabels.dayKey(day);
                        final count = dayCompletions[key] ?? 0;
                        final isToday = day.year == today.year && day.month == today.month && day.day == today.day;
                        final isFuture = day.isAfter(today);

                        Color cellColor;
                        Border? cellBorder;

                        if (isFuture) {
                          cellColor = Colors.transparent;
                          cellBorder = Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
                            width: 0.5,
                          );
                        } else if (count == 0) {
                          cellColor = isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.black.withValues(alpha: 0.04);
                          cellBorder = Border.all(
                            color: isToday
                                ? terracotta
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.08)),
                            width: isToday ? 1.4 : 0.6,
                          );
                        } else if (count <= 2) {
                          cellColor = terracotta.withValues(alpha: 0.45);
                          if (isToday) cellBorder = Border.all(color: gold, width: 1.4);
                        } else if (count <= 4) {
                          cellColor = terracotta.withValues(alpha: 0.85);
                          if (isToday) cellBorder = Border.all(color: gold, width: 1.4);
                        } else {
                          cellColor = gold;
                          if (isToday) cellBorder = Border.all(color: Colors.white, width: 1.4);
                        }

                        return Tooltip(
                          message: '${DateLabels.dateOnly(day)}${isToday ? " (Today)" : ""}: $count activities',
                          child: Container(
                            width: 13,
                            height: 13,
                            margin: const EdgeInsets.only(bottom: 4.5),
                            decoration: edBox(
                              color: cellColor,
                              borderRadius: BorderRadius.circular(3.5),
                              border: cellBorder,
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 12),
          // Legend Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Streak: ${settings.activeStreak} days',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: primaryText,
                ),
              ),
              Row(
                children: [
                  Text('Less', style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor)),
                  const SizedBox(width: 4),
                  _legendSquare(isDark ? Colors.white10 : Colors.black12),
                  _legendSquare(terracotta.withValues(alpha: 0.35)),
                  _legendSquare(terracotta.withValues(alpha: 0.75)),
                  _legendSquare(gold),
                  const SizedBox(width: 4),
                  Text('More', style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendSquare(Color color) {
    return Container(
      width: 9,
      height: 9,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: edBox(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _weekdayLabel(String label, Color color) {
    return Container(
      width: 12,
      height: 13,
      margin: const EdgeInsets.only(bottom: 4.5),
      alignment: Alignment.center,
      child: Text(
        label,
        style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}

/// Curator's Cabinet of Curiosities: Visual Collectible Milestones & Antique Crests
class CuratorsCabinetWidget extends ConsumerWidget {
  const CuratorsCabinetWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? const Color(0xFFFAF7F0) : const Color(0xFF1C1917);
    final subtextColor = isDark ? const Color(0xFFA8A29E) : const Color(0xFF78716C);
    const gold = Color(0xFFD9725B);
    const terracotta = Color(0xFFD9725B);

    final settings = ref.watch(appSettingsProvider);
    final streak = settings.activeStreak;
    final longest = settings.longestStreak;

    final badges = [
      {
        'title': 'Kindling Spark',
        'desc': '3-Day active streak maintained',
        'icon': '🥉',
        'unlocked': streak >= 3 || longest >= 3,
        'req': '3 Days Streak',
        'progress': ((streak / 3).clamp(0.0, 1.0)),
      },
      {
        'title': 'Brass Lantern',
        'desc': '7-Day unbroken sanctuary flame',
        'icon': '🏮',
        'unlocked': streak >= 7 || longest >= 7,
        'req': '7 Days Streak',
        'progress': ((streak / 7).clamp(0.0, 1.0)),
      },
      {
        'title': 'Sacred Hearth',
        'desc': '14-Day discipline masterwork',
        'icon': '🏛️',
        'unlocked': streak >= 14 || longest >= 14,
        'req': '14 Days Streak',
        'progress': ((streak / 14).clamp(0.0, 1.0)),
      },
      {
        'title': 'Supernova Corona',
        'desc': '30-Day unbroken habit mastery',
        'icon': '🌟',
        'unlocked': streak >= 30 || longest >= 30,
        'req': '30 Days Streak',
        'progress': ((streak / 30).clamp(0.0, 1.0)),
      },
      {
        'title': 'Golden Phoenix',
        'desc': '100-Day legendary persistence',
        'icon': '🦅',
        'unlocked': streak >= 100 || longest >= 100,
        'req': '100 Days Streak',
        'progress': ((streak / 100).clamp(0.0, 1.0)),
      },
      {
        'title': 'Watchmaker Apprentice',
        'desc': '10 Precision focus sessions completed',
        'icon': '⏱️',
        'unlocked': true, // default milestone unlocked for initial exploration
        'req': '10 Focus Sessions',
        'progress': 1.0,
      },
      {
        'title': 'Master Horologist',
        'desc': '50 Precision focus sessions completed',
        'icon': '⏳',
        'unlocked': streak >= 5,
        'req': '50 Focus Sessions',
        'progress': (streak / 5).clamp(0.0, 1.0),
      },
      {
        'title': 'Vault Guardian',
        'desc': '1st confidential secret encrypted',
        'icon': '🛡️',
        'unlocked': settings.vaultPin != null && settings.vaultPin!.isNotEmpty,
        'req': 'Configure Vault PIN',
        'progress': (settings.vaultPin != null && settings.vaultPin!.isNotEmpty) ? 1.0 : 0.0,
      },
    ];

    final unlockedCount = badges.where((b) => b['unlocked'] as bool).length;

    return BentoPod(
      style: PodTextureStyle.paper,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: edBox(
                      color: gold.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.trophy, size: 14, color: gold),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "CURATOR'S CABINET OF CURIOSITIES",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: gold,
                    ),
                  ),
                ],
              ),
              Text(
                '$unlockedCount / ${badges.length} UNLOCKED',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: terracotta,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Grid of Collectible Badges
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: badges.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.1,
            ),
            itemBuilder: (context, idx) {
              final b = badges[idx];
              final isUnlocked = b['unlocked'] as bool;
              final progress = b['progress'] as double;

              return InkWell(
                onTap: () {
                  SanctuaryHapticEngine.selection();
                  _showBadgeDialog(context, b, isDark);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: edBox(
                    color: isUnlocked
                        ? gold.withValues(alpha: isDark ? 0.08 : 0.05)
                        : (isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isUnlocked
                          ? gold.withValues(alpha: 0.45)
                          : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08)),
                      width: isUnlocked ? 1.2 : 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: edBox(
                          shape: BoxShape.circle,
                          color: isUnlocked
                              ? gold.withValues(alpha: 0.15)
                              : (isDark ? Colors.white10 : Colors.black12),
                          border: Border.all(
                            color: isUnlocked ? gold : Colors.transparent,
                            width: 1.0,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            isUnlocked ? (b['icon'] as String) : '🔒',
                            style: TextStyle(
                              fontSize: isUnlocked ? 18 : 14,
                              color: isUnlocked ? null : subtextColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              b['title'] as String,
                              style: GoogleFonts.bodoniModa(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: isUnlocked ? primaryText : subtextColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isUnlocked ? 'Unlocked' : (b['req'] as String),
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
                                color: isUnlocked ? gold : subtextColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (!isUnlocked) ...[
                              const SizedBox(height: 3),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 2.5,
                                  backgroundColor: isDark ? Colors.white12 : Colors.black12,
                                  valueColor: const AlwaysStoppedAnimation(terracotta),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showBadgeDialog(BuildContext context, Map<String, dynamic> badge, bool isDark) {
    const gold = Color(0xFFD9725B);
    final isUnlocked = badge['unlocked'] as bool;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161311),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isUnlocked ? gold : const Color(0xFF38332E), width: 1.2),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 70,
              height: 70,
              decoration: edBox(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    gold.withValues(alpha: isUnlocked ? 0.35 : 0.1),
                    Colors.transparent,
                  ],
                ),
                border: Border.all(color: isUnlocked ? gold : const Color(0xFF57534E), width: 2),
              ),
              child: Center(
                child: Text(
                  isUnlocked ? (badge['icon'] as String) : '🔒',
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              badge['title'] as String,
              style: GoogleFonts.bodoniModa(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              badge['desc'] as String,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(fontSize: 12.5, color: const Color(0xFFA8A29E), height: 1.4),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: edBox(
                color: isUnlocked ? gold.withValues(alpha: 0.15) : Colors.white10,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isUnlocked ? '✦ UNLOCKED & ACTIVE' : 'REQUIREMENT: ${badge['req']}',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: isUnlocked ? gold : const Color(0xFFA8A29E),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Close', style: GoogleFonts.dmSans(color: const Color(0xFFA8A29E))),
          ),
        ],
      ),
    );
  }
}
