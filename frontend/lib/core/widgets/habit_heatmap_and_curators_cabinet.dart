import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../performance/sanctuary_motion_engine.dart';
import '../state/app_settings.dart';
import '../state/sanctuary_state.dart';
import '../utils/date_labels.dart';
import '../motion/motion.dart';
import 'bento_pod.dart';
import 'card_kit.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';

/// Fourteen weeks of finished habits and tasks as a grid of days. The weeks sweep in
/// from the left when the card arrives; today carries an oxblood ring.
class HabitHeatmapWidget extends ConsumerWidget {
  const HabitHeatmapWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = CardInk.of(context);
    final settings = ref.watch(appSettingsProvider);
    final habits = ref.watch(habitsProvider);
    final tasks = ref.watch(tasksProvider);

    // Monday of the week 13 weeks ago, so the grid ends with the current week.
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    const totalWeeks = 14;
    final startMonday = today.subtract(Duration(days: today.weekday - 1 + (totalWeeks - 1) * 7));

    final Map<String, int> dayCompletions = {};
    for (final habit in habits) {
      for (final dateStr in habit.completedDays) {
        dayCompletions[dateStr] = (dayCompletions[dateStr] ?? 0) + 1;
      }
    }
    for (final task in tasks) {
      if (task.completed) {
        final key = DateLabels.dayKey(task.completedAt ?? task.dueAt ?? task.createdAt);
        dayCompletions[key] = (dayCompletions[key] ?? 0) + 1;
      }
    }

    var activeDays = 0;
    for (var i = 0; i < totalWeeks * 7; i++) {
      final d = startMonday.add(Duration(days: i));
      if (!d.isAfter(today) && (dayCompletions[DateLabels.dayKey(d)] ?? 0) > 0) activeDays++;
    }

    // Four steps from the empty track to full oxblood (blush on black).
    final full = c.dark ? c.mark : c.fill;
    Color shade(int count) => switch (count) {
          0 => c.track,
          <= 2 => Color.lerp(c.track, full, 0.4)!,
          <= 4 => Color.lerp(c.track, full, 0.7)!,
          _ => full,
        };

    return BentoPod(
      style: PodTextureStyle.glass,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardLabel('Activity', trailing: 'Last 14 weeks'),
          CardFigure('$activeDays', unit: activeDays == 1 ? 'active day' : 'active days'),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Reveal.builder(
              delay: const Duration(milliseconds: 150),
              duration: const Duration(milliseconds: 1400),
              builder: (context, t) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Column(
                      children: [
                        for (final (i, d) in const ['M', '', 'W', '', 'F', '', 'S'].indexed)
                          SizedBox(
                            key: ValueKey('wd$i'),
                            height: 17,
                            child: Text(d, style: c.meta.copyWith(fontSize: 11)),
                          ),
                      ],
                    ),
                  ),
                  for (var col = 0; col < totalWeeks; col++)
                    Builder(builder: (context) {
                      // Each week fades and rises a beat after the one before it.
                      final p = Motion.silk.transform(((t * 1.6) - col * (0.6 / totalWeeks)).clamp(0.0, 1.0));
                      return Opacity(
                        opacity: p,
                        child: Transform.translate(
                          offset: Offset(0, (1 - p) * 8),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Column(
                              children: [
                                for (var row = 0; row < 7; row++)
                                  Builder(builder: (context) {
                                    final day = startMonday.add(Duration(days: col * 7 + row));
                                    final count = dayCompletions[DateLabels.dayKey(day)] ?? 0;
                                    final isToday = day == today;
                                    final future = day.isAfter(today);
                                    return Tooltip(
                                      message: '${DateLabels.dateOnly(day)}${isToday ? ' (today)' : ''}: $count done',
                                      child: Container(
                                        width: 13,
                                        height: 13,
                                        margin: const EdgeInsets.only(bottom: 4),
                                        decoration: BoxDecoration(
                                          color: future ? Colors.transparent : shade(count),
                                          borderRadius: BorderRadius.circular(3.5),
                                          border: isToday ? Border.all(color: c.mark, width: 1.5) : null,
                                        ),
                                      ),
                                    );
                                  }),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  settings.activeStreak == 1 ? '1-day streak' : '${settings.activeStreak}-day streak',
                  style: c.meta,
                ),
              ),
              Text('Less', style: c.meta.copyWith(fontSize: 12)),
              const SizedBox(width: 6),
              for (final n in const [0, 2, 4, 5])
                Container(
                  width: 9,
                  height: 9,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(color: shade(n), borderRadius: BorderRadius.circular(2)),
                ),
              const SizedBox(width: 6),
              Text('More', style: c.meta.copyWith(fontSize: 12)),
            ],
          ),
        ],
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
    const gold = Color(0xFF8E2433);
    const terracotta = Color(0xFF8E2433);

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
          CardLabel('Milestones', trailing: '$unlockedCount of ${badges.length} unlocked'),
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
    const gold = Color(0xFF8E2433);
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
                style: GoogleFonts.dmSans(
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
