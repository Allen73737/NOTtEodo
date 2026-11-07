import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../services/device_media_service.dart';
import '../utils/date_labels.dart';
import '../state/app_settings.dart';
import '../state/sanctuary_state.dart';
import 'app_toast_engine.dart';
import 'sanctuary_avatar_catalog.dart';

class CuratorIdentityDialog extends ConsumerStatefulWidget {
  const CuratorIdentityDialog({super.key});

  static Future<void> show(BuildContext context) async {
    HapticFeedback.heavyImpact();
    await showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (_) => const CuratorIdentityDialog(),
    );
  }

  @override
  ConsumerState<CuratorIdentityDialog> createState() => _CuratorIdentityDialogState();
}

class _CuratorIdentityDialogState extends ConsumerState<CuratorIdentityDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  bool _isEditingLocation = false;
  late final TextEditingController _locCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack);
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();

    final loc = ref.read(appSettingsProvider).userLocation ?? '';
    _locCtrl = TextEditingController(text: loc);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _locCtrl.dispose();
    super.dispose();
  }

  void _saveLocation() {
    final text = _locCtrl.text.trim();
    ref.read(appSettingsProvider.notifier).setUserLocation(text.isEmpty ? null : text);
    setState(() => _isEditingLocation = false);
    HapticFeedback.lightImpact();
    AppToastEngine().showToast(
      context,
      title: 'Location Updated',
      message: text.isEmpty ? 'Location removed from profile.' : 'Set to "$text".',
    );
  }

  Future<void> _showAvatarPickerOptions(BuildContext context) async {
    HapticFeedback.selectionClick();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? const Color(0xFFFAF8F5) : const Color(0xFF1B1917);
    final subtextColor = isDark ? const Color(0xFFB0A89F) : const Color(0xFF6B655D);
    const terracotta = Color(0xFFD9725B);

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141210) : const Color(0xFFFFFDF8),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: isDark ? const Color(0xFF2C241E) : const Color(0xFFE5DDD0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: subtextColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Curator Avatar & Identity',
              style: GoogleFonts.bodoniModa(fontSize: 18, fontWeight: FontWeight.bold, color: primaryTextColor),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: terracotta.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: const Icon(LucideIcons.sparkles, size: 20, color: terracotta),
              ),
              title: Text('Choose Animated Archetype Avatar', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, color: primaryTextColor)),
              subtitle: Text('16 Archetypes across Gentlemen, Ladies, & Mythic personas', style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor)),
              onTap: () {
                Navigator.pop(ctx);
                SanctuaryAvatarCatalog.showSelector(context, ref);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF8FA878).withValues(alpha: 0.15), shape: BoxShape.circle),
                child: const Icon(LucideIcons.camera, size: 20, color: Color(0xFF8FA878)),
              ),
              title: Text('Upload Photo from Device', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, color: primaryTextColor)),
              subtitle: Text('Select an image from gallery or file storage', style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor)),
              onTap: () async {
                Navigator.pop(ctx);
                final media = await DeviceMediaService().pickImage();
                if (media != null && context.mounted) {
                  ref.read(appSettingsProvider.notifier).setAvatarCustomPath(media.path);
                  AppToastEngine().showToast(context, title: 'Avatar Updated', message: 'Your curator passport photo is refreshed.');
                }
              },
            ),
            if (ref.read(appSettingsProvider).avatarPreset != null ||
                (ref.read(appSettingsProvider).avatarCustomPath != null && ref.read(appSettingsProvider).avatarCustomPath!.isNotEmpty))
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: Icon(LucideIcons.rotateCcw, size: 20, color: subtextColor),
                ),
                title: Text('Reset to Monogram Initial', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, color: primaryTextColor)),
                subtitle: Text('Default to initial "${ref.read(appSettingsProvider).initial}"', style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor)),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(appSettingsProvider.notifier).resetAvatar();
                  AppToastEngine().showToast(context, title: 'Avatar Reset', message: 'Defaulted to your initial monogram.');
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? const Color(0xFFFAF8F5) : const Color(0xFF1B1917);
    final subtextColor = isDark ? const Color(0xFFB0A89F) : const Color(0xFF6B655D);
    final cardBg = isDark ? const Color(0xFF12100E) : const Color(0xFFFFFDF8);
    final borderColor = isDark ? const Color(0xFF2C241E) : const Color(0xFFE5DDD0);
    const terracotta = Color(0xFFD9725B);
    const warmSage = Color(0xFF8FA878);

    final notesCount = ref.watch(notesProvider).length;
    final tasksDone = ref.watch(tasksProvider).where((t) => t.completed).length;
    final habits = ref.watch(habitsProvider);
    final streak = settings.activeStreak > 0 ? settings.activeStreak : 1;

    final badges = [
      {'title': 'Genesis', 'desc': 'Day 1 Sanctuary Explorer', 'icon': '🌟', 'unlocked': streak >= 1},
      {'title': 'Momentum', 'desc': '3-Day Active Flow', 'icon': '🔥', 'unlocked': streak >= 3},
      {'title': 'Master', 'desc': '7-Day Unbroken Habit', 'icon': '👑', 'unlocked': streak >= 7},
      {'title': 'Archivist', 'desc': '5+ Notes Crafted', 'icon': '📜', 'unlocked': notesCount >= 5},
      {'title': 'Titan', 'desc': '5+ Tasks Conquered', 'icon': '⚡', 'unlocked': tasksDone >= 5},
      {'title': 'Zen Master', 'desc': 'Habit Discipline', 'icon': '🧘', 'unlocked': habits.isNotEmpty},
    ];

    return Center(
      child: ScaleTransition(
        scale: _scaleAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: borderColor, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.8 : 0.25),
                    blurRadius: 36,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Bar with Close Icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: terracotta.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: terracotta.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            'CURATOR PASSPORT',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: terracotta,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E1A16) : const Color(0xFFEDE6DA),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(LucideIcons.x, size: 16, color: subtextColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Expanded High-Res Avatar Pod with Glow Aura & Archetype Selector
                    GestureDetector(
                      onTap: () => _showAvatarPickerOptions(context),
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: terracotta.withValues(alpha: 0.35),
                                  blurRadius: 24,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: SanctuaryActiveAvatarView(
                              settings: settings,
                              size: 96,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: terracotta,
                              border: Border.all(color: cardBg, width: 2),
                            ),
                            child: const Icon(LucideIcons.pencil, size: 13, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Display Name
                    Text(
                      settings.displayName.isEmpty ? 'Sanctuary Curator' : settings.displayName,
                      style: GoogleFonts.bodoniModa(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      settings.bioMotto.isEmpty ? 'Focused productivity workspace' : settings.bioMotto,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(fontSize: 12, color: subtextColor),
                    ),
                    const SizedBox(height: 16),

                    // Live Real Streak & Metrics Ribbon
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0A0908) : const Color(0xFFF3ECE0),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMetricCol('🔥 $streak Days', 'Live Streak', terracotta),
                          _buildDivider(borderColor),
                          _buildMetricCol('❄️ ${settings.streakFreezesCount}', 'Streak Freezes', const Color(0xFF90B4CE)),
                          _buildDivider(borderColor),
                          _buildMetricCol('${badges.where((b) => b['unlocked'] == true).length}/6', 'Badges', warmSage),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF90B4CE).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF90B4CE).withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('❄️', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 6),
                          Text(
                            '${settings.streakFreezesCount} Streak Freezes Active · Shields missed days',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF90B4CE),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Flame Evolution Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: terracotta.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: terracotta.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Text(streak >= 14 ? '👑' : (streak >= 7 ? '⚡' : (streak >= 4 ? '🔥' : '✨')), style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'FLAME STATUS: ${_getFlameLevel(streak).toUpperCase()}',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.1,
                                    color: terracotta,
                                  ),
                                ),
                                Text(
                                  _getFlameDesc(streak),
                                  style: GoogleFonts.dmSans(fontSize: 11, color: primaryTextColor),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Streak Recovery Habit Quest Card
                    _buildStreakQuest(context, habits, settings, terracotta, warmSage, isDark, borderColor),
                    const SizedBox(height: 14),

                    // Wax-Seal Monthly Calendar Heatmap
                    _buildWaxSealCalendar(isDark, borderColor, primaryTextColor, subtextColor, terracotta, habits, streak),
                    const SizedBox(height: 16),

                    // Optional User Location Field
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF171411) : const Color(0xFFF5EEE2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: _isEditingLocation
                          ? Row(
                              children: [
                                const Icon(LucideIcons.mapPin, size: 15, color: terracotta),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _locCtrl,
                                    autofocus: true,
                                    style: GoogleFonts.dmSans(fontSize: 12.5, color: primaryTextColor),
                                    decoration: const InputDecoration(
                                      hintText: 'City, Country (e.g. Tokyo, JP)',
                                      isDense: true,
                                      border: InputBorder.none,
                                    ),
                                    onSubmitted: (_) => _saveLocation(),
                                  ),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(LucideIcons.check, size: 16, color: warmSage),
                                  onPressed: _saveLocation,
                                ),
                              ],
                            )
                          : InkWell(
                              onTap: () => setState(() => _isEditingLocation = true),
                              borderRadius: BorderRadius.circular(10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(LucideIcons.mapPin, size: 14, color: terracotta),
                                      const SizedBox(width: 8),
                                      Text(
                                        settings.userLocation != null && settings.userLocation!.isNotEmpty
                                            ? settings.userLocation!
                                            : 'Add Location (Optional)',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: settings.userLocation != null && settings.userLocation!.isNotEmpty
                                              ? primaryTextColor
                                              : subtextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Icon(LucideIcons.pencil, size: 12, color: subtextColor),
                                ],
                              ),
                            ),
                    ),
                    const SizedBox(height: 18),

                    // Badges & Stickers Grid
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'SANCTUARY BADGES & ACHIEVEMENTS',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: subtextColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: badges.map((b) {
                        final isUnlocked = b['unlocked'] as bool;
                        return Container(
                          width: 116,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          decoration: BoxDecoration(
                            color: isUnlocked
                                ? (isDark ? const Color(0xFF1E1712) : const Color(0xFFFBEFE3))
                                : (isDark ? const Color(0xFF110E0B) : const Color(0xFFEBE4D6)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isUnlocked
                                  ? terracotta.withValues(alpha: 0.5)
                                  : (isDark ? Colors.white10 : Colors.black12),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(b['icon'] as String, style: const TextStyle(fontSize: 16)),
                                  if (!isUnlocked)
                                    Icon(LucideIcons.lock, size: 11, color: subtextColor.withValues(alpha: 0.5)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                b['title'] as String,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isUnlocked ? primaryTextColor : subtextColor,
                                ),
                              ),
                              Text(
                                b['desc'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.dmSans(
                                  fontSize: 8.5,
                                  color: subtextColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCol(String val, String label, Color color) {
    return Column(
      children: [
        Text(
          val,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.dmSans(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildDivider(Color color) {
    return Container(width: 1, height: 26, color: color);
  }

  String _getFlameLevel(int streak) {
    if (streak >= 14) return 'Solar Flame';
    if (streak >= 7) return 'Blazing Flare';
    if (streak >= 4) return 'Warm Hearth';
    return 'Kindling Spark';
  }

  String _getFlameDesc(int streak) {
    if (streak >= 14) return 'Tier IV · Solar Flame · 14+ days unbroken light';
    if (streak >= 7) return 'Tier III · Blazing Flare · 1 full week of consistency';
    if (streak >= 4) return 'Tier II · Warm Hearth · Building steady discipline';
    return 'Tier I · Kindling Spark · Momentum ignited';
  }

  Widget _buildStreakQuest(
    BuildContext context,
    List<HabitItem> habits,
    AppSettings settings,
    Color terracotta,
    Color warmSage,
    bool isDark,
    Color borderColor,
  ) {
    final todayKey = DateLabels.dayKey(DateTime.now());
    final habitsDoneToday = habits.where((h) => h.completedDays.contains(todayKey)).length;
    const questTarget = 3;
    final isQuestDone = habitsDoneToday >= questTarget;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161412) : const Color(0xFFF7F3EA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isQuestDone ? warmSage.withValues(alpha: 0.6) : borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('🎯', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    'DAILY STREAK QUEST',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: isQuestDone ? warmSage : terracotta,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: (isQuestDone ? warmSage : terracotta).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$habitsDoneToday / $questTarget Habits',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isQuestDone ? warmSage : terracotta,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isQuestDone
                ? 'Quest completed! +1 Streak Freeze active to guard missed days.'
                : 'Complete 3 habits today to earn +1 Streak Freeze shield.',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildWaxSealCalendar(
    bool isDark,
    Color borderColor,
    Color primaryTextColor,
    Color subtextColor,
    Color terracotta,
    List<HabitItem> habits,
    int streak,
  ) {
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final today = now.day;

    final Set<int> activeDaysThisMonth = {};
    for (int day = 1; day <= daysInMonth; day++) {
      final dateKey = DateLabels.dayKey(DateTime(now.year, now.month, day));
      final hasHabit = habits.any((h) => h.completedDays.contains(dateKey));
      final isStreakDay = (today - day >= 0) && (today - day < streak);
      if (hasHabit || isStreakDay) {
        activeDaysThisMonth.add(day);
      }
    }

    final monthName = DateLabels.monthYear(now);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF110F0D) : const Color(0xFFFBF8F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'WAX-SEAL MOMENTUM HEATMAP',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: terracotta,
                ),
              ),
              Text(
                monthName.toUpperCase(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: subtextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map((d) => SizedBox(
                      width: 28,
                      child: Text(
                        d,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.bold, color: subtextColor),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 5,
            alignment: WrapAlignment.start,
            children: List.generate(daysInMonth, (index) {
              final dayNum = index + 1;
              final isToday = dayNum == today;
              final isActive = activeDaysThisMonth.contains(dayNum);

              return Container(
                width: 34,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? terracotta.withValues(alpha: isToday ? 0.35 : 0.2)
                      : (isToday ? (isDark ? Colors.white12 : Colors.black12) : Colors.transparent),
                  border: Border.all(
                    color: isToday
                        ? terracotta
                        : (isActive ? terracotta.withValues(alpha: 0.5) : Colors.transparent),
                    width: isToday ? 1.5 : 1.0,
                  ),
                ),
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isActive)
                        const Text('🔥', style: TextStyle(fontSize: 14))
                      else
                        Text(
                          '$dayNum',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10.5,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            color: isToday ? terracotta : (dayNum > today ? subtextColor.withValues(alpha: 0.3) : subtextColor),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

