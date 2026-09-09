import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/bento_pod.dart';
import '../../../core/widgets/ultra_micro_interactions.dart';
import 'habit_rewards_sheet.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  final List<Map<String, dynamic>> _habits = [
    {'title': 'Morning Reflection & Green Tea', 'streak': 18, 'completedToday': true},
    {'title': 'Deep Work: 90 Mins Study', 'streak': 12, 'completedToday': false},
    {'title': 'Night Journal Memoir', 'streak': 5, 'completedToday': false},
  ];

  void _toggleHabit(int idx) {
    setState(() {
      _habits[idx]['completedToday'] = !_habits[idx]['completedToday'];
      if (_habits[idx]['completedToday']) {
        _habits[idx]['streak'] += 1;
      }
    });

    if (_habits[idx]['completedToday']) {
      showDialog(
        context: context,
        builder: (ctx) => HabitRewardsSheet(
          habitTitle: _habits[idx]['title'],
          streakDays: _habits[idx]['streak'],
        ),
      );
    }
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
                    Text('SERENE CONSISTENCY TRACKER', style: AppTypography.labelSm),
                    const SizedBox(height: 4),
                    Text(
                      'Habits & Streaks',
                      style: GoogleFonts.bodoniModa(fontSize: 28, fontWeight: FontWeight.bold, color: primaryTextColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 365-Day Consistency Matrix Card
          BentoPod(
            style: PodTextureStyle.glass,
            showWaxSeal: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('365-DAY CONSISTENCY HEATMAP MATRIX', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.secondary)),
                const SizedBox(height: 12),

                // Annual 120-block Consistency Heatmap Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 120,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 20,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemBuilder: (context, idx) {
                    final isComplete = idx % 3 == 0 || idx % 7 == 0;
                    return Container(
                      decoration: BoxDecoration(
                        color: isComplete ? AppColors.secondary : AppColors.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Daily Habits List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _habits.length,
            itemBuilder: (context, idx) {
              final habit = _habits[idx];
              final isDone = habit['completedToday'] as bool;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: BentoPod(
                  style: PodTextureStyle.paper,
                  padding: const EdgeInsets.all(16),
                  onTap: () => _toggleHabit(idx),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          LiquidCheckmark(
                            isChecked: isDone,
                            size: 24,
                            onChanged: (_) => _toggleHabit(idx),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(habit['title'], style: GoogleFonts.bodoniModa(fontSize: 16, fontWeight: FontWeight.bold, color: primaryTextColor)),
                              Text('${habit['streak']} Days Streak', style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor)),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.flame, size: 14, color: AppColors.secondary),
                            const SizedBox(width: 4),
                            Text('${habit['streak']}d', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary)),
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
}
