import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/services/ai_briefing_service.dart';
import '../../../core/widgets/executive_dossier_dialog.dart';
import '../../../core/widgets/pressure_test_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/state/sanctuary_state.dart';
import '../../../core/widgets/bento_pod.dart';
import '../../../core/performance/sanctuary_motion_engine.dart';
import '../../../core/widgets/sparkle_explosion.dart';
import '../../../core/widgets/app_toast_engine.dart';

import 'sanctuary_timeline.dart';
import '../../../core/luxury/wax_melt_compression_ritual.dart';
import '../../../core/motion/motion.dart';
import '../../../core/state/app_settings.dart';
import 'dart:async';
import '../../../core/platform/browser_bridge.dart';
import '../../../core/utils/date_labels.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/entry_editor.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final Function(String) onOpenAiModal;

  const HomeScreen({super.key, required this.onOpenAiModal});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  DailyExecutiveBriefing? _briefing;
  bool _isLoadingBriefing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBriefing();
    });
  }

  Future<void> _loadBriefing({bool forceRefresh = false}) async {
    if (_isLoadingBriefing || !mounted) return;
    setState(() => _isLoadingBriefing = true);
    final tasks = ref.read(tasksProvider);
    final habits = ref.read(habitsProvider);
    final expenses = ref.read(expensesProvider).expenses;
    final b = await AiBriefingService().getOrGenerateBriefing(
      tasks: tasks,
      habits: habits,
      expenses: expenses,
      monthlyBudget: 25000.0,
      forceRefresh: forceRefresh,
    );
    if (mounted) {
      setState(() {
        _briefing = b;
        _isLoadingBriefing = false;
      });
    }
  }

  static String _greeting(String name) {
    final hour = DateTime.now().hour;
    final part = hour < 5 ? 'Good night' : hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    return name.isEmpty ? '$part.' : '$part, $name.';
  }

  Offset? _explosionPos;

  /// 25-minute focus session; runs while Home is open.
  static const Duration focusLength = Duration(minutes: 25);
  Duration _focusLeft = focusLength;
  Timer? _focusTimer;

  bool get _focusRunning => _focusTimer != null;

  void _toggleFocus() {
    if (_focusRunning) {
      _focusTimer!.cancel();
      setState(() => _focusTimer = null);
      return;
    }
    if (_focusLeft <= Duration.zero) _focusLeft = focusLength;
    setState(() {
      _focusTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _focusLeft -= const Duration(seconds: 1));
        if (_focusLeft <= Duration.zero) {
          _focusTimer?.cancel();
          setState(() => _focusTimer = null);
          HapticFeedback.heavyImpact();
          if (!showSystemNotification('Focus session complete', 'Time for a short break.')) {
            AppToastEngine().notify(title: 'Focus session complete', message: 'Time for a short break.');
          }
        }
      });
    });
  }

  void _resetFocus() {
    _focusTimer?.cancel();
    setState(() {
      _focusTimer = null;
      _focusLeft = focusLength;
    });
  }

  @override
  void dispose() {
    _focusTimer?.cancel();
    super.dispose();
  }

  static String _mmss(Duration d) =>
      '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  String _selectedTaskFilter = 'All';
  int _curatedOutfitIndex = 0;
  int _mobileSectionIndex = 0; // 0: Focus, 1: Treasury, 2: Lifestyle, 3: All

  Widget _buildMobileTabItem(
    int index,
    String label,
    IconData icon,
    bool isDark,
    Color primaryTextColor,
    Color accentColor,
  ) {
    final isSelected = _mobileSectionIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          SanctuaryHapticEngine.dialDetent();
          setState(() => _mobileSectionIndex = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF262320) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 11,
                  color: isSelected ? accentColor : primaryTextColor.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontSize: 10.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? primaryTextColor : primaryTextColor.withValues(alpha: 0.6),
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

  void _triggerExplosion(Offset globalPos) {
    setState(() {
      _explosionPos = globalPos;
    });
  }

  void _showAddQuickTaskDialog(BuildContext context, bool isDark) {
    final titleController = TextEditingController();
    String priority = 'High Priority';
    String timeSlot = 'Morning';

    showSanctuaryDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final dialogBg = isDark ? const Color(0xFF000000) : AppColors.surfaceContainerHigh;
          final textColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
          final borderColor = isDark ? const Color(0xFF2A2824) : AppColors.outlineVariant;

          return Dialog(
            backgroundColor: dialogBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: borderColor, width: 1.2),
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
                      Text(
                        'Add New Task',
                        style: GoogleFonts.bodoniModa(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      IconButton(
                        icon: Icon(LucideIcons.x, color: textColor.withValues(alpha: 0.6), size: 18),
                        onPressed: () => Navigator.pop(dialogCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'What would you like to accomplish?',
                      hintStyle: TextStyle(color: textColor.withValues(alpha: 0.4)),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF161514) : Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: timeSlot,
                          dropdownColor: isDark ? const Color(0xFF161514) : Colors.white,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: 'Time of Day',
                            labelStyle: TextStyle(color: textColor.withValues(alpha: 0.6)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: ['Morning', 'Afternoon', 'Evening']
                              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setDialogState(() => timeSlot = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: priority,
                          dropdownColor: isDark ? const Color(0xFF161514) : Colors.white,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: 'Priority',
                            labelStyle: TextStyle(color: textColor.withValues(alpha: 0.6)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: ['High Priority', 'Medium Priority', 'Low Priority']
                              .map((p) => DropdownMenuItem(value: p, child: Text(p, overflow: TextOverflow.ellipsis)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setDialogState(() => priority = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: Pressable(pressedScale: 0.95, hoverLift: 0, child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (titleController.text.trim().isNotEmpty) {
                          SanctuaryHapticEngine.sealImpression();
                          ref.read(tasksProvider.notifier).addTask(
                                title: titleController.text.trim(),
                                priority: priority,
                                timeSlot: timeSlot,
                              );
                          Navigator.pop(dialogCtx);
                          AppToastEngine().showToast(
                            context,
                            title: 'Task Added',
                            message: '"${titleController.text.trim()}" added to $timeSlot schedule.',
                          );
                        }
                      },
                      child: const Text('Save Task', style: TextStyle(fontWeight: FontWeight.bold)),
                    )),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    final accentColor = isDark ? const Color(0xFFE8927C) : AppColors.secondary;

    final tasks = ref.watch(tasksProvider);
    final activeTasks = tasks.where((t) => !t.isCompleted).toList();
    final completedTasks = tasks.where((t) => t.isCompleted).toList();
    final completionRatio = tasks.isEmpty ? 0.0 : (completedTasks.length / tasks.length);

    final outfits = ref.watch(wardrobeProvider);
    final expensesState = ref.watch(expensesProvider);

    final filteredTasks = _selectedTaskFilter == 'All'
        ? tasks
        : tasks.where((t) => t.timeSlot.toLowerCase() == _selectedTaskFilter.toLowerCase()).toList();

    final currentOutfit = outfits.isNotEmpty
        ? outfits[_curatedOutfitIndex % outfits.length]
        : null;

    final isCleanMode = ref.watch(appSettingsProvider.select((s) => s.cleanHomescreenMode));

    return Stack(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 960;

            if (isCleanMode) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: SingleChildScrollView(
                    physics: SanctuaryMotionEngine.fluidPhysics,
                    padding: EdgeInsets.fromLTRB(
                      isWide ? 36 : 18,
                      16,
                      isWide ? 36 : 18,
                      120,
                    ),
                    child: _buildCleanHomescreenView(
                      isDark: isDark,
                      primaryTextColor: primaryTextColor,
                      subtextColor: subtextColor,
                      accentColor: accentColor,
                      activeTasks: activeTasks,
                      expensesState: expensesState,
                    ),
                  ),
                ),
              );
            }

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1380),
                child: SingleChildScrollView(
                  physics: SanctuaryMotionEngine.fluidPhysics,
                  padding: EdgeInsets.fromLTRB(
                    isWide ? 36 : 18,
                    16,
                    isWide ? 36 : 18,
                    120,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. EDITORIAL MAGAZINE HERO
                      _buildEditorialHeroBar(isDark, primaryTextColor, subtextColor, accentColor, isWide),

                      const SizedBox(height: 18),

                      // AI Daily Executive Briefing & Agenda Synthesizer
                      _buildExecutiveBriefingBentoPod(isDark, primaryTextColor, subtextColor, accentColor),

                      const SizedBox(height: 18),

                      // 2. MASTER BENTO MAGAZINE GRID
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Column (flex 6)
                            Expanded(
                              flex: 6,
                              child: Column(
                                children: [
                                  // Pod 0: Today's Rhythm & Intentions
                                  _buildRhythmBentoPod(
                                    isDark,
                                    primaryTextColor,
                                    subtextColor,
                                    accentColor,
                                    filteredTasks,
                                    activeTasks.length,
                                    completionRatio,
                                  ),
                                  const SizedBox(height: 16),

                                  // Pod 1: Curated Studio Lookbook
                                  if (currentOutfit != null)
                                    _buildLookbookBentoPod(isDark, primaryTextColor, subtextColor, accentColor, currentOutfit),
                                  const SizedBox(height: 16),

                                  // Pod 2: Hermetic Knowledge Space
                                  _buildKnowledgeSpaceBentoPod(isDark, primaryTextColor, subtextColor, accentColor),
                                  const SizedBox(height: 16),

                                  // Pod 3: Curator Daily Reflection & Suminagashi Watermark
                                  _buildSuminagashiReflectionPod(isDark, primaryTextColor, subtextColor, accentColor),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),

                            // Right Column (flex 6)
                            Expanded(
                              flex: 6,
                              child: Column(
                                children: [
                                  // Pod 4: Sanctuary Treasury & Horizon Runway
                                  _buildTreasuryBentoPod(isDark, primaryTextColor, subtextColor, accentColor, expensesState),
                                  const SizedBox(height: 16),

                                  // Pod 5: Acoustic Memoirs & Tape Reel Capsule
                                  _buildAcousticMemoirBentoPod(isDark, primaryTextColor, subtextColor, accentColor),
                                  const SizedBox(height: 16),

                                  // Pod 6: Sanctuary Timeline & Life Log
                                  const SanctuaryTimeline(),
                                ],
                              ),
                            ),
                          ],
                        )
                      else
                        // Mobile Streamlined Tabbed Flow
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Sleek minimalist mobile segment bar
                            Container(
                              height: 38,
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF141210) : const Color(0xFFEFE9DB),
                                borderRadius: BorderRadius.circular(19),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF262320) : const Color(0xFFE2DCB8),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  _buildMobileTabItem(0, 'Focus', LucideIcons.checkSquare, isDark, primaryTextColor, accentColor),
                                  _buildMobileTabItem(1, 'Treasury', LucideIcons.wallet, isDark, primaryTextColor, accentColor),
                                  _buildMobileTabItem(2, 'Lifestyle', LucideIcons.compass, isDark, primaryTextColor, accentColor),
                                  _buildMobileTabItem(3, 'All', LucideIcons.layoutGrid, isDark, primaryTextColor, accentColor),
                                ],
                              ),
                            ),

                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              child: switch (_mobileSectionIndex) {
                                0 => Column(
                                    key: const ValueKey('mobile_focus'),
                                    children: [
                                      _buildRhythmBentoPod(
                                        isDark,
                                        primaryTextColor,
                                        subtextColor,
                                        accentColor,
                                        filteredTasks,
                                        activeTasks.length,
                                        completionRatio,
                                      ),
                                      const SizedBox(height: 16),
                                      const SanctuaryTimeline(),
                                    ],
                                  ),
                                1 => Column(
                                    key: const ValueKey('mobile_treasury'),
                                    children: [
                                      _buildTreasuryBentoPod(isDark, primaryTextColor, subtextColor, accentColor, expensesState),
                                    ],
                                  ),
                                2 => Column(
                                    key: const ValueKey('mobile_lifestyle'),
                                    children: [
                                      if (currentOutfit != null) ...[
                                        _buildLookbookBentoPod(isDark, primaryTextColor, subtextColor, accentColor, currentOutfit),
                                        const SizedBox(height: 16),
                                      ],
                                      _buildAcousticMemoirBentoPod(isDark, primaryTextColor, subtextColor, accentColor),
                                      const SizedBox(height: 16),
                                      _buildKnowledgeSpaceBentoPod(isDark, primaryTextColor, subtextColor, accentColor),
                                      const SizedBox(height: 16),
                                      _buildSuminagashiReflectionPod(isDark, primaryTextColor, subtextColor, accentColor),
                                    ],
                                  ),
                                _ => Column(
                                    key: const ValueKey('mobile_all'),
                                    children: [
                                      _buildRhythmBentoPod(
                                        isDark,
                                        primaryTextColor,
                                        subtextColor,
                                        accentColor,
                                        filteredTasks,
                                        activeTasks.length,
                                        completionRatio,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildTreasuryBentoPod(isDark, primaryTextColor, subtextColor, accentColor, expensesState),
                                      const SizedBox(height: 16),
                                      if (currentOutfit != null) ...[
                                        _buildLookbookBentoPod(isDark, primaryTextColor, subtextColor, accentColor, currentOutfit),
                                        const SizedBox(height: 16),
                                      ],
                                      _buildAcousticMemoirBentoPod(isDark, primaryTextColor, subtextColor, accentColor),
                                      const SizedBox(height: 16),
                                      _buildKnowledgeSpaceBentoPod(isDark, primaryTextColor, subtextColor, accentColor),
                                      const SizedBox(height: 16),
                                      _buildSuminagashiReflectionPod(isDark, primaryTextColor, subtextColor, accentColor),
                                      const SizedBox(height: 16),
                                      const SanctuaryTimeline(),
                                    ],
                                  ),
                              },
                            ),
                          ],
                        ),
                    ].revealed(),
                  ),
                ),
              ),
            );
          },
        ),

        // Celebratory Sparkle Explosion Canvas
        if (_explosionPos != null)
          SparkleExplosion(
            position: _explosionPos!,
            particleCount: 36,
            onComplete: () {
              setState(() {
                _explosionPos = null;
              });
            },
          ),
      ],
    );
  }

  Widget _buildExecutiveBriefingBentoPod(
    bool isDark,
    Color primaryTextColor,
    Color subtextColor,
    Color accentColor,
  ) {
    final briefing = _briefing;
    final surfaceColor = isDark ? const Color(0xFF0A0A0A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE8E3D8);

    return BentoPod(
      style: PodTextureStyle.glass,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar (buttons collapse to icons on phones)
          LayoutBuilder(builder: (context, headerBox) {
          final compact = headerBox.maxWidth < 520;
          return Row(
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
                        'DAILY BRIEF',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.6,
                          color: accentColor,
                        ),
                      ),
                      Text(
                        'Today\'s Overview & Focus',
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Pressable(
                    pressedScale: 0.95,
                    hoverLift: 0,
                    child: InkWell(
                      onTap: () => showExecutiveDossierDialog(context),
                      mouseCursor: SystemMouseCursors.click,
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
                            Tooltip(
                              message: 'Weekly summary',
                              child: Icon(LucideIcons.fileSpreadsheet, size: 12, color: accentColor),
                            ),
                            if (!compact) ...[
                              const SizedBox(width: 6),
                              Text(
                                'Weekly Summary',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: primaryTextColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Pressable(
                    pressedScale: 0.95,
                    hoverLift: 0,
                    child: InkWell(
                      onTap: _isLoadingBriefing ? null : () => _loadBriefing(forceRefresh: true),
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
                            _isLoadingBriefing
                                ? SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(strokeWidth: 1.5, color: accentColor),
                                  )
                                : Tooltip(
                                    message: 'Refresh the brief',
                                    child: Icon(LucideIcons.refreshCw, size: 12, color: accentColor),
                                  ),
                            if (!compact) ...[
                              const SizedBox(width: 6),
                              Text(
                                _isLoadingBriefing ? 'Thinking…' : 'Refresh',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: primaryTextColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
          }),
          const SizedBox(height: 14),

          if (briefing == null && _isLoadingBriefing)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SkeletonShimmer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 220, height: 20, borderRadius: 6),
                    SizedBox(height: 10),
                    SkeletonBox(width: double.infinity, height: 38, borderRadius: 10),
                    SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: SkeletonBox(height: 52, borderRadius: 8)),
                        SizedBox(width: 8),
                        Expanded(child: SkeletonBox(height: 52, borderRadius: 8)),
                        SizedBox(width: 8),
                        Expanded(child: SkeletonBox(height: 52, borderRadius: 8)),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Headline & Primary Directive
            Text(
              briefing?.headline ?? 'Strategic Execution Mode',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accentColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.target, size: 14, color: accentColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      briefing?.primaryDirective ?? 'Focus on your top priorities and keep a steady pace.',
                      style: GoogleFonts.dmSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFF5F2EB) : const Color(0xFF1C1917),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Top Priorities list
            if (briefing != null && briefing.topPriorities.isNotEmpty) ...[
              Text(
                'KEY FOCUS LANES TODAY',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: subtextColor,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: briefing.topPriorities.map((p) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.checkCircle2, size: 12, color: accentColor),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                          p,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: primaryTextColor,
                          ),
                        ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            // Guardrail & Maxim Footer
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(LucideIcons.wallet, size: 13, color: accentColor),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            briefing?.budgetGuardrail ?? 'Maintain balanced burn pace.',
                            style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(LucideIcons.quote, size: 13, color: accentColor),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            briefing?.strategicMaxim ?? 'Mastery is compounding momentum.',
                            style: GoogleFonts.dmSans(fontSize: 11, fontStyle: FontStyle.italic, color: subtextColor, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (briefing != null && briefing.forgottenWisdom.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0D0F11) : const Color(0xFFF7F5EE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accentColor.withValues(alpha: 0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(LucideIcons.sparkle, size: 12, color: accentColor),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'FROM YOUR ARCHIVE',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.4,
                              color: accentColor,
                            ),
                          ),
                        ),
                        Pressable(
                          pressedScale: 0.95,
                          child: InkWell(
                            onTap: () => showPressureTestDialog(
                              context,
                              title: 'Forgotten Wisdom Insight',
                              content: briefing.forgottenWisdom,
                            ),
                            child: Text(
                              'Spar on this →',
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: accentColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      briefing.forgottenWisdom,
                      style: GoogleFonts.dmSans(
                        fontSize: 12.5,
                        fontStyle: FontStyle.italic,
                        height: 1.45,
                        color: primaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // --- HEADER & COMPLICATION SELECTORS ---

  Widget _buildEditorialHeroBar(
    bool isDark,
    Color primaryTextColor,
    Color subtextColor,
    Color accentColor,
    bool isWide,
  ) {
    final complicationRow = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [


          // Unified Haute Horlogerie Complications Capsule
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF000000) : const Color(0xFFF4F0E6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFDDD5C4),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [


                // 2. Consecrate Daily Rhythm (Wax Seal Ritual)
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showWaxSealModal(context, isDark),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9E2A2B).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF9E2A2B).withValues(alpha: 0.35),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.stamp, size: 13, color: Color(0xFFE8927C)),
                        const SizedBox(width: 5),
                        Text(
                          'CHECK-IN',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: const Color(0xFFE8927C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Zen / Minimalist Clean Mode Button
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    SanctuaryHapticEngine.selection();
                    ref.read(appSettingsProvider.notifier).setCleanHomescreenMode(true);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.35),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.feather, size: 13, color: accentColor),
                        const SizedBox(width: 5),
                        Text(
                          'ZEN MODE',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Unified Sanctuary Telemetry Status Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF000000) : const Color(0xFFF4F0E6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFDDD5C4),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: accentColor.withValues(alpha: 0.5), blurRadius: 6, spreadRadius: 1),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${ref.watch(habitsProvider).fold<int>(0, (m, hb) => hb.streak > m ? hb.streak : m)}D STREAK',
                  style: GoogleFonts.dmSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: accentColor,
                  ),
                ),

              ],
            ),
          ),
        ],
      ),
    );

    if (!isWide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'TODAY · DAILY OVERVIEW',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.6,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _greeting(ref.watch(appSettingsProvider.select((s) => s.displayName))),
            style: GoogleFonts.bodoniModa(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '"Make space for what matters."',
            style: GoogleFonts.spectral(
              fontSize: 13.5,
              fontStyle: FontStyle.italic,
              color: subtextColor,
            ),
          ),
          const SizedBox(height: 14),
          complicationRow,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'TODAY · DAILY OVERVIEW',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.6,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _greeting(ref.watch(appSettingsProvider.select((s) => s.displayName))),
                    style: GoogleFonts.bodoniModa(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: primaryTextColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '"Make space for what matters."',
                    style: GoogleFonts.spectral(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: subtextColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Flexible(child: complicationRow),
          ],
        ),
      ],
    );
  }

  void _showWaxSealModal(BuildContext context, bool isDark) {
    SanctuaryHapticEngine.dialDetent();
    showSanctuaryDialog(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFFAF7F2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: isDark ? const Color(0xFF2A2824) : AppColors.outlineVariant,
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DAILY CHECK-IN',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.0,
                        color: AppColors.secondary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 18),
                      onPressed: () => Navigator.pop(dialogCtx),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  "Press and hold the seal below to record and complete today's check-in.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spectral(
                    fontSize: 13.5,
                    fontStyle: FontStyle.italic,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                WaxMeltCompressionRitual(
                  monogramLetter: 'N',
                  onSealed: () {
                    Navigator.pop(dialogCtx);
                    AppToastEngine().showToast(
                      context,
                      title: 'Check-in Complete',
                      message: "Today's progress saved successfully.",
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }


  // --- BENTO PODS ---

  Widget _buildRhythmBentoPod(
    bool isDark,
    Color primaryTextColor,
    Color subtextColor,
    Color accentColor,
    List<TaskItem> tasks,
    int activeCount,
    double completionRatio,
  ) {
    return BentoPod(
      style: PodTextureStyle.glass,
      showWaxSeal: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Focus",
                      style: GoogleFonts.bodoniModa(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your daily priorities and schedule',
                      style: GoogleFonts.spectral(
                        fontSize: 12.5,
                        fontStyle: FontStyle.italic,
                        color: subtextColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(LucideIcons.plusCircle, size: 22, color: AppColors.secondary),
                tooltip: 'Add Task',
                onPressed: () => _showAddQuickTaskDialog(context, isDark),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Serene Daily Completion Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF060606) : const Color(0xFFF3EDE2).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE2DDD2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'TODAY\'S TASKS PROGRESS',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: GoogleFonts.dmSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    RollingText(
                      '${(completionRatio * 100).toInt()}% COMPLETED',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Stack(
                    children: [
                      Container(
                        height: 6,
                        width: double.infinity,
                        color: isDark ? const Color(0xFF21262D) : const Color(0xFFE5DFD4),
                      ),
                      FractionallySizedBox(
                        widthFactor: completionRatio,
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Rhythm Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: ['All', 'Morning', 'Afternoon', 'Evening'].map((filter) {
                final isSel = _selectedTaskFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSel,
                    onSelected: (val) {
                      SanctuaryHapticEngine.dialDetent();
                      setState(() => _selectedTaskFilter = filter);
                    },
                    labelStyle: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      color: isSel ? Colors.black : (isDark ? Colors.white70 : AppColors.onSurface),
                    ),
                    backgroundColor: isDark ? const Color(0xFF161514) : Colors.white.withValues(alpha: 0.6),
                    selectedColor: accentColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    side: BorderSide(
                      color: isSel ? accentColor : (isDark ? const Color(0xFF2E2B26) : Colors.black12),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          if (tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No tasks in this slot. Tap + to add one.',
                  style: GoogleFonts.spectral(fontStyle: FontStyle.italic, color: subtextColor),
                ),
              ),
            )
          else
            ...tasks.take(4).map((task) => _buildAnimatedTaskTile(task, isDark, primaryTextColor, subtextColor)),
        ],
      ),
    );
  }

  Widget _buildAnimatedTaskTile(TaskItem task, bool isDark, Color primaryTextColor, Color subtextColor) {
    final completed = task.isCompleted;
    final accentColor = isDark ? const Color(0xFFE8927C) : AppColors.secondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTapDown: (details) {
          if (!completed) {
            _triggerExplosion(details.globalPosition);
          }
        },
        onTap: () {
          SanctuaryHapticEngine.escapementTick();
          ref.read(tasksProvider.notifier).toggleTask(task.id);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? (completed ? const Color(0xFF060606) : const Color(0xFF0C0C0C))
                : (completed ? Colors.white.withValues(alpha: 0.5) : Colors.white),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: completed
                  ? (isDark ? const Color(0xFF1A1A1A) : Colors.black.withValues(alpha: 0.05))
                  : (isDark ? const Color(0xFF262626) : const Color(0xFFE2DDD2)),
              width: 1.0,
            ),
            boxShadow: completed
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: completed ? accentColor : Colors.transparent,
                  border: Border.all(
                    color: completed
                        ? accentColor
                        : (isDark ? const Color(0xFF484F58) : AppColors.primary),
                    width: 1.8,
                  ),
                ),
                child: completed
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: AppTypography.bodyMd.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: completed ? TextDecoration.lineThrough : null,
                        color: completed
                            ? (isDark ? Colors.white30 : AppColors.onSurface.withValues(alpha: 0.4))
                            : primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${task.timeSlot} · ${task.priority}',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: subtextColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            task.space,
                            style: GoogleFonts.dmSans(
                              fontSize: 9.5,
                              color: accentColor,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildLookbookBentoPod(
    bool isDark,
    Color primaryTextColor,
    Color subtextColor,
    Color accentColor,
    WardrobeOutfit outfit,
  ) {
    return BentoPod(
      style: PodTextureStyle.polaroid,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "TODAY'S OUTFIT",
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: accentColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  SanctuaryHapticEngine.dialDetent();
                  setState(() => _curatedOutfitIndex++);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.shuffle, size: 11, color: accentColor),
                      const SizedBox(width: 4),
                      Text(
                        'SHUFFLE',
                        style: GoogleFonts.dmSans(fontSize: 9.5, fontWeight: FontWeight.bold, color: accentColor),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            outfit.title,
            style: GoogleFonts.bodoniModa(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            outfit.items,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFFE8DFC8) : AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _editorialPill(
                label: outfit.fabric,
                icon: LucideIcons.layers,
                color: isDark ? const Color(0xFFF5F2EB) : const Color(0xFF1C1917),
                isDark: isDark,
              ),
              _editorialPill(
                label: outfit.weather,
                icon: LucideIcons.sun,
                color: isDark ? const Color(0xFFE8927C) : AppColors.secondary,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTreasuryBentoPod(
    bool isDark,
    Color primaryTextColor,
    Color subtextColor,
    Color accentColor,
    ExpensesState expensesState,
  ) {
    // This calendar month against the user's own limit (Settings → Budget).
    final settings = ref.watch(appSettingsProvider);
    final symbol = settings.currencySymbol;
    final totalSpend = expensesState.spendInMonth(DateTime.now());
    final monthlyBudget = settings.monthlyBudget;
    final budgetFraction = monthlyBudget == null ? 0.0 : (totalSpend / monthlyBudget).clamp(0.0, 1.0);
    final remainingBudget = monthlyBudget == null ? 0.0 : (monthlyBudget - totalSpend).clamp(0.0, monthlyBudget);

    return BentoPod(
      style: PodTextureStyle.glass,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'MONTHLY EXPENSES & BUDGET',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: accentColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              RollingText(
                monthlyBudget == null
                    ? '${formatMoney(totalSpend, symbol)} this month'
                    : '${formatMoney(totalSpend, symbol)} / ${formatMoney(monthlyBudget, symbol)}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Clean Minimalist Runway Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF060606) : const Color(0xFFF2ECE1).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE2DDD2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: RollingText(
                        '${(budgetFraction * 100).toInt()}% ALLOCATED',
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: RollingText(
                        monthlyBudget == null
                            ? 'SET A BUDGET IN SETTINGS'
                            : totalSpend > monthlyBudget
                                ? '${formatMoney(totalSpend - monthlyBudget, symbol)} OVER'
                                : '${formatMoney(remainingBudget, symbol)} REMAINING',
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Stack(
                    children: [
                      Container(
                        height: 7,
                        width: double.infinity,
                        color: isDark ? const Color(0xFF21262D) : const Color(0xFFE5DFD4),
                      ),
                      FractionallySizedBox(
                        widthFactor: budgetFraction,
                        child: Container(
                          height: 7,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Settlements Pending Strip
          if (expensesState.settlements.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161411) : Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? const Color(0xFF30363D) : const Color(0xFFE2DDD2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(LucideIcons.arrowRightLeft, size: 14, color: accentColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Settlement: ${expensesState.settlements.first.from} owes ${expensesState.settlements.first.amount}',
                            style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: primaryTextColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    expensesState.settlements.first.isSettled ? 'SETTLED' : 'PENDING',
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: expensesState.settlements.first.isSettled ? accentColor : const Color(0xFFFF8A65),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAcousticMemoirBentoPod(
    bool isDark,
    Color primaryTextColor,
    Color subtextColor,
    Color accentColor,
  ) {
    return BentoPod(
      style: PodTextureStyle.glass,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'FOCUS TIMER',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: accentColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(LucideIcons.headphones, size: 16, color: accentColor),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF060606) : Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE2DDD2)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _toggleFocus();
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _focusRunning ? accentColor : (isDark ? const Color(0xFF161616) : const Color(0xFFEFE8DB)),
                    ),
                    child: Center(
                      child: Icon(
                        _focusRunning ? LucideIcons.pause : LucideIcons.play,
                        color: _focusRunning ? Colors.white : primaryTextColor,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _mmss(_focusLeft),
                        style: GoogleFonts.bodoniModa(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _focusRunning
                            ? 'Focusing · ${focusLength.inMinutes}-minute session'
                            : (_focusLeft == focusLength ? 'Ready · tap play to start' : 'Paused'),
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: subtextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_focusRunning && _focusLeft != focusLength)
                  IconButton(
                    tooltip: 'Reset timer',
                    icon: Icon(LucideIcons.rotateCcw, size: 16, color: subtextColor),
                    onPressed: _resetFocus,
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(4, (i) {
                    final heights = [14.0, 22.0, 10.0, 18.0];
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 3,
                      height: _focusRunning ? heights[i] : 4.0,
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      decoration: BoxDecoration(
                        color: _focusRunning ? accentColor : subtextColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKnowledgeSpaceBentoPod(
    bool isDark,
    Color primaryTextColor,
    Color subtextColor,
    Color accentColor,
  ) {
    final notes = [...ref.watch(notesProvider)]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final note = notes.isEmpty ? null : notes.first;
    final inSpace = note == null ? 0 : notes.where((n) => n.space == note.space).length;
    return BentoPod(
      style: PodTextureStyle.paper,
      onTap: note == null ? null : () => openEntryEditor(context, EntryKind.note, editing: note),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  note == null ? 'NOTEBOOK' : note.space.toUpperCase(),
                  style: AppTypography.labelSm,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'LATEST NOTE',
                  style: GoogleFonts.jetBrainsMono(fontSize: 9, fontWeight: FontWeight.bold, color: accentColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            note?.title ?? 'No notes yet',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.bodoniModa(fontSize: 20, fontWeight: FontWeight.bold, color: primaryTextColor),
          ),
          Text(
            note == null ? 'Capture your first thought to see it here.' : '$inSpace note${inSpace == 1 ? '' : 's'} in this space · ${note.tag}',
            style: GoogleFonts.dmSans(fontSize: 12, color: subtextColor),
          ),
          if (note != null && note.excerpt.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF060606) : const Color(0xFFF3ECE0).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE2DDD2)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.fileCheck, size: 14, color: accentColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      note.excerpt,
                      style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w500, color: primaryTextColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(DateLabels.relative(note.updatedAt), style: GoogleFonts.dmSans(fontSize: 10, color: subtextColor)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Pressable(pressedScale: 0.95, hoverLift: 0, child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFFE8927C) : AppColors.primary,
              foregroundColor: isDark ? Colors.black : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onPressed: () {
              SanctuaryHapticEngine.dialDetent();
              if (note == null) {
                openEntryEditor(context, EntryKind.note);
              } else {
                widget.onOpenAiModal(note.title);
              }
            },
            icon: Icon(note == null ? LucideIcons.plus : LucideIcons.sparkles, size: 14, color: isDark ? Colors.black : Colors.white),
            label: Text(note == null ? 'New note' : 'Ask about this note', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          )),
        ],
      ),
    );
  }

  Widget _buildSuminagashiReflectionPod(
    bool isDark,
    Color primaryTextColor,
    Color subtextColor,
    Color accentColor,
  ) {
    return BentoPod(
      style: PodTextureStyle.glass,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'DAILY QUOTE & INSPIRATION',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: accentColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(LucideIcons.quote, size: 14, color: accentColor),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '"Simplicity is not the absence of clutter, that\'s a consequence of simplicity. Simplicity is describing the purpose and place of an object and giving it meaning."',
            style: GoogleFonts.spectral(
              fontSize: 14.5,
              height: 1.5,
              fontStyle: FontStyle.italic,
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '— Dieter Rams · Good Design is Honest',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: subtextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanHomescreenView({
    required bool isDark,
    required Color primaryTextColor,
    required Color subtextColor,
    required Color accentColor,
    required List<TaskItem> activeTasks,
    required ExpensesState expensesState,
  }) {
    final settings = ref.watch(appSettingsProvider);
    final userName = settings.displayName;
    final habits = ref.watch(habitsProvider);
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMMM d').format(now);

    final totalSpent = expensesState.expenses.fold<double>(0.0, (acc, e) => acc + e.amount);
    final budget = settings.monthlyBudget ?? 15000.0;
    final budgetRatio = (totalSpent / (budget <= 0 ? 1 : budget)).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(userName),
                  style: GoogleFonts.bodoniModa(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  dateStr,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: subtextColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    SanctuaryHapticEngine.selection();
                    ref.read(appSettingsProvider.notifier).setCleanHomescreenMode(false);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: accentColor.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.sparkles, size: 13, color: accentColor),
                        const SizedBox(width: 4),
                        Text(
                          'Editorial Mode',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    SanctuaryHapticEngine.buttonPress();
                    _showAddQuickTaskDialog(context, isDark);
                  },
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE8E2D8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Icon(LucideIcons.plus, size: 18, color: primaryTextColor),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        // 1. TODAY'S ESSENTIAL PRIORITIES
        BentoPod(
          style: PodTextureStyle.paper,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.checkSquare, size: 15, color: accentColor),
                      const SizedBox(width: 8),
                      Text(
                        'TODAY\'S PRIORITIES',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${activeTasks.length} pending',
                    style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (activeTasks.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: Text(
                      'All tasks completed. Take a breath and enjoy your calm day.',
                      style: GoogleFonts.dmSans(fontSize: 12.5, color: subtextColor),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activeTasks.take(5).length,
                  separatorBuilder: (_, __) => Divider(height: 12, color: isDark ? const Color(0xFF1C1A18) : Colors.black12),
                  itemBuilder: (context, idx) {
                    final t = activeTasks[idx];
                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        SanctuaryHapticEngine.selection();
                        ref.read(tasksProvider.notifier).toggleTask(t.id);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: accentColor, width: 1.5),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                t.title,
                                style: GoogleFonts.dmSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: primaryTextColor,
                                ),
                              ),
                            ),
                            if (t.timeOfDay.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E1C1A) : const Color(0xFFEBE6DC),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  t.timeOfDay,
                                  style: GoogleFonts.spaceGrotesk(fontSize: 10, color: subtextColor),
                                ),
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
        const SizedBox(height: 16),

        // 2. DAILY HABITS
        if (habits.isNotEmpty) ...[
          BentoPod(
            style: PodTextureStyle.glass,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.repeat, size: 15, color: accentColor),
                    const SizedBox(width: 8),
                    Text(
                      'DAILY HABITS',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: habits.map((h) {
                    final isDoneToday = h.completedToday;
                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        SanctuaryHapticEngine.selection();
                        ref.read(habitsProvider.notifier).toggleHabit(h.id);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDoneToday
                              ? accentColor.withValues(alpha: 0.18)
                              : (isDark ? const Color(0xFF1A1816) : const Color(0xFFEFE9DC)),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDoneToday ? accentColor.withValues(alpha: 0.5) : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isDoneToday ? LucideIcons.checkCircle2 : LucideIcons.circle,
                              size: 14,
                              color: isDoneToday ? accentColor : subtextColor,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              h.title,
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: isDoneToday ? FontWeight.bold : FontWeight.w500,
                                color: isDoneToday ? primaryTextColor : subtextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 3. MONTHLY TREASURY SNAPSHOT
        BentoPod(
          style: PodTextureStyle.glass,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.wallet, size: 15, color: accentColor),
                      const SizedBox(width: 8),
                      Text(
                        'TREASURY RUNWAY',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${settings.currencySymbol}${totalSpent.toStringAsFixed(0)} / ${settings.currencySymbol}${budget.toStringAsFixed(0)}',
                    style: GoogleFonts.dmMono(fontSize: 11, fontWeight: FontWeight.bold, color: primaryTextColor),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: budgetRatio,
                  minHeight: 6,
                  backgroundColor: isDark ? const Color(0xFF22201D) : const Color(0xFFE5DDD0),
                  valueColor: AlwaysStoppedAnimation(accentColor),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 4. QUICK NODO AI SEARCH / NOTE BAR
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            SanctuaryHapticEngine.selection();
            widget.onOpenAiModal('');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141210) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? const Color(0xFF26221E) : const Color(0xFFE8E0D2)),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.sparkles, size: 16, color: accentColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ask Nodo or capture a quick thought...',
                    style: GoogleFonts.dmSans(fontSize: 12.5, color: subtextColor),
                  ),
                ),
                Icon(LucideIcons.arrowUpRight, size: 14, color: subtextColor),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _editorialPill({
    required String label,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.35 : 0.2),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
