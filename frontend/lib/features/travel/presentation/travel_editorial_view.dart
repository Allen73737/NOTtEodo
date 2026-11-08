import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/editorial/editorial_kit.dart';
import '../../../core/state/app_settings.dart';
import '../../../core/state/sanctuary_state.dart';
import '../../../core/utils/date_labels.dart';
import '../../../core/widgets/entry_editor.dart';

/// Trips as a short list of upcoming and past journeys; each opens to its plan,
/// packing list and spending.
class TravelEditorialView extends ConsumerWidget {
  const TravelEditorialView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips = ref.watch(travelProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current = trips.where((t) => t.covers(today)).toList();
    final upcoming = trips.where((t) => t.isUpcoming(now) && !t.covers(today)).toList();
    final undated = trips.where((t) => t.startDate == null).toList();
    final past = trips.where((t) => t.startDate != null && !t.isUpcoming(now) && !t.covers(today)).toList().reversed.toList();
    final n = ref.read(travelProvider.notifier);

    String meta(TravelTrip t) {
      final packed = t.packingChecked.where((c) => c).length;
      final until = t.startDate?.difference(today).inDays;
      return [
        t.date,
        if (until != null && until > 0) 'in $until ${until == 1 ? 'day' : 'days'}',
        if (t.packingList.isNotEmpty) '$packed of ${t.packingList.length} packed',
      ].join('  ·  ');
    }

    Widget entry(TravelTrip t) => EditorialEntry(
          key: ValueKey(t.id),
          id: t.id,
          title: t.destination.isNotEmpty && t.destination != t.title ? '${t.title} — ${t.destination}' : t.title,
          meta: meta(t),
          onTap: () => pushEditorial(context, TripPage(tripId: t.id)),
          onLongPress: () => showEditorialMenu(context, title: t.title, items: [
            EditorialMenuItem('Open', () => pushEditorial(context, TripPage(tripId: t.id))),
            EditorialMenuItem('Edit', () => openEntryEditor(context, EntryKind.trip, editing: t)),
            EditorialMenuItem('Delete', () => n.deleteTrip(t.id), destructive: true),
          ]),
          onSwipeLeft: EditorialSwipe(label: 'Delete', removes: true, onSwipe: () => n.deleteTrip(t.id)),
        );

    final next = current.isNotEmpty ? current.first : (upcoming.isNotEmpty ? upcoming.first : null);
    return EditorialPage(
      kicker: 'Travel',
      title: next == null ? 'Elsewhere' : (current.isNotEmpty ? 'Now in ${next.destination.isEmpty ? next.title : next.destination}' : next.title),
      standfirst: next == null
          ? 'Plan a trip: dates, a day-by-day plan, a packing list and a budget.'
          : (current.isNotEmpty ? 'Enjoy it.' : '${next.startDate!.difference(today).inDays} days to go.'),
      actionLabel: 'Plan',
      onAction: () => openEntryEditor(context, EntryKind.trip),
      slivers: [
        if (trips.isEmpty)
          SliverToBoxAdapter(
            child: EditorialEmpty(
              title: 'Nowhere planned yet.',
              message: 'Add a trip with its dates. Spending dated inside the trip is counted against its budget.',
              actionLabel: 'Plan a trip  →',
              onAction: () => openEntryEditor(context, EntryKind.trip),
            ),
          ),
        for (final (label, list) in [('Now', current), ('Coming up', upcoming), ('Someday', undated), ('Past', past)])
          if (list.isNotEmpty) ...[
            SliverToBoxAdapter(child: EditorialSectionLabel(label, count: list.length)),
            SliverList.builder(itemCount: list.length, itemBuilder: (_, i) => entry(list[i])),
          ],
      ],
    );
  }
}

class TripPage extends ConsumerWidget {
  final String tripId;

