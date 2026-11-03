import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/theme/app_colors.dart';
import '../state/sanctuary_state.dart';
import '../state/bin_state.dart';
import '../performance/sanctuary_motion_engine.dart';
import '../motion/motion.dart';
import 'stitch_logo_widget.dart';


/// Haute Horlogerie Sovereign Navigation Rail for Desktop & Workstations
/// Replaces mobile bottom dock on large displays with a permanent, ultra-premium sidebar.
class SanctuaryDesktopRail extends ConsumerStatefulWidget {
  final int activeIndex;
  final ValueChanged<int> onSelectModule;
  final bool isDarkMode;
  final ValueChanged<bool> onToggleDarkMode;
  final VoidCallback onLogout;

  const SanctuaryDesktopRail({
    super.key,
    required this.activeIndex,
    required this.onSelectModule,
    required this.isDarkMode,
    required this.onToggleDarkMode,
    required this.onLogout,
  });

  @override
  ConsumerState<SanctuaryDesktopRail> createState() => _SanctuaryDesktopRailState();
}

class _SanctuaryDesktopRailState extends ConsumerState<SanctuaryDesktopRail> with SingleTickerProviderStateMixin {
  int? _hoveredIndex;
  late AnimationController _gyroController;

  @override
  void initState() {
    super.initState();
    _gyroController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
  }

