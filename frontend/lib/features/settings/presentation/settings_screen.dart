import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/motion/motion.dart';
import '../../../core/performance/sanctuary_motion_engine.dart';
import '../../../core/services/sanctuary_supabase_service.dart';
import '../../../core/state/app_settings.dart';
import '../../../core/state/notification_log_state.dart';
import '../../../core/widgets/bento_pod.dart';
import '../../../core/widgets/curator_identity_dialog.dart';
import 'settings_subpages.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    final terracotta = isDark ? const Color(0xFFE8927C) : AppColors.secondary;
    final settings = ref.watch(appSettingsProvider);
    final cloud = SanctuarySupabaseService();
    final logs = ref.watch(notificationLogsProvider);
    final unreadLogs = logs.where((e) => !e.isRead).length;

    return SingleChildScrollView(
      physics: SanctuaryMotionEngine.fluidPhysics,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PREFERENCES & SYSTEM', style: AppTypography.labelSm),
          const SizedBox(height: 4),
          Text(
            'Settings',
            style: GoogleFonts.bodoniModa(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: 18),

          // 1. CURATOR PASSPORT SUMMARY CARD (Interactive Tap to expand)
          InkWell(
            onTap: () {
              SanctuaryHapticEngine.selection();
              CuratorIdentityDialog.show(context);
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141210) : const Color(0xFFFAF7F0),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF262220) : const Color(0xFFE5DDD0),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF332D20), const Color(0xFF1E1A14)]
                            : [const Color(0xFFF3ECE0), const Color(0xFFE2D6C3)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: terracotta.withValues(alpha: 0.6), width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        settings.initial,
                        style: GoogleFonts.bodoniModa(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: terracotta,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                settings.displayName.trim().isEmpty ? 'Curator' : settings.displayName,
                                style: GoogleFonts.bodoniModa(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: primaryTextColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: terracotta.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('🔥', style: TextStyle(fontSize: 10)),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${settings.activeStreak}d',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: terracotta,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          settings.userLocation != null && settings.userLocation!.isNotEmpty
                              ? '📍 ${settings.userLocation} · Tap to view Passport'
                              : (cloud.currentUser?.email ?? 'Tap to view Curator Passport & Badges'),
                          style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(LucideIcons.chevronRight, size: 18, color: subtextColor),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 2. CATEGORY NAVIGATION TILES
          Text(
            'CATEGORIES',
            style: GoogleFonts.dmSans(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: terracotta,
            ),
          ),
          const SizedBox(height: 12),

          // 1. Display & Layout
          _buildCategoryCard(
            context: context,
            icon: LucideIcons.palette,
            title: 'Display & Layout',
            subtitle: 'Theme modes, landing screens, card visibility toggles & fonts',
            badge: settings.cleanHomescreenMode ? 'MINIMAL' : null,
            badgeColor: terracotta,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DisplaySettingsSubpage())),
            isDark: isDark,
            primaryTextColor: primaryTextColor,
            subtextColor: subtextColor,
            accentColor: terracotta,
          ),
          const SizedBox(height: 10),

          // 2. Aesthetic Audio Studio
          _buildCategoryCard(
            context: context,
            icon: LucideIcons.volume2,
            title: 'Aesthetic Audio Studio',
            subtitle: '5 notification tones, 5 alarms, 5 focus loops & custom uploads',
            badge: '5 LOOPS',
            badgeColor: const Color(0xFF8FA878),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AudioSettingsSubpage())),
            isDark: isDark,
            primaryTextColor: primaryTextColor,
            subtextColor: subtextColor,
            accentColor: terracotta,
          ),
          const SizedBox(height: 10),

          // 3. Notifications & Reminders
          _buildCategoryCard(
            context: context,
            icon: LucideIcons.bellRing,
            title: 'Notifications & Alerts',
            subtitle: 'Due reminders, 3-hour streak push, audit history & quiet hours',
            badge: unreadLogs > 0 ? '$unreadLogs NEW' : null,
            badgeColor: terracotta,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsSettingsSubpage())),
            isDark: isDark,
            primaryTextColor: primaryTextColor,
            subtextColor: subtextColor,
            accentColor: terracotta,
          ),
          const SizedBox(height: 10),

          // 4. Financial Discipline
          _buildCategoryCard(
            context: context,
            icon: LucideIcons.wallet,
            title: 'Financial Discipline',
            subtitle: 'Currency symbols (${settings.currencySymbol}), monthly budget ceiling & pacing thresholds',
            badge: settings.monthlyBudget != null ? '${settings.currencySymbol}${settings.monthlyBudget!.toStringAsFixed(0)}' : null,
            badgeColor: terracotta,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FinancialSettingsSubpage())),
            isDark: isDark,
            primaryTextColor: primaryTextColor,
            subtextColor: subtextColor,
            accentColor: terracotta,
          ),
          const SizedBox(height: 10),

          // 5. Security & Sovereign Vault
          _buildCategoryCard(
            context: context,
            icon: LucideIcons.shieldCheck,
            title: 'Security & Sovereign Vault',
            subtitle: 'AES-256 PIN, biometric unlock, panic gestures & auto-lock',
            badge: settings.vaultPin != null ? 'SECURED' : null,
            badgeColor: const Color(0xFF8FA878),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SecuritySettingsSubpage())),
            isDark: isDark,
            primaryTextColor: primaryTextColor,
            subtextColor: subtextColor,
            accentColor: terracotta,
          ),
          const SizedBox(height: 10),

          // 6. AI & Intelligent Assistant
          _buildCategoryCard(
            context: context,
            icon: LucideIcons.sparkles,
            title: 'AI & Cognitive Assistant',
            subtitle: 'Persona demeanor (${settings.aiPersona}), tone styling & suggestion heuristics',
            badge: settings.aiPersona.toUpperCase(),
            badgeColor: terracotta,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AiSettingsSubpage())),
            isDark: isDark,
            primaryTextColor: primaryTextColor,
            subtextColor: subtextColor,
            accentColor: terracotta,
          ),
          const SizedBox(height: 10),

          // 7. Account & Cloud Sync
          _buildCategoryCard(
            context: context,
            icon: LucideIcons.cloud,
            title: 'Account & Cloud Sync',
            subtitle: 'Supabase encrypted cloud ledger & multi-device sync state',
            badge: cloud.isConnectedToCloud ? 'CONNECTED' : 'LOCAL',
            badgeColor: cloud.isConnectedToCloud ? const Color(0xFF8FA878) : terracotta,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SyncSettingsSubpage())),
            isDark: isDark,
            primaryTextColor: primaryTextColor,
            subtextColor: subtextColor,
            accentColor: terracotta,
          ),
          const SizedBox(height: 10),

          // 8. Data Portability & Backup
          _buildCategoryCard(
            context: context,
            icon: LucideIcons.database,
            title: 'Data Portability & Backup',
            subtitle: 'Encrypted JSON backups, CSV tables, ICS calendar & full wipe',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BackupSettingsSubpage())),
            isDark: isDark,
            primaryTextColor: primaryTextColor,
            subtextColor: subtextColor,
            accentColor: terracotta,
          ),
          const SizedBox(height: 10),

          // 9. Diagnostics & System Tools
          _buildCategoryCard(
            context: context,
            icon: LucideIcons.wrench,
            title: 'Diagnostics & System Tools',
            subtitle: 'What\'s new release log, interactive walkthrough & widget studio',
            badge: 'v2.5.0',
            badgeColor: terracotta,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DiagnosticsSettingsSubpage())),
            isDark: isDark,
            primaryTextColor: primaryTextColor,
            subtextColor: subtextColor,
            accentColor: terracotta,
          ),
        ].revealed(),
      ),
    );
  }

  Widget _buildCategoryCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    String? badge,
    Color? badgeColor,
    required VoidCallback onTap,
    required bool isDark,
    required Color primaryTextColor,
    required Color subtextColor,
    required Color accentColor,
  }) {
    return BentoPod(
      style: PodTextureStyle.glass,
      onTap: () {
        SanctuaryHapticEngine.selection();
        onTap();
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accentColor.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, size: 20, color: accentColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: GoogleFonts.bodoniModa(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: (badgeColor ?? accentColor).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: badgeColor ?? accentColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: subtextColor,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(LucideIcons.chevronRight, size: 16, color: subtextColor.withValues(alpha: 0.6)),
        ],
      ),
    );
  }
}
