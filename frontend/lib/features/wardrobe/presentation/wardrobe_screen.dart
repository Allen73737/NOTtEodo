import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/state/sanctuary_state.dart';
import '../../../core/widgets/bento_pod.dart';

class WardrobeScreen extends ConsumerStatefulWidget {
  const WardrobeScreen({super.key});

  @override
  ConsumerState<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends ConsumerState<WardrobeScreen> {
  String _selectedFabric = 'All Fabrics';

  void _showCurateOutfitDialog(BuildContext context, bool isDark) {
    final titleCtrl = TextEditingController();
    final itemsCtrl = TextEditingController();
    String vibe = 'College Casual';
    String fabric = 'Italian Linen';

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
                    Text('Curate Outfit Look', style: GoogleFonts.bodoniModa(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
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
                    labelText: 'Look Title',
                    hintText: 'e.g. Autumn Gallery Promenade',
                    labelStyle: TextStyle(color: isDark ? Colors.white70 : AppColors.onSurfaceVariant),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: itemsCtrl,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Garments & Pieces',
                    hintText: 'Oversized Blazer · Cream Turtleneck · Oxford Shoes',
                    labelStyle: TextStyle(color: isDark ? Colors.white70 : AppColors.onSurfaceVariant),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: vibe,
                        dropdownColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: 'Aesthetic Vibe',
                          labelStyle: TextStyle(color: isDark ? Colors.white70 : AppColors.onSurfaceVariant),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: ['College Casual', 'Smart Formal', 'Resort Vacation', 'Minimal Studio', 'Winter Warmth']
                            .map((v) => DropdownMenuItem(value: v, child: Text(v, overflow: TextOverflow.ellipsis)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) vibe = val;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: fabric,
                        dropdownColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: 'Textile',
                          labelStyle: TextStyle(color: isDark ? Colors.white70 : AppColors.onSurfaceVariant),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: ['Italian Linen', 'Raw Silk', 'Heavy Denim', 'Cashmere', 'Merino Wool']
                            .map((f) => DropdownMenuItem(value: f, child: Text(f, overflow: TextOverflow.ellipsis)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) fabric = val;
                        },
                      ),
                    ),
                  ],
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
                      if (titleCtrl.text.trim().isNotEmpty) {
                        ref.read(wardrobeProvider.notifier).addOutfit(
                              title: titleCtrl.text.trim(),
                              category: itemsCtrl.text.trim().isNotEmpty ? itemsCtrl.text.trim() : 'Curated Ensemble',
                              vibe: vibe,
                              tags: [fabric, vibe],
                              previewIcon: 'shirt',
                            );
                        Navigator.pop(dialogCtx);
                      }
                    },
                    child: const Text('Add to Lookbook', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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

    final outfits = ref.watch(wardrobeProvider);

    final filteredOutfits = _selectedFabric == 'All Fabrics'
        ? outfits
        : outfits.where((o) => o.tags.any((t) => t.toLowerCase() == _selectedFabric.toLowerCase()) || o.category.toLowerCase().contains(_selectedFabric.toLowerCase())).toList();

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
                    Text('EDITORIAL WARDROBE SANCTUARY', style: AppTypography.labelSm),
                    const SizedBox(height: 4),
                    Text(
                      'Wardrobe & Lookbook',
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
                onPressed: () => _showCurateOutfitDialog(context, isDark),
                icon: const Icon(LucideIcons.shirt, size: 16),
                label: const Text('Curate Look', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ],
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
                    Text('TACTILE TEXTILE SWATCH PALETTE', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: accentColor)),
                    if (_selectedFabric != 'All Fabrics')
                      GestureDetector(
                        onTap: () => setState(() => _selectedFabric = 'All Fabrics'),
                        child: Text('Reset Filter', style: GoogleFonts.dmSans(fontSize: 11, color: accentColor, fontWeight: FontWeight.bold)),
                      ),
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
                      _fabricSwatch('Raw Silk', const Color(0xFF9EBFDB), isDark, accentColor),
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF000000) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? const Color(0xFF1E1E1E) : Colors.black12),
              ),
              child: Center(
                child: Text('No curated looks with $_selectedFabric. Tap "+ Curate Look" to design one.', style: GoogleFonts.dmSans(color: subtextColor)),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredOutfits.length,
              itemBuilder: (context, idx) {
                final outfit = filteredOutfits[idx];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: BentoPod(
                    style: PodTextureStyle.paper,
                    showWaxSeal: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                outfit.vibe,
                                style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.bold, color: accentColor),
                              ),
                            ),
                            Row(
                              children: [
                                Text(outfit.tags.join(' · '), style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor)),
                                const SizedBox(width: 6),
                                IconButton(
                                  icon: Icon(LucideIcons.trash2, size: 14, color: isDark ? Colors.white30 : Colors.black26),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    ref.read(wardrobeProvider.notifier).removeOutfit(outfit.id);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(outfit.title, style: GoogleFonts.bodoniModa(fontSize: 18, fontWeight: FontWeight.bold, color: primaryTextColor)),
                        const SizedBox(height: 6),
                        Text(outfit.category, style: GoogleFonts.dmSans(fontSize: 13, color: subtextColor, height: 1.5)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Aesthetic: ${outfit.vibe}', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, color: primaryTextColor)),
                            Icon(LucideIcons.shirt, size: 16, color: accentColor),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
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
