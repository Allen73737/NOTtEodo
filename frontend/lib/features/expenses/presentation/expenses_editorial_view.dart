import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/editorial/editorial_kit.dart';
import '../../../core/services/data_portability_service.dart';
import '../../../core/state/app_settings.dart';
import '../../../core/state/sanctuary_state.dart';
import '../../../core/utils/date_labels.dart';
import '../../../core/widgets/app_toast_engine.dart';
import '../../../core/widgets/entry_editor.dart';

/// Spending as a monthly statement: the month's total against the budget, where it
/// went by category, then every expense by day. Step between months, import a bank
/// CSV, mark rent and subscriptions as monthly.
class ExpensesEditorialView extends ConsumerStatefulWidget {
  const ExpensesEditorialView({super.key});

  @override
  ConsumerState<ExpensesEditorialView> createState() => _ExpensesEditorialViewState();
}

class _ExpensesEditorialViewState extends ConsumerState<ExpensesEditorialView> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  String _query = '';
  String? _category;

  ExpensesNotifier get _expenses => ref.read(expensesProvider.notifier);

  Future<void> _importCsv() async {
    try {
      final files = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['csv', 'txt']);
      if (files.isEmpty) return;
      final text = utf8.decode(await files.first.xFile.readAsBytes(), allowMalformed: true);
      final rows = DataPortabilityService.expensesFromCsv(text);
      if (rows.isEmpty) {
        AppToastEngine().notify(
          title: 'Nothing imported',
          message: 'The file needs a header row with a description and an amount (or debit) column.',
          type: ToastType.alert,
        );
        return;
      }
      final added = _expenses.importExpenses(rows);
      AppToastEngine().notify(
        title: 'Imported $added ${added == 1 ? 'expense' : 'expenses'}',
        message: added < rows.length ? '${rows.length - added} were already here.' : 'From ${files.first.name}.',
        type: ToastType.success,
      );
    } catch (_) {
      AppToastEngine().notify(title: 'Could not read that file', message: 'Try exporting it again as CSV.', type: ToastType.alert);
    }
  }

  Future<void> _setBudget(String symbol) async {
    final current = ref.read(appSettingsProvider).monthlyBudget;
    final raw = await showEditorialPrompt(
      context,
      title: 'Monthly budget',
      hint: '${symbol}0 to remove',
      initial: current == null ? '' : current.toStringAsFixed(0),
      keyboard: const TextInputType.numberWithOptions(decimal: true),
    );
    if (raw == null) return;
    ref.read(appSettingsProvider.notifier).setMonthlyBudget(double.tryParse(raw.replaceAll(',', '')));
  }

  void _menu(ExpenseItem e, String Function(double) money) {
    showEditorialMenu(context, title: e.title, subtitle: '${money(e.amount)}  ·  ${e.category}  ·  ${DateLabels.long(e.spentAt)}', items: [
      EditorialMenuItem('Edit', () => openEntryEditor(context, EntryKind.expense, editing: e)),
      EditorialMenuItem(e.recurring ? 'Stop repeating monthly' : 'Repeat every month', () {
        _expenses.setRecurring(e.id, !e.recurring);
        if (!e.recurring) _expenses.rollRecurring();
      }),
      EditorialMenuItem('Show only ${e.category}', () => setState(() => _category = e.category)),
      EditorialMenuItem('Delete', () => _expenses.deleteExpense(e.id), destructive: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final ed = Ed.of(context);
    final settings = ref.watch(appSettingsProvider);
    final all = ref.watch(expensesProvider).expenses;
    final symbol = settings.currencySymbol;
    final fmt = NumberFormat.decimalPatternDigits(decimalDigits: 0);
    String money(double v) => '$symbol${fmt.format(v)}';

    final inMonth = all.where((e) => e.spentAt.year == _month.year && e.spentAt.month == _month.month).toList();
    final total = inMonth.fold(0.0, (s, e) => s + e.amount);
    final byCategory = <String, double>{};
    for (final e in inMonth) {
      byCategory[e.category] = (byCategory[e.category] ?? 0) + e.amount;
    }
    final categories = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final now = DateTime.now();
    final isCurrent = _month.year == now.year && _month.month == now.month;
    final budget = settings.monthlyBudget;
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final pace = isCurrent && now.day > 0 ? total / now.day * daysInMonth : total;

    final q = _query.toLowerCase();
    final shown = inMonth
        .where((e) =>
            (_category == null || e.category == _category) &&
            (q.isEmpty || e.title.toLowerCase().contains(q) || e.note.toLowerCase().contains(q) || e.category.toLowerCase().contains(q)))
        .toList();
    final byDay = <String, List<ExpenseItem>>{};
    for (final e in shown) {
      byDay.putIfAbsent(DateLabels.relative(e.spentAt, now: now), () => []).add(e);
    }

    String standfirst() {
      if (inMonth.isEmpty) return 'Nothing spent in ${DateFormat('MMMM').format(_month)}.';
      if (budget == null) return '${inMonth.length} expenses. Set a budget to see your pace.';
      final left = budget - total;
      if (left < 0) return '${money(-left)} over the ${money(budget)} budget.';
      if (isCurrent && pace > budget) return '${money(left)} left. At this pace you will spend ${money(pace)}.';
      return '${money(left)} left of ${money(budget)}.';
    }

    return EditorialPage(
      kicker: 'Money',
      title: DateFormat(_month.year == now.year ? 'MMMM' : 'MMMM y').format(_month),
      standfirst: standfirst(),
      actionLabel: 'Add',
      onAction: () => openEntryEditor(context, EntryKind.expense),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  EditorialAction(label: '←  ${DateFormat('MMM').format(DateTime(_month.year, _month.month - 1))}', muted: true, onTap: () {
                    setState(() => _month = DateTime(_month.year, _month.month - 1));
                  }),
                  const Spacer(),
                  if (!isCurrent)
                    EditorialAction(label: '${DateFormat('MMM').format(DateTime(_month.year, _month.month + 1))}  →', muted: true, onTap: () {
                      setState(() => _month = DateTime(_month.year, _month.month + 1));
                    }),
                ],
              ),
              const SizedBox(height: 8),
              EditorialFigure(value: money(total), caption: isCurrent ? 'spent so far this month' : 'spent'),
              if (budget != null && budget > 0) EditorialMeter(fraction: total / budget, over: total > budget),
              const SizedBox(height: 8),
              Wrap(
                spacing: 20,
                children: [
                  EditorialAction(label: budget == null ? 'Set a budget' : 'Budget ${money(budget)}', muted: true, onTap: () => _setBudget(symbol)),
                  EditorialAction(label: 'Import CSV', muted: true, onTap: _importCsv),
                ],
              ),
            ],
          ),
        ),
        if (categories.isNotEmpty) ...[
          const SliverToBoxAdapter(child: EditorialSectionLabel('Where it went')),
          SliverList.builder(
            itemCount: categories.length,
            itemBuilder: (context, i) {
              final c = categories[i];
              final share = total == 0 ? 0.0 : c.value / total;
              final selected = _category == c.key;
              return EditorialEntry(
                key: ValueKey('cat-${c.key}'),
                id: 'cat-${c.key}',
                title: c.key,
                meta: '${(share * 100).round()}%',
                trailing: money(c.value),
                leading: selected ? '●' : null,
                leadingColor: ed.accent,
                onTap: () => setState(() => _category = selected ? null : c.key),
                below: EditorialMeter(fraction: share),
              );
            },
          ),
        ],
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EditorialSectionLabel(
                _category == null ? 'Every expense' : _category!,
                count: shown.length,
                actionLabel: _category == null ? null : 'Show all',
                onAction: () => setState(() => _category = null),
              ),
              if (inMonth.isNotEmpty) EditorialSearch(hint: 'Search this month', onChanged: (v) => setState(() => _query = v)),
            ],
          ),
        ),
        if (all.isEmpty)
          SliverToBoxAdapter(
            child: EditorialEmpty(
              title: 'No spending yet.',
              message: 'Add an expense, or type "coffee 4 today" in quick capture. You can also import a CSV from your bank.',
              actionLabel: 'Add an expense  →',
              onAction: () => openEntryEditor(context, EntryKind.expense),
            ),
          ),
        for (final day in byDay.entries) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  Expanded(child: Text(day.key, style: ed.meta.copyWith(fontWeight: FontWeight.w600))),
                  Text(money(day.value.fold(0.0, (s, e) => s + e.amount)), style: ed.meta),
                ],
              ),
            ),
          ),
          SliverList.builder(
            itemCount: day.value.length,
            itemBuilder: (context, i) {
              final e = day.value[i];
              return EditorialEntry(
                key: ValueKey(e.id),
                id: e.id,
                title: e.title,
                meta: [e.category, if (e.recurring) 'monthly', if (e.note.isNotEmpty) e.note].join('  ·  '),
                trailing: money(e.amount),
                onTap: () => openEntryEditor(context, EntryKind.expense, editing: e),
                onLongPress: () => _menu(e, money),
                onSwipeLeft: EditorialSwipe(label: 'Delete', removes: true, onSwipe: () => _expenses.deleteExpense(e.id)),
              );
            },
          ),
        ],
      ],
    );
  }
}
