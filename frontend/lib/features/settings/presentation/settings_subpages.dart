import 'package:flutter/material.dart';
import 'account_deletion.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/performance/sanctuary_motion_engine.dart';
import '../../../core/platform/browser_bridge.dart';
import '../../../core/services/cloud_sync_service.dart';
import '../../../core/services/daily_engagement_service.dart';
import '../../../core/services/data_portability_service.dart';
import '../../../core/services/device_notification_service.dart';
import '../../../core/services/ics_export.dart';
import '../../../core/services/local_store.dart';
import '../../../core/services/sanctuary_supabase_service.dart';
import '../../../core/state/app_settings.dart';
import '../../../core/state/sanctuary_state.dart';
import '../../../core/systems/aesthetic_audio_service.dart';
import '../../../core/systems/ephemeral_clipboard_sanitizer.dart';
import '../../../core/utils/date_labels.dart';
import '../../../core/widgets/app_feature_walkthrough.dart';
import '../../../core/widgets/app_toast_engine.dart';
import '../../../core/widgets/bento_pod.dart';
import '../../../core/widgets/homescreen/homescreen_widget_studio_screen.dart';
import '../../../core/widgets/stitch_logo_widget.dart';
import '../../auth/presentation/mfa_dialogs.dart';
import 'ai_settings_section.dart';
import 'notifications_screen.dart';
import 'security_settings_section.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';

/// Subpage wrapper providing standard luxury navigation header and consistent scaffold
class SettingsSubpageScaffold extends StatelessWidget {
  final String title;
  final String categoryLabel;
  final Widget child;

  const SettingsSubpageScaffold({
    super.key,
    required this.title,
    required this.categoryLabel,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final terracotta = isDark ? const Color(0xFFE8927C) : AppColors.secondary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: primaryTextColor, size: 20),
          onPressed: () {
            SanctuaryHapticEngine.selection();
            Navigator.of(context).pop();
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              categoryLabel.toUpperCase(),
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: terracotta,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.bodoniModa(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryTextColor,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: SanctuaryMotionEngine.fluidPhysics,
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
          child: child,
        ),
      ),
    );
  }
}

/// Helper switch tile
Widget _subpageSwitch(
  String title,
  String desc,
  bool val,
  ValueChanged<bool> onChanged,
  Color primaryTextColor,
  Color subtextColor,
) {
  return MergeSemantics(
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.dmSans(fontSize: 13.5, fontWeight: FontWeight.bold, color: primaryTextColor)),
              const SizedBox(height: 2),
              Text(desc, style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor, height: 1.3)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Switch(value: val, activeTrackColor: AppColors.secondary, onChanged: onChanged),
      ],
    ),
  );
}

// ==========================================
// 1. DISPLAY & LAYOUT SUBPAGE
// ==========================================
class DisplaySettingsSubpage extends ConsumerWidget {
  const DisplaySettingsSubpage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    final terracotta = isDark ? const Color(0xFFE8927C) : AppColors.secondary;
    final settings = ref.watch(appSettingsProvider);

