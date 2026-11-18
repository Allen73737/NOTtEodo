import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/motion.dart';
import '../../../core/state/app_settings.dart';
import '../../../core/state/sanctuary_state.dart';
import '../../../core/utils/date_labels.dart';
import '../../../core/widgets/bento_pod.dart';
import '../../../core/widgets/card_kit.dart';

/// The last few things that happened — tasks finished, notes saved, habits kept,
/// money spent — down a thin rail, newest first. Rows slide in one after another.
class SanctuaryTimeline extends ConsumerWidget {
  const SanctuaryTimeline({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = CardInk.of(context);
    final symbol = ref.watch(appSettingsProvider.select((s) => s.currencySymbol));
    final tasks = ref.watch(tasksProvider);
    final notes = ref.watch(notesProvider);
    final habits = ref.watch(habitsProvider);
    final expenses = ref.watch(expensesProvider).expenses;

    final logs = <({String time, String kind, String title, bool done})>[
      for (final t in tasks.take(4))
        (time: DateLabels.relative(t.completedAt ?? t.createdAt), kind: t.isCompleted ? 'Task done' : 'Task added', title: t.title, done: t.isCompleted),
      for (final n in notes.take(3)) (time: DateLabels.relative(n.updatedAt), kind: 'Note · ${n.space}', title: n.title, done: false),
      for (final h in habits.where((h) => h.completedDays.isNotEmpty).take(2))
        (time: '${h.streak}-day streak', kind: 'Habit kept', title: h.title, done: true),
      for (final e in expenses.take(2))
        (time: DateLabels.relative(e.spentAt), kind: 'Spent · ${e.category}', title: '${e.title}  ${formatMoney(e.amount, symbol)}', done: false),
    ].take(5).toList();

    return BentoPod(
      style: PodTextureStyle.glass,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardLabel('Recent activity'),
          const SizedBox(height: 12),
          if (logs.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nothing yet', style: c.title),
                  const SizedBox(height: 4),
                  Text('Finished tasks, saved notes and kept habits will show here.', style: c.meta),
                ],
              ),
            )
          else
            Column(
              children: [
                for (var i = 0; i < logs.length; i++)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 14,
                          child: Column(
                            children: [
                              const SizedBox(height: 5),
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: i == 0 ? c.mark : (logs[i].done ? c.ink.withValues(alpha: 0.55) : c.hairline),
                                  border: i == 0 ? null : Border.all(color: c.muted.withValues(alpha: 0.45)),
                                ),
                              ),
                              if (i < logs.length - 1) Expanded(child: Container(width: 1, color: c.hairline)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text(logs[i].kind, style: c.meta.copyWith(fontSize: 12.5), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                    const SizedBox(width: 8),
                                    Text(logs[i].time, style: c.meta.copyWith(fontSize: 12.5)),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(logs[i].title, style: c.body.copyWith(fontSize: 14.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ].revealed(style: RevealStyle.slideIn, distance: 12),
            ),
        ],
      ),
    );
  }
}
