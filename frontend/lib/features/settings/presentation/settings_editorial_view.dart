import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/editorial/editorial_kit.dart';
import '../../../core/editorial/editorial_mode.dart';
import '../../../core/services/cloud_sync_service.dart';
import '../../../core/services/media_backup_service.dart';
import '../../../core/services/sanctuary_supabase_service.dart';
import '../../../core/state/app_settings.dart';
import '../../../core/widgets/app_toast_engine.dart';
import '../../../core/widgets/homescreen/homescreen_widget_studio_screen.dart';
import 'about_notteodo_subpage.dart';
import 'account_deletion.dart';
import 'help_support_subpage.dart';
import 'look_and_feel_page.dart';
import 'privacy_safety_subpage.dart';
import 'settings_subpages.dart';

/// Settings as a contents page: each line opens one area, with its current state
/// written underneath. Backup status comes first, because it is what protects the data.
class SettingsEditorialView extends ConsumerWidget {
  const SettingsEditorialView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appSettingsProvider);
    final p = UiPrefs.of(s);
    final signedIn = SanctuarySupabaseService().currentUser != null;

    void open(Widget page) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

    Widget line(String title, String meta, Widget page) => EditorialEntry(id: 'set-$title', title: title, meta: meta, trailing: '→', onTap: () => open(page));

    return ValueListenableBuilder<SyncStatus>(
      valueListenable: CloudSyncService().status,
      builder: (context, sync, _) => EditorialPage(
        kicker: 'Settings',
        title: 'Your app',
        standfirst: signedIn ? '${sync.label}.' : 'Not backed up: everything is on this phone only.',
        slivers: [
          SliverList.list(children: [
            const EditorialSectionLabel('Backup'),
            line('Account & sync', signedIn ? '${SanctuarySupabaseService().currentUser?.email ?? 'Signed in'} · ${sync.label}' : 'Sign in to keep your data safe across reinstalls', const SyncSettingsSubpage()),
            if (signedIn)
              ValueListenableBuilder<int>(
                valueListenable: MediaBackupService().pending,
                builder: (context, pending, _) => EditorialEntry(
                  id: 'set-media',
                  title: 'Photos & voice notes',
                  meta: pending == 0 ? 'Backed up with your account' : '$pending waiting to upload',
                  trailing: 'Back up now',
                  onTap: () async {
                    final done = await MediaBackupService().run(ref);
                    AppToastEngine().notify(
                      title: done == 0 ? 'Nothing new to back up' : 'Backed up $done ${done == 1 ? 'file' : 'files'}',
                      message: 'Photos and recordings now come back after a reinstall.',
                    );
                  },
                ),
              ),
            line('Backups & export', 'Encrypted backup file, CSV, calendar and Markdown', const BackupSettingsSubpage()),
            if (signedIn)
              EditorialEntry(
                id: 'set-delete-account',
                title: 'Delete my account',
                meta: 'Removes your account and everything stored in the cloud',
                onTap: () => confirmAndDeleteAccount(context),
              ),

            const EditorialSectionLabel('Appearance'),
            line('Look & feel', '${viewStyleName(s.cardStyle)} · ${p.accent} · ${p.textScale} text · ${p.density}', const LookAndFeelPage()),
            line('Display & fonts', 'Fonts for each module, cards shown on Home', const DisplaySettingsSubpage()),
            line('Home-screen widgets', 'Design the widgets for your phone’s home screen', const HomescreenWidgetStudioScreen()),
            line('Sounds', 'Notification, alarm and focus sounds', const AudioSettingsSubpage()),

            const EditorialSectionLabel('Everyday'),
            line(
              'Notifications',
              s.dailyEngagementNotifications ? '${s.notificationCadenceLabel}${s.quietHoursEnabled ? ' · quiet ${s.quietHoursStart}–${s.quietHoursEnd}' : ''}' : 'Nudges off · reminders ${s.remindersEnabled ? 'on' : 'off'}',
              const NotificationsSettingsSubpage(),
            ),
            line('Money', '${s.currencySymbol} · ${s.monthlyBudget == null ? 'no budget' : 'budget ${s.monthlyBudget!.toStringAsFixed(0)}'}', const FinancialSettingsSubpage()),
            line('Assistant', s.cloudAi ? 'Cloud AI on · ${s.aiPersona}' : 'Cloud AI off · on-device only', const AiSettingsSubpage()),

            const EditorialSectionLabel('Privacy'),
            line('Lock & vault', s.autoLockMinutes == 0 ? 'Auto-lock off' : 'Locks after ${s.autoLockMinutes} min', const SecuritySettingsSubpage()),
            line('Privacy & data', 'What stays on the phone, what is encrypted', const PrivacySafetySubpage()),

            const EditorialSectionLabel('Help'),
            line('Help & questions', 'Guides, streak rules and contact', const HelpSupportSubpage()),
            line('What’s new & tools', 'Release notes, walkthrough, diagnostics', const DiagnosticsSettingsSubpage()),
            line('About', 'The story and the people', const AboutNotteodoSubpage()),
          ]),
        ],
      ),
    );
  }
}