  @override
  void dispose() {
    _gyroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = widget.isDarkMode ? const Color(0xFF000000) : const Color(0xFFF7F3E9);
    final cardBgColor = widget.isDarkMode ? const Color(0xFF0A0A0A) : const Color(0xFFEDE5D6);
    final primaryTextColor = widget.isDarkMode ? AppColors.darkTextPrimary : AppColors.primary;
    final secondaryTextColor = widget.isDarkMode ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    final accentColor = widget.isDarkMode ? const Color(0xFFE8927C) : AppColors.secondary;

    final binCount = ref.watch(binProvider).length;
    final tasks = ref.watch(tasksProvider);
    final uncompletedTasks = tasks.where((t) => !t.isCompleted).length;
    final notes = ref.watch(notesProvider);
    final notesCount = notes.length;

    return Container(
      width: 270,
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(
          right: BorderSide(
            color: widget.isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFE2DAC8),
            width: 1.2,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Top Header: Stitch Monogram & Celestial Gyro
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
              child: Row(
                children: [
                  AnimatedBuilder(
                    animation: _gyroController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _gyroController.value * 2 * math.pi,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: accentColor.withValues(alpha: 0.6), width: 1.2),
                          ),
                          child: Center(
                            child: Icon(LucideIcons.sparkles, size: 14, color: accentColor),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: StitchLogoWidget(fontSize: 20, showMonogramN: false, showTagline: true),
                  ),
                ],
              ),
            ),

            // Live Curator Status Badge
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: widget.isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFDDD4C0),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF86CBB0),
                      boxShadow: [
                        BoxShadow(color: Color(0xFF86CBB0), blurRadius: 6, spreadRadius: 1),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ONLINE Â· SYNCED',
                      style: GoogleFonts.dmSans(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: const Color(0xFF86CBB0),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'PRO',
                      style: GoogleFonts.courierPrime(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Navigation Items List
            Expanded(
              child: ListView(
                physics: SanctuaryMotionEngine.fluidPhysics,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                children: [
                  _sectionHeader('WORKSPACE', secondaryTextColor),
                  _navTile(0, LucideIcons.home, 'Home', primaryTextColor, accentColor),
                  _navTile(1, LucideIcons.fileText, 'Notes', primaryTextColor, accentColor, badge: '$notesCount'),
                  _navTile(2, LucideIcons.checkSquare, 'Tasks', primaryTextColor, accentColor, badge: '$uncompletedTasks'),
                  _navTile(3, LucideIcons.calendar, 'Planner', primaryTextColor, accentColor),

                  const SizedBox(height: 12),
                  _sectionHeader('LIFESTYLE', secondaryTextColor),
                  _navTile(4, LucideIcons.shirt, 'Wardrobe', primaryTextColor, accentColor),
                  _navTile(5, LucideIcons.dollarSign, 'Expenses', primaryTextColor, accentColor),
                  _navTile(6, LucideIcons.plane, 'Travel', primaryTextColor, accentColor),
                  _navTile(7, LucideIcons.mic, 'Journal', primaryTextColor, accentColor),
                  _navTile(8, LucideIcons.layoutGrid, 'Moodboard', primaryTextColor, accentColor),
                  _navTile(9, LucideIcons.target, 'Habits', primaryTextColor, accentColor),
                  _navTile(10, LucideIcons.shoppingBag, 'Shopping', primaryTextColor, accentColor),

                  const SizedBox(height: 12),
                  _sectionHeader('SYSTEM', secondaryTextColor),
                  _navTile(13, LucideIcons.lock, 'Vault', primaryTextColor, accentColor, badge: 'AES'),
                  _navTile(14, LucideIcons.trash2, 'Bin', primaryTextColor, accentColor, badge: binCount > 0 ? '$binCount' : null),
                  _navTile(11, LucideIcons.settings, 'Settings', primaryTextColor, accentColor),
                  _navTile(12, LucideIcons.user, 'Profile', primaryTextColor, accentColor),
                ].revealed(style: RevealStyle.slideIn, distance: -14),
              ),
            ),

            // Bottom Rail: Theme Switcher & Logout
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFDDD4C0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        widget.isDarkMode ? LucideIcons.moon : LucideIcons.sun,
                        size: 16,
                        color: accentColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.isDarkMode ? 'Dark Mode' : 'Light Mode',
                        style: GoogleFonts.dmSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: widget.isDarkMode,
                    activeTrackColor: accentColor,
                    onChanged: (val) {
                      SanctuaryHapticEngine.escapementTick();
                      widget.onToggleDarkMode(val);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
      child: Text(
        text,
        style: GoogleFonts.dmSans(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.3,
          color: color,
        ),
      ),
    );
  }

  Widget _navTile(
    int index,
    IconData icon,
    String label,
    Color primaryColor,
    Color accentColor, {
    String? badge,
  }) {
    final isSelected = widget.activeIndex == index;
    final isHovered = _hoveredIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) {
        if (_hoveredIndex == index) setState(() => _hoveredIndex = null);
      },
      child: Pressable(
      pressedScale: 0.97,
      hoverLift: 0,
      child: InkWell(
      onTap: () {
        SanctuaryHapticEngine.escapementTick();
        widget.onSelectModule(index);
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Motion.silk,
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.16) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: accentColor.withValues(alpha: 0.45), width: 1.2) : null,
        ),
        child: Row(
          children: [
            // Gilt bead that grows on the active module.
            AnimatedContainer(
              duration: const Duration(milliseconds: 360),
              curve: Motion.settle,
              width: 3,
              height: isSelected ? 16 : (isHovered ? 6 : 0),
              margin: const EdgeInsets.only(right: 7),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [BoxShadow(color: accentColor.withValues(alpha: isSelected ? 0.6 : 0), blurRadius: 6)],
              ),
            ),
            AnimatedScale(
              scale: isSelected ? 1.14 : (isHovered ? 1.06 : 1.0),
              duration: const Duration(milliseconds: 420),
              curve: Motion.settle,
              child: Icon(icon, size: 16, color: isSelected ? accentColor : primaryColor.withValues(alpha: 0.8)),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Motion.silk,
              width: isHovered && !isSelected ? 14 : 10,
            ),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? accentColor : primaryColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? accentColor : accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.dmSans(
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : accentColor,
                  ),
                ),
              ),
          ],
        ),
      ),
      ),
      ),
    );
  }
}
