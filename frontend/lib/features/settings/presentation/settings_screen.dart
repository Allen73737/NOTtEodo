import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/motion/motion.dart';
import '../../../core/performance/sanctuary_motion_engine.dart';
import '../../../core/services/sanctuary_supabase_service.dart';
import '../../../core/state/app_settings.dart';
import '../../../core/state/notification_log_state.dart';
import '../../../core/widgets/bento_pod.dart';
import '../../../core/widgets/card_kit.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';
import '../../../core/widgets/curator_identity_dialog.dart';
import 'settings_subpages.dart';
import 'look_and_feel_page.dart';
import 'help_support_subpage.dart';
import 'privacy_safety_subpage.dart';
import 'terms_conditions_subpage.dart';
import 'about_notteodo_subpage.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = CardInk.of(context);
    final settings = ref.watch(appSettingsProvider);
    final cloud = SanctuarySupabaseService();
    final unreadLogs = ref.watch(notificationLogsProvider).where((e) => !e.isRead).length;
    void open(Widget page) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

    return SingleChildScrollView(
      physics: SanctuaryMotionEngine.fluidPhysics,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings', style: GoogleFonts.bodoniModa(fontSize: 36, fontWeight: FontWeight.bold, color: c.ink, height: 1.05)),
          const SizedBox(height: 20),

          // Who you are: initial, name, where you are, and your streak.
          BentoPod(
            style: PodTextureStyle.glass,
            padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
            onTap: () {
              SanctuaryHapticEngine.selection();
              CuratorIdentityDialog.show(context);
            },
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: c.fill),
                  alignment: Alignment.center,
                  child: Text(settings.initial, style: GoogleFonts.bodoniModa(fontSize: 22, fontWeight: FontWeight.bold, color: c.onFill)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        settings.displayName.trim().isEmpty ? 'Your profile' : settings.displayName,
                        style: c.title.copyWith(fontSize: 19),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (settings.userLocation != null && settings.userLocation!.isNotEmpty) settings.userLocation!,
                          if (cloud.currentUser?.email != null) cloud.currentUser!.email!,
                          '${settings.activeStreak}-day streak',
                        ].join(' · '),
                        style: c.meta.copyWith(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(LucideIcons.chevronRight, size: 18, color: c.muted),
              ],
            ),
          ),

          _SettingsGroup(title: 'Personal', rows: [
            _SettingsRow(icon: LucideIcons.sparkles, title: 'Look & feel', subtitle: 'View, accent, text size and gestures', status: viewStyleName(settings.cardStyle), onTap: () => open(const LookAndFeelPage())),
            _SettingsRow(icon: LucideIcons.palette, title: 'Display & layout', subtitle: 'Theme, fonts and home screen', status: settings.cleanHomescreenMode ? 'Minimal' : null, onTap: () => open(const DisplaySettingsSubpage())),
            _SettingsRow(icon: LucideIcons.volume2, title: 'Sounds', subtitle: 'Notification tones, alarms and focus loops', onTap: () => open(const AudioSettingsSubpage())),
            _SettingsRow(icon: LucideIcons.bellRing, title: 'Notifications', subtitle: 'Reminders, daily nudges and quiet hours', status: unreadLogs > 0 ? '$unreadLogs new' : null, highlight: unreadLogs > 0, onTap: () => open(const NotificationsSettingsSubpage())),
          ]),

          _SettingsGroup(title: 'Money and assistant', rows: [
            _SettingsRow(
              icon: LucideIcons.wallet,
              title: 'Money',
              subtitle: 'Currency and monthly budget',
              status: settings.monthlyBudget != null ? formatMoney(settings.monthlyBudget!, settings.currencySymbol) : settings.currencySymbol,
              onTap: () => open(const FinancialSettingsSubpage()),
            ),
            _SettingsRow(icon: LucideIcons.sparkles, title: 'Nodo assistant', subtitle: 'Personality, tone and suggestions', status: settings.aiPersona, onTap: () => open(const AiSettingsSubpage())),
          ]),

          _SettingsGroup(title: 'Privacy and data', rows: [
            _SettingsRow(icon: LucideIcons.shieldCheck, title: 'Security & vault', subtitle: 'PIN, biometrics and auto-lock', status: settings.vaultPin != null ? 'On' : 'Off', onTap: () => open(const SecuritySettingsSubpage())),
            _SettingsRow(icon: LucideIcons.cloud, title: 'Account & sync', subtitle: 'Backup to the cloud and other devices', status: cloud.isConnectedToCloud ? 'Connected' : 'This device only', onTap: () => open(const SyncSettingsSubpage())),
            _SettingsRow(icon: LucideIcons.database, title: 'Backup & export', subtitle: 'Encrypted backups, CSV, calendar files and erase', onTap: () => open(const BackupSettingsSubpage())),
            _SettingsRow(icon: LucideIcons.lock, title: 'Privacy & Data Safety', subtitle: 'What stays on your phone and what you control', onTap: () => open(const PrivacySafetySubpage())),
          ]),

          _SettingsGroup(title: 'About', rows: [
            _SettingsRow(icon: LucideIcons.wrench, title: 'Diagnostics & System Tools', subtitle: "What's new, the guided tour and widget studio", onTap: () => open(const DiagnosticsSettingsSubpage())),
            _SettingsRow(icon: LucideIcons.helpCircle, title: 'Help & Support', subtitle: 'Answers to common questions and how to reach us', onTap: () => open(const HelpSupportSubpage())),
            _SettingsRow(icon: LucideIcons.scale, title: 'Terms & Conditions', subtitle: 'Your rights and ours', onTap: () => open(const TermsConditionsSubpage())),
            _SettingsRow(icon: LucideIcons.info, title: 'About NOTtEodo', subtitle: 'The story, credits and version', status: 'v2.5.0', onTap: () => open(const AboutNotteodoSubpage())),
          ]),
        ].revealed(),
      ),
    );
  }
}

