import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/editorial/editorial_kit.dart';
import '../../../core/state/app_settings.dart';
import '../../../core/state/sanctuary_state.dart';
import '../../../core/utils/date_labels.dart';
import '../../../core/widgets/entry_editor.dart';

/// The wardrobe as a catalogue. Swipe right on an outfit when you wear it; the log
/// shows what you reach for, what is gathering dust and what each piece costs per wear.
class WardrobeEditorialView extends ConsumerStatefulWidget {
  const WardrobeEditorialView({super.key});

  @override
  ConsumerState<WardrobeEditorialView> createState() => _WardrobeEditorialViewState();
}

class _WardrobeEditorialViewState extends ConsumerState<WardrobeEditorialView> {
  String _filter = 'All';
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final outfits = ref.watch(wardrobeProvider);
    final n = ref.read(wardrobeProvider.notifier);
    final symbol = ref.watch(appSettingsProvider.select((s) => s.currencySymbol));
    final fmt = NumberFormat.decimalPatternDigits(decimalDigits: 0);
    String money(double v) => '$symbol${fmt.format(v)}';
    final now = DateTime.now();
    final monthAgo = now.subtract(const Duration(days: 30));

    final tags = {for (final o in outfits) if (o.tag.trim().isNotEmpty) o.tag.trim()}.toList()..sort();
    final filters = ['All', 'Most worn', 'Not worn lately', ...tags];
    if (!filters.contains(_filter)) _filter = 'All';
    final q = _query.toLowerCase();
    var shown = outfits.where((o) {
      if (_filter == 'Not worn lately' && o.lastWorn != null && o.lastWorn!.isAfter(monthAgo)) return false;
      if (tags.contains(_filter) && o.tag.trim() != _filter) return false;
      return q.isEmpty || '${o.title} ${o.items} ${o.fabric} ${o.tag}'.toLowerCase().contains(q);
    }).toList();
    if (_filter == 'Most worn') shown.sort((a, b) => b.timesWorn.compareTo(a.timesWorn));
    final wornToday = outfits.where((o) => o.wornDays.contains(DateLabels.dayKey(now))).toList();

    Future<void> setCost(WardrobeOutfit o) async {
      final raw = await showEditorialPrompt(
        context,
        title: 'What did it cost?',
        hint: '${symbol}0',
        initial: o.cost > 0 ? o.cost.toStringAsFixed(0) : '',
        keyboard: const TextInputType.numberWithOptions(decimal: true),
      );
      final v = double.tryParse((raw ?? '').replaceAll(',', ''));
      if (v != null) n.setCost(o.id, v);
    }

    void wear(WardrobeOutfit o) {
      HapticFeedback.lightImpact();
      n.toggleWorn(o.id);
    }

    String meta(WardrobeOutfit o) => [
          if (o.items.isNotEmpty && o.items != 'Curated Ensemble') o.items,
          o.timesWorn == 0 ? 'Not worn yet' : 'Worn ${o.timesWorn}×, last ${DateLabels.relative(o.lastWorn!, now: now).toLowerCase()}',
          if (o.costPerWear != null) '${money(o.costPerWear!)} a wear',
        ].join('  ·  ');

    return EditorialPage(
      kicker: 'Wardrobe',
      title: wornToday.isEmpty ? 'What to wear' : 'Today: ${wornToday.first.title}',
      standfirst: outfits.isEmpty ? 'Outfits you love, and how often you wear them.' : '${outfits.length} outfits.',
      actionLabel: 'Add',
      onAction: () => openEntryEditor(context, EntryKind.outfit),
      slivers: [
        if (outfits.isNotEmpty)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EditorialSearch(hint: 'Search outfits', onChanged: (v) => setState(() => _query = v)),
                EditorialTabs(options: filters, selected: _filter, onSelected: (f) => setState(() => _filter = f)),
              ],
            ),
          ),
        if (outfits.isEmpty)
          SliverToBoxAdapter(
            child: EditorialEmpty(
              title: 'An empty rail.',
              message: 'Add an outfit with a photo. Swipe right on it whenever you wear it to see what earns its place.',
              actionLabel: 'Add an outfit  →',
              onAction: () => openEntryEditor(context, EntryKind.outfit),
            ),
          )
        else if (shown.isEmpty)
          const SliverToBoxAdapter(child: EditorialEmpty(title: 'Nothing here.', message: 'Every outfit has been worn this month.')),
        SliverList.builder(
          itemCount: shown.length,
          itemBuilder: (context, i) {
            final o = shown[i];
            final worn = o.wornDays.contains(DateLabels.dayKey(now));
            return EditorialEntry(
              key: ValueKey(o.id),
              id: o.id,
              title: o.title,
              meta: meta(o),
              leading: worn ? '●' : null,
              leadingColor: Ed.of(context).accent,
              onTap: () => pushEditorial(context, _OutfitPage(outfitId: o.id)),
              onLongPress: () => showEditorialMenu(context, title: o.title, subtitle: meta(o), items: [
                EditorialMenuItem(worn ? 'Not worn today' : 'Wearing it today', () => wear(o)),
                EditorialMenuItem(o.cost > 0 ? 'Change cost (${money(o.cost)})' : 'Add what it cost', () => setCost(o)),
                EditorialMenuItem('Edit', () => openEntryEditor(context, EntryKind.outfit, editing: o)),
                EditorialMenuItem('Delete', () => n.removeOutfit(o.id), destructive: true),
              ]),
              onSwipeRight: EditorialSwipe(label: worn ? 'Undo' : 'Wore it', onSwipe: () => wear(o)),
              onSwipeLeft: EditorialSwipe(label: 'Delete', removes: true, onSwipe: () => n.removeOutfit(o.id)),
            );
          },
        ),
      ],
    );
  }
}

class _OutfitPage extends ConsumerWidget {
  final String outfitId;

  const _OutfitPage({required this.outfitId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ed = Ed.of(context);
    final o = ref.watch(wardrobeProvider).where((e) => e.id == outfitId).firstOrNull;
    if (o == null) return const EditorialDetail(kicker: 'Wardrobe', title: 'Outfit deleted', children: []);
    final worn = o.wornDays.reversed.take(12).map(DateLabels.parseDayKey).whereType<DateTime>();
    return EditorialDetail(
      kicker: [o.tag, o.fabric, o.weather].where((s) => s.trim().isNotEmpty).join('  ·  '),
      title: o.title,
      actions: [
        ('Wore it', () => ref.read(wardrobeProvider.notifier).toggleWorn(o.id)),
        ('Edit', () => openEntryEditor(context, EntryKind.outfit, editing: o)),
      ],
      children: [
        if (o.imageUrl != null && o.imageUrl!.isNotEmpty)
          Padding(padding: const EdgeInsets.only(bottom: 20), child: EditorialImage(o.imageUrl!, semanticLabel: o.title)),
        if (o.items.isNotEmpty) Text(o.items, style: ed.body),
        const EditorialSectionLabel('Worn'),
        if (worn.isEmpty)
          Text('Not yet. Tap "Wore it" when you do.', style: ed.standfirst)
        else
          Text(worn.map(DateLabels.long).join('\n'), style: ed.body.copyWith(color: ed.muted)),
      ],
    );
  }
}
