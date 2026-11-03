import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/platform/browser_bridge.dart';
import '../../../core/services/cloud_sync_service.dart';
import '../../../core/services/data_portability_service.dart';
import '../../../core/services/ics_export.dart';
import '../../../core/services/local_store.dart';
import '../../../core/services/sanctuary_supabase_service.dart';
import '../../../core/state/app_settings.dart';
import '../../../core/state/sanctuary_state.dart';
import '../../../core/systems/ephemeral_clipboard_sanitizer.dart';
import '../../auth/presentation/mfa_dialogs.dart';
import 'ai_settings_section.dart';
import 'security_settings_section.dart';
import '../../../core/utils/date_labels.dart';
import '../../../core/widgets/bento_pod.dart';
import 'enterprise_governance_screen.dart';
import 'grand_master_luxury_suite_screen.dart';
import '../../../core/motion/motion.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const currencies = ['₹', '\$', '€', '£', 'Â¥', 'CHF '];

  late final TextEditingController _budgetCtrl = TextEditingController(
    text: ref.read(appSettingsProvider).monthlyBudget?.toStringAsFixed(0) ?? '',
  );

  @override
  void dispose() {
    _budgetCtrl.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      content: Text(message, style: GoogleFonts.dmSans(color: Colors.white)),
    ));
  }

  String get _stamp => DateLabels.dayKey(DateTime.now());

  Future<void> _download(String name, String content, String mime) async {
    final ok = await downloadTextFile(name, content, mimeType: mime);
    if (!mounted) return;
    if (ok) {
      _toast('Saved $name');
    } else {
      // Outside a browser there is no download folder; hand the text over instead,
      // and wipe it from the clipboard again shortly after.
      await EphemeralClipboardSanitizer.copyEphemeralSecret(secret: content, timeout: const Duration(seconds: 90));
      if (mounted) _toast('Copied $name to the clipboard (cleared again in 90 s)');
    }
  }

  /// Full backup; password-protected unless the user explicitly skips it.
  Future<void> _exportBackup() async {
    final pass = await showDialog<String>(
      context: context,
      builder: (_) => const PassphraseDialog(
        title: 'Protect this backup',
        message: 'The file is encrypted with AES-256 using this password, so it is safe to keep in cloud drives or email. '
            'You will need it to restore. Without a password, anyone who gets the file can read it.',
        submitLabel: 'Encrypt & save',
        skipLabel: 'Save unencrypted',
      ),
    );
    if (pass == null || !mounted) return;
    final name = 'notteodo-backup-$_stamp.json';
    if (pass.isEmpty) {
      await _download(name, DataPortabilityService.buildBackupJson(), 'application/json');
      return;
    }
    final content = await DataPortabilityService.buildEncryptedBackup(pass);
    await _download(name, content, 'application/json');
  }

  Future<void> _import() async {
    var text = await pickTextFile(accept: '.json,application/json');
    if (text == null || !mounted) return;
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
      if (pass == null || !mounted) return;
      try {
        text = await DataPortabilityService.decryptBackup(text, pass);
      } on FormatException catch (e) {
        _toast(e.message);
        return;
      } catch (_) {
        _toast('This backup file is damaged.');
        return;
      }
      if (!mounted) return;
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
      _toast('Restored $total items from backup');
    } on FormatException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _removeSamples() async {
    removeAllSamples(ref);
    _toast('Sample content removed');
  }

  Future<void> _eraseAll() async {
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
              const Text('Notes, tasks, expenses, settings, the app PIN and the Bin are deleted from this device, its '
                  'encryption key is destroyed, and you are signed out. Your cloud copy (if any) is kept. Export a backup '
                  'first if you might need it. Type ERASE to confirm.'),
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
    // Sign out first so the now-empty device never syncs over the cloud copy.
    if (SanctuarySupabaseService().currentUser != null) {
      await SanctuarySupabaseService().signOut();
    }
    CloudSyncService().resetForAccountChange();
    await LocalStore().eraseAll();
    ref.read(appSettingsProvider.notifier).reloadFromStore();
    resetAllProviders(ref);
    // Start genuinely empty rather than from the first-run samples.
    removeAllSamples(ref);
    _toast('All data on this device was erased');
  }

  Future<void> _toggleReminders(bool on) async {
    if (!on) {
      ref.read(appSettingsProvider.notifier).setRemindersEnabled(false);
      return;
    }
    final granted = await requestNotificationPermission();
    ref.read(appSettingsProvider.notifier).setRemindersEnabled(true);
    _toast(granted
        ? 'Reminders on. You will get a notification when something is due.'
        : 'Reminders on. They appear inside the app while it is open (system notifications are blocked).');
  }

  void _saveBudget() {
    final v = double.tryParse(_budgetCtrl.text.replaceAll(',', '').trim());
    ref.read(appSettingsProvider.notifier).setMonthlyBudget(v);
    FocusScope.of(context).unfocus();
    _toast(v == null || v <= 0 ? 'Monthly budget cleared' : 'Monthly budget set');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    final settings = ref.watch(appSettingsProvider);
    final cloud = SanctuarySupabaseService();

    Widget header(IconData icon, String label) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.secondary),
              const SizedBox(width: 8),
              Text(label,
                  style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.secondary)),
            ],
          ),
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PREFERENCES', style: AppTypography.labelSm),
          const SizedBox(height: 4),
          Text(
            'Settings',
            style: GoogleFonts.bodoniModa(fontSize: 28, fontWeight: FontWeight.bold, color: primaryTextColor),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),

          // Appearance
          BentoPod(
            style: PodTextureStyle.glass,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header(LucideIcons.palette, 'APPEARANCE'),
                Text('Theme', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.bold, color: primaryTextColor)),
                const SizedBox(height: 8),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(LucideIcons.monitor, size: 14)),
                    ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(LucideIcons.sun, size: 14)),
                    ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(LucideIcons.moon, size: 14)),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (s) => ref.read(appSettingsProvider.notifier).setThemeMode(s.first),
                ),
                const Divider(height: 28),
                _settingSwitch('Reduce motion', 'Turn off entrance animations and ambient loops', settings.reducedMotion,
                    (v) => ref.read(appSettingsProvider.notifier).setReducedMotion(v), primaryTextColor, subtextColor),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Money
          BentoPod(
            style: PodTextureStyle.glass,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header(LucideIcons.wallet, 'MONEY'),
                Text('Currency symbol', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.bold, color: primaryTextColor)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final c in currencies)
                      ChoiceChip(
                        label: Text(c.trim()),
                        selected: settings.currencySymbol == c,
                        onSelected: (_) => ref.read(appSettingsProvider.notifier).setCurrency(c),
                      ),
                  ],
                ),
                const Divider(height: 28),
                Text('Monthly budget', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.bold, color: primaryTextColor)),
                Text('You get a heads-up at 80% and when you go over. Leave empty for no limit.',
                    style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor)),
                const SizedBox(height: 10),
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
                          border: const OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _saveBudget(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(onPressed: _saveBudget, child: const Text('Save')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Reminders & privacy
          BentoPod(
            style: PodTextureStyle.glass,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header(LucideIcons.bell, 'REMINDERS'),
                _settingSwitch('Reminders', 'Due tasks, events (10 min before) and habit times while the app is open',
                    settings.remindersEnabled, _toggleReminders, primaryTextColor, subtextColor),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const SecuritySettingsPod(),
          const SizedBox(height: 20),

          const AiSettingsPod(),
          const SizedBox(height: 20),

          // Account & sync
          BentoPod(
            style: PodTextureStyle.glass,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header(LucideIcons.cloud, 'ACCOUNT & SYNC'),
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
          const SizedBox(height: 20),

          // Data
          BentoPod(
            style: PodTextureStyle.paper,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header(LucideIcons.database, 'YOUR DATA'),
                Text('Export a full backup, or individual modules in common formats.',
                    style: GoogleFonts.dmSans(fontSize: 13, color: subtextColor)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _exportButton('Full backup (.json)', LucideIcons.fileCode, primaryTextColor, _exportBackup),
                    _exportButton('Expenses (.csv)', LucideIcons.table, primaryTextColor,
                        () => _download('notteodo-expenses-$_stamp.csv', DataPortabilityService.expensesCsv(ref.read(expensesProvider).expenses), 'text/csv')),
                    _exportButton('Tasks (.csv)', LucideIcons.checkSquare, primaryTextColor,
                        () => _download('notteodo-tasks-$_stamp.csv', DataPortabilityService.tasksCsv(ref.read(tasksProvider)), 'text/csv')),
                    _exportButton('Notes (.md)', LucideIcons.fileText, primaryTextColor,
                        () => _download('notteodo-notes-$_stamp.md', DataPortabilityService.notesMarkdown(ref.read(notesProvider)), 'text/markdown')),
                    _exportButton('Calendar (.ics)', LucideIcons.calendar, primaryTextColor, () => _download(
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
                    _exportButton('Restore backup…', LucideIcons.upload, primaryTextColor, _import),
                    _exportButton('Remove sample content', LucideIcons.eraser, primaryTextColor, _removeSamples),
                    Pressable(
                      pressedScale: 0.95,
                      hoverLift: 0,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.error.withValues(alpha: 0.6)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        onPressed: _eraseAll,
                        icon: const Icon(LucideIcons.trash2, size: 14, color: AppColors.error),
                        label: Text('Erase all data', style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Developer tools
          BentoPod(
            style: PodTextureStyle.glass,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header(LucideIcons.wrench, 'DIAGNOSTICS & SYSTEM TOOLS'),
                Text(
                  'Developer tools, the audit ledger, and the UI testbed. Also on Ctrl/âŒ˜+E and Ctrl/âŒ˜+G.',
                  style: GoogleFonts.dmSans(fontSize: 12.5, color: subtextColor, height: 1.4),
                ),
                const SizedBox(height: 16),
                _developerSuiteTile(
                  context: context,
                  icon: LucideIcons.shieldCheck,
                  iconColor: const Color(0xFF86CBB0),
                  title: 'Enterprise Governance',
                  subtitle: 'Audit ledger integrity, pre-flight diagnostics & the sync outbox.',
                  badge: 'DIAG',
                  badgeColor: const Color(0xFF86CBB0),
                  shortcutText: 'Ctrl+E',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EnterpriseGovernanceScreen())),
                  primaryTextColor: primaryTextColor,
                  subtextColor: subtextColor,
                  isDark: isDark,
                ),
                const Divider(height: 18),
                _developerSuiteTile(
                  context: context,
                  icon: LucideIcons.crown,
                  iconColor: const Color(0xFFD4AF37),
                  title: 'Grand Master Suite',
                  subtitle: 'Showcase and testbed for the custom widgets and animations.',
                  badge: 'FX',
                  badgeColor: const Color(0xFFD4AF37),
                  shortcutText: 'Ctrl+G',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GrandMasterLuxurySuiteScreen())),
                  primaryTextColor: primaryTextColor,
                  subtextColor: subtextColor,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ].revealed(),
      ),
    );
  }

  Widget _developerSuiteTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required String shortcutText,
    required VoidCallback onTap,
    required Color primaryTextColor,
    required Color subtextColor,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF000000) : Colors.black.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? const Color(0xFF1E1E1E) : Colors.black12, width: 1.0),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: GoogleFonts.dmSans(fontSize: 13.5, fontWeight: FontWeight.bold, color: primaryTextColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                          child: Text(badge, style: GoogleFonts.courierPrime(fontSize: 9, fontWeight: FontWeight.bold, color: badgeColor)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(subtitle, style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor, height: 1.3)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF121212) : const Color(0xFFECE5D5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: isDark ? const Color(0xFF262626) : Colors.black12),
                    ),
                    child: Text(shortcutText,
                        style: GoogleFonts.courierPrime(fontSize: 9.5, fontWeight: FontWeight.bold, color: primaryTextColor)),
                  ),
                  const SizedBox(height: 6),
                  Icon(LucideIcons.chevronRight, size: 14, color: subtextColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _exportButton(String label, IconData icon, Color textColor, VoidCallback onPressed) {
    return Pressable(
      pressedScale: 0.95,
      hoverLift: 0,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.secondary.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 14, color: AppColors.secondary),
        label: Text(label, style: GoogleFonts.dmSans(fontSize: 12, color: textColor, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _settingSwitch(
      String title, String desc, bool val, ValueChanged<bool> onChanged, Color primaryTextColor, Color subtextColor) {
    return MergeSemantics(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.bold, color: primaryTextColor)),
                Text(desc, style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor)),
              ],
            ),
          ),
          Switch(value: val, activeTrackColor: AppColors.secondary, onChanged: onChanged),
        ],
      ),
    );
  }
}
