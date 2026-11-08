import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/theme/app_colors.dart';
import 'fluid_ui_effects.dart';

class RadialQuickAddMenu extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final Function(String)? onActionSelected;

  const RadialQuickAddMenu({
    super.key,
    required this.isOpen,
    required this.onClose,
    this.onActionSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOpen) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF000000) : AppColors.background;
    final itemBgColor = isDark ? const Color(0xFF080808) : AppColors.surfaceContainerHigh;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final accentColor = isDark ? const Color(0xFFE8927C) : AppColors.secondary;

    final actions = [
      {'icon': LucideIcons.fileText, 'label': 'Note'},
      {'icon': LucideIcons.checkSquare, 'label': 'Task'},
      {'icon': LucideIcons.calendar, 'label': 'Event'},
      {'icon': LucideIcons.dollarSign, 'label': 'Expense'},
      {'icon': LucideIcons.shirt, 'label': 'Wardrobe'},
      {'icon': LucideIcons.shoppingBag, 'label': 'Shopping'},
      {'icon': LucideIcons.mic, 'label': 'Journal'},
      {'icon': LucideIcons.pin, 'label': 'Moodboard'},
    ];

    return Positioned(
      bottom: 96,
      left: MediaQuery.of(context).size.width > 440
          ? MediaQuery.of(context).size.width / 2 - 170
          : 16,
      right: MediaQuery.of(context).size.width > 440 ? null : 16,
      child: GestureDetector(
        onTap: () {}, // Prevent taps inside menu from closing the barrier
        behavior: HitTestBehavior.opaque,
        child: Container(
            width: MediaQuery.of(context).size.width > 440 ? 340 : null,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: surfaceColor.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark ? const Color(0xFF2E2E2E) : Colors.white.withValues(alpha: 0.9),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? Colors.black : AppColors.primary).withValues(alpha: isDark ? 0.6 : 0.18),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.sparkles, size: 14, color: accentColor),
                        const SizedBox(width: 6),
                        Text(
                          'QUICK ADD',
                          style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: accentColor),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: onClose,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentColor.withValues(alpha: 0.12),
                        ),
                        child: Icon(LucideIcons.x, size: 14, color: primaryTextColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: actions.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.95,
                  ),
                  itemBuilder: (context, index) {
                    final act = actions[index];
                    return StaggeredEntrance(
                      index: index,
                      stepDelayMs: 25,
                      child: BouncyTouchEffect(
                        pressedScale: 0.90,
                        onTap: () {
                          onClose();
                          if (onActionSelected != null) {
                            onActionSelected!(act['label'] as String);
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: itemBgColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? const Color(0xFF2E2E2E) : AppColors.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(act['icon'] as IconData, size: 20, color: accentColor),
                              const SizedBox(height: 6),
                              Text(
                                act['label'] as String,
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: primaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }
}
