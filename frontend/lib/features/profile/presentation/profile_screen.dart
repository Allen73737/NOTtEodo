import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/motion/motion.dart';
import '../../../core/performance/sanctuary_motion_engine.dart';
import '../../../core/services/cloud_sync_service.dart';
import '../../../core/services/device_media_service.dart';
import '../../../core/services/sanctuary_supabase_service.dart';
import '../../../core/state/app_settings.dart';
import '../../../core/state/sanctuary_state.dart';
import '../../../core/utils/date_labels.dart';
import '../../../core/widgets/app_toast_engine.dart';
import '../../../core/widgets/bento_pod.dart';
import '../../../core/widgets/fluid_ui_effects.dart';
import '../../../core/widgets/stitch_logo_widget.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    final gold = isDark ? AppColors.goldLight : AppColors.secondary;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Choose Your Avatar',
                        style: GoogleFonts.bodoniModa(fontSize: 20, fontWeight: FontWeight.bold, color: primaryTextColor)),
                    IconButton(icon: Icon(LucideIcons.x, size: 18, color: subtextColor), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 16),
                Text('UPLOAD PHOTO', style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: gold)),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryTextColor,
                    side: BorderSide(color: isDark ? const Color(0xFF222222) : const Color(0xFFE2DDD2)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final media = await DeviceMediaService().pickImage();
                    if (media != null) {
                      ref.read(appSettingsProvider.notifier).setAvatarCustomPath(media.path);
                      SanctuaryHapticEngine.sealImpression();
                      if (context.mounted) {
                        AppToastEngine().showToast(context, title: 'Avatar Updated', message: 'Profile photo set successfully.');
                      }
                    }
                  },
                  icon: const Icon(LucideIcons.uploadCloud, size: 16),
                  label: const Text('Upload Photo from Device', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const SizedBox(height: 20),
                Text('LUXURY PRESETS', style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: gold)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _presetAvatarButton('horology', LucideIcons.watch, 'Watch', settings.avatarPreset == 'horology', gold, () {
                      ref.read(appSettingsProvider.notifier).setAvatarPreset('horology');
                      Navigator.pop(ctx);
                    }),
                    _presetAvatarButton('wax_seal', LucideIcons.stamp, 'Seal', settings.avatarPreset == 'wax_seal', gold, () {
                      ref.read(appSettingsProvider.notifier).setAvatarPreset('wax_seal');
                      Navigator.pop(ctx);
                    }),
                    _presetAvatarButton('fountain_pen', LucideIcons.penTool, 'Pen', settings.avatarPreset == 'fountain_pen', gold, () {
                      ref.read(appSettingsProvider.notifier).setAvatarPreset('fountain_pen');
                      Navigator.pop(ctx);
                    }),
                    _presetAvatarButton('compass', LucideIcons.compass, 'Compass', settings.avatarPreset == 'compass', gold, () {
                      ref.read(appSettingsProvider.notifier).setAvatarPreset('compass');
                      Navigator.pop(ctx);
                    }),
                    _presetAvatarButton('monogram', LucideIcons.gem, 'Gem', settings.avatarPreset == 'monogram', gold, () {
                      ref.read(appSettingsProvider.notifier).setAvatarPreset('monogram');
                      Navigator.pop(ctx);
                    }),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () {
                      ref.read(appSettingsProvider.notifier).setAvatarPreset(null);
                      Navigator.pop(ctx);
                    },
                    child: Text('Reset to Name Initial', style: TextStyle(color: subtextColor, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _presetAvatarButton(String id, IconData icon, String label, bool isSelected, Color gold, VoidCallback onTap) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? gold.withValues(alpha: 0.2) : Colors.transparent,
              border: Border.all(color: isSelected ? gold : const Color(0xFF333333), width: isSelected ? 2 : 1),
            ),
            child: Icon(icon, color: isSelected ? gold : const Color(0xFF888888), size: 20),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF888888))),
      ],
    );
  }

  Widget _buildAvatarWidget(AppSettings settings, Color gold) {
    if (settings.avatarCustomPath != null && settings.avatarCustomPath!.isNotEmpty) {
      final path = settings.avatarCustomPath!;
      if (!kIsWeb && File(path).existsSync()) {
        return ClipOval(
          child: Image.file(File(path), width: 72, height: 72, fit: BoxFit.cover),
        );
      }
    }

    if (settings.avatarPreset != null) {
      IconData icon = LucideIcons.user;
      if (settings.avatarPreset == 'horology') icon = LucideIcons.watch;
      if (settings.avatarPreset == 'wax_seal') icon = LucideIcons.stamp;
      if (settings.avatarPreset == 'fountain_pen') icon = LucideIcons.penTool;
      if (settings.avatarPreset == 'compass') icon = LucideIcons.compass;
      if (settings.avatarPreset == 'monogram') icon = LucideIcons.gem;
      return Center(child: Icon(icon, size: 28, color: gold));
    }

    if (settings.displayName.isEmpty) {
      return const StitchLogoWidget(fontSize: 20, showTagline: false, showMonogramN: true);
    }

    return Center(
      child: Text(settings.initial,
          style: GoogleFonts.bodoniModa(fontSize: 30, fontWeight: FontWeight.bold, color: gold)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    final tileColor = isDark ? const Color(0xFF0E0E0E) : AppColors.surfaceContainerHigh.withValues(alpha: 0.6);
    final gold = isDark ? AppColors.goldLight : AppColors.secondary;

    final settings = ref.watch(appSettingsProvider);
    final notes = ref.watch(notesProvider);
    final tasks = ref.watch(tasksProvider);
    final habits = ref.watch(habitsProvider);
    final trips = ref.watch(travelProvider);
    final journal = ref.watch(journalProvider);
    final pins = ref.watch(moodboardProvider);
    final expenses = ref.watch(expensesProvider).expenses;
    final user = SanctuarySupabaseService().currentUser;

    final bestStreak = habits.fold<int>(0, (m, h) => h.bestStreak > m ? h.bestStreak : m);
    final tasksDone = tasks.where((t) => t.completed).length;
    final name = settings.displayName.isEmpty ? 'Add your name' : settings.displayName;

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
      ('🌿', '7-Day Streak', 'Keep a habit a week', bestStreak >= 7),
      ('📌', 'Note Keeper', '25 notes saved', notes.length >= 25),
      ('✅', 'Finisher', '50 tasks done', tasksDone >= 50),
      ('✈️', 'Wanderer', '3 trips planned', trips.length >= 3),
      ('📖', 'Reflective', '10 journal entries', journal.length >= 10),
      ('🎨', 'Curator', '12 moodboard pins', pins.length >= 12),
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
          Text('ACCOUNT & IDENTITY', style: AppTypography.labelSm),
          const SizedBox(height: 4),
          Text(
            'Profile',
            style: GoogleFonts.bodoniModa(fontSize: 28, fontWeight: FontWeight.bold, color: primaryTextColor),
            overflow: TextOverflow.ellipsis,
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
                                        style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.bold, color: gold),
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
                    _statItem('${notes.length}', 'Notes', primaryTextColor, subtextColor),
                    _statItem('$tasksDone', 'Tasks Done', primaryTextColor, subtextColor),
                    _statItem('${bestStreak}d', 'Best Streak', primaryTextColor, subtextColor),
                    _statItem('${trips.length}', 'Trips', primaryTextColor, subtextColor),
                  ],
                ),
              ],
            ),
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
                            style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.bold, color: count > 1 ? Colors.black : gold),
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
                    Text('Less', style: GoogleFonts.dmSans(fontSize: 9, color: subtextColor)),
                    const SizedBox(width: 4),
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: gold.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 3),
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: gold.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 3),
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: gold.withValues(alpha: 0.65), borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 3),
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: gold.withValues(alpha: 0.95), borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 4),
                    Text('More', style: GoogleFonts.dmSans(fontSize: 9, color: subtextColor)),
                  ],
                ),
              ],
            ),
          ),
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
                        child: Container(height: 10, color: const Color(0xFFD4AF37)),
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
                    _storageCategoryDot(const Color(0xFFD4AF37), 'Notes & Journal', '${textMb.toStringAsFixed(1)} MB', primaryTextColor, subtextColor),
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
          child: Text(size, style: GoogleFonts.dmSans(fontSize: 10, color: subText)),
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
              Text(subtitle, style: GoogleFonts.dmSans(fontSize: 9, color: subtextColor), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statItem(String val, String label, Color primaryTextColor, Color subtextColor) {
    return Expanded(
      child: Column(
        children: [
          Text(val, style: GoogleFonts.bodoniModa(fontSize: 22, fontWeight: FontWeight.bold, color: primaryTextColor)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.dmSans(fontSize: 10, color: subtextColor), textAlign: TextAlign.center),
        ],
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
            child: Text(badge, style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.bold, color: gold)),
          ),
        ],
      ),
    );
  }
}
