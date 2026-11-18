import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/state/sanctuary_state.dart';
import '../../../core/widgets/bento_pod.dart';
import '../../../core/widgets/card_kit.dart';
import '../../../core/motion/motion.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/entry_editor.dart';

class TravelScreen extends ConsumerStatefulWidget {
  final Function(String) onOpenAiModal;

  const TravelScreen({super.key, required this.onOpenAiModal});

  @override
  ConsumerState<TravelScreen> createState() => _TravelScreenState();
}

class _TravelScreenState extends ConsumerState<TravelScreen> {
  int _activeTab = 0; // 0: Passes, 1: Packing, 2: Budget

  String? _selectedTripId;
  final TextEditingController _packingCtrl = TextEditingController();

  @override
  void dispose() {
    _packingCtrl.dispose();
    super.dispose();
  }

  /// The chosen trip, else the next upcoming one, else the first.
  TravelTrip? _selectedTrip(List<TravelTrip> trips) {
    if (trips.isEmpty) return null;
    for (final t in trips) {
      if (t.id == _selectedTripId) return t;
    }
    final now = DateTime.now();
    return trips.firstWhere((t) => t.isUpcoming(now), orElse: () => trips.first);
  }

  static String _countdown(TravelTrip t) {
    final start = t.startDate;
    if (start == null) return '';
    final now = DateTime.now();
    final days = DateTime(start.year, start.month, start.day).difference(DateTime(now.year, now.month, now.day)).inDays;
    final end = t.endDate ?? start;
    if (days > 1) return 'in $days days';
    if (days == 1) return 'tomorrow';
    if (days == 0) return 'today';
    return now.isAfter(end.add(const Duration(days: 1))) ? 'past trip' : 'happening now';
  }

  void _addPackingItem(TravelTrip trip) {
    final text = _packingCtrl.text.trim();
    if (text.isEmpty) return;
    ref.read(travelProvider.notifier).addPackingItem(trip.id, text);
    _packingCtrl.clear();
  }


  void _showAddTripDialog(BuildContext context, bool isDark) {
    openEntryEditor(context, EntryKind.trip);
  }

  static const _tabs = ['Trips', 'Packing', 'Plan with Nodo'];

