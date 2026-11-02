import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../app/theme/app_colors.dart';
import 'fluid_ui_effects.dart';
import 'radial_quick_add.dart';

class GlassNavigation extends StatefulWidget {
  final int activeIndex;
  final Function(int) onTabSelected;
  final VoidCallback onDedicatedAddTapped;
  final Function(String)? onQuickAction;

  const GlassNavigation({
    super.key,
    required this.activeIndex,
    required this.onTabSelected,
    required this.onDedicatedAddTapped,
    this.onQuickAction,
  });

  @override
  State<GlassNavigation> createState() => _GlassNavigationState();
}

class _GlassNavigationState extends State<GlassNavigation> with SingleTickerProviderStateMixin {
  late AnimationController _auraController;
  bool _quickMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _auraController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _auraController.dispose();
    super.dispose();
  }

  void _toggleQuickMenu() {
    setState(() {
      _quickMenuOpen = !_quickMenuOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final navBgColor = isDark ? const Color(0xFF000000).withValues(alpha: 0.95) : AppColors.surfaceContainerHigh.withValues(alpha: 0.90);
    final borderColor = isDark ? const Color(0xFF1E1E1E) : Colors.white.withValues(alpha: 0.7);
    final fabBgColor = isDark ? const Color(0xFFE8927C) : AppColors.secondary;
    final fabIconColor = isDark ? Colors.black : Colors.white;
    final selectedColor = isDark ? const Color(0xFFE8927C) : AppColors.secondary;

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Full Signature 8-Action Radial Quick Add Overlay
        RadialQuickAddMenu(
          isOpen: _quickMenuOpen,
          onClose: () => setState(() => _quickMenuOpen = false),
          onActionSelected: (action) {
            setState(() => _quickMenuOpen = false);
            if (widget.onQuickAction != null) {
              widget.onQuickAction!(action);
            } else {
              widget.onDedicatedAddTapped();
            }
          },
        ),

        // Main Glass Navigation Capsule Dock
        Positioned(
          bottom: 24,
          left: 16,
          right: 16,
          child: Center(
            child: AnimatedBuilder(
                  animation: _auraController,
                  builder: (context, child) {
                    return Container(
                      height: 72,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: navBgColor,
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          color: Color.lerp(borderColor, const Color(0xFFE8927C).withValues(alpha: 0.4), _auraController.value)!,
                          width: 1.6,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isDark ? const Color(0xFFE8927C) : AppColors.primary).withValues(alpha: isDark ? 0.18 : 0.12),
                            blurRadius: 32,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _navTab(context, 0, LucideIcons.home, 'Home', isDark, selectedColor),
                          _navTab(context, 1, LucideIcons.fileText, 'Notes', isDark, selectedColor),

                          // Central Kinetic FAB with Dual Pulse Ring & 45deg Morphing Icon
                          BouncyTouchEffect(
                            pressedScale: 0.88,
                            onTap: _toggleQuickMenu,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 58,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFE8927C).withValues(alpha: 0.3 + _auraController.value * 0.3),
                                        blurRadius: 16 + _auraController.value * 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: fabBgColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                                  ),
                                  child: AnimatedRotation(
                                    turns: _quickMenuOpen ? 0.125 : 0.0, // Rotates + to x when open
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOutBack,
                                    child: Icon(
                                      LucideIcons.plus,
                                      color: fabIconColor,
                                      size: 26,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          _navTab(context, 2, LucideIcons.checkSquare, 'Tasks', isDark, selectedColor),
                          _navTab(context, 3, LucideIcons.calendar, 'Planner', isDark, selectedColor),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      }

  Widget _navTab(BuildContext context, int index, IconData icon, String label, bool isDark, Color selectedColor) {
    final bool isSelected = widget.activeIndex == index;
    final unselectedColor = isDark ? AppColors.darkTextSecondary : AppColors.primary.withValues(alpha: 0.75);

    return BouncyTouchEffect(
      pressedScale: 0.94,
      onTap: () {
        if (_quickMenuOpen) setState(() => _quickMenuOpen = false);
        widget.onTabSelected(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor.withValues(alpha: isDark ? 0.22 : 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: isSelected
              ? Border.all(color: selectedColor.withValues(alpha: 0.5), width: 1.2)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? selectedColor : unselectedColor,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? selectedColor : unselectedColor,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: selectedColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: selectedColor.withValues(alpha: 0.9), blurRadius: 6, spreadRadius: 1),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