    return SettingsSubpageScaffold(
      categoryLabel: 'Display & Aesthetics',
      title: 'Display & Layout',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Theme Mode
          BentoPod(
            style: PodTextureStyle.glass,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Color Theme Mode', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.bold, color: primaryTextColor)),
                const SizedBox(height: 8),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(LucideIcons.monitor, size: 14)),
                    ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(LucideIcons.sun, size: 14)),
                    ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(LucideIcons.moon, size: 14)),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (s) {
                    SanctuaryHapticEngine.dialDetent();
                    ref.read(appSettingsProvider.notifier).setThemeMode(s.first);
                  },
                ),
                const Divider(height: 24),
                // In-App Font Size & Scaling
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('In-App Font Size', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.bold, color: primaryTextColor)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: terracotta.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${(UiPrefs.of(settings).textScaleFactor * 100).toInt()}% Scale',
                        style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold, color: terracotta),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ('compact', 'Compact', '0.95×'),
                      ('regular', 'Regular', '1.05×'),
                      ('larger', 'Larger', '1.18×'),
                      ('largest', 'Largest', '1.30×'),
                      ('sovereign', 'Sovereign', '1.42×'),
                    ].map((scale) {
                      final currentScale = UiPrefs.of(settings).textScale.toLowerCase();
                      final isSel = currentScale == scale.$1 ||
                          (scale.$1 == 'compact' && currentScale == 'smaller') ||
                          (scale.$1 == 'regular' && currentScale == 'normal');
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () {
                            SanctuaryHapticEngine.dialDetent();
                            ref.read(appSettingsProvider.notifier).setUi('textScale', scale.$1);
                            rebuildAllWidgets(context);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSel ? terracotta : (isDark ? const Color(0xFF1C1917) : const Color(0xFFF3ECE0)),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSel ? terracotta : (isDark ? const Color(0xFF2C241E) : const Color(0xFFDDD4C5)),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  scale.$2,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                    color: isSel ? Colors.white : primaryTextColor,
                                  ),
                                ),
                                Text(
                                  scale.$3,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 10,
                                    color: isSel ? Colors.white70 : subtextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF141210) : const Color(0xFFFAF7F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isDark ? const Color(0xFF24201C) : const Color(0xFFE8E2D5)),
                  ),
                  child: Text(
                    'Preview: The quick brown fox writes intentional thoughts.',
                    style: GoogleFonts.dmSans(
                      fontSize: 13 * UiPrefs.of(settings).textScaleFactor,
                      color: primaryTextColor,
                    ),
                  ),
                ),
                const Divider(height: 24),
                // Default Start Screen
                Text('Default Landing Screen on Launch', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.bold, color: primaryTextColor)),
                const SizedBox(height: 8),
                Container(
                  decoration: edBox(
                    color: isDark ? const Color(0xFF141210) : const Color(0xFFFAF7F0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? const Color(0xFF262220) : const Color(0xFFE5DDD0)),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Row(
                    children: [
                      (0, 'Home', LucideIcons.home),
                      (1, 'Notes', LucideIcons.fileText),
                      (2, 'Tasks', LucideIcons.checkSquare),
                      (3, 'Planner', LucideIcons.calendar),
                    ].map((item) {
                      final isSel = settings.defaultStartScreen == item.$1;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            SanctuaryHapticEngine.dialDetent();
                            ref.read(appSettingsProvider.notifier).setDefaultStartScreen(item.$1);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
                            decoration: edBox(
                              color: isSel ? terracotta : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(item.$3, size: 11.5, color: isSel ? Colors.white : subtextColor),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    item.$2,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 11,
                                      fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                      color: isSel ? Colors.white : primaryTextColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const Divider(height: 24),
                // Clock Format & Week Start
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Week Starts On', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.bold, color: primaryTextColor)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            children: [
                              ChoiceChip(
                                label: const Text('Mon'),
                                selected: settings.firstDayOfWeek == 1,
                                onSelected: (_) {
                                  SanctuaryHapticEngine.dialDetent();
                                  ref.read(appSettingsProvider.notifier).setFirstDayOfWeek(1);
                                },
                              ),
                              ChoiceChip(
                                label: const Text('Sun'),
                                selected: settings.firstDayOfWeek == 7,
                                onSelected: (_) {
                                  SanctuaryHapticEngine.dialDetent();
                                  ref.read(appSettingsProvider.notifier).setFirstDayOfWeek(7);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Clock Format', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.bold, color: primaryTextColor)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            children: [
                              ChoiceChip(
                                label: const Text('12h'),
                                selected: !settings.timeFormat24h,
                                onSelected: (_) {
                                  SanctuaryHapticEngine.dialDetent();
                                  ref.read(appSettingsProvider.notifier).setTimeFormat24h(false);
                                },
                              ),
                              ChoiceChip(
                                label: const Text('24h'),
                                selected: settings.timeFormat24h,
                                onSelected: (_) {
                                  SanctuaryHapticEngine.dialDetent();
                                  ref.read(appSettingsProvider.notifier).setTimeFormat24h(true);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                // Haptics & Motion
                Text('Tactile Haptic Feedback', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.bold, color: primaryTextColor)),
                Text('Fine-tune physical sensations on every touch.', style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: ['off', 'light', 'medium', 'crisp'].map((intensity) {
                    final isSel = settings.hapticIntensity == intensity;
                    return ChoiceChip(
                      label: Text(intensity[0].toUpperCase() + intensity.substring(1)),
                      selected: isSel,
                      onSelected: (_) {
                        ref.read(appSettingsProvider.notifier).setHapticIntensity(intensity);
                        SanctuaryHapticEngine.sealImpression();
                      },
                    );
                  }).toList(),
                ),
                const Divider(height: 24),
                _subpageSwitch(
                  'Reduce Motion',
                  'Minimize spring physics, transitions, and ambient loops.',
                  settings.reducedMotion,
                  (v) => ref.read(appSettingsProvider.notifier).setReducedMotion(v),
                  primaryTextColor,
                  subtextColor,
                ),
                const Divider(height: 24),
                // Card & Container Architecture (Bento vs Swiss Editorial)
                Text('Card & List Architecture', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.bold, color: primaryTextColor)),
                Text('Editorial sets everything as type on the page: no cards, no boxes, just text and motion. Bento shows each item in its own card.',
                    style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          SanctuaryHapticEngine.dialDetent();
                          ref.read(appSettingsProvider.notifier).setCardStyle('bento');
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(12),
                          decoration: edBox(
                            color: settings.cardStyle == 'bento'
                                ? terracotta.withValues(alpha: 0.12)
                                : (isDark ? const Color(0xFF141210) : const Color(0xFFFAF7F0)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: settings.cardStyle == 'bento'
                                  ? terracotta
                                  : (isDark ? const Color(0xFF262220) : const Color(0xFFE5DDD0)),
                              width: settings.cardStyle == 'bento' ? 1.5 : 1.0,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(LucideIcons.layoutGrid, size: 16, color: settings.cardStyle == 'bento' ? terracotta : subtextColor),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Cards',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: settings.cardStyle == 'bento' ? terracotta : primaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Curated frames, rounded chamfers, and soft spatial depth.',
                                style: GoogleFonts.dmSans(fontSize: 11.5, color: subtextColor, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          SanctuaryHapticEngine.dialDetent();
                          ref.read(appSettingsProvider.notifier).setCardStyle('editorial');
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(12),
                          decoration: edBox(
                            color: settings.cardStyle == 'editorial'
                                ? terracotta.withValues(alpha: 0.12)
                                : (isDark ? const Color(0xFF141210) : const Color(0xFFFAF7F0)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: settings.cardStyle == 'editorial'
                                  ? terracotta
                                  : (isDark ? const Color(0xFF262220) : const Color(0xFFE5DDD0)),
                              width: settings.cardStyle == 'editorial' ? 1.5 : 1.0,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(LucideIcons.rows, size: 16, color: settings.cardStyle == 'editorial' ? terracotta : subtextColor),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Editorial',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: settings.cardStyle == 'editorial' ? terracotta : primaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Borderless flush paper, razor hairline dividers, and spacious rows.',
                                style: GoogleFonts.dmSans(fontSize: 11.5, color: subtextColor, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _subpageSwitch(
                  'Minimalist Homescreen Mode',
                  'Condenses layout into a focused, tranquil view.',
                  settings.cleanHomescreenMode,
                  (v) => ref.read(appSettingsProvider.notifier).setCleanHomescreenMode(v),
                  primaryTextColor,
                  subtextColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Homescreen Card Visibility Toggles (User Requested)
          BentoPod(
            style: PodTextureStyle.glass,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.eyeOff, size: 16, color: terracotta),
                    const SizedBox(width: 8),
                    Text(
                      'CARD VISIBILITY & UNCLUTTER',
                      style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: terracotta),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Hide verbose cards from your homescreen for a serene, distraction-free view.',
                  style: GoogleFonts.dmSans(fontSize: 11.5, color: subtextColor),
                ),
                const SizedBox(height: 14),
                _subpageSwitch(
                  'Hide Daily Executive Briefing',
                  'Hides the verbose AI morning briefing text and strategic maxim card from the home feed.',
                  settings.hideDailyBriefing,
                  (v) => ref.read(appSettingsProvider.notifier).setHideDailyBriefing(v),
                  primaryTextColor,
                  subtextColor,
                ),
                const Divider(height: 24),
                _subpageSwitch(
                  'Hide Monthly Budget Ceiling',
                  'Hides the budget percentage runway progress bar while keeping monthly spend metrics available.',
                  settings.hideMonthlyBudget,
                  (v) => ref.read(appSettingsProvider.notifier).setHideMonthlyBudget(v),
                  primaryTextColor,
                  subtextColor,
                ),
                const Divider(height: 24),
                _subpageSwitch(
                  'Hide Expenses Treasury Summary',
                  'Hides the entire Treasury runway card from the home screen.',
                  settings.hideExpensesSummary,
                  (v) => ref.read(appSettingsProvider.notifier).setHideExpensesSummary(v),
                  primaryTextColor,
                  subtextColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // User Optional Location
          BentoPod(
            style: PodTextureStyle.glass,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.mapPin, size: 16, color: terracotta),
                    const SizedBox(width: 8),
                    Text(
                      'USER LOCATION (OPTIONAL)',
                      style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: terracotta),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Add your city or sanctuary base to display on your Curator Passport.', style: GoogleFonts.dmSans(fontSize: 11.5, color: subtextColor)),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: settings.userLocation ?? '',
                  decoration: InputDecoration(
                    hintText: 'e.g. Kyoto, Japan or Zurich, CH',
                    prefixIcon: Icon(LucideIcons.mapPin, size: 15, color: terracotta),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    isDense: true,
                  ),
                  onFieldSubmitted: (val) {
                    ref.read(appSettingsProvider.notifier).setUserLocation(val.trim().isEmpty ? null : val.trim());
                    SanctuaryHapticEngine.sealImpression();
                    AppToastEngine().showToast(context, title: 'Location Updated', message: val.trim().isEmpty ? 'Location cleared.' : 'Location set to ${val.trim()}');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Typography & Font Studio
          BentoPod(
            style: PodTextureStyle.glass,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.type, size: 16, color: terracotta),
                    const SizedBox(width: 8),
                    Text(
                      'TYPOGRAPHY & FONT STUDIO',
                      style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: terracotta),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Select universal and dedicated fonts for individual modules.', style: GoogleFonts.dmSans(fontSize: 11.5, color: subtextColor)),
                const SizedBox(height: 14),
                // Universal Font Selector
                Text('Universal Global Font', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.bold, color: primaryTextColor)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: edBox(
                    color: isDark ? const Color(0xFF141210) : const Color(0xFFFAF7F0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: terracotta.withValues(alpha: 0.4)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: settings.fontFamilyGlobal,
                      isExpanded: true,
                      dropdownColor: isDark ? const Color(0xFF141210) : const Color(0xFFFAF7F0),
                      icon: Icon(LucideIcons.chevronDown, size: 14, color: terracotta),
                      items: AppTypography.availableFonts.map((font) {
                        return DropdownMenuItem(
                          value: font,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(font, style: AppTypography.getStyle(font, fontSize: 13, fontWeight: FontWeight.bold, color: primaryTextColor)),
                              Text(AppTypography.fontDescriptions[font] ?? '', style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (f) {
                        if (f != null) {
                          SanctuaryHapticEngine.dialDetent();
                          ref.read(appSettingsProvider.notifier).setFontFamilyGlobal(f);
                        }
                      },
                    ),
                  ),
                ),
                const Divider(height: 24),
                Text('Dedicated Module Fonts', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.bold, color: primaryTextColor)),
                const SizedBox(height: 10),
                _sectionFontPicker('Notes Module', settings.fontFamilyNotes, (v) => ref.read(appSettingsProvider.notifier).setFontFamilyNotes(v), isDark, primaryTextColor, subtextColor, terracotta, ref),
                const SizedBox(height: 8),
                _sectionFontPicker('Tasks Module', settings.fontFamilyTasks, (v) => ref.read(appSettingsProvider.notifier).setFontFamilyTasks(v), isDark, primaryTextColor, subtextColor, terracotta, ref),
                const SizedBox(height: 8),
                _sectionFontPicker('Journal Module', settings.fontFamilyJournal, (v) => ref.read(appSettingsProvider.notifier).setFontFamilyJournal(v), isDark, primaryTextColor, subtextColor, terracotta, ref),
                const SizedBox(height: 8),
                _sectionFontPicker('Treasury Module', settings.fontFamilyTreasury, (v) => ref.read(appSettingsProvider.notifier).setFontFamilyTreasury(v), isDark, primaryTextColor, subtextColor, terracotta, ref),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionFontPicker(
    String label,
    String currentValue,
    ValueChanged<String> onChanged,
    bool isDark,
    Color primaryTextColor,
    Color subtextColor,
    Color gold,
    WidgetRef ref,
  ) {
    final options = ['Default', ...AppTypography.availableFonts];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: edBox(
        color: isDark ? const Color(0xFF141210) : const Color(0xFFFAF7F0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? const Color(0xFF262220) : const Color(0xFFE5DDD0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: primaryTextColor)),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentValue,
              isDense: true,
              dropdownColor: isDark ? const Color(0xFF141210) : const Color(0xFFFAF7F0),
              icon: Icon(LucideIcons.chevronDown, size: 12, color: subtextColor),
              items: options.map((opt) {
                return DropdownMenuItem(
                  value: opt,
                  child: Text(
                    opt == 'Default' ? 'Universal (${ref.read(appSettingsProvider).fontFamilyGlobal})' : opt,
                    style: opt == 'Default' ? GoogleFonts.dmSans(fontSize: 11.5, color: subtextColor) : AppTypography.getStyle(opt, fontSize: 11.5, fontWeight: FontWeight.bold, color: primaryTextColor),
                  ),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) {
                  SanctuaryHapticEngine.dialDetent();
                  onChanged(v);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 2. AESTHETIC AUDIO STUDIO SUBPAGE
// ==========================================
class AudioSettingsSubpage extends ConsumerStatefulWidget {
  const AudioSettingsSubpage({super.key});

  @override
  ConsumerState<AudioSettingsSubpage> createState() => _AudioSettingsSubpageState();
}

class _AudioSettingsSubpageState extends ConsumerState<AudioSettingsSubpage> {
  String? _previewingSoundId;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    final terracotta = isDark ? const Color(0xFFE8927C) : AppColors.secondary;
    final settings = ref.watch(appSettingsProvider);

    return SettingsSubpageScaffold(
      categoryLabel: 'Acoustic Identity',
      title: 'Aesthetic Audio Studio',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. NOTIFICATION SOUNDS (5 PRESETS + UPLOAD)
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
                        Icon(LucideIcons.bellRing, size: 16, color: terracotta),
                        const SizedBox(width: 8),
                        Text('NOTIFICATION TONES', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: terracotta)),
                      ],
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      onPressed: () => AestheticAudioService().pickCustomSound(isAlarm: false, context: context, ref: ref),
                      icon: const Icon(LucideIcons.upload, size: 12),
                      label: const Text('Upload', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                Text('5 curated aesthetic notification tones synthesized natively.', style: GoogleFonts.dmSans(fontSize: 11.5, color: subtextColor)),
                const SizedBox(height: 12),
                ...AestheticAudioService.notificationPresets.map((sound) {
                  final isSelected = settings.notificationSound == sound.id;
                  final isPlaying = _previewingSoundId == sound.id;
                  return _buildSubSoundTile(
                    sound: sound,
                    isSelected: isSelected,
                    isPlaying: isPlaying,
                    isDark: isDark,
                    primaryTextColor: primaryTextColor,
                    subtextColor: subtextColor,
                    accentColor: terracotta,
                    onSelect: () {
                      SanctuaryHapticEngine.dialDetent();
                      ref.read(appSettingsProvider.notifier).setNotificationSound(sound.id);
                    },
                    onPreview: () async {
                      setState(() => _previewingSoundId = sound.id);
                      await AestheticAudioService().previewSound(soundId: sound.id, isAlarm: false);
                      await Future.delayed(const Duration(milliseconds: 600));
                      if (mounted) setState(() => _previewingSoundId = null);
                    },
                  );
                }),
                if (settings.notificationSound == 'custom') ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: edBox(
                      color: terracotta.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: terracotta.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.fileAudio, size: 14, color: terracotta),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Custom: ${settings.customNotificationSoundName ?? 'Uploaded audio file'}',
                              style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, color: primaryTextColor)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. ALARM MELODIES (5 PRESETS + UPLOAD)
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
                        Icon(LucideIcons.watch, size: 16, color: terracotta),
                        const SizedBox(width: 8),
                        Text('ALARM & REMINDER MELODIES', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: terracotta)),
                      ],
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      onPressed: () => AestheticAudioService().pickCustomSound(isAlarm: true, context: context, ref: ref),
                      icon: const Icon(LucideIcons.upload, size: 12),
                      label: const Text('Upload', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                Text('5 distinct harmonic melodies for alarms and critical reminders.', style: GoogleFonts.dmSans(fontSize: 11.5, color: subtextColor)),
                const SizedBox(height: 12),
                ...AestheticAudioService.alarmPresets.map((sound) {
                  final isSelected = settings.alarmSound == sound.id;
                  final isPlaying = _previewingSoundId == sound.id;
                  return _buildSubSoundTile(
                    sound: sound,
                    isSelected: isSelected,
                    isPlaying: isPlaying,
                    isDark: isDark,
                    primaryTextColor: primaryTextColor,
                    subtextColor: subtextColor,
                    accentColor: terracotta,
                    onSelect: () {
                      SanctuaryHapticEngine.dialDetent();
                      ref.read(appSettingsProvider.notifier).setAlarmSound(sound.id);
                    },
                    onPreview: () async {
                      setState(() => _previewingSoundId = sound.id);
                      await AestheticAudioService().previewSound(soundId: sound.id, isAlarm: true);
                      await Future.delayed(const Duration(milliseconds: 700));
                      if (mounted) setState(() => _previewingSoundId = null);
                    },
                  );
                }),
                if (settings.alarmSound == 'custom') ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: edBox(
                      color: terracotta.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: terracotta.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.fileAudio, size: 14, color: terracotta),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Custom: ${settings.customAlarmSoundName ?? 'Uploaded audio file'}',
                              style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, color: primaryTextColor)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. FOCUS TIMER CONTINUOUS LOOP SOUNDS (5 PRESETS + UPLOAD)
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
                        Icon(LucideIcons.headphones, size: 16, color: terracotta),
                        const SizedBox(width: 8),
                        Text('FOCUS TIMER AMBIENT SOUNDTRACKS', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: terracotta)),
                      ],
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      onPressed: () => AestheticAudioService().pickCustomFocusSound(context, ref),
                      icon: const Icon(LucideIcons.upload, size: 12),
                      label: const Text('Upload', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                Text('Endless looping ambient sounds that play continuously for your focus session.', style: GoogleFonts.dmSans(fontSize: 11.5, color: subtextColor)),
                const SizedBox(height: 12),
                ...AestheticAudioService.focusLoopPresets.map((sound) {
                  final isSelected = settings.focusLoopSound == sound.id;
                  final isPlaying = _previewingSoundId == sound.id;
                  return _buildSubSoundTile(
                    sound: sound,
                    isSelected: isSelected,
                    isPlaying: isPlaying,
                    isDark: isDark,
                    primaryTextColor: primaryTextColor,
                    subtextColor: subtextColor,
                    accentColor: terracotta,
                    onSelect: () {
                      SanctuaryHapticEngine.dialDetent();
                      ref.read(appSettingsProvider.notifier).setFocusLoopSound(sound.id);
                    },
                    onPreview: () async {
                      if (_previewingSoundId == sound.id) {
                        await AestheticAudioService().stopFocusLoop();
                        setState(() => _previewingSoundId = null);
                      } else {
                        setState(() => _previewingSoundId = sound.id);
                        await AestheticAudioService().startFocusLoop(soundId: sound.id);
                        await Future.delayed(const Duration(seconds: 4));
                        if (mounted && _previewingSoundId == sound.id) {
                          await AestheticAudioService().stopFocusLoop();
                          setState(() => _previewingSoundId = null);
                        }
                      }
                    },
                  );
                }),
                if (settings.focusLoopSound == 'custom') ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: edBox(
                      color: terracotta.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: terracotta.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.fileAudio, size: 14, color: terracotta),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Custom: ${settings.customFocusSoundName ?? 'Uploaded audio file'}',
                              style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, color: primaryTextColor)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubSoundTile({
    required AestheticSound sound,
    required bool isSelected,
    required bool isPlaying,
    required bool isDark,
    required Color primaryTextColor,
    required Color subtextColor,
    required Color accentColor,
    required VoidCallback onSelect,
    required VoidCallback onPreview,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: edBox(
        color: isSelected ? accentColor.withValues(alpha: 0.1) : (isDark ? const Color(0xFF111111) : const Color(0xFFF9F6F0)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? accentColor : (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE5DFD4)),
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Radio<bool>(value: true, groupValue: isSelected, activeColor: accentColor, onChanged: (_) => onSelect()),
          const SizedBox(width: 4),
          Icon(sound.icon, size: 16, color: sound.accentColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sound.name, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.bold, color: primaryTextColor)),
                Text(sound.subtitle, style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Preview sound',
            icon: Icon(isPlaying ? LucideIcons.volume2 : LucideIcons.play, size: 16, color: isPlaying ? accentColor : subtextColor),
            onPressed: onPreview,
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 3. NOTIFICATIONS & REMINDERS SUBPAGE
// ==========================================
class NotificationsSettingsSubpage extends ConsumerWidget {
  const NotificationsSettingsSubpage({super.key});

  Future<void> _pickTime({
    required BuildContext context,
    required String initialTime,
    required ValueChanged<String> onSelected,
  }) async {
    final parts = initialTime.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 8,
      minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      final formatted = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      onSelected(formatted);
      SanctuaryHapticEngine.dialDetent();
    }
  }

  String _formatTzOffset(Duration offset) {
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    return '$sign$hours:$minutes';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    final terracotta = isDark ? const Color(0xFFE8927C) : AppColors.secondary;
    final gold = isDark ? const Color(0xFFE5B869) : AppColors.goldPrimary;
    final settings = ref.watch(appSettingsProvider);

    return SettingsSubpageScaffold(
      categoryLabel: 'Reminders & Cadence',
      title: 'Notifications & Alerts',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notification History & Audit Log Tile
          InkWell(
            onTap: () {
              SanctuaryHapticEngine.selection();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: edBox(
                color: terracotta.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: terracotta.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: edBox(color: terracotta.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                    child: Icon(LucideIcons.bellDot, size: 18, color: terracotta),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Notification History & Audit Log', style: GoogleFonts.dmSans(fontSize: 13.5, fontWeight: FontWeight.bold, color: primaryTextColor)),
                        const SizedBox(height: 2),
                        Text('Filter, search, and review dispatched notifications by user.', style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor)),
                      ],
                    ),
                  ),
                  Icon(LucideIcons.chevronRight, size: 18, color: terracotta),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Master Notifications Kill-Switch & Quick Control
          Builder(builder: (context) {
            final masterEnabled = settings.remindersEnabled ||
                settings.deviceSystemNotifications ||
                settings.dailyEngagementNotifications;
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: edBox(
                color: (masterEnabled ? terracotta : Colors.grey).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (masterEnabled ? terracotta : Colors.grey).withValues(alpha: 0.35),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              masterEnabled ? LucideIcons.bell : LucideIcons.bellOff,
                              size: 18,
                              color: masterEnabled ? terracotta : subtextColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'All Notifications',
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: primaryTextColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          masterEnabled
                              ? 'Notifications are Active. Tap switch to turn off all alerts & alarms with one tap.'
                              : 'All notifications, streak alerts, and alarms are completely turned off.',
                          style: GoogleFonts.dmSans(fontSize: 11.5, color: subtextColor),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: masterEnabled,
                    activeColor: terracotta,
                    onChanged: (enabled) {
                      SanctuaryHapticEngine.selection();
                      ref.read(appSettingsProvider.notifier).setRemindersEnabled(enabled);
                      ref.read(appSettingsProvider.notifier).setDeviceSystemNotifications(enabled);
                      ref.read(appSettingsProvider.notifier).setDailyEngagementNotifications(enabled);
                      if (!enabled) {
                        DeviceNotificationService().cancelAllReminders();
                        DailyEngagementService().scheduleDailyCadence(
                          enabled: false,
                          cadenceHours: settings.notificationCadenceHours,
                          morningTimeStr: settings.morningBriefingTime,
                          eveningTimeStr: settings.eveningReflectionTime,
                          quietHoursEnabled: settings.quietHoursEnabled,
                          quietHoursStart: settings.quietHoursStart,
                          quietHoursEnd: settings.quietHoursEnd,
                        );
                      } else {
                        DailyEngagementService().scheduleDailyCadence(
                          enabled: true,
                          cadenceHours: settings.notificationCadenceHours,
                          morningTimeStr: settings.morningBriefingTime,
                          eveningTimeStr: settings.eveningReflectionTime,
                          quietHoursEnabled: settings.quietHoursEnabled,
                          quietHoursStart: settings.quietHoursStart,
                          quietHoursEnd: settings.quietHoursEnd,
                        );
                        DeviceNotificationService().requestPermission();
                      }
                    },
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),

          // Cadence & System Push
          BentoPod(
            style: PodTextureStyle.glass,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _subpageSwitch(
                  'Due Reminders',
                  'Notify when tasks, calendar events, or habit milestones arrive.',
                  settings.remindersEnabled,
                  (v) => ref.read(appSettingsProvider.notifier).setRemindersEnabled(v),
                  primaryTextColor,
                  subtextColor,
                ),
                const Divider(height: 24),
                _subpageSwitch(
                  'Device System Notifications',
                  'Deliver task due alerts and calendar reminders directly in the Android notification bar even when closed.',
                  settings.deviceSystemNotifications,
                  (v) {
                    ref.read(appSettingsProvider.notifier).setDeviceSystemNotifications(v);
                    if (v) DeviceNotificationService().requestPermission();
                  },
                  primaryTextColor,
                  subtextColor,
                ),
                const Divider(height: 24),
                _subpageSwitch(
                  'Daily Engagement & Streak Alerts',
                  settings.notificationCadenceHours >= 24
                      ? 'Personalized on-device push notifications once daily for streak momentum and daily reflections.'
                      : 'Personalized on-device push notifications every ${settings.notificationCadenceHours} hours for streak momentum and daily reflections.',
                  settings.dailyEngagementNotifications,
                  (v) {
                    ref.read(appSettingsProvider.notifier).setDailyEngagementNotifications(v);
                    DailyEngagementService().scheduleDailyCadence(
                      enabled: v,
                      cadenceHours: settings.notificationCadenceHours,
                      morningTimeStr: settings.morningBriefingTime,
                      eveningTimeStr: settings.eveningReflectionTime,
                      quietHoursEnabled: settings.quietHoursEnabled,
                      quietHoursStart: settings.quietHoursStart,
                      quietHoursEnd: settings.quietHoursEnd,
                    );
                    if (v) DeviceNotificationService().requestPermission();
                  },
                  primaryTextColor,
                  subtextColor,
                ),
                const Divider(height: 24),
                // Daily Briefing Time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Morning Briefing Time', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.bold, color: primaryTextColor)),
                        Text('Scheduled morning synthesis delivery time.', style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor)),
                      ],
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: terracotta.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _pickTime(
                        context: context,
                        initialTime: settings.morningBriefingTime,
                        onSelected: (t) {
                          ref.read(appSettingsProvider.notifier).setMorningBriefingTime(t);
                          DailyEngagementService().scheduleDailyCadence(
                            enabled: settings.dailyEngagementNotifications,
                            cadenceHours: settings.notificationCadenceHours,
                            morningTimeStr: t,
                            eveningTimeStr: settings.eveningReflectionTime,
                            quietHoursEnabled: settings.quietHoursEnabled,
                            quietHoursStart: settings.quietHoursStart,
                            quietHoursEnd: settings.quietHoursEnd,
                          );
                        },
                      ),
                      child: Text(settings.morningBriefingTime, style: TextStyle(fontWeight: FontWeight.bold, color: terracotta)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Evening Reflection Time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Evening Reflection & Daily Recap', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.bold, color: primaryTextColor)),
                        Text('Scheduled evening review and gratitude recap.', style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor)),
                      ],
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: terracotta.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _pickTime(
                        context: context,
                        initialTime: settings.eveningReflectionTime,
                        onSelected: (t) {
                          ref.read(appSettingsProvider.notifier).setEveningReflectionTime(t);
                          DailyEngagementService().scheduleDailyCadence(
                            enabled: settings.dailyEngagementNotifications,
                            cadenceHours: settings.notificationCadenceHours,
                            morningTimeStr: settings.morningBriefingTime,
                            eveningTimeStr: t,
                            quietHoursEnabled: settings.quietHoursEnabled,
                            quietHoursStart: settings.quietHoursStart,
                            quietHoursEnd: settings.quietHoursEnd,
                          );
                        },
                      ),
                      child: Text(settings.eveningReflectionTime, style: TextStyle(fontWeight: FontWeight.bold, color: terracotta)),
                    ),
                  ],
                ),
                const Divider(height: 24),
                // Notification Cadence Interval Selector
                Row(
                  children: [
                    Icon(LucideIcons.clock, size: 16, color: terracotta),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Notification Cadence / Interval',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: edBox(
                        color: terracotta.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: terracotta.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        settings.notificationCadenceLabel,
                        style: GoogleFonts.dmSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: terracotta,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Frequency of on-device streak reminders, focus pulses, and mindful check-ins throughout waking hours.',
                  style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    (1, '1h'),
                    (2, '2h'),
                    (3, '3h'),
                    (4, '4h'),
                    (6, '6h'),
                    (12, 'Twice Daily (Default)'),
                    (24, 'Once Daily'),
                  ].map((opt) {
                    final isSelected = settings.notificationCadenceHours == opt.$1;
                    return InkWell(
                      onTap: () {
                        SanctuaryHapticEngine.dialDetent();
                        ref.read(appSettingsProvider.notifier).setNotificationCadenceHours(opt.$1);
                        DailyEngagementService().scheduleDailyCadence(
                          enabled: settings.dailyEngagementNotifications,
                          cadenceHours: opt.$1,
                          morningTimeStr: settings.morningBriefingTime,
                          eveningTimeStr: settings.eveningReflectionTime,
                          quietHoursEnabled: settings.quietHoursEnabled,
                          quietHoursStart: settings.quietHoursStart,
                          quietHoursEnd: settings.quietHoursEnd,
                        );
                        AppToastEngine().notifyAnimated(
                          title: 'Cadence Updated',
                          message: 'On-device notifications spaced ${opt.$2}.',
                          type: ToastType.success,
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: edBox(
                          color: isSelected
                              ? terracotta.withValues(alpha: isDark ? 0.25 : 0.15)
                              : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04)),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? terracotta
                                : (isDark ? Colors.white24 : Colors.black12),
                            width: isSelected ? 1.4 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[
                              Icon(LucideIcons.check, size: 12, color: terracotta),
                              const SizedBox(width: 5),
                            ],
                            Text(
                              opt.$2,
                              style: GoogleFonts.dmSans(
                                fontSize: 11.5,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? terracotta : primaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                Builder(builder: (context) {
                  final estTimes = DailyEngagementService.calculateScheduleTimes(
                    referenceTime: DateTime.now(),
                    cadenceHours: settings.notificationCadenceHours,
                    morningTimeStr: settings.morningBriefingTime,
                    eveningTimeStr: settings.eveningReflectionTime,
                    quietHoursEnabled: settings.quietHoursEnabled,
                    quietHoursStart: settings.quietHoursStart,
                    quietHoursEnd: settings.quietHoursEnd,
                  );
                  return Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: edBox(
                      color: gold.withValues(alpha: isDark ? 0.1 : 0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: gold.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.bellRing, size: 13, color: gold),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            settings.dailyEngagementNotifications
                                ? 'Schedules ~${estTimes.length} smart check-in${estTimes.length == 1 ? '' : 's'} per day between ${settings.morningBriefingTime} and ${settings.eveningReflectionTime}.'
                                : 'Daily engagement notifications are currently disabled.',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: subtextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(height: 24),
                _subpageSwitch(
                  'Quiet Hours (Do Not Disturb)',
                  'Mute all non-critical notifications between ${settings.quietHoursStart} and ${settings.quietHoursEnd}.',
                  settings.quietHoursEnabled,
                  (v) {
                    ref.read(appSettingsProvider.notifier).setQuietHours(enabled: v);
                    DailyEngagementService().scheduleDailyCadence(
                      enabled: settings.dailyEngagementNotifications,
                      cadenceHours: settings.notificationCadenceHours,
                      morningTimeStr: settings.morningBriefingTime,
                      eveningTimeStr: settings.eveningReflectionTime,
                      quietHoursEnabled: v,
                      quietHoursStart: settings.quietHoursStart,
                      quietHoursEnd: settings.quietHoursEnd,
                    );
                  },
                  primaryTextColor,
                  subtextColor,
                ),
                const Divider(height: 24),
                // Local Timezone & Location Awareness Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: edBox(
                    color: gold.withValues(alpha: isDark ? 0.12 : 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: gold.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.globe, size: 16, color: gold),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Local Timezone: ${DateTime.now().timeZoneName} (UTC${_formatTzOffset(DateTime.now().timeZoneOffset)})',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: primaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Notifications deliver at scheduled wall-clock times in your local timezone. When traveling, alerts automatically adapt to your new location.',
                              style: GoogleFonts.dmSans(fontSize: 11.5, color: subtextColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Test Notifications
          BentoPod(
            style: PodTextureStyle.glass,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TEST NOTIFICATION TRIGGERS', style: GoogleFonts.dmSans(fontSize: 11.5, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: terracotta)),
                const SizedBox(height: 8),
                Text('Verify in-app animated notifications and Android status bar push alerts.', style: GoogleFonts.dmSans(fontSize: 11.5, color: subtextColor)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: terracotta.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          SanctuaryHapticEngine.sealImpression();
                          AppToastEngine().notifyAnimated(
                            title: 'Sanctuary Synchronized',
                            message: 'Haute precision timing and encrypted sync verified.',
                            type: ToastType.success,
                          );
                        },
                        icon: Icon(LucideIcons.bellRing, size: 14, color: terracotta),
                        label: Text('In-App Alert', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, color: terracotta)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: terracotta.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          SanctuaryHapticEngine.sealImpression();
                          final ok = await DeviceNotificationService().showSystemNotification(
                            title: 'NOTtEodo System Notification',
                            message: 'Creative notification verified outside the app in the status bar!',
                          );
                          AppToastEngine().notifyAnimated(
                            title: ok ? 'Notification Delivered' : 'Permission Required',
                            message: ok ? 'Check your device notification bar.' : 'Please allow notifications for NOTtEodo.',
                            type: ok ? ToastType.success : ToastType.alert,
                          );
                        },
                        icon: Icon(LucideIcons.bell, size: 14, color: terracotta),
                        label: Text('Device Push', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, color: terracotta)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 4. FINANCIAL DISCIPLINE SUBPAGE
// ==========================================
class FinancialSettingsSubpage extends ConsumerStatefulWidget {
  const FinancialSettingsSubpage({super.key});

  @override
  ConsumerState<FinancialSettingsSubpage> createState() => _FinancialSettingsSubpageState();
}

class _FinancialSettingsSubpageState extends ConsumerState<FinancialSettingsSubpage> {
  static const currencies = ['₹', '\$', '€', '£', '¥', 'CHF '];
  late final TextEditingController _budgetCtrl = TextEditingController(
    text: ref.read(appSettingsProvider).monthlyBudget?.toStringAsFixed(0) ?? '',
  );

  @override
  void dispose() {
    _budgetCtrl.dispose();
    super.dispose();
  }

  void _saveBudget() {
    final v = double.tryParse(_budgetCtrl.text.replaceAll(',', '').trim());
    ref.read(appSettingsProvider.notifier).setMonthlyBudget(v);
    FocusScope.of(context).unfocus();
    SanctuaryHapticEngine.sealImpression();
    AppToastEngine().showToast(context, title: 'Budget Saved', message: v == null || v <= 0 ? 'Monthly budget cleared.' : 'Monthly budget set to $v');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    final terracotta = isDark ? const Color(0xFFE8927C) : AppColors.secondary;
    final settings = ref.watch(appSettingsProvider);

    return SettingsSubpageScaffold(
      categoryLabel: 'Treasury Guardrails',
      title: 'Financial Discipline',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BentoPod(
            style: PodTextureStyle.glass,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.coins, size: 16, color: terracotta),
                    const SizedBox(width: 8),
                    Text('CURRENCY SYMBOL', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: terracotta)),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final c in currencies)
                      ChoiceChip(
                        label: Text(c.trim()),
                        selected: settings.currencySymbol == c,
                        onSelected: (_) {
                          SanctuaryHapticEngine.dialDetent();
                          ref.read(appSettingsProvider.notifier).setCurrency(c);
                        },
                      ),
                  ],
                ),
                const Divider(height: 28),
                Row(
                  children: [
                    Icon(LucideIcons.wallet, size: 16, color: terracotta),
                    const SizedBox(width: 8),
                    Text('MONTHLY BUDGET CEILING', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: terracotta)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Discretionary spending guardrail for executive pacing.', style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _budgetCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                        decoration: InputDecoration(
                          isDense: true,
                          prefixText: '${settings.currencySymbol} ',
                          hintText: 'e.g. 25000',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onSubmitted: (_) => _saveBudget(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: terracotta, foregroundColor: Colors.black),
                      onPressed: _saveBudget,
                      child: const Text('Save'),
                    ),
                  ],
                ),
                const Divider(height: 28),
                Text('Budget Alert Sensitivity', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.bold, color: primaryTextColor)),
                Text('Trigger alerts when burn pace reaches this ratio.', style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [75, 80, 90, 100].map((thr) {
                    final isSel = settings.budgetAlertThreshold == thr;
                    return ChoiceChip(
                      label: Text('$thr% of Budget'),
                      selected: isSel,
                      onSelected: (_) {
                        SanctuaryHapticEngine.dialDetent();
                        ref.read(appSettingsProvider.notifier).setBudgetAlertThreshold(thr);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 5. SECURITY & SOVEREIGN VAULT SUBPAGE
// ==========================================
class SecuritySettingsSubpage extends StatelessWidget {
  const SecuritySettingsSubpage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsSubpageScaffold(
      categoryLabel: 'Cryptography & Biometrics',
      title: 'Security & Private Vault',
      child: SecuritySettingsPod(),
    );
  }
}

// ==========================================
// 6. AI & INTELLIGENT ASSISTANT SUBPAGE
// ==========================================
class AiSettingsSubpage extends StatelessWidget {
  const AiSettingsSubpage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsSubpageScaffold(
      categoryLabel: 'Cognitive Persona & Intelligence',
      title: 'AI & Intelligent Assistant',
      child: AiSettingsPod(),
    );
  }
}

// ==========================================
// 7. ACCOUNT & CLOUD SYNC SUBPAGE
// ==========================================
class SyncSettingsSubpage extends ConsumerWidget {
  const SyncSettingsSubpage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    final cloud = SanctuarySupabaseService();

    return SettingsSubpageScaffold(
      categoryLabel: 'Multi-Device Ledger',
      title: 'Account & Cloud Sync',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cloud.currentUser != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => confirmAndDeleteAccount(context),
                child: Text('Delete my account', style: GoogleFonts.dmSans(color: AppColors.error, fontWeight: FontWeight.w600)),
              ),
            ),
          BentoPod(
            style: PodTextureStyle.glass,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ValueListenableBuilder<SyncStatus>(
                  valueListenable: CloudSyncService().status,
                  builder: (context, status, _) => Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(cloud.currentUser?.email ?? 'Not signed in',
                                style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.bold, color: primaryTextColor)),
                            Text(
                              !cloud.isInitialized
                                  ? 'Cloud sync is not configured in this build; everything stays on this device.'
                                  : status.lastSyncAt == null
                                      ? (status.message ?? status.label)
                                      : '${status.label} · ${DateLabels.dateTime(status.lastSyncAt!)}',
                              style: GoogleFonts.dmSans(fontSize: 11, color: status.phase == SyncPhase.error ? AppColors.error : subtextColor),
                            ),
                          ],
                        ),
                      ),
                      if (cloud.isConnectedToCloud && status.phase == SyncPhase.needsMfa)
                        FilledButton(
                          onPressed: () async {
                            if (await showMfaChallenge(context)) CloudSyncService().syncNow();
                          },
                          child: const Text('Verify'),
                        )
                      else if (cloud.isConnectedToCloud)
                        OutlinedButton.icon(
                          onPressed: status.phase == SyncPhase.syncing ? null : () => CloudSyncService().syncNow(),
                          icon: const Icon(LucideIcons.refreshCw, size: 14),
                          label: const Text('Sync now'),
                        ),
                    ],
                  ),
                ),
                if (cloud.isConnectedToCloud) const CloudSecurityTiles(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 8. DATA PORTABILITY & BACKUP SUBPAGE
// ==========================================
class BackupSettingsSubpage extends ConsumerWidget {
  const BackupSettingsSubpage({super.key});

  String get _stamp => DateLabels.dayKey(DateTime.now());

  Future<void> _download(BuildContext context, String name, String content, String mime) async {
    final ok = await downloadTextFile(name, content, mimeType: mime);
    if (!context.mounted) return;
    if (ok) {
      AppToastEngine().showToast(context, title: 'Export Saved', message: 'Saved $name');
    } else {
      await EphemeralClipboardSanitizer.copyEphemeralSecret(secret: content, timeout: const Duration(seconds: 90));
      if (context.mounted) AppToastEngine().showToast(context, title: 'Copied to Clipboard', message: 'Copied $name (cleared in 90s)');
    }
  }

  Future<void> _exportBackup(BuildContext context) async {
    final pass = await showDialog<String>(
      context: context,
      builder: (_) => const PassphraseDialog(
        title: 'Protect this backup',
        message: 'The file is encrypted with AES-256 using this password. You will need it to restore.',
        submitLabel: 'Encrypt & save',
        skipLabel: 'Save unencrypted',
      ),
    );
    if (pass == null || !context.mounted) return;
    final name = 'notteodo-backup-$_stamp.json';
    if (pass.isEmpty) {
      await _download(context, name, DataPortabilityService.buildBackupJson(), 'application/json');
      return;
    }
    final content = await DataPortabilityService.buildEncryptedBackup(pass);
    if (context.mounted) await _download(context, name, content, 'application/json');
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    var text = await pickTextFile(accept: '.json,application/json');
    if (text == null || !context.mounted) return;
    if (DataPortabilityService.isEncryptedBackup(text)) {
      final pass = await showDialog<String>(
        context: context,
        builder: (_) => const PassphraseDialog(
          title: 'Backup password',
          message: 'This backup is encrypted. Enter the password used when it was saved.',
          confirm: false,
          submitLabel: 'Decrypt',
        ),
      );
      if (pass == null || !context.mounted) return;
      try {
        text = await DataPortabilityService.decryptBackup(text, pass);
      } on FormatException catch (e) {
        if (context.mounted) AppToastEngine().showToast(context, title: 'Error', message: e.message);
        return;
      } catch (_) {
        if (context.mounted) AppToastEngine().showToast(context, title: 'Error', message: 'This backup file is damaged.');
        return;
      }
      if (!context.mounted) return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore this backup?'),
        content: const Text('Every module in the backup replaces what is on this device now. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restore')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final counts = await DataPortabilityService.importBackupJson(text);
      reloadAllFromStore(ref);
      final total = counts.values.fold<int>(0, (a, b) => a + b);
      if (context.mounted) AppToastEngine().showToast(context, title: 'Restored', message: 'Restored $total items from backup');
    } on FormatException catch (e) {
      if (context.mounted) AppToastEngine().showToast(context, title: 'Error', message: e.message);
    }
  }

  Future<void> _eraseAll(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Erase everything on this device?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Notes, tasks, expenses, settings, the app PIN and Bin are deleted from this device. Type ERASE to confirm.'),
              const SizedBox(height: 12),
              TextField(controller: ctrl, autofocus: true, onChanged: (_) => setLocal(() {})),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: ctrl.text.trim() == 'ERASE' ? () => Navigator.pop(ctx, true) : null,
              child: const Text('Erase'),
            ),
          ],
        ),
      ),
    );
    ctrl.dispose();
    if (confirmed != true) return;
    if (SanctuarySupabaseService().currentUser != null) {
      await SanctuarySupabaseService().signOut();
    }
    CloudSyncService().resetForAccountChange();
    await LocalStore().eraseAll();
    ref.read(appSettingsProvider.notifier).reloadFromStore();
    resetAllProviders(ref);
    removeAllSamples(ref);
    if (context.mounted) AppToastEngine().showToast(context, title: 'Device Erased', message: 'All local data was permanently removed.');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;

    return SettingsSubpageScaffold(
      categoryLabel: 'Open Formats & Recovery',
      title: 'Data Portability & Backup',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BentoPod(
            style: PodTextureStyle.paper,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Export your encrypted data in open JSON, CSV, Markdown, or ICS formats.', style: GoogleFonts.dmSans(fontSize: 12, color: subtextColor)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _exportBtn('Full backup (.json)', LucideIcons.fileCode, primaryTextColor, () => _exportBackup(context)),
                    _exportBtn('Expenses (.csv)', LucideIcons.table, primaryTextColor,
                        () => _download(context, 'notteodo-expenses-$_stamp.csv', DataPortabilityService.expensesCsv(ref.read(expensesProvider).expenses), 'text/csv')),
                    _exportBtn('Tasks (.csv)', LucideIcons.checkSquare, primaryTextColor,
                        () => _download(context, 'notteodo-tasks-$_stamp.csv', DataPortabilityService.tasksCsv(ref.read(tasksProvider)), 'text/csv')),
                    _exportBtn('Notes (.md)', LucideIcons.fileText, primaryTextColor,
                        () => _download(context, 'notteodo-notes-$_stamp.md', DataPortabilityService.notesMarkdown(ref.read(notesProvider)), 'text/markdown')),
                    _exportBtn('Calendar (.ics)', LucideIcons.calendar, primaryTextColor, () => _download(
                        context,
                        'notteodo-calendar-$_stamp.ics',
                        IcsExport.build(events: ref.read(eventsProvider), tasks: ref.read(tasksProvider), trips: ref.read(travelProvider)),
                        'text/calendar')),
                  ],
                ),
                const Divider(height: 28),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _exportBtn('Restore backup…', LucideIcons.upload, primaryTextColor, () => _import(context, ref)),
                    _exportBtn('Remove sample data', LucideIcons.eraser, primaryTextColor, () {
                      removeAllSamples(ref);
                      AppToastEngine().showToast(context, title: 'Samples Removed', message: 'Sample content cleared.');
                    }),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.error.withValues(alpha: 0.6)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      onPressed: () => _eraseAll(context, ref),
                      icon: const Icon(LucideIcons.trash2, size: 14, color: AppColors.error),
                      label: Text('Erase all data', style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _exportBtn(String label, IconData icon, Color textColor, VoidCallback onPressed) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: AppColors.secondary.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 14, color: AppColors.secondary),
      label: Text(label, style: GoogleFonts.dmSans(fontSize: 12, color: textColor, fontWeight: FontWeight.bold)),
    );
  }
}

// ==========================================
// 9. SYSTEM TOOLS & DIAGNOSTICS SUBPAGE
// ==========================================
class DiagnosticsSettingsSubpage extends StatelessWidget {
  const DiagnosticsSettingsSubpage({super.key});

  void _showChangelogModal(BuildContext context) {
    SanctuaryHapticEngine.buttonPress();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0F0F0F) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(LucideIcons.sparkles, size: 20, color: isDark ? const Color(0xFFE8927C) : AppColors.secondary),
            const SizedBox(width: 8),
            Text("What's New in NOTtEodo", style: GoogleFonts.bodoniModa(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _clItem('In-App Voice Studio', 'Playable voice recording + real-time speech transcription router to notes, tasks, habits, and journal.'),
              _clItem('Continuous Focus Audio Loops', '5 soothing default looping soundtracks (Rain, Zen Drone, Forest Wind, Singing Bowl, Campfire) + custom audio uploads.'),
              _clItem('Hierarchical Settings Hub', 'Organized dedicated category sub-pages with card visibility toggles (hide briefing, budget, and expenses).'),
              _clItem('Live Streaks & Badges', 'Real consecutive active streaks with collectible passport badges and expanded identity card.'),
              _clItem('Duolingo-Style 3-Hr Alerts', 'Scheduled background push notifications for daily momentum and streak protection.'),
            ],
          ),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: isDark ? const Color(0xFFE8927C) : AppColors.secondary, foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Awesome'),
          ),
        ],
      ),
    );
  }

  Widget _clItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• $title', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 2),
          Text(desc, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    final terracotta = isDark ? const Color(0xFFE8927C) : AppColors.secondary;

    return SettingsSubpageScaffold(
      categoryLabel: 'Developer & Governance',
      title: 'Diagnostics & System Tools',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BentoPod(
            style: PodTextureStyle.glass,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: terracotta,
                      side: BorderSide(color: terracotta.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _showChangelogModal(context),
                    icon: const Icon(LucideIcons.sparkles, size: 15),
                    label: const Text("What's New in NOTtEodo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: terracotta,
                      side: BorderSide(color: terracotta.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => AppFeatureWalkthroughModal.show(context),
                    icon: const Icon(LucideIcons.compass, size: 15),
                    label: const Text("Interactive Feature Walkthrough", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: terracotta,
                      side: BorderSide(color: terracotta.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HomescreenWidgetStudioScreen()));
                    },
                    icon: const Icon(LucideIcons.layoutGrid, size: 15),
                    label: const Text("Homescreen Widget Studio", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // About NOTtEodo
          BentoPod(
            style: PodTextureStyle.glass,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                const StitchMonogramNWidget(size: 54),
                const SizedBox(height: 12),
                Text('NOTtEodo', style: GoogleFonts.bodoniModa(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: primaryTextColor)),
                const SizedBox(height: 4),
                Text('Enterprise Edition · v2.5.0', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: terracotta)),
                const SizedBox(height: 8),
                Text(
                  'Crafted with Swiss watchmaker precision. Zero-knowledge on-device privacy, in-app voice studio, ambient focus soundtracks, and clean animated HUD.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(fontSize: 11.5, color: subtextColor, height: 1.4),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
