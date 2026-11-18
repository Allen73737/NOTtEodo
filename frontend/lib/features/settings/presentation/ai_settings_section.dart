import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/performance/sanctuary_motion_engine.dart';
import '../../../core/security/sync_keyring.dart';
import '../../../core/services/companion_memory_service.dart';
import '../../../core/services/groq_ai_service.dart';
import '../../../core/services/sanctuary_supabase_service.dart';
import '../../../core/state/app_settings.dart';
import '../../../core/widgets/bento_pod.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';

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
                  Text(subtitle, style: GoogleFonts.dmSans(fontSize: 12, color: sub, height: 1.35)),
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
                        fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.secondary)),
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
            'Nodo AI Roaming Companion',
            'Allows your animated assistant "Nodo" to roam gracefully across screens and suggest helpful actions.',
            settings.nodoCompanionEnabled,
            (v) => ref.read(appSettingsProvider.notifier).setNodoCompanionEnabled(v),
          ),
          const Divider(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nodo Personality & Persona',
                  style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.bold, color: text)),
              const SizedBox(height: 4),
              Text('Select the conversational character and humor level of your AI companion.',
                  style: GoogleFonts.dmSans(fontSize: 12, color: sub, height: 1.35)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _personaChip('sarcastic', 'Witty & Sarcastic', 'Clever dry humor, playful irony & banter', settings.aiPersona, ref, text, sub, isDark),
                  _personaChip('scholarly', 'Scholarly & Poetic', 'Reflective, eloquent & analytical depth', settings.aiPersona, ref, text, sub, isDark),
                  _personaChip('stoic', 'Stoic & Concise', 'Direct, disciplined, zero fluff or filler', settings.aiPersona, ref, text, sub, isDark),
                  _personaChip('energetic', 'Sprightly & Energetic', 'Passionate encouragement & high momentum', settings.aiPersona, ref, text, sub, isDark),
                ],
              ),
            ],
          ),
          const Divider(height: 24),
          toggle(
            'Cloud AI',
            signedIn
                ? 'Answers, summaries, task breakdowns, smart group names and voice transcription use Nodo in the cloud. '
                    'Only the snippets relevant to each request are sent. Nodo keeps short memories about you '
                    '(never passwords or codes) so it can personalise answers; you can see and delete them below.'
                : 'Sign in to use the cloud assistant. Without it, every AI feature answers on this device.',
            settings.cloudAi,
            (v) => ref.read(appSettingsProvider.notifier).setCloudAi(v),
          ),
          const Divider(height: 24),
          _NodoMemoryPanel(text: text, sub: sub, isDark: isDark),
          if (e2ee && settings.cloudAi) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: edBox(
                color: const Color(0xFFB5505E).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Your sync is end-to-end encrypted, but cloud AI requests still send the relevant snippets to the model '
                'in readable form. Turn cloud AI off to keep everything zero-knowledge.',
                style: GoogleFonts.dmSans(fontSize: 12, color: text, height: 1.4),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _personaChip(
    String id,
    String title,
    String desc,
    String current,
    WidgetRef ref,
    Color text,
    Color sub,
    bool isDark,
  ) {
    final isSelected = id == current;
    final accent = isDark ? const Color(0xFFD0485A) : AppColors.secondary;

    return InkWell(
      onTap: () {
        SanctuaryHapticEngine.sealImpression();
        ref.read(appSettingsProvider.notifier).setAiPersona(id);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minWidth: 220),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: edBox(
          color: isSelected ? accent.withValues(alpha: 0.12) : (isDark ? const Color(0xFF141414) : const Color(0xFFF3EFE9)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? LucideIcons.circleCheck : LucideIcons.circle,
              size: 15,
              color: isSelected ? accent : sub,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? accent : text,
                    ),
                  ),
                  Text(
                    desc,
                    style: GoogleFonts.dmSans(fontSize: 12.5, color: sub),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// What Nodo remembers about this person: memories kept with their account in the cloud
/// and ones kept on this device. Each can be deleted, or all of them at once.
class _NodoMemoryPanel extends StatefulWidget {
  final Color text;
  final Color sub;
  final bool isDark;

  const _NodoMemoryPanel({required this.text, required this.sub, required this.isDark});

  @override
  State<_NodoMemoryPanel> createState() => _NodoMemoryPanelState();
}

class _NodoMemoryPanelState extends State<_NodoMemoryPanel> {
  List<NodoMemory>? _cloud;
  List<String> _local = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cloud = await GroqAiService().memories();
    if (!mounted) return;
    setState(() {
      _cloud = cloud;
      _local = CompanionMemoryService().memories;
      _loading = false;
    });
  }

  Future<void> _forgetCloud(NodoMemory m) async {
    SanctuaryHapticEngine.selection();
    setState(() => _cloud = [...?_cloud]..remove(m));
    if (!await GroqAiService().forget(id: m.id)) _load();
  }

  void _forgetLocal(int index) {
    SanctuaryHapticEngine.selection();
    CompanionMemoryService().removeMemory(index);
    setState(() => _local = CompanionMemoryService().memories);
  }

  Future<void> _forgetAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Forget everything?'),
        content: const Text('Nodo will forget what it has learned about you and your earlier chats. Your notes, tasks and other items stay as they are.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Forget')),
        ],
      ),
    );
    if (ok != true) return;
    SanctuaryHapticEngine.sealImpression();
    CompanionMemoryService()
      ..clearMemories()
      ..clearHistory();
    await GroqAiService().forget();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final entries = <(String, VoidCallback)>[
      for (final m in _cloud ?? const <NodoMemory>[]) (m.content, () => _forgetCloud(m)),
      for (final (i, m) in _local.indexed) (m, () => _forgetLocal(i)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('What Nodo remembers', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.bold, color: widget.text)),
            ),
            if (entries.isNotEmpty)
              TextButton(
                onPressed: _forgetAll,
                child: Text('Forget all', style: GoogleFonts.dmSans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.secondary)),
              ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          _cloud == null && !_loading
              ? 'Things you tell Nodo are remembered on this device. Sign in and Nodo also remembers across your devices.'
              : 'Nodo picks these up from your chats so it can tailor answers. Only you can see them.',
          style: GoogleFonts.dmSans(fontSize: 12, color: widget.sub, height: 1.35),
        ),
        const SizedBox(height: 10),
        AnimatedSize(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _loading
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text('Remembering…', style: GoogleFonts.dmSans(fontSize: 12.5, color: widget.sub)),
                )
              : entries.isEmpty
                  ? Text('Nothing yet. Tell Nodo about yourself, or say "remember that…".',
                      style: GoogleFonts.dmSans(fontSize: 12.5, color: widget.sub, fontStyle: FontStyle.italic))
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final (content, onForget) in entries)
                          Container(
                            constraints: const BoxConstraints(maxWidth: 420),
                            padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
                            decoration: edBox(
                              color: widget.isDark ? const Color(0xFF141414) : const Color(0xFFF3EFE9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(child: Text(content, style: GoogleFonts.dmSans(fontSize: 12.5, color: widget.text, height: 1.3))),
                                IconButton(
                                  tooltip: 'Forget this',
                                  visualDensity: VisualDensity.compact,
                                  iconSize: 14,
                                  onPressed: onForget,
                                  icon: Icon(LucideIcons.x, color: widget.sub),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
        ),
      ],
    );
  }
}
