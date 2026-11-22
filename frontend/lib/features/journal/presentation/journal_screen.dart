import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/performance/sanctuary_motion_engine.dart';
import '../../../core/state/sanctuary_state.dart';
import '../../../core/widgets/bento_pod.dart';
import '../../../core/widgets/card_kit.dart';
import '../../../core/widgets/audio_cassette_player.dart';
import 'encrypted_vault_view.dart';
import '../../../core/motion/motion.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/entry_editor.dart';
import '../../../core/utils/date_labels.dart';
import '../../../core/tour/spotlight_tour.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  bool _showVault = false;
  int _selectedMemoirIndex = 0;

  @override
  Widget build(BuildContext context) {
    final c = CardInk.of(context);
    final memoirs = ref.watch(journalProvider).where((m) => !m.isPrivate).toList();

    if (_showVault) {
      return EncryptedVaultView(onClose: () => setState(() => _showVault = false));
    }

    final activeMemoir = memoirs.isNotEmpty && _selectedMemoirIndex < memoirs.length
        ? memoirs[_selectedMemoirIndex]
        : (memoirs.isNotEmpty ? memoirs.first : null);
    bool hasAudio(MemoirItem m) => m.audioPath != null || m.excerpt.contains('🎙️') || m.title.contains('🎙️') || m.duration.isNotEmpty;

    return SingleChildScrollView(
      physics: SanctuaryMotionEngine.fluidPhysics,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Journal', style: GoogleFonts.bodoniModa(fontSize: 36, fontWeight: FontWeight.bold, color: c.ink, height: 1.05)),
                        const SizedBox(height: 4),
                        RollingText('${memoirs.length} ${memoirs.length == 1 ? 'entry' : 'entries'}', style: c.meta.copyWith(fontSize: 14)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  TourTarget(id: 'journal.vault', child: CardLink(label: 'Vault', onTap: () => setState(() => _showVault = true))),
                  const SizedBox(width: 14),
                  TourTarget(id: 'page.primary', child: CardAction(label: 'New entry', icon: LucideIcons.plus, onTap: () => openEntryEditor(context, EntryKind.memoir))),
                ],
              ),
              const SizedBox(height: 22),

              // The chosen entry, set for reading. Picking another one cross-fades it in.
              if (activeMemoir != null)
                BentoPod(
                  style: PodTextureStyle.glass,
                  padding: const EdgeInsets.fromLTRB(24, 20, 14, 24),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 420),
                    switchInCurve: Motion.silk,
                    transitionBuilder: (child, a) => FadeTransition(
                      opacity: a,
                      child: SlideTransition(position: Tween(begin: const Offset(0, 0.03), end: Offset.zero).animate(a), child: child),
                    ),
                    child: Column(
                      key: ValueKey(activeMemoir.id),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                [activeMemoir.mood, DateLabels.dateTime(activeMemoir.createdAt)].where((s) => s.trim().isNotEmpty).join(' · '),
                                style: c.label,
                              ),
                            ),
                            Tooltip(
                              message: 'Edit entry',
                              child: Pressable(
                                pressedScale: 0.85,
                                hoverLift: 0,
                                onTap: () => openEntryEditor(context, EntryKind.memoir, editing: activeMemoir),
                                child: SizedBox(width: 40, height: 40, child: Center(child: Icon(LucideIcons.pencil, size: 16, color: c.muted))),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Text(activeMemoir.title, style: c.title.copyWith(fontSize: 26, height: 1.15)),
                        ),
                        if (hasAudio(activeMemoir)) ...[
                          const SizedBox(height: 12),
                          AudioCassettePlayer(
                            title: activeMemoir.title,
                            audioPath: activeMemoir.audioPath,
                            totalDuration: AudioCassettePlayer.parseDuration('${activeMemoir.duration} ${activeMemoir.excerpt}'),
                          ),
                        ],
                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: SelectableText(
                            activeMemoir.excerpt,
                            style: c.body.copyWith(fontSize: 16, height: 1.7, fontWeight: FontWeight.w400),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 22),

              if (memoirs.isEmpty)
                Builder(
                  builder: (context) {
                    final targetH = (MediaQuery.sizeOf(context).height - 320).clamp(200.0, 720.0);
                    return ConstrainedBox(
                      constraints: BoxConstraints(minHeight: targetH),
                      child: Center(
                        child: EmptyState(
                          icon: LucideIcons.bookOpen,
                          title: 'Your journal is quiet',
                          message: 'Write a few lines about today, or record a voice reflection.',
                          action: CardAction(label: 'Write the first entry', icon: LucideIcons.plus, onTap: () => openEntryEditor(context, EntryKind.memoir)),
                        ),
                      ),
                    );
                  },
                )
              else ...[
                const CardLabel('All entries'),
                const SizedBox(height: 10),
                MotionColumn(
                  spacing: 0,
                  // A board of entries on wide screens; one column on phones.
                  minTileWidth: 320,
                  children: [
                    for (var idx = 0; idx < memoirs.length; idx++)
                      Builder(key: ValueKey(memoirs[idx].id), builder: (context) {
                        final memoir = memoirs[idx];
                        final selected = memoir.id == activeMemoir?.id;
                        return Reveal(
                          style: RevealStyle.slideIn,
                          distance: 18,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: BentoPod(
                              style: PodTextureStyle.paper,
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                              onTap: () => setState(() => _selectedMemoirIndex = idx),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      // The entry being read carries a small oxblood dot.
                                      AnimatedContainer(
                                        duration: Motion.standard,
                                        curve: Motion.settle,
                                        width: selected ? 6 : 0,
                                        height: 6,
                                        margin: EdgeInsets.only(right: selected ? 8 : 0),
                                        decoration: BoxDecoration(shape: BoxShape.circle, color: c.mark),
                                      ),
                                      Expanded(
                                        child: Text(
                                          [memoir.date, memoir.mood, if (hasAudio(memoir)) 'Voice'].where((s) => s.trim().isNotEmpty).join(' · '),
                                          style: c.label.copyWith(fontSize: 12.5),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(memoir.title, style: c.title.copyWith(fontSize: 18), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  if (memoir.excerpt.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(memoir.excerpt, style: c.meta.copyWith(fontSize: 13.5), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ],
            ].revealed(),
          ),
        ),
      ),
    );
  }
}
