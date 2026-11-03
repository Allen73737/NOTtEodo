import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/state/sanctuary_state.dart';
import '../../../core/widgets/airmail_envelope_card.dart';
import '../../../core/widgets/bento_pod.dart';
import '../../../core/widgets/sanctuary_loaders.dart';
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    final accentColor = isDark ? const Color(0xFFE8927C) : AppColors.secondary;

    final trips = ref.watch(travelProvider);
    final selected = _selectedTrip(trips);
    final packing = selected?.packingList ?? const <String>[];
    final packedCount = selected?.packingChecked.where((c) => c).length ?? 0;
    final packingProgress = packing.isEmpty ? 0.0 : packedCount / packing.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 460;
              final headerInfo = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LIFESTYLE', style: AppTypography.labelSm),
                  const SizedBox(height: 4),
                  Text(
                    'Travel',
                    style: GoogleFonts.bodoniModa(fontSize: 28, fontWeight: FontWeight.bold, color: primaryTextColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );

              final addTripBtn = Pressable(pressedScale: 0.95, hoverLift: 0, child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _showAddTripDialog(context, isDark),
                icon: const Icon(LucideIcons.plane, size: 16),
                label: const Text('New Trip', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ));

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    headerInfo,
                    const SizedBox(height: 12),
                    SizedBox(width: double.infinity, child: addTripBtn),
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: headerInfo),
                  const SizedBox(width: 12),
                  addTripBtn,
                ],
              );
            },
          ),
          const SizedBox(height: 18),

          // Tabs: Passes, Packing, Budget
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF000000) : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppColors.darkBorder : Colors.black12),
            ),
            child: Row(
              children: [
                _buildTabBtn('Trips (${trips.length})', 0, isDark, accentColor),
                _buildTabBtn('Packing ($packedCount/${packing.length})', 1, isDark, accentColor),
                _buildTabBtn('Itinerary & AI', 2, isDark, accentColor),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Tab 0: Boarding Stubs
          if (_activeTab == 0) ...[
            if (trips.isEmpty)
              const EmptyState(
  icon: LucideIcons.plane,
  title: 'No trips yet',
  message: 'Tap "+ New Trip" to start planning your next escape.',
)
            else
              ...trips.map((trip) => Semantics(
                    button: true,
                    label: 'Edit ${trip.title}',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => openEntryEditor(context, EntryKind.trip, editing: trip),
                      child: AirmailEnvelopeCard(
                        title: trip.title,
                        flight: trip.flight.isEmpty ? 'â€”' : trip.flight,
                        destination: trip.destination,
                        date: [trip.date, _countdown(trip)].where((s) => s.isNotEmpty).join(' Â· '),
                      ),
                    ),
                  )),
          ],

          // Tab 1: Interactive Packing Checklist
          if ((_activeTab == 1 || _activeTab == 2) && trips.length > 1) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final t in trips)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(t.title, overflow: TextOverflow.ellipsis),
                        selected: t.id == selected?.id,
                        onSelected: (_) => setState(() => _selectedTripId = t.id),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          if (_activeTab == 1 && selected == null)
            const EmptyState(
              icon: LucideIcons.luggage,
              title: 'No trip to pack for',
              message: 'Create a trip first; each trip keeps its own packing list.',
            ),
          if (_activeTab == 1 && selected != null) ...[
            BentoPod(
              style: PodTextureStyle.glass,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Packing Progress', style: GoogleFonts.bodoniModa(fontSize: 20, fontWeight: FontWeight.bold, color: primaryTextColor)),
                      RollingText('${(packingProgress * 100).toInt()}% Ready', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, color: accentColor)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SilkProgressBar(
                    value: packingProgress,
                    height: 6,
                    colors: [accentColor.withValues(alpha: 0.75), accentColor],
                    trackColor: isDark ? const Color(0xFF262626) : Colors.black12,
                  ),
                  const SizedBox(height: 16),
                  for (var i = 0; i < packing.length; i++)
                    Builder(builder: (context) {
                      final isChecked = selected.packingChecked[i];
                      return InkWell(
                        onTap: () => ref.read(travelProvider.notifier).togglePackingItem(selected.id, i),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
                          decoration: BoxDecoration(
                            color: isChecked
                                ? (isDark ? const Color(0xFF000000).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.5))
                                : (isDark ? const Color(0xFF000000) : Colors.white),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isChecked ? accentColor.withValues(alpha: 0.3) : (isDark ? AppColors.darkBorder : Colors.black12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isChecked ? LucideIcons.checkSquare : LucideIcons.square,
                                size: 18,
                                color: isChecked ? accentColor : (isDark ? Colors.white38 : Colors.black38),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  packing[i],
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    decoration: isChecked ? TextDecoration.lineThrough : null,
                                    color: isChecked ? subtextColor : primaryTextColor,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Remove item',
                                icon: Icon(LucideIcons.x, size: 14, color: subtextColor),
                                onPressed: () => ref.read(travelProvider.notifier).removePackingItem(selected.id, i),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _packingCtrl,
                          onSubmitted: (_) => _addPackingItem(selected),
                          decoration: const InputDecoration(
                            isDense: true,
                            hintText: 'Add an item, e.g. Phone charger',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        tooltip: 'Add item',
                        onPressed: () => _addPackingItem(selected),
                        icon: const Icon(LucideIcons.plus, size: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Tab 2: Itinerary & AI Curator
          if (_activeTab == 2) ...[
            BentoPod(
              style: PodTextureStyle.paper,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Voyage Intelligence', style: GoogleFonts.bodoniModa(fontSize: 20, fontWeight: FontWeight.bold, color: primaryTextColor)),
                      Icon(LucideIcons.sparkles, color: accentColor, size: 20),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    selected == null
                        ? 'Create a trip, then ask the assistant for an itinerary or local tips.'
                        : 'Ask for an itinerary, packing advice or local tips for ${selected.destination.isEmpty ? selected.title : selected.destination}.',
                    style: GoogleFonts.dmSans(fontSize: 13, color: subtextColor),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Pressable(pressedScale: 0.95, hoverLift: 0, child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: selected == null ? null : () => widget.onOpenAiModal('${selected.title} itinerary'),
                        icon: const Icon(LucideIcons.compass, size: 14),
                        label: const Text('Plan an itinerary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      )),
                      Pressable(pressedScale: 0.95, hoverLift: 0, child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: accentColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: selected == null ? null : () => widget.onOpenAiModal('${selected.title} local tips'),
                        icon: Icon(LucideIcons.mapPin, size: 14, color: accentColor),
                        label: Text('Local tips', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12)),
                      )),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ].revealed(),
      ),
    );
  }

  Widget _buildTabBtn(String label, int index, bool isDark, Color accentColor) {
    final isSelected = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? accentColor.withValues(alpha: isDark ? 0.25 : 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? accentColor : (isDark ? Colors.white60 : AppColors.onSurfaceVariant),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
