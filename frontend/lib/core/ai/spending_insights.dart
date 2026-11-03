import 'package:flutter/foundation.dart';

import '../state/app_settings.dart' show formatMoney;
import '../state/sanctuary_state.dart';

enum InsightTone { good, info, warning }

@immutable
class Insight {
  final InsightTone tone;
  final String title;
  final String detail;
  const Insight(this.tone, this.title, this.detail);
}

/// Finds patterns in the user's expenses: month-end forecast, category spikes,
/// subscriptions, unusual purchases and weekday habits. Pure Dart; runs on device.
class SpendingInsights {
  SpendingInsights._();

  static int _daysIn(DateTime m) => DateTime(m.year, m.month + 1, 0).day;
  static String _monthKey(DateTime d) => '${d.year}-${d.month}';

  static List<Insight> analyze(
    List<ExpenseItem> expenses, {
    required DateTime now,
    double? monthlyBudget,
    String currency = '₹',
  }) {
    String money(double v) => formatMoney(v, currency);
    final out = <Insight>[];
    if (expenses.isEmpty) return out;

    final thisMonth = expenses.where((e) => e.spentAt.year == now.year && e.spentAt.month == now.month).toList();
    final mtd = thisMonth.fold<double>(0, (s, e) => s + e.amount);
    final day = now.day, days = _daysIn(now);

    // 1. Forecast for the month (needs a few days of data to mean anything).
    if (day >= 3 && mtd > 0) {
      final projected = mtd / day * days;
      if (monthlyBudget != null && monthlyBudget > 0) {
        final over = projected - monthlyBudget;
        if (over > monthlyBudget * 0.03) {
          final perDay = (monthlyBudget - mtd) / (days - day + 1);
          out.add(Insight(
            InsightTone.warning,
            'On pace to overspend by ${money(over)}',
            perDay > 0
                ? 'At this rate the month ends near ${money(projected)}. Keeping to about ${money(perDay)} a day stays within budget.'
                : 'At this rate the month ends near ${money(projected)}; the budget is already used up.',
          ));
        } else {
          out.add(Insight(InsightTone.good, 'On track for your budget',
              'Projected month total ${money(projected)} of ${money(monthlyBudget)}.'));
        }
      } else {
        out.add(Insight(InsightTone.info, 'Heading for about ${money(projected)} this month',
            'Based on ${money(mtd)} spent in the first $day days.'));
      }
    }

    // 2. Categories running hot compared with the previous three months.
    final prevMonths = [for (var i = 1; i <= 3; i++) DateTime(now.year, now.month - i)];
    final prevKeys = prevMonths.map(_monthKey).toSet();
    final monthsWithData = expenses.where((e) => prevKeys.contains(_monthKey(e.spentAt))).map((e) => _monthKey(e.spentAt)).toSet();
    if (monthsWithData.isNotEmpty && day >= 5) {
      final avgByCat = <String, double>{};
      for (final e in expenses.where((e) => prevKeys.contains(_monthKey(e.spentAt)))) {
        avgByCat[e.category] = (avgByCat[e.category] ?? 0) + e.amount / monthsWithData.length;
      }
      final nowByCat = <String, double>{};
      for (final e in thisMonth) {
        nowByCat[e.category] = (nowByCat[e.category] ?? 0) + e.amount;
      }
      final spikes = <(String, double, double)>[];
      nowByCat.forEach((cat, spent) {
        final projected = spent / day * days;
        final avg = avgByCat[cat] ?? 0;
        if (avg > 0 && projected >= avg * 1.4 && projected - avg >= 0.05 * (mtd / day * days)) {
          spikes.add((cat, projected, avg));
        }
      });
      spikes.sort((a, b) => (b.$2 - b.$3).compareTo(a.$2 - a.$3));
      for (final s in spikes.take(2)) {
        final pct = ((s.$2 / s.$3 - 1) * 100).round();
        out.add(Insight(InsightTone.warning, '${s.$1} is running $pct% above usual',
            'Heading for ${money(s.$2)} against a ${money(s.$3)} monthly average.'));
      }

      // Good news is worth saying too.
      final lastMonthKey = _monthKey(prevMonths.first);
      final lastMonthTotal =
          expenses.where((e) => _monthKey(e.spentAt) == lastMonthKey).fold<double>(0, (s, e) => s + e.amount);
      final projectedTotal = mtd / day * days;
      if (lastMonthTotal > 0 && projectedTotal < lastMonthTotal * 0.85) {
        out.add(Insight(InsightTone.good, 'Spending is down ${((1 - projectedTotal / lastMonthTotal) * 100).round()}%',
            'Compared with ${money(lastMonthTotal)} last month.'));
      }
    }

    // 3. Subscriptions: the same title in 3+ different months with a steady amount.
    final byTitle = <String, List<ExpenseItem>>{};
    for (final e in expenses) {
      final key = e.title.toLowerCase().replaceAll(RegExp(r'[^a-z ]'), '').trim();
      if (key.length >= 3) byTitle.putIfAbsent(key, () => []).add(e);
    }
    final subs = <(String, double)>[];
    byTitle.forEach((_, items) {
      final months = items.map((e) => _monthKey(e.spentAt)).toSet();
      if (months.length < 3) return;
      final amounts = items.map((e) => e.amount).toList()..sort();
      final median = amounts[amounts.length ~/ 2];
      final steady = items.where((e) => (e.amount - median).abs() <= median * 0.15).length >= items.length * 0.7;
      if (steady) subs.add((items.first.title, median));
    });
    if (subs.isNotEmpty) {
      subs.sort((a, b) => b.$2.compareTo(a.$2));
      final total = subs.fold<double>(0, (s, x) => s + x.$2);
      out.add(Insight(
        InsightTone.info,
        '${subs.length} recurring payment${subs.length == 1 ? '' : 's'} · ${money(total)}/month',
        subs.take(4).map((s) => '${s.$1} (${money(s.$2)})').join(', '),
      ));
    }

    // 4. An unusually large purchase this month.
    if (expenses.length >= 10 && thisMonth.isNotEmpty) {
      final all = expenses.map((e) => e.amount).toList()..sort();
      final median = all[all.length ~/ 2];
      final biggest = thisMonth.reduce((a, b) => a.amount >= b.amount ? a : b);
      if (median > 0 && biggest.amount >= median * 6) {
        out.add(Insight(InsightTone.info, 'Big one: ${biggest.title}',
            '${money(biggest.amount)} is about ${(biggest.amount / median).round()}× your typical expense.'));
      }
    }

    // 5. The most expensive weekday.
    if (expenses.length >= 20) {
      final sums = List<double>.filled(7, 0);
      final counts = List<int>.filled(7, 0);
      final dates = <int, Set<String>>{};
      for (final e in expenses) {
        final w = e.spentAt.weekday - 1;
        sums[w] += e.amount;
        counts[w]++;
        dates.putIfAbsent(w, () => {}).add('${e.spentAt.year}-${e.spentAt.month}-${e.spentAt.day}');
      }
      final perDay = [for (var w = 0; w < 7; w++) (dates[w]?.isEmpty ?? true) ? 0.0 : sums[w] / dates[w]!.length];
      final avg = perDay.reduce((a, b) => a + b) / 7;
      final top = perDay.indexOf(perDay.reduce((a, b) => a > b ? a : b));
      if (avg > 0 && perDay[top] >= avg * 1.5) {
        const names = ['Mondays', 'Tuesdays', 'Wednesdays', 'Thursdays', 'Fridays', 'Saturdays', 'Sundays'];
        out.add(Insight(InsightTone.info, 'You spend most on ${names[top]}',
            'About ${money(perDay[top])} on a typical ${names[top].substring(0, names[top].length - 1)}, versus ${money(avg)} on average.'));
      }
    }
    return out;
  }
}
