import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme/app_colors.dart';
import '../state/sanctuary_state.dart';
import '../state/bin_state.dart';
import '../brand/notteodo_app_icon.dart';
import 'fluid_ui_effects.dart';
import '../motion/motion.dart';
import '../state/app_settings.dart';
import '../services/sanctuary_supabase_service.dart';
import 'curator_identity_dialog.dart';
import 'curator_feedback_dialog.dart';
import 'sanctuary_avatar_catalog.dart';
import 'streak_flame_evolution.dart';
import '../performance/sanctuary_motion_engine.dart';
import 'focus_dial_modal.dart';
import 'app_feature_walkthrough.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';


class AppDrawer extends ConsumerStatefulWidget {
  final int activeIndex;
  final Function(int) onSelectModule;
  final bool isDarkMode;
  final ValueChanged<bool> onToggleDarkMode;
  final VoidCallback? onLogout;
  final VoidCallback? onOpenAdminDashboard;

  const AppDrawer({
    super.key,
    required this.activeIndex,
    required this.onSelectModule,
    required this.isDarkMode,
    required this.onToggleDarkMode,
    this.onLogout,
    this.onOpenAdminDashboard,
  });

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _pulseController;
  late AnimationController _spinController;
  late AnimationController _sheenController;
  bool _isCardExpanded = false;

