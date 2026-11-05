import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/brand/notteodo_app_icon.dart';
import '../../../core/widgets/app_toast_engine.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/motion/motion.dart';
import '../../../core/performance/sanctuary_motion_engine.dart';
import '../../../core/platform/browser_bridge.dart';
import '../../../core/services/cloud_sync_service.dart';
import '../../../core/services/data_portability_service.dart';
import '../../../core/services/ics_export.dart';
import '../../../core/services/local_store.dart';
import '../../../core/services/sanctuary_supabase_service.dart';
import '../../../core/state/app_settings.dart';
import '../../../core/state/sanctuary_state.dart';
import '../../../core/systems/aesthetic_audio_service.dart';
import '../../../core/systems/ephemeral_clipboard_sanitizer.dart';
import '../../../core/utils/date_labels.dart';
import '../../../core/widgets/bento_pod.dart';
import '../../../core/widgets/homescreen/homescreen_widget_studio_screen.dart';
import '../../auth/presentation/mfa_dialogs.dart';
import 'ai_settings_section.dart';
import 'enterprise_governance_screen.dart';
import 'grand_master_luxury_suite_screen.dart';
import 'security_settings_section.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const currencies = ['₹', '\$', '€', '£', '¥', 'CHF '];

  late final TextEditingController _budgetCtrl = TextEditingController(
    text: ref.read(appSettingsProvider).monthlyBudget?.toStringAsFixed(0) ?? '',
  );

  String? _previewingSoundId;

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
      await EphemeralClipboardSanitizer.copyEphemeralSecret(secret: content, timeout: const Duration(seconds: 90));
      if (mounted) _toast('Copied $name to the clipboard (cleared again in 90 s)');
    }
  }

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
    if (SanctuarySupabaseService().currentUser != null) {
      await SanctuarySupabaseService().signOut();
    }
    CloudSyncService().resetForAccountChange();
    await LocalStore().eraseAll();
    ref.read(appSettingsProvider.notifier).reloadFromStore();
    resetAllProviders(ref);
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
        : 'Reminders on. They appear inside the app while it is open.');
  }

  void _saveBudget() {
    final v = double.tryParse(_budgetCtrl.text.replaceAll(',', '').trim());
    ref.read(appSettingsProvider.notifier).setMonthlyBudget(v);
    FocusScope.of(context).unfocus();
    _toast(v == null || v <= 0 ? 'Monthly budget cleared' : 'Monthly budget set');
  }

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
            Icon(LucideIcons.sparkles, size: 20, color: isDark ? AppColors.goldLight : AppColors.secondary),
            const SizedBox(width: 8),
            Text("What's New in NOTtEodo", style: GoogleFonts.bodoniModa(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _changelogItem('Aesthetic Sound Studio', '5 trendy notification tones, 5 distinct alarm melodies, plus custom device audio uploads with live preview.'),
              _changelogItem('Full-View Non-Scrolling Vault', 'Sovereign vault lock screen fits 100% on any display without awkward scrolling.'),
              _changelogItem('Multi-Category Storage Meter', 'Detailed visual breakdown for Notes & Journal, Photos & Moodboards, and Local Cache.'),
              _changelogItem('30-Day Activity Heatmap', 'Interactive activity grid tracking notes, tasks, habits, and daily consistency.'),
              _changelogItem('Advanced Haptic Engine', 'Configurable tactile micro-haptics for buttons, cards, dials, and task completions.'),
            ],
          ),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: isDark ? AppColors.goldLight : AppColors.secondary, foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Awesome'),
          ),
        ],
      ),
    );
  }

  Widget _changelogItem(String title, String desc) {
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
    final gold = isDark ? AppColors.goldLight : AppColors.secondary;
    const terracotta = AppColors.secondary;
    final settings = ref.watch(appSettingsProvider);
    final cloud = SanctuarySupabaseService();

    Widget header(IconData icon, String label) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              Icon(icon, size: 18, color: gold),
              const SizedBox(width: 8),
              Text(label,
                  style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: gold)),
            ],
          ),
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PREFERENCES & SYSTEM', style: AppTypography.labelSm),
          const SizedBox(height: 4),
          Text(
            'Settings',
            style: GoogleFonts.bodoniModa(fontSize: 28, fontWeight: FontWeight.bold, color: primaryTextColor),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),

          // Appearance & General Behavior
          BentoPod(
            style: PodTextureStyle.glass,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header(LucideIcons.palette, 'APPEARANCE & GENERAL BEHAVIOR'),
                Text('Theme Mode', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.bold, color: primaryTextColor)),
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
                // Default Start Screen
                Text('Default Landing Screen on Launch', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.bold, color: primaryTextColor)),
                const SizedBox(height: 8),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('Home'), icon: Icon(LucideIcons.home, size: 13)),
                    ButtonSegment(value: 1, label: Text('Notes'), icon: Icon(LucideIcons.fileText, size: 13)),
                    ButtonSegment(value: 2, label: Text('Tasks'), icon: Icon(LucideIcons.checkSquare, size: 13)),
                    ButtonSegment(value: 3, label: Text('Planner'), icon: Icon(LucideIcons.calendar, size: 13)),
                  ],
                  selected: {settings.defaultStartScreen},
                  onSelectionChanged: (s) {
                    SanctuaryHapticEngine.dialDetent();
                    ref.read(appSettingsProvider.notifier).setDefaultStartScreen(s.first);
                  },
                ),
                const Divider(height: 24),
                // First Day of Week & Clock format
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
                                label: const Text('Monday'),
                                selected: settings.firstDayOfWeek == 1,
                                onSelected: (_) {
                                  SanctuaryHapticEngine.dialDetent();
                                  ref.read(appSettingsProvider.notifier).setFirstDayOfWeek(1);
                                },
                              ),
                              ChoiceChip(
                                label: const Text('Sunday'),
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
                                label: const Text('12-Hour'),
                                selected: !settings.timeFormat24h,
                                onSelected: (_) {
                                  SanctuaryHapticEngine.dialDetent();
                                  ref.read(appSettingsProvider.notifier).setTimeFormat24h(false);
                                },
                              ),
                              ChoiceChip(
                                label: const Text('24-Hour'),
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
                // Advanced Haptics Intensity
                Text('Haptic Feedback Intensity', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.bold, color: primaryTextColor)),
                Text('Fine-tune physical vibrations on every button, dial, card, and gesture.', style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor)),
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
                _settingSwitch('Reduce motion', 'Turn off entrance animations and ambient loops', settings.reducedMotion,
                    (v) => ref.read(appSettingsProvider.notifier).setReducedMotion(v), primaryTextColor, subtextColor),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Aesthetic Audio Studio (Notification & Alarm sounds with live testing)
          BentoPod(
            style: PodTextureStyle.glass,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header(LucideIcons.volume2, 'AESTHETIC SOUNDS & AUDIO STUDIO'),
                Text('Notification & Alarm Audio Studio',
                    style: GoogleFonts.bodoniModa(fontSize: 16, fontWeight: FontWeight.bold, color: primaryTextColor)),
                const SizedBox(height: 4),
                Text('Preview 5 distinct aesthetic notification tones and 5 dedicated alarm melodies, or upload audio from your device.',
                    style: GoogleFonts.dmSans(fontSize: 12, color: subtextColor)),
                const SizedBox(height: 16),

                // 1. NOTIFICATION SOUNDS (5 PRESETS)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('NOTIFICATION SOUNDS',
                        style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: gold)),
                    TextButton.icon(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      onPressed: () => AestheticAudioService().pickCustomSound(isAlarm: false, context: context, ref: ref),
                      icon: const Icon(LucideIcons.upload, size: 12),
                      label: const Text('Upload Sound', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Column(
                  children: AestheticAudioService.notificationPresets.map((sound) {
                    final isSelected = settings.notificationSound == sound.id;
                    final isPlaying = _previewingSoundId == sound.id;
                    return _buildSoundTile(
                      sound: sound,
                      isSelected: isSelected,
                      isPlaying: isPlaying,
                      isDark: isDark,
                      primaryTextColor: primaryTextColor,
                      subtextColor: subtextColor,
                      gold: gold,
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
                  }).toList(),
                ),

                if (settings.notificationSound == 'custom') ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: gold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: gold.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.fileAudio, size: 14, color: gold),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Custom: ${settings.customNotificationSoundName ?? 'Uploaded audio file'}',
                            style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, color: primaryTextColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const Divider(height: 28),

                // 2. ALARM & REMINDER SOUNDS (5 DISTINCT PRESETS)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ALARM & REMINDER MELODIES',
                        style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: gold)),
                    TextButton.icon(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      onPressed: () => AestheticAudioService().pickCustomSound(isAlarm: true, context: context, ref: ref),
                      icon: const Icon(LucideIcons.upload, size: 12),
                      label: const Text('Upload Sound', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Column(
                  children: AestheticAudioService.alarmPresets.map((sound) {
                    final isSelected = settings.alarmSound == sound.id;
                    final isPlaying = _previewingSoundId == sound.id;
                    return _buildSoundTile(
                      sound: sound,
                      isSelected: isSelected,
                      isPlaying: isPlaying,
                      isDark: isDark,
                      primaryTextColor: primaryTextColor,
                      subtextColor: subtextColor,
                      gold: gold,
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
                  }).toList(),
                ),

                if (settings.alarmSound == 'custom') ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: gold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: gold.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.fileAudio, size: 14, color: gold),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Custom: ${settings.customAlarmSoundName ?? 'Uploaded audio file'}',
                            style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, color: primaryTextColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Granular Notifications & Schedule
          BentoPod(
            style: PodTextureStyle.glass,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header(LucideIcons.bellRing, 'NOTIFICATIONS & SCHEDULE'),
                _settingSwitch('Due Reminders', 'Notify when tasks, calendar events, or habit milestones arrive.',
                    settings.remindersEnabled, _toggleReminders, primaryTextColor, subtextColor),
                const Divider(height: 24),
                // Daily Briefing Time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Morning Executive Briefing', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.bold, color: primaryTextColor)),
                        Text('Scheduled morning synthesis delivery time.', style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor)),
                      ],
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: gold.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _pickTime(
                        context: context,
                        initialTime: settings.morningBriefingTime,
                        onSelected: (t) => ref.read(appSettingsProvider.notifier).setMorningBriefingTime(t),
                      ),
                      child: Text(settings.morningBriefingTime, style: TextStyle(fontWeight: FontWeight.bold, color: gold)),
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
                        Text('Evening Reflection Prompt', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.bold, color: primaryTextColor)),
                        Text('Gentle prompt to journal and log habit cadence.', style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor)),
                      ],
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: gold.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _pickTime(
                        context: context,
                        initialTime: settings.eveningReflectionTime,
                        onSelected: (t) => ref.read(appSettingsProvider.notifier).setEveningReflectionTime(t),
                      ),
                      child: Text(settings.eveningReflectionTime, style: TextStyle(fontWeight: FontWeight.bold, color: gold)),
                    ),
                  ],
                ),
                const Divider(height: 24),
                // Quiet Hours (Do Not Disturb)
                _settingSwitch(
                  'Quiet Hours (Do Not Disturb)',
                  'Mute all non-critical notifications between ${settings.quietHoursStart} and ${settings.quietHoursEnd}.',
                  settings.quietHoursEnabled,
                  (v) => ref.read(appSettingsProvider.notifier).setQuietHours(enabled: v),
                  primaryTextColor,
                  subtextColor,
                ),
                const SizedBox(height: 14),
                // Budget Alert Threshold
                Text('Budget Alert Sensitivity', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.bold, color: primaryTextColor)),
                Text('Trigger financial pacing alerts when discretionary burn reaches this ratio.', style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor)),
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
                const Divider(height: 24),
                // App-Themed Animated Notifications Demonstration
                Text('App-Themed Animated Notifications', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.bold, color: primaryTextColor)),
                Text('Luxury on-screen heads-up alerts with spring physics, specular light sweep, app logo badge, countdown progress, and bespoke acoustic cues.', style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: gold.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          SanctuaryHapticEngine.sealImpression();
                          AppToastEngine().notifyAnimated(
                            title: 'Sanctuary Synchronized',
                            message: 'Haute horlogerie precision timing and encrypted cloud sync verified.',
                            type: ToastType.success,
                          );
                        },
                        icon: Icon(LucideIcons.bellRing, size: 14, color: gold),
                        label: Text('Test Notification', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, color: gold)),
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
                        onPressed: () {
                          SanctuaryHapticEngine.sealImpression();
                          AppToastEngine().notifyAnimated(
                            title: 'Horology Alarm Due',
                            message: 'Swiss escapement cadence chime. Time to review your evening notes.',
                            type: ToastType.alert,
                            isAlarm: true,
                          );
                        },
                        icon: const Icon(LucideIcons.watch, size: 14, color: terracotta),
                        label: Text('Test Alarm Chime', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, color: terracotta)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Homescreen Widgets Studio
          BentoPod(
            style: PodTextureStyle.glass,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header(LucideIcons.layoutGrid, 'HOMESCREEN WIDGETS'),
                Text(
                  'Homescreen Widgets',
                  style: GoogleFonts.bodoniModa(fontSize: 16, fontWeight: FontWeight.bold, color: primaryTextColor),
                ),
                const SizedBox(height: 4),
                Text(
                  'Aesthetic widgets with torn paper, washi tape, and minimal stamps for your home screen.',
                  style: GoogleFonts.dmSans(fontSize: 12, color: subtextColor),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(LucideIcons.sparkles, size: 16),
                    label: const Text('OPEN WIDGET STUDIO'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const HomescreenWidgetStudioScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Money & Budget
          BentoPod(
            style: PodTextureStyle.glass,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header(LucideIcons.wallet, 'FINANCIAL DISCIPLINE'),
                Text('Currency Symbol', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.bold, color: primaryTextColor)),
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
                Text('Monthly Budget Ceiling', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.bold, color: primaryTextColor)),
                Text('Discretionary spending guardrail for daily executive synthesis.',
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

          // Security Settings
          const SecuritySettingsPod(),
          const SizedBox(height: 20),

          // AI Tone & Settings
          const AiSettingsPod(),
          const SizedBox(height: 20),

          // Account & Sync
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

          // Data Portability & Backup
          BentoPod(
            style: PodTextureStyle.paper,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header(LucideIcons.database, 'YOUR DATA & EXPORT'),
                Text('Export a full backup, or individual modules in common open formats.',
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

          // About & Diagnostics
          BentoPod(
            style: PodTextureStyle.glass,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header(LucideIcons.wrench, 'DIAGNOSTICS & SYSTEM TOOLS'),
                Text(
                  'Explore developer tools, release changelogs, and enterprise governance.',
                  style: GoogleFonts.dmSans(fontSize: 12.5, color: subtextColor, height: 1.4),
                ),
                const SizedBox(height: 14),
                // What's New in v2.4
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: gold,
                      side: BorderSide(color: gold.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _showChangelogModal(context),
                    icon: const Icon(LucideIcons.sparkles, size: 15),
                    label: const Text("What's New in NOTtEodo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 14),
                _developerSuiteTile(
                  context: context,
                  icon: LucideIcons.shieldCheck,
                  iconColor: gold,
                  title: 'Enterprise Governance',
                  subtitle: 'Audit ledger integrity, pre-flight diagnostics & the sync outbox.',
                  badge: 'DIAG',
                  badgeColor: gold,
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
          const SizedBox(height: 20),

          // About NOTtEodo Sovereign Life OS
          BentoPod(
            style: PodTextureStyle.glass,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                const NotteodoAppIcon.large(withGlow: true),
                const SizedBox(height: 14),
                Text(
                  'NOTtEodo',
                  style: GoogleFonts.bodoniModa(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Enterprise Sovereign Edition · v2.4.0',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: gold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Crafted with haute horlogerie precision. Zero-knowledge on-device cryptography, aesthetic acoustic studio, and luxury animated notification HUD.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(fontSize: 11.5, color: subtextColor, height: 1.4),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _aboutBadge('AES-256-GCM', LucideIcons.shieldCheck, gold, isDark),
                    _aboutBadge('Audio Studio v2', LucideIcons.volume2, terracotta, isDark),
                    _aboutBadge('Animated HUD', LucideIcons.sparkles, gold, isDark),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ].revealed(),
      ),
    );
  }

  Widget _buildSoundTile({
    required AestheticSound sound,
    required bool isSelected,
    required bool isPlaying,
    required bool isDark,
    required Color primaryTextColor,
    required Color subtextColor,
    required Color gold,
    required VoidCallback onSelect,
    required VoidCallback onPreview,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? gold.withValues(alpha: 0.1) : (isDark ? const Color(0xFF111111) : const Color(0xFFF9F6F0)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? gold : (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE5DFD4)),
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Radio<bool>(
            value: true,
            groupValue: isSelected,
            activeColor: gold,
            onChanged: (_) => onSelect(),
          ),
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
            icon: Icon(
              isPlaying ? LucideIcons.volume2 : LucideIcons.play,
              size: 16,
              color: isPlaying ? gold : subtextColor,
            ),
            onPressed: onPreview,
          ),
        ],
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

  Widget _aboutBadge(String label, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(label, style: GoogleFonts.dmSans(fontSize: 10.5, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