  const TripPage({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ed = Ed.of(context);
    final t = ref.watch(travelProvider).where((e) => e.id == tripId).firstOrNull;
    if (t == null) return const EditorialDetail(kicker: 'Travel', title: 'Trip deleted', children: []);
    final n = ref.read(travelProvider.notifier);
    final symbol = ref.watch(appSettingsProvider.select((s) => s.currencySymbol));
    final fmt = NumberFormat.decimalPatternDigits(decimalDigits: 0);
    String money(double v) => '$symbol${fmt.format(v)}';
    final spending = ref.watch(expensesProvider).expenses.where((e) => t.covers(e.spentAt)).toList();
    final spent = spending.fold(0.0, (s, e) => s + e.amount);

    Future<void> setBudget() async {
      final raw = await showEditorialPrompt(
        context,
        title: 'Trip budget',
        initial: t.budget > 0 ? t.budget.toStringAsFixed(0) : '',
        hint: '${symbol}0',
        keyboard: const TextInputType.numberWithOptions(decimal: true),
      );
      final v = double.tryParse((raw ?? '').replaceAll(',', ''));
      if (v != null) n.setBudget(t.id, v);
    }

    Future<void> pickDay(ItineraryEntry e) async {
      final start = t.startDate ?? DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: e.day ?? start,
        firstDate: DateTime(start.year - 1),
        lastDate: DateTime(start.year + 2),
      );
      if (picked == null) return;
      n.removeItineraryEntry(t.id, e.id);
      n.addItineraryEntry(t.id, e.text, day: picked);
    }

    final byDay = <String, List<ItineraryEntry>>{};
    for (final e in t.itinerary) {
      final label = e.day == null
          ? 'Any day'
          : (t.startDate != null ? 'Day ${e.day!.difference(DateTime(t.startDate!.year, t.startDate!.month, t.startDate!.day)).inDays + 1} · ' : '') +
              DateFormat('EEE d MMM').format(e.day!);
      byDay.putIfAbsent(label, () => []).add(e);
    }

    return EditorialDetail(
      kicker: [t.date, if (t.flight.isNotEmpty) t.flight].join('  ·  '),
      title: t.destination.isEmpty ? t.title : t.destination,
      standfirst: t.destination.isEmpty || t.destination == t.title ? null : t.title,
      actions: [('Edit', () => openEntryEditor(context, EntryKind.trip, editing: t))],
      children: [
        EditorialFigure(
          value: money(spent),
          caption: t.budget > 0 ? 'spent of ${money(t.budget)}' : (t.startDate == null ? 'spent (set dates to track)' : 'spent during the trip'),
        ),
        if (t.budget > 0) EditorialMeter(fraction: spent / t.budget, over: spent > t.budget),
        EditorialAction(label: t.budget > 0 ? 'Change budget' : 'Set a budget', muted: true, onTap: setBudget),
        const EditorialSectionLabel('Plan'),
        for (final day in byDay.entries) ...[
          Padding(padding: const EdgeInsets.only(top: 10), child: Text(day.key, style: ed.meta.copyWith(fontWeight: FontWeight.w600))),
          for (final e in day.value)
            EditorialEntry(
              key: ValueKey(e.id),
              id: e.id,
              title: e.text,
              onLongPress: () => showEditorialMenu(context, title: e.text, items: [
                EditorialMenuItem(e.day == null ? 'Set the day' : 'Change the day', () => pickDay(e)),
                EditorialMenuItem('Remove', () => n.removeItineraryEntry(t.id, e.id), destructive: true),
              ]),
              onSwipeLeft: EditorialSwipe(label: 'Remove', removes: true, onSwipe: () => n.removeItineraryEntry(t.id, e.id)),
            ),
        ],
        EditorialAddLine(hint: 'Add to the plan (hold it to set a day)', onAdd: (v) => n.addItineraryEntry(t.id, v)),
        EditorialSectionLabel('Packing', count: t.packingList.length),
        for (var i = 0; i < t.packingList.length; i++)
          EditorialEntry(
            key: ValueKey('pack-$i-${t.packingList[i]}'),
            id: 'pack-${t.id}-$i-${t.packingList[i]}',
            title: t.packingList[i],
            leading: t.packingChecked[i] ? '●' : '○',
            leadingColor: t.packingChecked[i] ? ed.faint : ed.muted,
            done: t.packingChecked[i],
            onLeadingTap: () => n.togglePackingItem(t.id, i),
            onTap: () {
              HapticFeedback.selectionClick();
              n.togglePackingItem(t.id, i);
            },
            onSwipeLeft: EditorialSwipe(label: 'Remove', removes: true, onSwipe: () => n.removePackingItem(t.id, i)),
          ),
        EditorialAddLine(hint: 'Add something to pack', onAdd: (v) => n.addPackingItem(t.id, v)),
        if (spending.isNotEmpty) ...[
          EditorialSectionLabel('Spent', count: spending.length),
          for (final e in spending)
            EditorialEntry(id: 'sp-${e.id}', title: e.title, meta: '${e.category}  ·  ${DateLabels.short(e.spentAt)}', trailing: money(e.amount)),
        ],
      ],
    );
  }
}
