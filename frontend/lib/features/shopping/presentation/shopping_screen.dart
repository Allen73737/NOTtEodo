import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/widgets/app_toast_engine.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/state/sanctuary_state.dart';
import '../../../core/widgets/bento_pod.dart';
import '../../../core/motion/motion.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/entry_editor.dart';
import '../../../core/state/app_settings.dart';
import '../../../core/ai/smart_classifier.dart';

class ShoppingScreen extends ConsumerStatefulWidget {
  const ShoppingScreen({super.key});

  @override
  ConsumerState<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends ConsumerState<ShoppingScreen> {
  /// Sort the list in store order (produce, bakery, dairy…) with aisle headers.
  bool _byAisle = false;

  void _showAddItemModal(BuildContext context, bool isDark) {
    openEntryEditor(context, EntryKind.shopping);
  }

  Widget _itemTile(BuildContext context, ShoppingItem item, bool isDark, Color primaryTextColor, Color subtextColor,
      Color accentColor, String currency) {
                      final bool isChecked = item.isChecked;

                      return Reveal(style: RevealStyle.slideIn, distance: 18, child: GestureDetector(
                        onTap: () {
                          ref.read(shoppingProvider.notifier).toggleShoppingItem(item.id);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isChecked
                                ? (isDark ? const Color(0xFF000000).withValues(alpha: 0.6) : AppColors.surfaceContainerHigh)
                                : (isDark ? const Color(0xFF000000) : Colors.white),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isChecked
                                  ? (isDark ? const Color(0xFF22201D) : AppColors.outlineVariant)
                                  : (isDark ? AppColors.darkBorder : AppColors.primary.withValues(alpha: 0.15)),
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
                                          Text(
                                            item.store,
                                            style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  if (item.url != null && item.url!.trim().isNotEmpty) ...[
                                    IconButton(
                                      tooltip: 'Open buying link',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: Icon(LucideIcons.externalLink, size: 15, color: accentColor),
                                      onPressed: () async {
                                        final raw = item.url!.trim();
                                        final uri = Uri.tryParse(raw.startsWith('http') ? raw : 'https://$raw');
                                        if (uri != null && await canLaunchUrl(uri)) {
                                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                                        } else if (context.mounted) {
                                          AppToastEngine().showToast(context, title: 'Invalid URL', message: 'Could not open $raw');
                                        }
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Text(
                                    formatMoney(item.price.toDouble(), currency),
                                    style: GoogleFonts.bodoniModa(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isChecked ? subtextColor : accentColor,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  PopupMenuButton<String>(
                                    tooltip: 'More',
                                    padding: EdgeInsets.zero,
                                    iconSize: 16,
                                    constraints: const BoxConstraints(minWidth: 120),
                                    icon: Icon(LucideIcons.moreVertical, size: 16, color: isDark ? Colors.white38 : Colors.black38),
                                    onSelected: (v) async {
                                      if (v == 'edit') {
                                        openEntryEditor(context, EntryKind.shopping, editing: item);
                                      } else if (v == 'link' && item.url != null) {
                                        final raw = item.url!.trim();
                                        final uri = Uri.tryParse(raw.startsWith('http') ? raw : 'https://$raw');
                                        if (uri != null && await canLaunchUrl(uri)) {
                                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                                        }
                                      } else {
                                        ref.read(shoppingProvider.notifier).removeShoppingItem(item.id);
                                      }
                                    },
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                      if (item.url != null && item.url!.trim().isNotEmpty)
                                        const PopupMenuItem(value: 'link', child: Text('Open Buying Link')),
                                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    final accentColor = isDark ? const Color(0xFFE8927C) : AppColors.secondary;

    final listed = ref.watch(shoppingProvider);
    final items = !_byAisle
        ? listed
        : ([...listed]..sort((a, b) {
            final ai = ShoppingAisles.order.indexOf(ShoppingAisles.aisleFor(a.name));
            final bi = ShoppingAisles.order.indexOf(ShoppingAisles.aisleFor(b.name));
            if (ai != bi) return ai.compareTo(bi);
            if (a.isChecked != b.isChecked) return a.isChecked ? 1 : -1;
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          }));
    final currency = ref.watch(appSettingsProvider.select((s) => s.currencySymbol));
    final remainingTotal = items.where((i) => !i.isChecked).fold<double>(0, (sum, i) => sum + i.price);

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
                    'Shopping',
                    style: GoogleFonts.bodoniModa(fontSize: 28, fontWeight: FontWeight.bold, color: primaryTextColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );

              final addBtn = Pressable(pressedScale: 0.95, hoverLift: 0, child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onPressed: () => _showAddItemModal(context, isDark),
                icon: const Icon(LucideIcons.plus, size: 16),
                label: Text('Add Item', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 13)),
              ));

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    headerInfo,
                    const SizedBox(height: 12),
                    SizedBox(width: double.infinity, child: addBtn),
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: headerInfo),
                  const SizedBox(width: 12),
                  addBtn,
                ],
              );
            },
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
                    Flexible(
                      child: Text(
                        'WISHLIST',
                        style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: accentColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: RollingText(
                        'REMAINING: ${formatMoney(remainingTotal, currency)}',
                        style: GoogleFonts.bodoniModa(fontSize: 14, fontWeight: FontWeight.bold, color: primaryTextColor),
                      ),
                    ),
                  ],
                ),
                if (items.length >= 3 && ref.watch(appSettingsProvider.select((s) => s.smartSuggestions))) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilterChip(
                      avatar: Icon(LucideIcons.sparkles, size: 14, color: _byAisle ? accentColor : subtextColor),
                      label: const Text('Group by aisle'),
                      tooltip: 'Walk the store once: items sorted into aisles automatically',
                      selected: _byAisle,
                      showCheckmark: false,
                      selectedColor: accentColor.withValues(alpha: isDark ? 0.25 : 0.15),
                      labelStyle: GoogleFonts.dmSans(fontSize: 12, color: _byAisle ? accentColor : primaryTextColor),
                      onSelected: (v) => setState(() => _byAisle = v),
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                if (items.isEmpty)
                  const EmptyState(
  icon: LucideIcons.shoppingBag,
  title: 'Your wishlist is empty',
  message: 'Tap "+ Add Item" to start a list.',
)
                else
                  MotionColumn(
  spacing: 10,
  children: [
    for (var idx = 0; idx < items.length; idx++) ...[
      if (_byAisle && (idx == 0 || ShoppingAisles.aisleFor(items[idx - 1].name) != ShoppingAisles.aisleFor(items[idx].name)))
        Padding(
          key: ValueKey('aisle-${ShoppingAisles.aisleFor(items[idx].name)}'),
          padding: EdgeInsets.only(top: idx == 0 ? 0 : 8, bottom: 2),
          child: Text(ShoppingAisles.aisleFor(items[idx].name).toUpperCase(),
              style: GoogleFonts.dmSans(fontSize: 11.5, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: subtextColor)),
        ),
      Builder(
          key: ValueKey(items[idx].id),
          builder: (context) => _itemTile(context, items[idx], isDark, primaryTextColor, subtextColor, accentColor, currency)),
    ],
  ],
),
              ],
            ),
          ),
        ].revealed(),
      ),
    );
  }
}
