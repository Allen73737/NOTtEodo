import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/state/sanctuary_state.dart';
import '../../../core/widgets/airmail_envelope_card.dart';
import '../../../core/widgets/bento_pod.dart';

class TravelScreen extends ConsumerStatefulWidget {
  final Function(String) onOpenAiModal;

  const TravelScreen({super.key, required this.onOpenAiModal});

  @override
  ConsumerState<TravelScreen> createState() => _TravelScreenState();
}

class _TravelScreenState extends ConsumerState<TravelScreen> {
  int _activeTab = 0; // 0: Passes, 1: Packing, 2: Budget

  final List<Map<String, dynamic>> _packingItems = [
    {'title': 'Physical Passport & Boarding Passes', 'category': 'Documents', 'checked': true},
    {'title': 'Linen Resort Shirt & Chino Shorts', 'category': 'Wardrobe', 'checked': true},
    {'title': 'Sony WH-1000XM5 ANC Headphones', 'category': 'Electronics', 'checked': true},
    {'title': 'Mineral Sunscreen SPF 50+', 'category': 'Toiletries', 'checked': false},
    {'title': 'GoPro Hero 12 & Waterproof Housing', 'category': 'Electronics', 'checked': false},
    {'title': 'Polarized UV400 Sunglasses', 'category': 'Accessories', 'checked': false},
  ];

  void _showAddTripDialog(BuildContext context, bool isDark) {
    final titleCtrl = TextEditingController();
    final destCtrl = TextEditingController();
    final flightCtrl = TextEditingController();
    final dateCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        final dialogBg = isDark ? const Color(0xFF000000) : AppColors.surfaceContainerHigh;
        final textColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
        final borderColor = isDark ? const Color(0xFF1E1E1E) : AppColors.outlineVariant;

        return Dialog(
          backgroundColor: dialogBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Postmark New Voyage', style: GoogleFonts.bodoniModa(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                    IconButton(
                      icon: Icon(LucideIcons.x, color: isDark ? Colors.white70 : AppColors.onSurface, size: 20),
                      onPressed: () => Navigator.pop(dialogCtx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleCtrl,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Voyage Title',
                    labelStyle: TextStyle(color: isDark ? Colors.white70 : AppColors.onSurfaceVariant),
                    hintText: 'e.g. Kyoto Cherry Blossom Retreat',
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: destCtrl,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: 'Destination (Code)',
                          labelStyle: TextStyle(color: isDark ? Colors.white70 : AppColors.onSurfaceVariant),
                          hintText: 'HND (Tokyo)',
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: flightCtrl,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: 'Flight / Transport',
                          labelStyle: TextStyle(color: isDark ? Colors.white70 : AppColors.onSurfaceVariant),
                          hintText: 'NH-828',
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dateCtrl,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Dates',
                    labelStyle: TextStyle(color: isDark ? Colors.white70 : AppColors.onSurfaceVariant),
                    hintText: 'Nov 04 - Nov 14, 2026',
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFFE8927C) : AppColors.primary,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      if (titleCtrl.text.trim().isNotEmpty && destCtrl.text.trim().isNotEmpty) {
                        ref.read(travelProvider.notifier).addTrip(
                              title: titleCtrl.text.trim(),
                              destination: destCtrl.text.trim(),
                              flight: flightCtrl.text.trim().isNotEmpty ? flightCtrl.text.trim() : 'AUTO-PASS',
                              date: dateCtrl.text.trim().isNotEmpty ? dateCtrl.text.trim() : 'Upcoming Season',
                            );
                        Navigator.pop(dialogCtx);
                      }
                    },
                    child: const Text('Seal Travel Postmark', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    final accentColor = isDark ? const Color(0xFFE8927C) : AppColors.secondary;

    final trips = ref.watch(travelProvider);
    final packedCount = _packingItems.where((i) => i['checked'] == true).length;
    final packingProgress = packedCount / _packingItems.length;

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
                    Text('EDITORIAL TRAVEL SANCTUARY', style: AppTypography.labelSm),
                    const SizedBox(height: 4),
                    Text(
                      'Travel & Passport Stubs',
                      style: GoogleFonts.bodoniModa(fontSize: 28, fontWeight: FontWeight.bold, color: primaryTextColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _showAddTripDialog(context, isDark),
                icon: const Icon(LucideIcons.plane, size: 16),
                label: const Text('New Trip', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Tabs: Passes, Packing, Budget
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF000000) : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF1E1E1E) : Colors.black12),
            ),
            child: Row(
              children: [
                _buildTabBtn('Boarding Stubs (${trips.length})', 0, isDark, accentColor),
                _buildTabBtn('Packing ($packedCount/${_packingItems.length})', 1, isDark, accentColor),
                _buildTabBtn('Itinerary & AI', 2, isDark, accentColor),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Tab 0: Boarding Stubs
          if (_activeTab == 0) ...[
            if (trips.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF000000) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: isDark ? Border.all(color: const Color(0xFF1E1E1E)) : null,
                ),
                child: Center(
                  child: Text('No voyages planned yet. Tap "+ New Trip" to seal an itinerary!', style: GoogleFonts.dmSans(color: subtextColor)),
                ),
              )
            else
              ...trips.map((trip) => AirmailEnvelopeCard(
                    title: trip.title,
                    flight: trip.flight,
                    destination: trip.destination,
                    date: trip.date,
                  )),
          ],

          // Tab 1: Interactive Packing Checklist
          if (_activeTab == 1) ...[
            BentoPod(
              style: PodTextureStyle.glass,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Suitcase Readiness', style: GoogleFonts.bodoniModa(fontSize: 20, fontWeight: FontWeight.bold, color: primaryTextColor)),
                      Text('${(packingProgress * 100).toInt()}% Ready', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, color: accentColor)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: packingProgress,
                      backgroundColor: isDark ? const Color(0xFF262626) : Colors.black12,
                      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._packingItems.map((item) {
                    final isChecked = item['checked'] as bool;

                    return InkWell(
                      onTap: () {
                        setState(() {
                          item['checked'] = !isChecked;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isChecked
                              ? (isDark ? const Color(0xFF080808) : Colors.white.withValues(alpha: 0.5))
                              : (isDark ? const Color(0xFF000000) : Colors.white),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isChecked ? accentColor.withValues(alpha: 0.3) : (isDark ? const Color(0xFF1E1E1E) : Colors.black12),
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
                                item['title'] as String,
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  decoration: isChecked ? TextDecoration.lineThrough : null,
                                  color: isChecked ? subtextColor : primaryTextColor,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF202020) : Colors.black.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item['category'] as String,
                                style: GoogleFonts.dmSans(fontSize: 10, color: subtextColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
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
                    'Curate local itineraries, hidden café gems, and weather forecasting with Voyage AI.',
                    style: GoogleFonts.dmSans(fontSize: 13, color: subtextColor),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => widget.onOpenAiModal('Goa Trip 2026 Itinerary'),
                        icon: const Icon(LucideIcons.compass, size: 14),
                        label: const Text('Ask Goa AI Itinerary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: accentColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => widget.onOpenAiModal('Tokyo Autumn Guide'),
                        icon: Icon(LucideIcons.mapPin, size: 14, color: accentColor),
                        label: Text('Tokyo Hidden Map', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
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
