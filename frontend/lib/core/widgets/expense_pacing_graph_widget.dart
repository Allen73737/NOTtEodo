import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../performance/sanctuary_motion_engine.dart';
import '../state/app_settings.dart';
import '../state/sanctuary_state.dart';
import '../utils/date_labels.dart';
import 'bento_pod.dart';

/// Interactive 7-Day Expense Pacing Bar Chart & Financial Health Widget
/// Compares daily spend vs daily budget pacing and provides Nodo financial advice.
class ExpensePacingGraphWidget extends ConsumerWidget {
  final VoidCallback? onAddExpense;

  const ExpensePacingGraphWidget({super.key, this.onAddExpense});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? const Color(0xFFFAF7F0) : const Color(0xFF1C1917);
    final subtextColor = isDark ? const Color(0xFFA8A29E) : const Color(0xFF78716C);
    const terracotta = Color(0xFFD9725B);
    const gold = Color(0xFFD4AF37);
    const sage = Color(0xFF8FA878);
    const amber = Color(0xFFC88552);

    final expensesState = ref.watch(expensesProvider);
    final expenses = expensesState.expenses;
    final settings = ref.watch(appSettingsProvider);

    // Monthly budget default or user-configured
    final monthlyBudget = (settings.monthlyBudget != null && settings.monthlyBudget! > 0)
        ? settings.monthlyBudget!
        : 25000.0;
    final dailyBudgetThreshold = monthlyBudget / 30.0;

    // Get last 7 days data
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final List<Map<String, dynamic>> daysData = [];

    double weeklyTotal = 0.0;
    double maxDayAmount = dailyBudgetThreshold * 1.5;

    for (int i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final dayKey = DateLabels.dayKey(day);
      final dayExpenses = expenses.where((e) => DateLabels.dayKey(e.spentAt) == dayKey);
      final total = dayExpenses.fold(0.0, (sum, e) => sum + e.amount);

      weeklyTotal += total;
      if (total > maxDayAmount) maxDayAmount = total;

      daysData.add({
        'day': day,
        'label': DateLabels.shortWeekday(day),
        'amount': total,
        'isToday': i == 0,
        'isOver': total > dailyBudgetThreshold,
      });
    }

    final weeklyBudget = dailyBudgetThreshold * 7;
    final isPacingGood = weeklyTotal <= weeklyBudget;
    final pacingPercent = weeklyBudget > 0 ? ((weeklyTotal / weeklyBudget) * 100).toInt() : 0;
    final remainingWeekly = (weeklyBudget - weeklyTotal).clamp(0.0, double.infinity);

    // Category breakdown
    final Map<String, double> categoryTotals = {};
    for (final e in expenses) {
      categoryTotals[e.category] = (categoryTotals[e.category] ?? 0) + e.amount;
    }
    final topCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return BentoPod(
      style: PodTextureStyle.glass,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: sage.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.wallet, size: 14, color: sage),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '7-DAY PACING & FINANCIAL HEALTH',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: sage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (onAddExpense != null) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    SanctuaryHapticEngine.selection();
                    onAddExpense!();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: terracotta.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: terracotta.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.plus, size: 11, color: terracotta),
                        const SizedBox(width: 3),
                        Text(
                          'LOG',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: terracotta,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),

          // Weekly Metrics & Nodo Advice Pill
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F1B18) : const Color(0xFFF2ECE2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isPacingGood ? sage.withValues(alpha: 0.35) : amber.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                Text(isPacingGood ? '🦉' : '⚡', style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPacingGood
                            ? 'Pacing Healthy · $pacingPercent% of Weekly Target'
                            : 'Pacing Alert · $pacingPercent% of Weekly Target',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isPacingGood ? sage : amber,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isPacingGood
                            ? 'You have \$${remainingWeekly.toStringAsFixed(0)} buffer left this week. Feel free to enjoy that coffee without guilt!'
                            : 'Spending is running hot this week. Slow discretionary expenses down for the next 48 hours.',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: subtextColor,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 7-Day Bar Chart
          SizedBox(
            height: 110,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: daysData.map((d) {
                final amount = d['amount'] as double;
                final isToday = d['isToday'] as bool;
                final isOver = d['isOver'] as bool;
                final barHeight = maxDayAmount > 0
                    ? ((amount / maxDayAmount) * 75).clamp(6.0, 75.0)
                    : 6.0;

                final barColor = isOver
                    ? amber
                    : (isToday ? terracotta : sage);

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (amount > 0)
                      Text(
                        '\$${amount.toStringAsFixed(0)}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: barColor,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Container(
                      width: 22,
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: barColor.withValues(alpha: isToday ? 0.9 : 0.65),
                        borderRadius: BorderRadius.circular(6),
                        border: isToday
                            ? Border.all(color: gold, width: 1.2)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      d['label'] as String,
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        color: isToday ? primaryText : subtextColor,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Top Spending Categories Chips
          if (topCategories.isNotEmpty) ...[
            Text(
              'TOP SPEND CATEGORIES',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: subtextColor,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: topCategories.take(4).map((c) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: sage.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    '${c.key}: \$${c.value.toStringAsFixed(0)}',
                    style: GoogleFonts.dmSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: primaryText,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
