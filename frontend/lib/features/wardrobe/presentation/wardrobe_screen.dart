import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../core/services/ai_stylist_service.dart';
import '../../../core/widgets/app_toast_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
  StylistRecommendation? _recommendation;
  bool _isLoadingRecommendation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecommendation();
    });
  }

  Future<void> _loadRecommendation() async {
    if (_isLoadingRecommendation || !mounted) return;
    setState(() => _isLoadingRecommendation = true);
    final outfits = ref.read(wardrobeProvider);
    final rec = await AiStylistService().recommendDailyOutfit(wardrobe: outfits);
    if (mounted) {
      setState(() {
        _recommendation = rec;
        _isLoadingRecommendation = false;
      });
    }
  }

  void _showCurateOutfitDialog(BuildContext context, bool isDark) {
    openEntryEditor(context, EntryKind.outfit);
  }

  Widget _buildStylistBentoPod(
    bool isDark,
    Color primaryTextColor,
    Color subtextColor,
    Color accentColor,
  ) {
    final rec = _recommendation;
    final surfaceColor = isDark ? const Color(0xFF0A0A0A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE8E3D8);

    return BentoPod(
      style: PodTextureStyle.glass,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(LucideIcons.sparkles, size: 16, color: accentColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI STYLIST',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.6,
                          color: accentColor,
                        ),
                      ),
                      Text(
                        'An outfit for the weather and occasion',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: subtextColor,
                        ),
                      ),
                    ],
                  ),
                  ),
                ],
              ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _isLoadingRecommendation ? null : _loadRecommendation,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _isLoadingRecommendation
                          ? SizedBox(
                              width: 11,
                              height: 11,
                              child: CircularProgressIndicator(strokeWidth: 1.5, color: accentColor),
                            )
                          : Icon(LucideIcons.refreshCw, size: 11, color: accentColor),
                      const SizedBox(width: 5),
                      Text(
                        _isLoadingRecommendation ? 'Styling...' : 'Suggest Outfit',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (rec == null && _isLoadingRecommendation)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Finding the best outfit combination...',
                  style: GoogleFonts.dmSans(fontSize: 12, color: subtextColor),
                ),
              ),
            )
          else ...[
            Text(
              rec?.lookTitle ?? 'Today\'s Suggested Outfit',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              rec?.ensemble ?? 'Italian Linen Shirt & Raw Silk Pleated Trousers',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFDDD6CA) : const Color(0xFF635F59),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accentColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.layers, size: 13, color: accentColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rec?.fabricHarmony ?? 'Texture balance designed for mild weather.',
                      style: GoogleFonts.dmSans(fontSize: 11.5, color: subtextColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(LucideIcons.sparkle, size: 12, color: accentColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    rec?.stylingTip ?? 'Maintain clean minimalist accents.',
                    style: GoogleFonts.dmSans(fontSize: 11.5, fontStyle: FontStyle.italic, color: subtextColor),
                  ),
                ),
                const SizedBox(width: 10),
                Pressable(
                  pressedScale: 0.95,
                  hoverLift: 0,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      backgroundColor: accentColor,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      if (rec == null) return;
                      ref.read(wardrobeProvider.notifier).addOutfit(
                        title: rec.lookTitle,
                        category: rec.ensemble,
                        vibe: rec.occasion,
                        tags: ['AI Suggested', 'Wardrobe'],
                        previewIcon: 'sparkles',
                      );
                      AppToastEngine().showToast(
                        context,
                        title: 'Look Added',
                        message: '"${rec.lookTitle}" saved to Wardrobe collection.',
                      );
                    },
                    icon: const Icon(LucideIcons.plus, size: 12),
                    label: Text(
                      'Save Look',
                      style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
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
          const SizedBox(height: 18),

          // AI Sartorial Stylist BentoPod
          _buildStylistBentoPod(isDark, primaryTextColor, subtextColor, accentColor),

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
  message: 'No outfits with $_selectedFabric. Tap "+ Add Outfit" to design one.',
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
                                color: (isDark ? const Color(0xFFE8927C) : AppColors.secondary).withValues(alpha: isDark ? 0.16 : 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: (isDark ? const Color(0xFFE8927C) : AppColors.secondary).withValues(alpha: isDark ? 0.35 : 0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.sparkles, size: 13, color: isDark ? const Color(0xFFE8927C) : AppColors.secondary),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      outfit.vibe,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.dmSans(fontSize: 12.5, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFFE8927C) : AppColors.secondary),
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
                        if (outfit.imageUrl != null && outfit.imageUrl!.trim().isNotEmpty) ...[
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: _buildOutfitImage(outfit.imageUrl!, isDark),
                          ),
                        ],
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

  Widget _buildOutfitImage(String url, bool isDark) {
    final bgColor = isDark ? const Color(0xFF141414) : const Color(0xFFF3EFE8);
    final fallback = Container(
      height: 180,
      width: double.infinity,
      color: bgColor,
      child: Center(
        child: Icon(LucideIcons.shirt, size: 28, color: isDark ? Colors.white30 : Colors.black26),
      ),
    );

    if (url.startsWith('http://') || url.startsWith('https://') || kIsWeb) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 190,
        errorBuilder: (_, __, ___) => fallback,
      );
    }
    try {
      final f = File(url);
      if (f.existsSync()) {
        return Image.file(
          f,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 190,
          errorBuilder: (_, __, ___) => fallback,
        );
      }
    } catch (_) {}
    return fallback;
  }
}
