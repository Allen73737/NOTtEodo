import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/state/sanctuary_state.dart';
import '../../../core/widgets/bento_pod.dart';
import '../../../core/performance/sanctuary_motion_engine.dart';
import '../../../core/motion/motion.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/entry_editor.dart';

class WardrobeScreen extends ConsumerStatefulWidget {
  const WardrobeScreen({super.key});

  @override
  ConsumerState<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends ConsumerState<WardrobeScreen> {
  String _selectedFabric = 'All Fabrics';

  void _showCurateOutfitDialog(BuildContext context, bool isDark) {
    openEntryEditor(context, EntryKind.outfit);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    final accentColor = isDark ? const Color(0xFFE8927C) : AppColors.secondary;

    final outfits = ref.watch(wardrobeProvider);

    final filteredOutfits = _selectedFabric == 'All Fabrics'
        ? outfits
        : outfits.where((o) => o.tags.any((t) => t.toLowerCase() == _selectedFabric.toLowerCase()) || o.category.toLowerCase().contains(_selectedFabric.toLowerCase())).toList();

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
                    'Wardrobe',
                    style: GoogleFonts.bodoniModa(fontSize: 28, fontWeight: FontWeight.bold, color: primaryTextColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );

              final curateBtn = Pressable(pressedScale: 0.95, hoverLift: 0, child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _showCurateOutfitDialog(context, isDark),
                icon: const Icon(LucideIcons.shirt, size: 16),
                label: const Text('New Outfit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ));

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    headerInfo,
                    const SizedBox(height: 12),
                    SizedBox(width: double.infinity, child: curateBtn),
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: headerInfo),
                  const SizedBox(width: 12),
                  curateBtn,
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Interactive Fabric & Textile Texture Swatches Bar
          BentoPod(
            style: PodTextureStyle.glass,
            showWashiTape: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'TACTILE TEXTILE SWATCH PALETTE',
                        style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: accentColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_selectedFabric != 'All Fabrics') ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _selectedFabric = 'All Fabrics'),
                        child: Text('Reset Filter', style: GoogleFonts.dmSans(fontSize: 11, color: accentColor, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _fabricSwatch('All Fabrics', const Color(0xFF757575), isDark, accentColor),
                      const SizedBox(width: 10),
                      _fabricSwatch('Italian Linen', const Color(0xFFE5DFC9), isDark, accentColor),
                      const SizedBox(width: 10),
                      _fabricSwatch('Raw Silk', const Color(0xFFB5C9BE), isDark, accentColor),
                      const SizedBox(width: 10),
                      _fabricSwatch('Heavy Denim', const Color(0xFF2C4347), isDark, accentColor),
                      const SizedBox(width: 10),
                      _fabricSwatch('Cashmere', const Color(0xFFE8927C), isDark, accentColor),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Outfits List
          if (filteredOutfits.isEmpty)
            EmptyState(
  icon: LucideIcons.shirt,
  title: 'No looks yet',
  message: 'No curated looks with $_selectedFabric. Tap "+ Curate Look" to design one.',
)
          else
            MotionColumn(
  spacing: 0,
  // Pinterest-style board on wide screens; one column on phones.
  minTileWidth: 330,
  children: [
    for (var idx = 0; idx < filteredOutfits.length; idx++)
      Builder(key: ValueKey(filteredOutfits[idx].id), builder: (context) {
                final outfit = filteredOutfits[idx];
                return Reveal(style: RevealStyle.slideIn, distance: 18, child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: BentoPod(
                    style: PodTextureStyle.polaroid,
                    showWaxSeal: true,
                    onTap: () => openEntryEditor(context, EntryKind.outfit, editing: outfit),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: (isDark ? const Color(0xFF86CBB0) : const Color(0xFF16282C)).withValues(alpha: isDark ? 0.16 : 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: (isDark ? const Color(0xFF86CBB0) : const Color(0xFF16282C)).withValues(alpha: isDark ? 0.35 : 0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.sparkles, size: 12, color: isDark ? const Color(0xFF86CBB0) : const Color(0xFF16282C)),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      outfit.vibe,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF86CBB0) : const Color(0xFF16282C)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 120),
                                  child: Text(
                                    outfit.weather,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  tooltip: 'Delete outfit',
                                  icon: Icon(LucideIcons.trash2, size: 14, color: isDark ? Colors.white30 : Colors.black26),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    SanctuaryHapticEngine.sealImpression();
                                    ref.read(wardrobeProvider.notifier).removeOutfit(outfit.id);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(outfit.title, style: GoogleFonts.bodoniModa(fontSize: 19, fontWeight: FontWeight.bold, color: primaryTextColor)),
                        const SizedBox(height: 6),
                        Text(outfit.items, style: GoogleFonts.dmSans(fontSize: 13, color: isDark ? const Color(0xFFE8DFC8) : AppColors.primary, height: 1.5)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: (isDark ? const Color(0xFFE8927C) : AppColors.secondary).withValues(alpha: isDark ? 0.16 : 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: (isDark ? const Color(0xFFE8927C) : AppColors.secondary).withValues(alpha: isDark ? 0.35 : 0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.layers, size: 12, color: isDark ? const Color(0xFFE8927C) : AppColors.secondary),
                                  const SizedBox(width: 5),
                                  Text(
                                    outfit.fabric,
                                    style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFFE8927C) : AppColors.secondary),
                                  ),
                                ],
                              ),
                            ),
                            Icon(LucideIcons.shirt, size: 18, color: accentColor),
                          ],
                        ),
                      ],
                    ),
                  ),
                ));
              }),
  ],
),
        ].revealed(),
      ),
    );
  }

  Widget _fabricSwatch(String name, Color color, bool isDark, Color accentColor) {
    final isSelected = _selectedFabric == name;
    return GestureDetector(
      onTap: () => setState(() => _selectedFabric = name),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.7 : 0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accentColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
            const SizedBox(width: 6),
            Text(
              name,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
