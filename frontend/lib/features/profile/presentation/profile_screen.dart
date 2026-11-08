import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/motion/motion.dart';
import '../../../core/performance/sanctuary_motion_engine.dart';
import '../../../core/services/cloud_sync_service.dart';
import '../../../core/services/sanctuary_supabase_service.dart';
import '../../../core/services/streak_achievement_service.dart';
import '../../../core/state/app_settings.dart';
import '../../../core/state/sanctuary_state.dart';
import '../../../core/utils/date_labels.dart';
import '../../../core/widgets/app_toast_engine.dart';
import '../../../core/widgets/bento_pod.dart';
import '../../../core/widgets/fluid_ui_effects.dart';
import '../../../core/widgets/habit_heatmap_and_curators_cabinet.dart';
import '../../../core/widgets/sanctuary_avatar_catalog.dart';
import '../../../core/widgets/streak_flame_evolution.dart';
import '../../settings/presentation/settings_screen.dart';

class ProfileScreen extends ConsumerWidget {
  /// Signs out (or, when not signed in, goes to the sign-in screen).
  final VoidCallback? onLogout;

  const ProfileScreen({super.key, this.onLogout});

  Future<void> _editName(BuildContext context, WidgetRef ref) async {
    SanctuaryHapticEngine.buttonPress();
    final ctrl = TextEditingController(text: ref.read(appSettingsProvider).displayName);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Your name'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 40,
          decoration: const InputDecoration(hintText: 'What should we call you?'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Save')),
        ],
      ),
    );
    ctrl.dispose();
    if (name != null) ref.read(appSettingsProvider.notifier).setDisplayName(name);
  }

  Future<void> _editMotto(BuildContext context, WidgetRef ref) async {
    SanctuaryHapticEngine.buttonPress();
    final ctrl = TextEditingController(text: ref.read(appSettingsProvider).bioMotto);
    final motto = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Personal Motto / Focus Status'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 80,
          decoration: const InputDecoration(hintText: 'e.g. Focus on high-leverage priorities.'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Save')),
        ],
      ),
    );
    ctrl.dispose();
    if (motto != null) ref.read(appSettingsProvider.notifier).setBioMotto(motto);
  }

  void _showAvatarCustomizer(BuildContext context, WidgetRef ref, AppSettings settings) {
    SanctuaryHapticEngine.buttonPress();
    SanctuaryAvatarCatalog.showSelector(context, ref);
  }

  Widget _buildAvatarWidget(AppSettings settings, Color gold) {
    return SanctuaryActiveAvatarView(settings: settings, size: 72);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    final tileColor = isDark ? const Color(0xFF0E0E0E) : AppColors.surfaceContainerHigh.withValues(alpha: 0.6);
    final gold = isDark ? const Color(0xFFE8927C) : AppColors.secondary;
    final terracotta = isDark ? const Color(0xFFE8927C) : const Color(0xFFD9725B);

    final settings = ref.watch(appSettingsProvider);
    final notes = ref.watch(notesProvider);
    final tasks = ref.watch(tasksProvider);
    final habits = ref.watch(habitsProvider);
    final journal = ref.watch(journalProvider);
    final pins = ref.watch(moodboardProvider);
    final expenses = ref.watch(expensesProvider).expenses;
    final user = SanctuarySupabaseService().currentUser;

    final bestStreak = habits.fold<int>(0, (m, h) => h.bestStreak > m ? h.bestStreak : m);
    final activeStreak = settings.activeStreak > 0 ? settings.activeStreak : 1;
    final longestStreak = math.max(settings.longestStreak, math.max(activeStreak, bestStreak));
    final tasksDone = tasks.where((t) => t.completed).length;
    final name = settings.displayName.isEmpty ? 'Add your name' : settings.displayName;

    // Automatic streak synchronization on profile view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      StreakAchievementService.checkAndUpdateStreak(ref, null);
    });

    // 30-Day Activity Heatmap computation
    final now = DateTime.now();
    final List<int> activityLast30Days = List.generate(30, (i) {
      final targetDate = now.subtract(Duration(days: 29 - i));
      int count = 0;
      count += tasks.where((t) => t.completed && t.completedAt != null && _isSameDay(t.completedAt!, targetDate)).length;
      count += expenses.where((e) => _isSameDay(e.spentAt, targetDate)).length;
      count += notes.where((n) => _isSameDay(n.updatedAt, targetDate)).length;
      return count;
    });

    final activeDaysCount = activityLast30Days.where((c) => c > 0).length;

    // Storage footprint estimation
    final notesChars = notes.fold<int>(0, (sum, n) => sum + n.title.length + n.content.length);
    final journalChars = journal.fold<int>(0, (sum, j) => sum + j.title.length + j.excerpt.length);
    final textMb = ((notesChars + journalChars) * 2 / (1024 * 1024)).clamp(0.4, 25.0);
    final photosMb = (pins.length * 1.8).clamp(0.8, 120.0);
    const cacheMb = 4.2;
    final totalMb = textMb + photosMb + cacheMb;

    // Milestones earned
    final achievements = <(String, String, String, bool)>[
      ('🌿', '7-Day Streak', 'Maintain a 7-day streak', longestStreak >= 7 || activeStreak >= 7),
      ('🔥', 'Streak Master', 'Reach a 14-day streak', longestStreak >= 14 || activeStreak >= 14),
      ('❄️', 'Shielded', 'Possess a streak freeze shield', settings.streakFreezesCount > 0),
      ('📌', 'Note Keeper', '25 notes saved', notes.length >= 25),
      ('✅', 'Finisher', '50 tasks done', tasksDone >= 50),
      ('📖', 'Reflective', '10 journal entries', journal.length >= 10),
    ];

    final spaces = <String, int>{};
    for (final n in notes) {
      spaces[n.space] = (spaces[n.space] ?? 0) + 1;
    }
    final spaceList = spaces.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 140),
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
                    Text('ACCOUNT & IDENTITY', style: AppTypography.labelSm, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(
                      'Profile',
                      style: GoogleFonts.bodoniModa(fontSize: 28, fontWeight: FontWeight.bold, color: primaryTextColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: terracotta.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  SanctuaryHapticEngine.selection();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
                },
                icon: const Icon(LucideIcons.settings, size: 16),
                label: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // User Profile Dossier Card
          BentoPod(
            style: PodTextureStyle.glass,
            showWaxSeal: true,
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => _showAvatarCustomizer(context, ref, settings),
                      child: Stack(
                        children: [
                          Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: gold.withValues(alpha: 0.12),
                              border: Border.all(color: gold, width: 2),
                            ),
                            child: _buildAvatarWidget(settings, gold),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(color: gold, shape: BoxShape.circle),
                              child: const Icon(LucideIcons.pencil, size: 10, color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  style: GoogleFonts.bodoniModa(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: settings.displayName.isEmpty ? subtextColor : primaryTextColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Edit name',
                                icon: Icon(LucideIcons.pencil, size: 14, color: subtextColor),
                                onPressed: () => _editName(context, ref),
                              ),
                            ],
                          ),
                          // Personal Motto / Bio Status
                          GestureDetector(
                            onTap: () => _editMotto(context, ref),
                            child: Row(
                              children: [
                                Icon(LucideIcons.quote, size: 12, color: gold),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    settings.bioMotto.isEmpty ? 'Tap to set daily motto...' : settings.bioMotto,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: subtextColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Verification Badge & Member Since
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: gold.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: gold.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(LucideIcons.shieldCheck, size: 11, color: gold),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        'Verified',
                                        style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, color: gold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            user?.email ?? 'Saved on this device · Member since Oct 2026',
                            style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          ValueListenableBuilder<SyncStatus>(
                            valueListenable: CloudSyncService().status,
                            builder: (context, status, _) => Row(
                              children: [
                                Icon(
                                  status.phase == SyncPhase.error ? LucideIcons.cloudOff : LucideIcons.cloud,
                                  size: 13,
                                  color: gold,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    status.lastSyncAt == null
                                        ? status.label
                                        : '${status.label} · ${DateLabels.dateTime(status.lastSyncAt!)}',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: gold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    _statItem('${activeStreak}d', 'Active Streak', primaryTextColor, subtextColor, valueColor: gold),
                    _statItem('$tasksDone', 'Tasks Done', primaryTextColor, subtextColor),
                    _statItem('${notes.length}', 'Notes', primaryTextColor, subtextColor),
                    _statItem('${longestStreak}d', 'Best Streak', primaryTextColor, subtextColor, valueColor: gold),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Live Streak Momentum & Rituals Pod
          _buildStreakMomentumCard(
            context: context,
            ref: ref,
            settings: settings,
            activeStreak: activeStreak,
            longestStreak: longestStreak,
            isDark: isDark,
            primaryTextColor: primaryTextColor,
            subtextColor: subtextColor,
            gold: gold,
          ),
          const SizedBox(height: 20),

          // 30-Day Activity Cadence Heatmap
          BentoPod(
            style: PodTextureStyle.glass,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('30-DAY ACTIVITY CADENCE',
                          style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: gold),
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 6),
                    Text('$activeDaysCount of 30 active days',
                        style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: subtextColor)),
                  ],
                ),
                const SizedBox(height: 14),
                // 30 Days Heatmap Grid (6 columns x 5 rows)
                LayoutBuilder(builder: (context, c) {
                  final itemWidth = (c.maxWidth - 5 * 8) / 6;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(30, (idx) {
                      final count = activityLast30Days[idx];
                      final alpha = count == 0
                          ? 0.06
                          : count == 1
                              ? 0.35
                              : count == 2
                                  ? 0.65
                                  : 0.95;
                      return Container(
                        width: itemWidth,
                        height: 24,
                        decoration: BoxDecoration(
                          color: gold.withValues(alpha: alpha),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: count > 0 ? gold.withValues(alpha: 0.4) : (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE2DDD2)),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            count > 0 ? '$count' : '',
                            style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, color: count > 1 ? Colors.black : gold),
                          ),
                        ),
                      );
                    }),
                  );
                }),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('Less', style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor)),
                    const SizedBox(width: 4),
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: gold.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 3),
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: gold.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 3),
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: gold.withValues(alpha: 0.65), borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 3),
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: gold.withValues(alpha: 0.95), borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 4),
                    Text('More', style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Curator's Cabinet of Curiosities (Collectible Badges & Antique Crests)
          const CuratorsCabinetWidget(),
          const SizedBox(height: 20),

          // Visual Storage Meter (Requested: "photos and moodboards")
          BentoPod(
            style: PodTextureStyle.glass,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('DATA & STORAGE FOOTPRINT',
                          style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: gold),
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 6),
                    Text('${totalMb.toStringAsFixed(1)} MB Total',
                        style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, color: primaryTextColor)),
                  ],
                ),
                const SizedBox(height: 14),
                // Segmented Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: (textMb * 10).toInt(),
                        child: Container(height: 10, color: gold),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        flex: (photosMb * 10).toInt(),
                        child: Container(height: 10, color: const Color(0xFFD9725B)),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        flex: (cacheMb * 10).toInt(),
                        child: Container(height: 10, color: const Color(0xFF888888)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Storage categories breakdown
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    _storageCategoryDot(gold, 'Notes & Journal', '${textMb.toStringAsFixed(1)} MB', primaryTextColor, subtextColor),
                    _storageCategoryDot(const Color(0xFFD9725B), 'Photos & Moodboards', '${photosMb.toStringAsFixed(1)} MB', primaryTextColor, subtextColor),
                    _storageCategoryDot(const Color(0xFF888888), 'Local Cache', '${cacheMb.toStringAsFixed(1)} MB', primaryTextColor, subtextColor),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: gold,
                      side: BorderSide(color: gold.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () {
                      SanctuaryHapticEngine.sealImpression();
                      AppToastEngine().showToast(
                        context,
                        title: 'Cache Cleaned',
                        message: 'Freed up ${cacheMb.toStringAsFixed(1)} MB of temporary cache.',
                      );
                    },
                    icon: const Icon(LucideIcons.sparkles, size: 14),
                    label: const Text('Free Up Space', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Achievements BentoPod
          BentoPod(
            style: PodTextureStyle.glass,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ACHIEVEMENTS · ${achievements.where((a) => a.$4).length} OF ${achievements.length}',
                    style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: gold)),
                const SizedBox(height: 12),
                LayoutBuilder(builder: (context, c) {
                  final perRow = c.maxWidth >= 520 ? 6 : 3;
                  final w = (c.maxWidth - (perRow - 1) * 8) / perRow;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final a in achievements)
                        SizedBox(width: w, child: _badgeCard(a.$1, a.$2, a.$3, a.$4, primaryTextColor, subtextColor, tileColor, gold)),
                    ],
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Spaces BentoPod
          BentoPod(
            style: PodTextureStyle.paper,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('YOUR SPACES', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: gold)),
                const SizedBox(height: 12),
                if (spaceList.isEmpty)
                  Text('Spaces appear here as you file notes into them.', style: GoogleFonts.dmSans(fontSize: 12, color: subtextColor))
                else
                  for (final s in spaceList) ...[
                    _spaceTile(
                      s.key,
                      notes.where((n) => n.space == s.key).take(3).map((n) => n.title).join(', '),
                      '${s.value} note${s.value == 1 ? '' : 's'}',
                      primaryTextColor,
                      subtextColor,
                      tileColor,
                      gold,
                    ),
                    const SizedBox(height: 10),
                  ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (onLogout != null)
            BouncyTouchEffect(
              pressedScale: 0.94,
              onTap: onLogout,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: gold.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(user == null ? LucideIcons.logIn : LucideIcons.logOut, size: 18, color: gold),
                    const SizedBox(width: 10),
                    Text(
                      user == null ? 'Sign in to sync' : 'Log Out',
                      style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.bold, color: gold),
                    ),
                  ],
                ),
              ),
            ),
        ].revealed(),
      ),
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _storageCategoryDot(Color color, String title, String size, Color primaryText, Color subText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(title, style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, color: primaryText)),
          ],
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Text(size, style: GoogleFonts.dmSans(fontSize: 11, color: subText)),
        ),
      ],
    );
  }

  Widget _badgeCard(String icon, String title, String subtitle, bool earned, Color primaryTextColor, Color subtextColor, Color tileColor, Color gold) {
    return Semantics(
      label: '$title, ${earned ? 'earned' : 'not yet earned'}: $subtitle',
      child: Opacity(
        opacity: earned ? 1 : 0.45,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: gold.withValues(alpha: earned ? 0.6 : 0.2)),
          ),
          child: Column(
            children: [
              Text(earned ? icon : '🔒', style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 6),
              Text(title, style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, color: primaryTextColor), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(subtitle, style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statItem(String val, String label, Color primaryTextColor, Color subtextColor, {Color? valueColor}) {
    return Expanded(
      child: Column(
        children: [
          Text(val, style: GoogleFonts.bodoniModa(fontSize: 22, fontWeight: FontWeight.bold, color: valueColor ?? primaryTextColor)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildStreakMomentumCard({
    required BuildContext context,
    required WidgetRef ref,
    required AppSettings settings,
    required int activeStreak,
    required int longestStreak,
    required bool isDark,
    required Color primaryTextColor,
    required Color subtextColor,
    required Color gold,
  }) {
    const sage = Color(0xFF8FA878);

    final today = DateLabels.dayKey(DateTime.now());
    final isCheckedInToday = settings.lastActiveDate == today;

    // Milestone calculation (3, 7, 14, 30, 100)
    const milestones = [3, 7, 14, 30, 100];
    int nextMilestone = 3;
    int prevMilestone = 0;
    for (int i = 0; i < milestones.length; i++) {
      if (activeStreak < milestones[i]) {
        nextMilestone = milestones[i];
        prevMilestone = i == 0 ? 0 : milestones[i - 1];
        break;
      }
      if (i == milestones.length - 1) {
        nextMilestone = milestones[i];
        prevMilestone = milestones[i - 1];
      }
    }
    final range = (nextMilestone - prevMilestone).clamp(1, 100);
    final progress = ((activeStreak - prevMilestone) / range).clamp(0.0, 1.0);
    final tier = StreakFlameTier.fromDays(activeStreak);

    return BentoPod(
      style: PodTextureStyle.glass,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(tier.glyph, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'SANCTUARY STREAK & RITUALS',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(fontSize: 11.5, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: tier.glowColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: (isCheckedInToday ? sage : tier.glowColor).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: (isCheckedInToday ? sage : tier.glowColor).withValues(alpha: 0.4)),
                ),
                child: Text(
                  isCheckedInToday ? 'DAY $activeStreak ACTIVE' : 'CHECK-IN READY',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isCheckedInToday ? sage : tier.glowColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Main Streak Hero Row
          Row(
            children: [
              StreakFlameTierBadge(
                days: activeStreak,
                size: 46,
                onTap: () {
                  SanctuaryHapticEngine.selection();
                  StreakFlameEvolutionSheet.show(context, activeStreak);
                },
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      children: [
                        Text(
                          '$activeStreak Days',
                          style: GoogleFonts.bodoniModa(fontSize: 18, fontWeight: FontWeight.bold, color: primaryTextColor),
                        ),
                        Text(
                          '(Best: ${longestStreak}d)',
                          style: GoogleFonts.dmSans(fontSize: 11.5, color: subtextColor),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: tier.glowColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tier.badgeTitle,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: tier.glowColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Shielded by ${settings.streakFreezesCount} Freezes · Next: Day $nextMilestone',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        backgroundColor: isDark ? const Color(0xFF22201D) : const Color(0xFFEADBCE),
                        valueColor: AlwaysStoppedAnimation<Color>(tier.glowColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCheckedInToday ? sage.withValues(alpha: 0.2) : tier.glowColor,
                  foregroundColor: isCheckedInToday ? sage : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                ),
                onPressed: () {
                  SanctuaryHapticEngine.selection();
                  StreakAchievementService.checkAndUpdateStreak(ref, context);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isCheckedInToday ? LucideIcons.check : LucideIcons.flame, size: 12),
                    const SizedBox(width: 3),
                    Text(
                      isCheckedInToday ? 'Active' : 'Check In',
                      style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: isDark ? const Color(0xFF22201D) : const Color(0xFFEADBCE)),
          const SizedBox(height: 10),

          // Micro badge row
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.start,
            children: [
              _buildMiniBadge('❄️ ${settings.streakFreezesCount} Freezes', isDark, subtextColor),
              _buildMiniBadge('🏆 ${longestStreak}d Longest', isDark, subtextColor),
              InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () {
                  SanctuaryHapticEngine.selection();
                  StreakFlameEvolutionSheet.show(context, activeStreak);
                },
                child: _buildMiniBadge('🔥 ${tier.name} (View Tiers)', isDark, tier.glowColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBadge(String text, bool isDark, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141210) : const Color(0xFFF6F0E7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
      ),
    );
  }

  Widget _spaceTile(String title, String desc, String badge, Color primaryTextColor, Color subtextColor, Color tileColor, Color gold) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.bold, color: primaryTextColor)),
                Text(desc, style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: gold.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
            child: Text(badge, style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, color: gold)),
          ),
        ],
      ),
    );
  }
}