  @override
  Widget build(BuildContext context) {
    final c = CardInk.of(context);
    final trips = ref.watch(travelProvider);
    final selected = _selectedTrip(trips);
    final packing = selected?.packingList ?? const <String>[];
    final packedCount = selected?.packingChecked.where((c) => c).length ?? 0;
    final packingProgress = packing.isEmpty ? 0.0 : packedCount / packing.length;
    final next = trips.where((t) => t.isUpcoming(DateTime.now())).firstOrNull;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Travel', style: GoogleFonts.bodoniModa(fontSize: 36, fontWeight: FontWeight.bold, color: c.ink, height: 1.05)),
                    const SizedBox(height: 4),
                    Text(
                      next == null ? '${trips.length} ${trips.length == 1 ? 'trip' : 'trips'}' : 'Next: ${next.destination.isEmpty ? next.title : next.destination}, ${_countdown(next)}',
                      style: c.meta.copyWith(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              CardAction(label: 'New trip', icon: LucideIcons.plus, onTap: () => _showAddTripDialog(context, c.dark)),
            ],
          ),
          const SizedBox(height: 14),
          CardTabs(options: _tabs, selected: _tabs[_activeTab], onSelected: (t) => setState(() => _activeTab = _tabs.indexOf(t))),
          const SizedBox(height: 14),

          // Which trip the packing list and plan are for.
          if (_activeTab != 0 && trips.length > 1) ...[
            CardTabs(
              options: [for (final t in trips) t.title],
              selected: selected?.title ?? '',
              onSelected: (title) => setState(() => _selectedTripId = trips.firstWhere((t) => t.title == title).id),
            ),
            const SizedBox(height: 12),
          ],

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 420),
            switchInCurve: Motion.silk,
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(position: Tween(begin: const Offset(0.04, 0), end: Offset.zero).animate(a), child: child),
            ),
            layoutBuilder: (current, previous) => Stack(alignment: Alignment.topLeft, children: [...previous, if (current != null) current]),
            child: KeyedSubtree(
              key: ValueKey('$_activeTab-${selected?.id}'),
              child: switch (_activeTab) {
                0 => _tripsTab(c, trips),
                1 => _packingTab(c, selected, packing, packedCount, packingProgress),
                _ => _planTab(c, selected),
              },
            ),
          ),
        ].revealed(),
      ),
    );
  }

  Widget _tripsTab(CardInk c, List<TravelTrip> trips) {
    if (trips.isEmpty) {
      return EmptyState(
        icon: LucideIcons.plane,
        title: 'No trips yet',
        message: 'Add a trip to keep its dates, flight and packing list together.',
        action: CardAction(label: 'New trip', icon: LucideIcons.plus, onTap: () => _showAddTripDialog(context, c.dark)),
      );
    }
    final now = DateTime.now();
    return Column(
      children: [
        for (final trip in trips)
          Padding(
            key: ValueKey(trip.id),
            padding: const EdgeInsets.only(bottom: 14),
            child: BentoPod(
              style: PodTextureStyle.glass,
              padding: EdgeInsets.zero,
              onTap: () => openEntryEditor(context, EntryKind.trip, editing: trip),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (trip.coverUrl != null && trip.coverUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                      child: SizedBox(
                        height: 140,
                        width: double.infinity,
                        child: Image.network(trip.coverUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CardLabel(trip.title, trailing: trip.flight.isEmpty ? null : trip.flight),
                        const SizedBox(height: 4),
                        Text(trip.destination.isEmpty ? trip.title : trip.destination, style: c.title.copyWith(fontSize: 24)),
                        const SizedBox(height: 4),
                        Text([trip.date, _countdown(trip)].where((s) => s.isNotEmpty).join(' · '),
                            style: c.meta.copyWith(fontSize: 13.5, color: trip.isUpcoming(now) ? c.mark : c.muted)),
                        if (trip.packingList.isNotEmpty) ...[
                          CardMeter(fraction: trip.packingChecked.where((x) => x).length / trip.packingList.length),
                          const SizedBox(height: 6),
                          Text('${trip.packingChecked.where((x) => x).length} of ${trip.packingList.length} packed', style: c.meta.copyWith(fontSize: 12.5)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _packingTab(CardInk c, TravelTrip? selected, List<String> packing, int packedCount, double progress) {
    if (selected == null) {
      return const EmptyState(
        icon: LucideIcons.luggage,
        title: 'No trip to pack for',
        message: 'Create a trip first; each trip keeps its own packing list.',
      );
    }
    return BentoPod(
      style: PodTextureStyle.glass,
      padding: const EdgeInsets.fromLTRB(22, 20, 14, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CardLabel('Packing for ${selected.destination.isEmpty ? selected.title : selected.destination}', trailing: '${(progress * 100).round()}%'),
                CardFigure(packing.isEmpty ? '0' : '$packedCount of ${packing.length}', unit: 'packed'),
                CardMeter(fraction: progress),
              ],
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < packing.length; i++)
            Builder(builder: (context) {
              final isChecked = selected.packingChecked[i];
              return Pressable(
                pressedScale: 0.98,
                hoverLift: 0,
                onTap: () => ref.read(travelProvider.notifier).togglePackingItem(selected.id, i),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 320),
                      curve: Motion.silk,
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: isChecked ? c.fill : Colors.transparent,
                        border: Border.all(color: isChecked ? c.fill : c.muted.withValues(alpha: 0.6), width: 1.5),
                      ),
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 420),
                        curve: Motion.settle,
                        scale: isChecked ? 1 : 0,
                        child: Icon(Icons.check_rounded, size: 13, color: c.onFill),
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: AnimatedDefaultTextStyle(
                        duration: Motion.standard,
                        style: c.body.copyWith(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w400,
                          color: isChecked ? c.muted : c.ink,
                          decoration: isChecked ? TextDecoration.lineThrough : TextDecoration.none,
                          decorationColor: c.muted,
                        ),
                        child: Text(packing[i]),
                      ),
                    ),
                    Tooltip(
                      message: 'Remove item',
                      child: Pressable(
                        pressedScale: 0.85,
                        hoverLift: 0,
                        onTap: () => ref.read(travelProvider.notifier).removePackingItem(selected.id, i),
                        child: SizedBox(width: 40, height: 40, child: Center(child: Icon(LucideIcons.x, size: 14, color: c.muted))),
                      ),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _packingCtrl,
                  onSubmitted: (_) => _addPackingItem(selected),
                  style: c.body.copyWith(fontSize: 14.5, fontWeight: FontWeight.w400),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: false,
                    hintText: 'Add an item, e.g. phone charger',
                    hintStyle: c.meta.copyWith(fontSize: 14.5),
                    border: UnderlineInputBorder(borderSide: BorderSide(color: c.hairline)),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: c.hairline)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: c.mark, width: 1.5)),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              CardLink(label: 'Add', onTap: () => _addPackingItem(selected)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _planTab(CardInk c, TravelTrip? selected) {
    final place = selected == null ? null : (selected.destination.isEmpty ? selected.title : selected.destination);
    return BentoPod(
      style: PodTextureStyle.paper,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardLabel('Plan with Nodo'),
          const SizedBox(height: 4),
          Text(place == null ? 'Add a trip first' : 'Ideas for $place', style: c.title.copyWith(fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            place == null ? 'Then ask Nodo for an itinerary or local tips.' : 'Ask for a day-by-day itinerary, what to pack, or where locals eat.',
            style: c.meta.copyWith(fontSize: 14),
          ),
          if (selected != null) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 18,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                CardAction(label: 'Plan an itinerary', icon: LucideIcons.compass, onTap: () => widget.onOpenAiModal('${selected.title} itinerary')),
                CardLink(label: 'Local tips', onTap: () => widget.onOpenAiModal('${selected.title} local tips')),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
