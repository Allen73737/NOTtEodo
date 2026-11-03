import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme/app_colors.dart';
import '../state/sanctuary_state.dart';
import 'fluid_ui_effects.dart';

class SanctuaryBottomDock extends ConsumerStatefulWidget {
  final int activeIndex;
  final bool isQuickDialOpen;
  final VoidCallback onToggleQuickDial;
  final Function(int) onTabSelected;
  final VoidCallback onDedicatedAddTapped;
  final Function(String)? onQuickAction;
  final VoidCallback? onOpenSearch;
  final VoidCallback? onOpenAi;

  const SanctuaryBottomDock({
    super.key,
    required this.activeIndex,
    required this.isQuickDialOpen,
    required this.onToggleQuickDial,
    required this.onTabSelected,
    required this.onDedicatedAddTapped,
    this.onQuickAction,
    this.onOpenSearch,
    this.onOpenAi,
  });

  @override
  ConsumerState<SanctuaryBottomDock> createState() => _SanctuaryBottomDockState();
}

class _SanctuaryBottomDockState extends ConsumerState<SanctuaryBottomDock> with TickerProviderStateMixin {
  late AnimationController _auraController;
  late AnimationController _dockMorphController;
  late AnimationController _modeFlipController;

  bool _isCollapsed = false;
  bool _isLifeMode = false; // false = Workstation Space, true = Life & Vault Space
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _auraController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _dockMorphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _modeFlipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    // Auto-select mode based on active index
    if (widget.activeIndex >= 5 && widget.activeIndex != 11 && widget.activeIndex != 12) {
      _isLifeMode = true;
    }
  }

  @override
  void didUpdateWidget(covariant SanctuaryBottomDock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeIndex != oldWidget.activeIndex) {
      if (widget.activeIndex >= 5 && widget.activeIndex != 11 && widget.activeIndex != 12) {
        if (!_isLifeMode) {
          setState(() => _isLifeMode = true);
          _modeFlipController.forward();
        }
      } else if (widget.activeIndex <= 4) {
        if (_isLifeMode) {
          setState(() => _isLifeMode = false);
          _modeFlipController.reverse();
        }
      }
    }
  }

  @override
  void dispose() {
    _auraController.dispose();
    _dockMorphController.dispose();
    _modeFlipController.dispose();
    super.dispose();
  }

  void _toggleCollapse() {
    HapticFeedback.lightImpact();
    setState(() {
      _isCollapsed = !_isCollapsed;
      if (_isCollapsed) {
        _dockMorphController.forward();
      } else {
        _dockMorphController.reverse();
      }
    });
  }

  void _toggleUniverseMode() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isLifeMode = !_isLifeMode;
      if (_isLifeMode) {
        _modeFlipController.forward();
      } else {
        _modeFlipController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? const Color(0xFFE8927C) : AppColors.secondary;
    // Secondary dock ink from the app palette: sage on black, midnight teal on cream.
    final goldColor = isDark ? const Color(0xFF86CBB0) : AppColors.primary;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 460;

    // Riverpod Live Counts
    final tasks = ref.watch(tasksProvider);
    final uncompletedTasks = tasks.where((t) => !t.isCompleted).length;
    final notes = ref.watch(notesProvider);
    final notesCount = notes.length;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 12 : 16,
          vertical: isCompact ? 10 : 16,
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 1.0,
          child: AnimatedCrossFade(
            duration: const Duration(milliseconds: 350),
            firstCurve: Curves.easeOutCubic,
            secondCurve: Curves.easeInCubic,
            crossFadeState: _isCollapsed ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: _buildExpandedMonolithDock(
              isDark: isDark,
              accentColor: accentColor,
              goldColor: goldColor,
              uncompletedTasks: uncompletedTasks,
              notesCount: notesCount,
              isCompact: isCompact,
              screenWidth: screenWidth,
            ),
            secondChild: _buildDynamicIslandMonolith(isDark, accentColor, uncompletedTasks),
          ),
        ),
      ),
    );
  }

  /// 1. Substantial, Ultra-Creative Haute Horlogerie Monolith Dock (Theme Adaptive)
  Widget _buildExpandedMonolithDock({
    required bool isDark,
    required Color accentColor,
    required Color goldColor,
    required int uncompletedTasks,
    required int notesCount,
    required bool isCompact,
    required double screenWidth,
  }) {
    // Dock Item Sets
    final workstationItems = [
      _DockItem(0, LucideIcons.home, 'Home', null),
      _DockItem(1, LucideIcons.fileText, 'Notes', notesCount > 0 ? '$notesCount' : null),
      _DockItem(2, LucideIcons.checkSquare, 'Tasks', uncompletedTasks > 0 ? '$uncompletedTasks' : null),
      _DockItem(3, LucideIcons.calendar, 'Planner', null),
      if (screenWidth >= 520) _DockItem(4, LucideIcons.shirt, 'Wardrobe', null),
    ];

    final lifeItems = [
      _DockItem(5, LucideIcons.dollarSign, 'Expenses', null),
      _DockItem(6, LucideIcons.plane, 'Travel', 'Goa'),
      _DockItem(7, LucideIcons.mic, 'Journal', 'HQ'),
      _DockItem(8, LucideIcons.layoutGrid, 'Moodboard', '3D'),
      if (screenWidth >= 520) _DockItem(9, LucideIcons.target, 'Habits', '18d'),
      if (screenWidth >= 580) _DockItem(13, LucideIcons.lock, 'Vault', 'AES'),
    ];

    final currentItems = _isLifeMode ? lifeItems : workstationItems;

    final dockBackground = isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);

    final rimBorderColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE2DDD2);

    return Container(
      height: 72,
      constraints: BoxConstraints(maxWidth: isCompact ? 480 : 680),
      decoration: BoxDecoration(
        color: dockBackground,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
          color: rimBorderColor,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.65 : 0.08),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: accentColor.withValues(alpha: isDark ? 0.08 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 8 : 12,
          vertical: 6,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Chamber 1: Celestial Space Switcher Capsule (Work / Life Engine)
              _buildCelestialSpaceCapsule(
                isDark: isDark,
                accentColor: accentColor,
                goldColor: goldColor,
                isCompact: isCompact,
              ),

              SizedBox(width: isCompact ? 4 : 6),
              _buildLaserDivider(isDark),
              SizedBox(width: isCompact ? 4 : 6),

              // Chamber 2: Substantial Kinetic Module Deck (Spring-Magnified Complications)
              ...currentItems.map((item) {
                return _buildSubstantialModuleTab(
                  item: item,
                  isDark: isDark,
                  accentColor: accentColor,
                  goldColor: goldColor,
                  isCompact: isCompact,
                );
              }),

              SizedBox(width: isCompact ? 4 : 6),

              // Chamber 3: The Crown Jewel Catalyst FAB (Haute Horlogerie Gyroscope)
              _buildHauteHorlogerieCatalystFab(
                isDark: isDark,
                accentColor: accentColor,
                goldColor: goldColor,
                auraGlow: 0.0,
                isCompact: isCompact,
              ),

              SizedBox(width: isCompact ? 4 : 6),

              // Chamber 4: Dynamic Control Pill (Search / Island Collapse)
              _buildLaserDivider(isDark),
              SizedBox(width: isCompact ? 4 : 6),
              _buildDynamicControlCapsule(
                isDark: isDark,
                accentColor: accentColor,
                isCompact: isCompact,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Chamber 1: The Celestial Space Capsule Selector (Work vs Life)
  Widget _buildCelestialSpaceCapsule({
    required bool isDark,
    required Color accentColor,
    required Color goldColor,
    required bool isCompact,
  }) {
    return BouncyTouchEffect(
      pressedScale: 0.88,
      onTap: _toggleUniverseMode,
      child: Tooltip(
        message: _isLifeMode ? 'Switch to Workspace' : 'Switch to Lifestyle',
        child: Container(
          width: isCompact ? 52 : 58,
          height: 58,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF2ECE4),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark
                  ? Color.lerp(const Color(0xFF222222), accentColor.withValues(alpha: 0.6), 0.5)!
                  : Color.lerp(const Color(0xFFE0D7CB), accentColor.withValues(alpha: 0.5), 0.5)!,
              width: 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: isDark ? 0.15 : 0.08),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Dynamic Mode Micro-LED Indicator
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isLifeMode ? goldColor : accentColor,
                  boxShadow: [
                    BoxShadow(
                      color: (_isLifeMode ? goldColor : accentColor).withValues(alpha: 0.9),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),

              // Orbiting Mode Icon with 3D Rotation Animation
              RotationTransition(
                turns: _modeFlipController,
                child: Icon(
                  _isLifeMode ? LucideIcons.sparkles : LucideIcons.briefcase,
                  size: 20,
                  color: _isLifeMode ? goldColor : accentColor,
                ),
              ),
              const SizedBox(height: 3),

              // Micro Status Text
              Text(
                _isLifeMode ? 'LIFE' : 'WORK',
                style: GoogleFonts.dmSans(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: isDark ? Colors.white : AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Chamber 2: Substantial, Tactile Primary Module Tab
  Widget _buildSubstantialModuleTab({
    required _DockItem item,
    required bool isDark,
    required Color accentColor,
    required Color goldColor,
    required bool isCompact,
  }) {
    final isSelected = widget.activeIndex == item.index;
    final isHovered = _hoveredIndex == item.index;
    final scale = isHovered ? 1.18 : (isSelected ? 1.08 : 1.0);
    final yOffset = isHovered ? -4.0 : (isSelected ? -2.0 : 0.0);

    final itemColor = isSelected
        ? accentColor
        : (isDark
            ? (isHovered ? Colors.white : Colors.white.withValues(alpha: 0.72))
            : (isHovered ? AppColors.primary : const Color(0xFF2C2A29).withValues(alpha: 0.82)));

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = item.index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          if (widget.isQuickDialOpen) widget.onToggleQuickDial();
          widget.onTabSelected(item.index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, yOffset, 0),
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            child: Container(
              width: isCompact ? 50 : 56,
              height: 58,
              margin: EdgeInsets.symmetric(horizontal: isCompact ? 2 : 3),
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                // Recessed Obsidian or Opalescent Cup for Active Tab
                color: isSelected
                    ? accentColor.withValues(alpha: isDark ? 0.18 : 0.14)
                    : (isHovered
                        ? (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05))
                        : Colors.transparent),
                borderRadius: BorderRadius.circular(22),
                border: isSelected
                    ? Border.all(color: accentColor.withValues(alpha: 0.75), width: 1.5)
                    : (isHovered ? Border.all(color: isDark ? Colors.white24 : Colors.black12, width: 1) : null),
                boxShadow: [
                  BoxShadow(
                    color: isSelected ? accentColor.withValues(alpha: isDark ? 0.30 : 0.18) : Colors.transparent,
                    blurRadius: isSelected ? 14 : 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Scale down rather than overflow under large accessibility text.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Substantial, Prominent Icon
                        Icon(item.icon, size: isCompact ? 22 : 24, color: itemColor),
                        const SizedBox(height: 3),

                        // Rich DM Sans Typography Label
                        Text(
                          item.label,
                          maxLines: 1,
                          softWrap: false,
                          style: GoogleFonts.dmSans(
                            fontSize: 9.5,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            letterSpacing: 0.2,
                            color: isSelected ? accentColor : (isDark ? Colors.white70 : const Color(0xFF3D3A37)),
                          ),
                        ),

                        // Liquid Neon Mercury Underglow Pill
                        if (isSelected) ...[
                          const SizedBox(height: 2),
                          Container(
                            width: 16,
                            height: 3,
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor,
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 5),
                        ],
                      ],
                    ),
                  ),

                  // Dynamic Haute Horlogerie Notification Complication (Wax-Seal Pip)
                  if (item.badge != null)
                    Positioned(
                      top: 0,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: isSelected ? goldColor : accentColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isDark ? Colors.black : Colors.white, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: (isSelected ? goldColor : accentColor).withValues(alpha: 0.6),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Text(
                          item.badge!,
                          style: GoogleFonts.dmSans(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Chamber 3: The Crown Jewel Catalyst FAB (Haute Horlogerie Gyroscope Jewel)
  Widget _buildHauteHorlogerieCatalystFab({
    required bool isDark,
    required Color accentColor,
    required Color goldColor,
    required double auraGlow,
    required bool isCompact,
  }) {
    final fabDiameter = isCompact ? 56.0 : 62.0;
    final innerDiameter = isCompact ? 44.0 : 50.0;
    final iconSize = isCompact ? 24.0 : 26.0;

    return BouncyTouchEffect(
      pressedScale: 0.88,
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onToggleQuickDial();
      },
      child: Tooltip(
        message: 'Master Quick Creation Dial (Tap) / Celestial Oracle (Long Press)',
        child: GestureDetector(
          onLongPress: () {
            HapticFeedback.heavyImpact();
            if (widget.onOpenAi != null) {
              widget.onOpenAi!();
            } else {
              widget.onDedicatedAddTapped();
            }
          },
          child: Container(
            width: fabDiameter,
            height: 58,
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // 1. Pulsing Celestial Atmospheric Aura
                Container(
                  width: fabDiameter,
                  height: fabDiameter,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.35 + auraGlow * 0.35),
                        blurRadius: 24 + auraGlow * 12,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: goldColor.withValues(alpha: 0.20 + auraGlow * 0.15),
                        blurRadius: 36,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),

                // 2. Slow Counter-Rotating Chromatic Bezel (Astronomical Sweep Ring)
                Transform.rotate(
                  angle: _auraController.value * math.pi * 2,
                  child: Container(
                    width: fabDiameter - 2,
                    height: fabDiameter - 2,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          Color(0xFFE8927C), // Coral Rose
                          Color(0xFF86CBB0), // Sage Jade
                          Color(0xFF16282C), // Midnight Teal
                          Color(0xFF86CBB0), // Sage Jade
                          Color(0xFFE8927C), // Loop
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. Precision Disc Core
                Container(
                  width: innerDiameter,
                  height: innerDiameter,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? const Color(0xFF000000) : const Color(0xFF1C1917), // Deep Obsidian contrast disc
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.40)
                          : AppColors.secondary.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.8 : 0.25),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: AnimatedRotation(
                    turns: widget.isQuickDialOpen ? 0.125 : 0.0,
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutBack,
                    child: Center(
                      child: Icon(
                        widget.isQuickDialOpen ? LucideIcons.x : LucideIcons.plus,
                        color: widget.isQuickDialOpen ? Colors.white : (isDark ? accentColor : const Color(0xFFFAF8F5)),
                        size: iconSize,
                      ),
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

  /// Chamber 4: Dynamic Control Capsule (Search & Island Minimize)
  Widget _buildDynamicControlCapsule({
    required bool isDark,
    required Color accentColor,
    required bool isCompact,
  }) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF2ECE4),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF222222) : const Color(0xFFE0D7CB),
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Instant Search Tool (on tablets/desktops where screen width permits)
          if (!isCompact)
            BouncyTouchEffect(
              pressedScale: 0.85,
              onTap: widget.onOpenSearch ?? () {},
              child: Tooltip(
                message: 'Search Sanctuary (Ctrl + K)',
                child: Container(
                  width: 38,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.transparent,
                  ),
                  child: Icon(
                    LucideIcons.search,
                    size: 17,
                    color: isDark ? Colors.white70 : const Color(0xFF2C2A29),
                  ),
                ),
              ),
            ),

          // Dynamic Island Collapse Toggle
          BouncyTouchEffect(
            pressedScale: 0.85,
            onTap: _toggleCollapse,
            child: Tooltip(
              message: 'Collapse to Dynamic Island Monolith',
              child: Container(
                width: isCompact ? 34 : 38,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
                ),
                child: Icon(LucideIcons.minimize2, size: 16, color: accentColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Collapsed Dynamic Island Monolith Capsule (Theme Adaptive)
  Widget _buildDynamicIslandMonolith(bool isDark, Color accentColor, int uncompletedTasks) {
    return BouncyTouchEffect(
      pressedScale: 0.94,
      onTap: _toggleCollapse,
      child: Tooltip(
        message: 'Tap to Expand Sanctuary Monolith Deck',
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF000000).withValues(alpha: 0.96)
                : const Color(0xFFFAF8F5).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isDark ? accentColor.withValues(alpha: 0.85) : const Color(0xFFE2DDD2),
              width: 1.6,
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? accentColor : AppColors.primary).withValues(alpha: isDark ? 0.40 : 0.14),
                blurRadius: 28,
                offset: const Offset(0, 8),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pulsing Heartbeat Emerald Dot
              Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF86CBB0),
                  boxShadow: [
                    BoxShadow(color: Color(0xFF86CBB0), blurRadius: 10, spreadRadius: 2),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Title & Complication Status
              Text(
                'SANCTUARY ORBIT',
                style: GoogleFonts.dmSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: isDark ? Colors.white : AppColors.primary,
                ),
              ),
              if (uncompletedTasks > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accentColor.withValues(alpha: 0.6)),
                  ),
                  child: Text(
                    '$uncompletedTasks PENDING',
                    style: GoogleFonts.dmSans(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      color: isDark ? accentColor : AppColors.primary,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 12),

              // Expand Glyph
              Icon(LucideIcons.maximize2, size: 16, color: accentColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLaserDivider(bool isDark) {
    return Container(
      width: 1.2,
      height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            isDark ? const Color(0xFF333333) : const Color(0xFFE2D9CD),
            isDark ? Colors.white.withValues(alpha: 0.2) : AppColors.secondary.withValues(alpha: 0.4),
            isDark ? const Color(0xFF333333) : const Color(0xFFE2D9CD),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _DockItem {
  final int index;
  final IconData icon;
  final String label;
  final String? badge;

  _DockItem(this.index, this.icon, this.label, this.badge);
}