  Future<void> _showQuickLocationDialog(BuildContext context) async {
    HapticFeedback.lightImpact();
    final currentLoc = ref.read(appSettingsProvider).userLocation ?? '';
    final ctrl = TextEditingController(text: currentLoc);
    final isDark = widget.isDarkMode;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    const terracotta = Color(0xFFD9725B);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF141210) : const Color(0xFFFFFDF8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: terracotta.withValues(alpha: 0.3)),
        ),
        title: Row(
          children: [
            const Icon(LucideIcons.mapPin, size: 20, color: terracotta),
            const SizedBox(width: 8),
            Text(
              'Sanctuary Location',
              style: GoogleFonts.bodoniModa(fontSize: 18, fontWeight: FontWeight.bold, color: primaryTextColor),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Optional: Personalize your daily briefing, weather, and workspace records.',
              style: GoogleFonts.dmSans(fontSize: 12, color: subtextColor),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              style: GoogleFonts.dmSans(fontSize: 14, color: primaryTextColor),
              decoration: InputDecoration(
                hintText: 'e.g. Kyoto, Japan or Zurich, CH',
                hintStyle: GoogleFonts.dmSans(fontSize: 13, color: subtextColor.withValues(alpha: 0.6)),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E1A16) : const Color(0xFFF3ECE0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: terracotta.withValues(alpha: 0.4)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: terracotta, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (currentLoc.isNotEmpty)
            TextButton(
              onPressed: () {
                ref.read(appSettingsProvider.notifier).setUserLocation(null);
                Navigator.pop(ctx);
              },
              child: Text('Clear', style: GoogleFonts.dmSans(color: subtextColor, fontSize: 13)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.dmSans(color: subtextColor, fontSize: 13)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: terracotta,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final text = ctrl.text.trim();
              ref.read(appSettingsProvider.notifier).setUserLocation(text.isEmpty ? null : text);
              Navigator.pop(ctx);
            },
            child: Text('Save', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );

    _sheenController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    _spinController.dispose();
    _sheenController.dispose();
    super.dispose();
  }

  Animation<double> _staggeredAnimation(double begin, double end) {
    return CurvedAnimation(
      parent: _entranceController,
      curve: Interval(begin, end, curve: Curves.easeOutBack),
    );
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = widget.isDarkMode ? const Color(0xFF000000) : const Color(0xFFFAF7F0);
    final cardBgColor = widget.isDarkMode ? const Color(0xFF060606) : const Color(0xFFF3EDE2);
    final primaryTextColor = widget.isDarkMode ? AppColors.darkTextPrimary : AppColors.primary;
    final secondaryTextColor = widget.isDarkMode ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    final accentColor = widget.isDarkMode ? const Color(0xFFE8927C) : AppColors.secondary;
    final statAccentColor = accentColor;

    // Riverpod Live Counts
    final tasks = ref.watch(tasksProvider);
    final uncompletedTasks = tasks.where((t) => !t.isCompleted).length;
    final notes = ref.watch(notesProvider);
    final notesCount = notes.length;

    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        final progress = _entranceController.value;
        // 3D Perspective Curved Unfolding In-Transition
        final angle = (1.0 - progress) * 0.12;

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(-angle),
          alignment: Alignment.centerLeft,
          child: Drawer(
            backgroundColor: Colors.transparent,
            elevation: 0,
            width: 335,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(38),
                bottomRight: Radius.circular(38),
              ),
              child: Container(
                  decoration: edBox(
                    color: surfaceColor.withValues(alpha: widget.isDarkMode ? 0.96 : 0.92),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(38),
                      bottomRight: Radius.circular(38),
                    ),
                    border: Border(
                      right: BorderSide(
                        color: widget.isDarkMode
                            ? accentColor.withValues(alpha: 0.35 + _pulseController.value * 0.25)
                            : Colors.black12,
                        width: 1.8,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (widget.isDarkMode ? accentColor : Colors.black).withValues(alpha: widget.isDarkMode ? 0.25 : 0.15),
                        blurRadius: 40,
                        offset: const Offset(10, 0),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        // 1. Drawer Header with Monogram & Kinetic Close
                        ScaleTransition(
                          scale: _staggeredAnimation(0.0, 0.4),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const NotteodoAppIcon(size: 32, withGlow: false),
                                BouncyTouchEffect(
                                  pressedScale: 0.85,
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.pop(context);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: edBox(
                                      color: accentColor.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                                    ),
                                    child: Icon(LucideIcons.x, color: primaryTextColor, size: 18),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Divider(height: 1, color: widget.isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFE5DFC9)),

                        // 2. Curator Profile Command Card with Revolving Celestial Gyroscope
                        ScaleTransition(
                          scale: _staggeredAnimation(0.12, 0.52),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(22),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(22),
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  setState(() => _isCardExpanded = !_isCardExpanded);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: edBox(
                                    color: cardBgColor,
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: _isCardExpanded
                                          ? accentColor.withValues(alpha: 0.7)
                                          : accentColor.withValues(alpha: 0.4),
                                      width: _isCardExpanded ? 1.8 : 1.4,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: accentColor.withValues(alpha: _isCardExpanded ? 0.22 : 0.12),
                                        blurRadius: _isCardExpanded ? 24 : 18,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          // Multi-Ring Spinning Celestial Gyroscope
                                          Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              AnimatedBuilder(
                                                animation: _spinController,
                                                builder: (context, child) {
                                                  return Transform.rotate(
                                                    angle: _spinController.value * 2 * math.pi,
                                                    child: Container(
                                                      width: 52,
                                                      height: 52,
                                                      decoration: edBox(
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                          color: accentColor.withValues(alpha: 0.6),
                                                          width: 1.2,
                                                        ),
                                                      ),
                                                      child: Align(
                                                        alignment: Alignment.topCenter,
                                                        child: Icon(LucideIcons.sparkles, size: 11, color: statAccentColor),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                              AnimatedBuilder(
                                                animation: _pulseController,
                                                builder: (context, child) {
                                                  return GestureDetector(
                                                    onTap: () {
                                                      HapticFeedback.selectionClick();
                                                      SanctuaryAvatarCatalog.showSelector(context, ref);
                                                    },
                                                    child: SanctuaryActiveAvatarView(
                                                      settings: ref.watch(appSettingsProvider),
                                                      size: 42,
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  width: 7,
                                                  height: 7,
                                                  decoration: edBox(
                                                    shape: BoxShape.circle,
                                                    color: const Color(0xFF8FA878),
                                                    boxShadow: [
                                                      const BoxShadow(color: Color(0xFF8FA878), blurRadius: 6, spreadRadius: 1),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Flexible(
                                                  child: Text(
                                                    'ONLINE · SYNCED',
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: GoogleFonts.dmSans(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      letterSpacing: 1.0,
                                                      color: const Color(0xFF8FA878),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              ref.watch(appSettingsProvider.select((s) => s.displayName)).isEmpty
                                                  ? 'Your workspace'
                                                  : ref.watch(appSettingsProvider.select((s) => s.displayName)),
                                              style: GoogleFonts.bodoniModa(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: primaryTextColor,
                                              ),
                                            ),
                                            Builder(
                                              builder: (context) {
                                                final loc = ref.watch(appSettingsProvider.select((s) => s.userLocation));
                                                final hasLoc = loc != null && loc.trim().isNotEmpty;
                                                return Row(
                                                  children: [
                                                    if (hasLoc) ...[
                                                      Icon(LucideIcons.mapPin, size: 10, color: statAccentColor),
                                                      const SizedBox(width: 3),
                                                    ],
                                                    Expanded(
                                                      child: Text(
                                                        hasLoc ? loc : 'Saved on this device',
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: GoogleFonts.dmSans(
                                                          fontSize: 11,
                                                          color: secondaryTextColor,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      AnimatedRotation(
                                        turns: _isCardExpanded ? 0.25 : 0.0,
                                        duration: const Duration(milliseconds: 280),
                                        curve: Curves.easeOutCubic,
                                        child: Icon(
                                          LucideIcons.chevronRight,
                                          size: 16,
                                          color: accentColor.withValues(alpha: 0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Live Sanctuary Micro-Metrics Bar
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: edBox(
                                      color: widget.isDarkMode ? const Color(0xFF000000) : Colors.white.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.black12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildMicroStat('$notesCount', 'Notes', accentColor),
                                        _buildVerticalDivider(widget.isDarkMode),
                                        _buildMicroStat('$uncompletedTasks', 'Tasks', statAccentColor),
                                        _buildVerticalDivider(widget.isDarkMode),
                                        InkWell(
                                          borderRadius: BorderRadius.circular(8),
                                          onTap: () {
                                            SanctuaryHapticEngine.selection();
                                            StreakFlameEvolutionSheet.show(context, ref.read(appSettingsProvider).activeStreak);
                                          },
                                          child: _buildStreakMicroStat(ref.watch(appSettingsProvider).activeStreak),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Expanded Creative Animated Section
                                  AnimatedSize(
                                    duration: const Duration(milliseconds: 320),
                                    curve: Curves.easeInOutCubic,
                                    child: _isCardExpanded
                                        ? Padding(
                                            padding: const EdgeInsets.only(top: 14),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Divider(
                                                  height: 1,
                                                  color: widget.isDarkMode
                                                      ? const Color(0xFF221E1A)
                                                      : const Color(0xFFE5DDD0),
                                                ),
                                                const SizedBox(height: 12),
                                                // Active Archetype Avatar & Switcher
                                                Consumer(
                                                  builder: (context, ref, _) {
                                                    final settings = ref.watch(appSettingsProvider);
                                                    final preset = settings.avatarPreset != null
                                                        ? SanctuaryAvatarCatalog.findById(settings.avatarPreset)
                                                        : null;
                                                    final archetypeTitle = preset?.title ?? 'Personal Workspace';
                                                    final archetypeSub = preset?.subtitle ?? 'Your personal focus space';

                                                    return Container(
                                                      padding: const EdgeInsets.all(10),
                                                      decoration: edBox(
                                                        color: widget.isDarkMode
                                                            ? const Color(0xFF100E0C)
                                                            : const Color(0xFFEDE4D5),
                                                        borderRadius: BorderRadius.circular(14),
                                                        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
                                                      ),
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              SanctuaryActiveAvatarView(
                                                                settings: settings,
                                                                size: 38,
                                                              ),
                                                              const SizedBox(width: 10),
                                                              Expanded(
                                                                child: Column(
                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                  children: [
                                                                    Text(
                                                                      archetypeTitle,
                                                                      style: GoogleFonts.bodoniModa(
                                                                        fontSize: 13.5,
                                                                        fontWeight: FontWeight.bold,
                                                                        color: primaryTextColor,
                                                                      ),
                                                                    ),
                                                                    Text(
                                                                      archetypeSub,
                                                                      maxLines: 1,
                                                                      overflow: TextOverflow.ellipsis,
                                                                      style: GoogleFonts.dmSans(
                                                                        fontSize: 11,
                                                                        color: secondaryTextColor,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              InkWell(
                                                                borderRadius: BorderRadius.circular(8),
                                                                onTap: () {
                                                                  HapticFeedback.selectionClick();
                                                                  SanctuaryAvatarCatalog.showSelector(context, ref);
                                                                },
                                                                child: Container(
                                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                                  decoration: edBox(
                                                                    color: accentColor.withValues(alpha: 0.2),
                                                                    borderRadius: BorderRadius.circular(8),
                                                                    border: Border.all(color: accentColor.withValues(alpha: 0.4)),
                                                                  ),
                                                                  child: Row(
                                                                    mainAxisSize: MainAxisSize.min,
                                                                    children: [
                                                                      Icon(LucideIcons.sparkles, size: 10, color: accentColor),
                                                                      const SizedBox(width: 4),
                                                                      Text(
                                                                        'Archetype',
                                                                        style: GoogleFonts.dmSans(
                                                                          fontSize: 11.5,
                                                                          fontWeight: FontWeight.bold,
                                                                          color: accentColor,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(height: 10),
                                                          // Location Row (Optional Location)
                                                          Row(
                                                            children: [
                                                              Icon(LucideIcons.mapPin, size: 12, color: statAccentColor),
                                                              const SizedBox(width: 6),
                                                              Expanded(
                                                                child: Text(
                                                                  settings.userLocation != null && settings.userLocation!.trim().isNotEmpty
                                                                      ? settings.userLocation!
                                                                      : 'Location not set (optional)',
                                                                  maxLines: 1,
                                                                  overflow: TextOverflow.ellipsis,
                                                                  style: GoogleFonts.dmSans(
                                                                    fontSize: 11,
                                                                    color: secondaryTextColor,
                                                                  ),
                                                                ),
                                                              ),
                                                              InkWell(
                                                                onTap: () => _showQuickLocationDialog(context),
                                                                child: Padding(
                                                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                                  child: Text(
                                                                    settings.userLocation != null && settings.userLocation!.trim().isNotEmpty
                                                                        ? 'Edit'
                                                                        : '+ Add',
                                                                    style: GoogleFonts.dmSans(
                                                                      fontSize: 11.5,
                                                                      fontWeight: FontWeight.bold,
                                                                      color: statAccentColor,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(height: 8),
                                                          // Live Real Streak & Protection Status
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                                            decoration: edBox(
                                                              color: accentColor.withValues(alpha: 0.1),
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                            child: Row(
                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                              children: [
                                                                Text(
                                                                  '🔥 Day ${settings.activeStreak > 0 ? settings.activeStreak : 1} Streak',
                                                                  style: GoogleFonts.dmSans(
                                                                    fontSize: 11.5,
                                                                    fontWeight: FontWeight.bold,
                                                                    color: accentColor,
                                                                  ),
                                                                ),
                                                                Text(
                                                                  '🛡️ ${settings.streakFreezesCount} Freezes remaining',
                                                                  style: GoogleFonts.dmSans(
                                                                    fontSize: 11,
                                                                    color: secondaryTextColor,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          const SizedBox(height: 10),
                                                          // Full Curator Passport CTA
                                                          InkWell(
                                                            borderRadius: BorderRadius.circular(10),
                                                            onTap: () {
                                                              HapticFeedback.selectionClick();
                                                              CuratorIdentityDialog.show(context);
                                                            },
                                                            child: Container(
                                                              width: double.infinity,
                                                              padding: const EdgeInsets.symmetric(vertical: 7),
                                                              alignment: Alignment.center,
                                                              decoration: edBox(
                                                                border: Border.all(color: accentColor.withValues(alpha: 0.35)),
                                                                borderRadius: BorderRadius.circular(10),
                                                              ),
                                                              child: Row(
                                                                mainAxisAlignment: MainAxisAlignment.center,
                                                                children: [
                                                                  Icon(LucideIcons.idCard, size: 12, color: accentColor),
                                                                  const SizedBox(width: 6),
                                                                  Text(
                                                                    'Open Full Curator Passport',
                                                                    style: GoogleFonts.dmSans(
                                                                      fontSize: 11,
                                                                      fontWeight: FontWeight.bold,
                                                                      color: accentColor,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(height: 6),
                                                          // Feedback & Suggestions Action
                                                          InkWell(
                                                            borderRadius: BorderRadius.circular(10),
                                                            onTap: () {
                                                              HapticFeedback.selectionClick();
                                                              Navigator.pop(context);
                                                              CuratorFeedbackDialog.show(context);
                                                            },
                                                            child: Container(
                                                              width: double.infinity,
                                                              padding: const EdgeInsets.symmetric(vertical: 7),
                                                              alignment: Alignment.center,
                                                              decoration: edBox(
                                                                color: accentColor.withValues(alpha: 0.12),
                                                                border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                                                                borderRadius: BorderRadius.circular(10),
                                                              ),
                                                              child: Row(
                                                                mainAxisAlignment: MainAxisAlignment.center,
                                                                children: [
                                                                  Icon(LucideIcons.messageSquarePlus, size: 12, color: accentColor),
                                                                  const SizedBox(width: 6),
                                                                  Text(
                                                                    'Feedback & Feature Suggestions',
                                                                    style: GoogleFonts.dmSans(
                                                                      fontSize: 11,
                                                                      fontWeight: FontWeight.bold,
                                                                      color: accentColor,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                        // 3. Staggered Entrance Navigation Modules List
                        Expanded(
                          child: ListView(
                            cacheExtent: 1500,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            children: [
                              _staggeredWrapper(
                                0.22, 0.62,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _sectionHeader('PROFILE', secondaryTextColor),
                                    _drawerItem(context, 12, LucideIcons.user, 'Profile', primaryTextColor, accentColor),
                                    _drawerActionItem(
                                      context,
                                      LucideIcons.messageSquarePlus,
                                      'Feedback & Ideas',
                                      primaryTextColor,
                                      accentColor,
                                      badgeText: 'Share',
                                      onTap: () {
                                        Navigator.pop(context);
                                        CuratorFeedbackDialog.show(context);
                                      },
                                    ),
                                  ].revealed(style: RevealStyle.slideIn, distance: -16),
                                ),
                              ),
                              const SizedBox(height: 10),

                              _staggeredWrapper(
                                0.32, 0.72,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _sectionHeader('WORKSPACE', secondaryTextColor),
                                    _drawerItem(context, 0, LucideIcons.home, 'Home', primaryTextColor, accentColor),
                                    _drawerItem(context, 1, LucideIcons.fileText, 'Notes', primaryTextColor, accentColor, badgeText: '$notesCount'),
                                    _drawerItem(context, 2, LucideIcons.checkSquare, 'Tasks', primaryTextColor, accentColor, badgeText: '$uncompletedTasks'),
                                    _drawerItem(context, 3, LucideIcons.calendar, 'Planner', primaryTextColor, accentColor),
                                    _drawerActionItem(
                                      context,
                                      LucideIcons.timer,
                                      'Focus Dial',
                                      primaryTextColor,
                                      accentColor,
                                      badgeText: 'Timer',
                                      onTap: () {
                                        Navigator.pop(context);
                                        FocusDialModal.show(context);
                                      },
                                    ),
                                  ].revealed(style: RevealStyle.slideIn, distance: -16),
                                ),
                              ),
                              const SizedBox(height: 10),

                              _staggeredWrapper(
                                0.42, 0.82,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _sectionHeader('LIFESTYLE', secondaryTextColor),
                                    _drawerItem(context, 4, LucideIcons.shirt, 'Wardrobe', primaryTextColor, accentColor),
                                    _drawerItem(context, 5, LucideIcons.dollarSign, 'Expenses', primaryTextColor, accentColor),
                                    _drawerItem(context, 6, LucideIcons.plane, 'Travel', primaryTextColor, accentColor),
                                    _drawerItem(context, 7, LucideIcons.mic, 'Journal', primaryTextColor, accentColor),
                                    _drawerItem(context, 8, LucideIcons.layoutGrid, 'Moodboard', primaryTextColor, accentColor),
                                    _drawerItem(context, 9, LucideIcons.target, 'Habits', primaryTextColor, accentColor),
                                    _drawerItem(context, 10, LucideIcons.shoppingBag, 'Shopping', primaryTextColor, accentColor),
                                  ].revealed(style: RevealStyle.slideIn, distance: -16),
                                ),
                              ),
                              const SizedBox(height: 10),

                              _staggeredWrapper(
                                0.52, 0.92,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _sectionHeader('SYSTEM & SANCTUARY', secondaryTextColor),
                                    _drawerActionItem(
                                      context,
                                      LucideIcons.compass,
                                      'Sanctuary Tour',
                                      primaryTextColor,
                                      accentColor,
                                      badgeText: 'GUIDE',
                                      onTap: () {
                                        Navigator.pop(context);
                                        AppFeatureWalkthroughModal.show(
                                          context,
                                          onNavigateModule: widget.onSelectModule,
                                        );
                                      },
                                    ),
                                    _drawerItem(context, 13, LucideIcons.lock, 'Vault', primaryTextColor, accentColor, badgeText: 'AES-256'),
                                    _drawerItem(context, 14, LucideIcons.trash2, 'Bin', primaryTextColor, accentColor,
                                        badgeText: ref.watch(binProvider).isEmpty ? null : '${ref.watch(binProvider).length}'),
                                    _drawerItem(context, 11, LucideIcons.settings, 'Settings', primaryTextColor, accentColor),
                                  ].revealed(style: RevealStyle.slideIn, distance: -16),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 4. Bottom Pitch Black OLED Theme Toggle & Logout Card
                        ScaleTransition(
                          scale: _staggeredAnimation(0.60, 1.0),
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(14, 6, 14, 14),
                            padding: const EdgeInsets.all(12),
                            decoration: edBox(
                              color: cardBgColor,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: widget.isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFE0D8C8)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Icon(
                                            widget.isDarkMode ? LucideIcons.moon : LucideIcons.sun,
                                            size: 18,
                                            color: accentColor,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  widget.isDarkMode ? 'Dark Mode' : 'Light Mode',
                                                  style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.bold, color: primaryTextColor),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  widget.isDarkMode ? 'Pitch black surface' : 'Warm daylight canvas',
                                                  style: GoogleFonts.dmSans(fontSize: 11, color: secondaryTextColor),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Switch(
                                      value: widget.isDarkMode,
                                      activeTrackColor: accentColor,
                                      onChanged: (val) {
                                        HapticFeedback.selectionClick();
                                        widget.onToggleDarkMode(val);
                                      },
                                    ),
                                  ],
                                ),
                                if (widget.onOpenAdminDashboard != null && ref.watch(appSettingsProvider).isAdminSession && SanctuarySupabaseService().currentUser != null) ...[
                                  const SizedBox(height: 8),
                                  BouncyTouchEffect(
                                    pressedScale: 0.95,
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      Navigator.pop(context);
                                      widget.onOpenAdminDashboard!();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: edBox(
                                        color: accentColor.withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: accentColor.withValues(alpha: 0.4), width: 1.2),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(LucideIcons.crown, size: 15, color: accentColor),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Admin Dashboard',
                                            style: GoogleFonts.spaceGrotesk(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: accentColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                                if (widget.onLogout != null) ...[
                                  const SizedBox(height: 8),
                                  Divider(height: 1, color: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.black12),
                                  const SizedBox(height: 8),
                                  BouncyTouchEffect(
                                    pressedScale: 0.95,
                                    onTap: () {
                                      HapticFeedback.mediumImpact();
                                      Navigator.pop(context);
                                      widget.onLogout!();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: edBox(
                                        color: accentColor.withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 1.2),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(LucideIcons.logOut, size: 15, color: accentColor),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Log Out',
                                            style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.bold, color: accentColor),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
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
        },
      );
  }

  Widget _buildMicroStat(String value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.bodoniModa(fontSize: 14, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: GoogleFonts.dmSans(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildStreakMicroStat(int streak) {
    final tier = StreakFlameTier.fromDays(streak);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tier.glyph, style: const TextStyle(fontSize: 11)),
            const SizedBox(width: 3),
            Text(
              '${streak}d',
              style: GoogleFonts.bodoniModa(fontSize: 14, fontWeight: FontWeight.bold, color: tier.glowColor),
            ),
          ],
        ),
        Text(
          tier.badgeTitle,
          style: GoogleFonts.dmSans(fontSize: 11, color: tier.glowColor, fontWeight: FontWeight.bold, letterSpacing: 0.6),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider(bool isDark) {
    return Container(
      width: 1,
      height: 18,
      color: isDark ? const Color(0xFF222222) : Colors.black12,
    );
  }

  Widget _staggeredWrapper(double start, double end, {required Widget child}) {
    return ScaleTransition(
      scale: _staggeredAnimation(start, end),
      child: FadeTransition(
        opacity: CurvedAnimation(parent: _entranceController, curve: Interval(start, end, curve: Curves.easeIn)),
        child: child,
      ),
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Text(
        title,
        style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.4, color: color),
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context,
    int index,
    IconData icon,
    String title,
    Color primaryColor,
    Color accentColor, {
    String? badgeText,
  }) {
    final bool isSelected = widget.activeIndex == index;

    return BouncyTouchEffect(
      pressedScale: 0.95,
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.pop(context);
        widget.onSelectModule(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 3),
        decoration: edBox(
          color: isSelected ? accentColor.withValues(alpha: 0.20) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: isSelected
              ? Border.all(color: accentColor.withValues(alpha: 0.5), width: 1.2)
              : null,
        ),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 1),
          leading: Icon(icon, size: 18, color: isSelected ? accentColor : primaryColor),
          title: Text(
            title,
            style: GoogleFonts.dmSans(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? accentColor : primaryColor,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (badgeText != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: edBox(
                    color: isSelected ? accentColor : accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeText,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : accentColor,
                    ),
                  ),
                ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                Container(
                  width: 7,
                  height: 7,
                  decoration: edBox(
                    color: accentColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.9),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerActionItem(
    BuildContext context,
    IconData icon,
    String title,
    Color primaryColor,
    Color accentColor, {
    required VoidCallback onTap,
    String? badgeText,
  }) {
    return BouncyTouchEffect(
      pressedScale: 0.95,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 3),
        decoration: edBox(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 1),
          leading: Icon(icon, size: 18, color: accentColor),
          title: Text(
            title,
            style: GoogleFonts.dmSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (badgeText != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: edBox(
                    color: accentColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accentColor.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    badgeText,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: accentColor,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              Icon(LucideIcons.chevronRight, size: 14, color: accentColor.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}
