import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/security/sync_keyring.dart';
import '../../../core/services/sanctuary_supabase_service.dart';
import '../../../core/state/app_settings.dart';
import '../../../core/widgets/bento_pod.dart';

/// Settings → AI: what runs on the device and what may use the cloud model.
class AiSettingsPod extends ConsumerWidget {
  const AiSettingsPod({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final sub = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    final settings = ref.watch(appSettingsProvider);
    final signedIn = SanctuarySupabaseService().isConnectedToCloud;
    final e2ee = SyncKeyring().state.value == E2eeState.ready;

    Widget toggle(String title, String subtitle, bool value, ValueChanged<bool> onChanged) => Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.bold, color: text)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.dmSans(fontSize: 11, color: sub, height: 1.35)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch.adaptive(value: value, onChanged: onChanged, activeTrackColor: AppColors.secondary),
          ],
        );

    return BentoPod(
      style: PodTextureStyle.glass,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                const Icon(LucideIcons.sparkles, size: 18, color: AppColors.secondary),
                const SizedBox(width: 8),
                Text('AI',
                    style: GoogleFonts.dmSans(
                        fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.secondary)),
              ],
            ),
          ),
          toggle(
            'Smart suggestions',
            'Categories, priorities, spaces, tags and moods suggested as you type, plus smart groups, '
                'aisle sorting and spending insights. Runs entirely on this device.',
            settings.smartSuggestions,
            (v) => ref.read(appSettingsProvider.notifier).setSmartSuggestions(v),
          ),
          const Divider(height: 24),
          toggle(
            'Cloud AI',
            signedIn
                ? 'Answers, summaries, task breakdowns, smart group names and voice transcription use NOTtEodo AI. '
                    'Only the snippets relevant to each request are sent, and they are not stored.'
                : 'Sign in to use the cloud assistant. Without it, every AI feature answers on this device.',
            settings.cloudAi,
            (v) => ref.read(appSettingsProvider.notifier).setCloudAi(v),
          ),
          if (e2ee && settings.cloudAi) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFC9A227).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Your sync is end-to-end encrypted, but cloud AI requests still send the relevant snippets to the model '
                'in readable form. Turn cloud AI off to keep everything zero-knowledge.',
                style: GoogleFonts.dmSans(fontSize: 11, color: text, height: 1.4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
