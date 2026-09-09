import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/state/sanctuary_state.dart';
import '../../../core/widgets/bento_pod.dart';

class ShoppingScreen extends ConsumerStatefulWidget {
  const ShoppingScreen({super.key});

  @override
  ConsumerState<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends ConsumerState<ShoppingScreen> {
  void _showAddItemModal(BuildContext context, bool isDark) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final storeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
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
                    Text('Add Wishlist Item', style: GoogleFonts.bodoniModa(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                    IconButton(
                      icon: Icon(LucideIcons.x, color: isDark ? Colors.white70 : AppColors.onSurface, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Item Name',
                    labelStyle: TextStyle(color: isDark ? Colors.white70 : AppColors.onSurfaceVariant),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: storeCtrl,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Store / Curation Space',
                    labelStyle: TextStyle(color: isDark ? Colors.white70 : AppColors.onSurfaceVariant),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Estimated Price (₹)',
                    labelStyle: TextStyle(color: isDark ? Colors.white70 : AppColors.onSurfaceVariant),
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
                      if (nameCtrl.text.trim().isNotEmpty) {
                        ref.read(shoppingProvider.notifier).addShoppingItem(
                              name: nameCtrl.text.trim(),
                              store: storeCtrl.text.trim().isNotEmpty ? storeCtrl.text.trim() : 'General Sanctuary',
                              price: double.tryParse(priceCtrl.text.trim()) ?? 0.0,
                            );
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text('Tally to Wishlist', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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

    final items = ref.watch(shoppingProvider);
    final remainingTotal = items.where((i) => !i.isChecked).fold<double>(0, (sum, i) => sum + i.price);

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
                    Text('CURATED TALLY LIST', style: AppTypography.labelSm),
                    const SizedBox(height: 4),
                    Text(
                      'Shopping & Goods',
                      style: GoogleFonts.bodoniModa(fontSize: 28, fontWeight: FontWeight.bold, color: primaryTextColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onPressed: () => _showAddItemModal(context, isDark),
                icon: const Icon(LucideIcons.plus, size: 16),
                label: Text('+ Add Item', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 24),

          BentoPod(
            style: PodTextureStyle.paper,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('WISHLIST TALLY TAGS', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: accentColor)),
                    Text('REMAINING: ₹${remainingTotal.toStringAsFixed(0)}', style: GoogleFonts.bodoniModa(fontSize: 14, fontWeight: FontWeight.bold, color: primaryTextColor)),
                  ],
                ),
                const SizedBox(height: 14),

                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text('Your wishlist is empty. Tap "+ Add Item" to tally goods.', style: GoogleFonts.dmSans(color: subtextColor)),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (context, idx) => const SizedBox(height: 10),
                    itemBuilder: (context, idx) {
                      final item = items[idx];
                      final bool isChecked = item.isChecked;

                      return GestureDetector(
                        onTap: () {
                          ref.read(shoppingProvider.notifier).toggleShoppingItem(item.id);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isChecked
                                ? (isDark ? const Color(0xFF080808) : AppColors.surfaceContainerHigh)
                                : (isDark ? const Color(0xFF000000) : Colors.white),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isChecked
                                  ? (isDark ? const Color(0xFF1E1E1E) : AppColors.outlineVariant)
                                  : (isDark ? const Color(0xFF1E1E1E) : AppColors.primary.withValues(alpha: 0.3)),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: isChecked,
                                      activeColor: accentColor,
                                      checkColor: isDark ? Colors.black : Colors.white,
                                      onChanged: (val) {
                                        ref.read(shoppingProvider.notifier).toggleShoppingItem(item.id);
                                      },
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            style: GoogleFonts.dmSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              decoration: isChecked ? TextDecoration.lineThrough : null,
                                              color: isChecked ? subtextColor : primaryTextColor,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(item.store, style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '₹${item.price.toStringAsFixed(0)}',
                                    style: GoogleFonts.bodoniModa(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isChecked ? subtextColor : accentColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: Icon(LucideIcons.trash2, size: 14, color: isDark ? Colors.white30 : Colors.black26),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      ref.read(shoppingProvider.notifier).removeShoppingItem(item.id);
                                    },
                                  ),
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
          ),
        ],
      ),
    );
  }
}