class _SettingsRow {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? status;
  final bool highlight;
  final VoidCallback onTap;

  const _SettingsRow({required this.icon, required this.title, required this.subtitle, required this.onTap, this.status, this.highlight = false});
}

/// A titled card of settings rows separated by hairlines. Each row sinks when pressed
/// and its arrow edges forward.
class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<_SettingsRow> rows;

  const _SettingsGroup({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    final c = CardInk.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(left: 4, bottom: 10), child: CardLabel(title)),
          BentoPod(
            style: PodTextureStyle.glass,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0) Padding(padding: const EdgeInsets.only(left: 54), child: Container(height: 1, color: c.hairline)),
                  _RowTile(row: rows[i]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RowTile extends StatefulWidget {
  final _SettingsRow row;

  const _RowTile({required this.row});

  @override
  State<_RowTile> createState() => _RowTileState();
}

class _RowTileState extends State<_RowTile> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final c = CardInk.of(context);
    final r = widget.row;
    return Semantics(
      button: true,
      label: '${r.title}${r.status == null ? '' : ', ${r.status}'}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: () {
          SanctuaryHapticEngine.selection();
          r.onTap();
        },
        child: AnimatedContainer(
          duration: Motion.quick,
          color: _down ? c.hairline.withValues(alpha: 0.6) : Colors.transparent,
          padding: const EdgeInsets.fromLTRB(18, 13, 14, 13),
          child: Row(
            children: [
              Icon(r.icon, size: 19, color: c.muted),
              const SizedBox(width: 17),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.title, style: c.body.copyWith(fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(r.subtitle, style: c.meta.copyWith(fontSize: 12.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (r.status != null) ...[
                const SizedBox(width: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Text(
                    r.status!,
                    style: c.meta.copyWith(fontSize: 13, color: r.highlight ? c.mark : c.muted, fontWeight: r.highlight ? FontWeight.w700 : FontWeight.w400),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              AnimatedPadding(
                duration: Motion.standard,
                curve: Motion.settle,
                padding: EdgeInsets.only(left: _down ? 10 : 6),
                child: Icon(LucideIcons.chevronRight, size: 16, color: c.muted.withValues(alpha: 0.7)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
