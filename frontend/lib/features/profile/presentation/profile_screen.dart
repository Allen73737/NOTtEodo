import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/services/cloud_sync_service.dart';
import '../../../core/services/sanctuary_supabase_service.dart';
import '../../../core/state/app_settings.dart';
import '../../../core/state/sanctuary_state.dart';
import '../../../core/utils/date_labels.dart';
import '../../../core/widgets/bento_pod.dart';
import '../../../core/widgets/stitch_logo_widget.dart';

import '../../../core/widgets/fluid_ui_effects.dart';
import '../../../core/motion/motion.dart';

class ProfileScreen extends ConsumerWidget {
  /// Signs out (or, when not signed in, goes to the sign-in screen).
  final VoidCallback? onLogout;

  const ProfileScreen({super.key, this.onLogout});

  Future<void> _editName(BuildContext context, WidgetRef ref) async {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    final tileColor = isDark ? const Color(0xFF0E0E0E) : AppColors.surfaceContainerHigh.withValues(alpha: 0.6);

    final settings = ref.watch(appSettingsProvider);
    final notes = ref.watch(notesProvider);
    final tasks = ref.watch(tasksProvider);
    final habits = ref.watch(habitsProvider);
    final trips = ref.watch(travelProvider);
    final journal = ref.watch(journalProvider);
    final pins = ref.watch(moodboardProvider);
    final user = SanctuarySupabaseService().currentUser;

    final bestStreak = habits.fold<int>(0, (m, h) => h.bestStreak > m ? h.bestStreak : m);
    final tasksDone = tasks.where((t) => t.completed).length;
    final name = settings.displayName.isEmpty ? 'Add your name' : settings.displayName;

    // Milestones earned from what is actually in the app.
    final achievements = <(String, String, String, bool)>[
      ('ðŸŒ¿', '7-Day Streak', 'Keep a habit a week', bestStreak >= 7),
      ('ðŸ“', 'Note Keeper', '25 notes saved', notes.length >= 25),
      ('âœ…', 'Finisher', '50 tasks done', tasksDone >= 50),
      ('âœˆï¸', 'Wanderer', '3 trips planned', trips.length >= 3),
      ('ðŸ“–', 'Reflective', '10 journal entries', journal.length >= 10),
      ('ðŸŽ¨', 'Curator', '12 moodboard pins', pins.length >= 12),
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
          Text('ACCOUNT', style: AppTypography.labelSm),
          const SizedBox(height: 4),
          Text(
            'Profile',
            style: GoogleFonts.bodoniModa(fontSize: 28, fontWeight: FontWeight.bold, color: primaryTextColor),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),

          BentoPod(
            style: PodTextureStyle.glass,
            showWaxSeal: true,
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.secondary.withValues(alpha: 0.15),
                        border: Border.all(color: AppColors.secondary, width: 2),
                      ),
                      child: Center(
                        child: settings.displayName.isEmpty
                            ? const StitchLogoWidget(fontSize: 20, showTagline: false, showMonogramN: true)
                            : Text(settings.initial,
                                style: GoogleFonts.bodoniModa(fontSize: 30, fontWeight: FontWeight.bold, color: AppColors.secondary)),
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
                                icon: Icon(LucideIcons.pencil, size: 15, color: subtextColor),
                                onPressed: () => _editName(context, ref),
                              ),
                            ],
                          ),
                          Text(
                            user?.email ?? 'Not signed in Â· saved on this device',
                            style: GoogleFonts.dmSans(fontSize: 12, color: subtextColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          ValueListenableBuilder<SyncStatus>(
                            valueListenable: CloudSyncService().status,
                            builder: (context, status, _) => Row(
                              children: [
                                Icon(
                                  status.phase == SyncPhase.error ? LucideIcons.cloudOff : LucideIcons.cloud,
                                  size: 14,
                                  color: isDark ? AppColors.goldLight : AppColors.secondary,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    status.lastSyncAt == null
                                        ? status.label
                                        : '${status.label} Â· ${DateLabels.dateTime(status.lastSyncAt!)}',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? AppColors.goldLight : AppColors.secondary,
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

          BentoPod(
            style: PodTextureStyle.glass,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ACHIEVEMENTS Â· ${achievements.where((a) => a.$4).length} OF ${achievements.length}',
                    style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.secondary)),
                const SizedBox(height: 12),
                LayoutBuilder(builder: (context, c) {
                  final perRow = c.maxWidth >= 520 ? 6 : 3;
                  final w = (c.maxWidth - (perRow - 1) * 8) / perRow;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final a in achievements)
                        SizedBox(width: w, child: _badgeCard(a.$1, a.$2, a.$3, a.$4, primaryTextColor, subtextColor, tileColor)),
                    ],
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),

          BentoPod(
            style: PodTextureStyle.paper,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('YOUR SPACES', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.secondary)),
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
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(user == null ? LucideIcons.logIn : LucideIcons.logOut, size: 18, color: AppColors.secondary),
                    const SizedBox(width: 10),
                    Text(
                      user == null ? 'Sign in to sync' : 'Log Out',
                      style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.secondary),
                    ),
                  ],
                ),
              ),
            ),
        ].revealed(),
      ),
    );
  }

  Widget _badgeCard(String icon, String title, String subtitle, bool earned, Color primaryTextColor, Color subtextColor, Color tileColor) {
    return Semantics(
      label: '$title, ${earned ? 'earned' : 'not yet earned'}: $subtitle',
      child: Opacity(
        opacity: earned ? 1 : 0.45,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.secondary.withValues(alpha: earned ? 0.6 : 0.2)),
          ),
          child: Column(
            children: [
              Text(earned ? icon : 'ðŸ”’', style: const TextStyle(fontSize: 24)),
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

  Widget _spaceTile(String title, String desc, String badge, Color primaryTextColor, Color subtextColor, Color tileColor) {
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
            decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
            child: Text(badge, style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondary)),
          ),
        ],
      ),
    );
  }
}
