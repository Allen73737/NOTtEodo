import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/state/sanctuary_state.dart';
import '../../../core/widgets/bento_pod.dart';
import '../../../core/widgets/card_kit.dart';
import '../../../core/widgets/ink_signature_canvas.dart';
import '../../../core/performance/sanctuary_motion_engine.dart';

import '../../../core/luxury/deckled_paper_tear.dart';

import 'notes_graph_view.dart';
import '../../../core/motion/motion.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/entry_editor.dart';
import '../../../core/widgets/workflow_evolution_dialog.dart';
import '../../../core/widgets/pressure_test_dialog.dart';
import '../../../core/widgets/executive_dossier_dialog.dart';
import '../../../core/services/document_ingestion_service.dart';
import '../../../core/widgets/app_toast_engine.dart';
import 'notes_rag_modal.dart';
import '../../../core/ai/ai_widgets.dart';
import '../../../core/state/app_settings.dart';
import '../../../core/widgets/audio_cassette_player.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';

class NotesScreen extends ConsumerStatefulWidget {
  final Function(String) onOpenAiModal;

  const NotesScreen({super.key, required this.onOpenAiModal});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  bool _showGraphView = false;
  bool _showDualCanvas = false;
  bool _showInkCanvas = false;
  String _selectedSpace = 'All Spaces';

  /// Group notes by meaning instead of by space.
  bool _smartGroups = false;
  final Set<String> _tearingNoteIds = {};
  bool _isSelectionMode = false;
  final Set<String> _selectedNoteIds = {};

  Future<void> _importDocument(BuildContext context) async {
    final doc = await DocumentIngestionService().pickAndParseDocument();
    if (doc != null) {
      final note = DocumentIngestionService().toNoteItem(doc, space: _selectedSpace == 'All Spaces' ? 'General Space' : _selectedSpace);
      ref.read(notesProvider.notifier).addNote(
        title: note.title,
        content: note.content,
        space: note.space,
        tag: note.tag,
        excerpt: note.excerpt,
      );
      if (context.mounted) {
        AppToastEngine().notify(
          title: 'Document Ingested into Notes',
          message: 'Ingested "${doc.fileName}" (${doc.content.length} characters).',
          actionLabel: 'Open in RAG AI',
          onAction: () => showNotesRagModal(context, notes: [note]),
        );
      }
    }
  }

  void _showAddNoteDialog(BuildContext context, bool isDark) {
    openEntryEditor(context, EntryKind.note);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    final accentColor = isDark ? const Color(0xFFE2B6BB) : AppColors.secondary;

    final allNotes = ref.watch(notesProvider);
    final aiOn = ref.watch(appSettingsProvider.select((s) => s.smartSuggestions));

    // Extract dynamic spaces
    final Set<String> spacesSet = {'All Spaces'};
    for (final note in allNotes) {
      spacesSet.add(note.space);
    }
    final spacesList = spacesSet.toList();

    final filteredNotes = (_selectedSpace == 'All Spaces'
        ? [...allNotes]
        : allNotes.where((n) => n.space == _selectedSpace).toList())
      ..sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });

    return Stack(
      children: [
        SingleChildScrollView(
          physics: SanctuaryMotionEngine.fluidPhysics,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title, summary and one action; the tools sit quietly beneath.
          Builder(builder: (context) {
            final c = CardInk.of(context);
            Widget tool(String tip, IconData icon, VoidCallback onTap, {bool on = false}) => Tooltip(
                  message: tip,
                  child: Pressable(
                    onTap: () {
                      SanctuaryHapticEngine.dialDetent();
                      onTap();
                    },
                    pressedScale: 0.86,
                    hoverLift: 0,
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: Motion.standard,
                          child: Icon(icon, key: ValueKey('$icon$on'), size: 17, color: on ? c.mark : c.muted),
                        ),
                      ),
                    ),
                  ),
                );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Notes', style: GoogleFonts.bodoniModa(fontSize: 36, fontWeight: FontWeight.bold, color: c.ink, height: 1.05)),
                          const SizedBox(height: 4),
                          RollingText(
                            '${allNotes.length} ${allNotes.length == 1 ? 'note' : 'notes'} in ${spacesList.length - 1} ${spacesList.length - 1 == 1 ? 'space' : 'spaces'}',
                            style: c.meta.copyWith(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    CardAction(label: 'New note', icon: LucideIcons.plus, onTap: () => _showAddNoteDialog(context, isDark)),
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      tool(_isSelectionMode ? 'Stop selecting' : 'Select notes', LucideIcons.checkSquare, () {
                        setState(() {
                          _isSelectionMode = !_isSelectionMode;
                          if (!_isSelectionMode) _selectedNoteIds.clear();
                        });
                      }, on: _isSelectionMode),
                      tool('Import a document (PDF, MD, TXT, CSV)', LucideIcons.fileUp, () => _importDocument(context)),
                      tool('Handwriting', LucideIcons.penTool, () => setState(() => _showInkCanvas = !_showInkCanvas), on: _showInkCanvas),
                      tool('Two notes side by side', LucideIcons.columns, () => setState(() => _showDualCanvas = !_showDualCanvas), on: _showDualCanvas),
                      tool('Note font', LucideIcons.type, () => _showNotesFontPicker(context, isDark, primaryTextColor, subtextColor, accentColor)),
                      tool(_showGraphView ? 'Back to list' : 'Mind map', LucideIcons.network, () => setState(() => _showGraphView = !_showGraphView), on: _showGraphView),
                      const SizedBox(width: 8),
                      CardLink(label: 'Weekly summary', onTap: () => showExecutiveDossierDialog(context)),
                    ],
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 14),
          // Digital Ink Signature Canvas
          if (_showInkCanvas) ...[
            InkSignatureCanvas(onClose: () => setState(() => _showInkCanvas = false)),
            const SizedBox(height: 20),
          ],

          // Knowledge Graph View Modal
          if (_showGraphView) ...[
            NotesGraphView(onClose: () => setState(() => _showGraphView = false)),
            const SizedBox(height: 20),
          ],

          // Space words (and AI groups when smart suggestions are on).
          CardTabs(
            options: [if (aiOn) 'Smart groups', ...spacesList.map((s) => s == 'All Spaces' ? 'All' : s)],
            selected: _smartGroups && aiOn ? 'Smart groups' : (_selectedSpace == 'All Spaces' ? 'All' : _selectedSpace),
            onSelected: (choice) {
              SanctuaryHapticEngine.dialDetent();
              setState(() {
                _smartGroups = choice == 'Smart groups';
                if (!_smartGroups) _selectedSpace = choice == 'All' ? 'All Spaces' : choice;
              });
            },
          ),
          const SizedBox(height: 16),

          if (aiOn && _smartGroups && filteredNotes.isNotEmpty)
            SmartGroupsView<NoteItem>(
              items: filteredNotes,
              kind: 'notes',
              textOf: (n) => '${n.title} ${n.title} ${n.tag} ${n.body}',
              itemBuilder: (n) => Padding(
                key: ValueKey('sg-${n.id}'),
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildNoteItem(n, isDark, primaryTextColor, subtextColor, accentColor),
              ),
            )
          // Dual Canvas Split-Screen View Mode
          else if (_showDualCanvas && filteredNotes.length >= 2)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildNoteItem(filteredNotes[0], isDark, primaryTextColor, subtextColor, accentColor)),
                const SizedBox(width: 12),
                Expanded(child: _buildNoteItem(filteredNotes[1], isDark, primaryTextColor, subtextColor, accentColor)),
              ],
            )
          else if (filteredNotes.isEmpty)
            const EmptyState(
  icon: LucideIcons.fileText,
  title: 'No notes in this space',
  message: 'Tap "Add Note" or use the + dial to capture a new thought.',
)
          else
            MotionColumn(
  spacing: 0,
  // Pinterest-style board on wide screens; one column on phones.
  minTileWidth: 300,
  children: [
    for (var idx = 0; idx < filteredNotes.length; idx++)
      Builder(key: ValueKey(filteredNotes[idx].id), builder: (context) {
                final note = filteredNotes[idx];
                return Reveal(style: RevealStyle.slideIn, distance: 18, child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildNoteItem(note, isDark, primaryTextColor, subtextColor, accentColor),
                ));
              }),
  ],
),
        ].revealed(),
          ),
        ),
        if (_isSelectionMode && _selectedNoteIds.isNotEmpty)
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 520),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: edBox(
                  color: isDark ? const Color(0xFF141720) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.secondary, width: 1.4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.18),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: edBox(
                        color: AppColors.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_selectedNoteIds.length} Selected',
                        style: GoogleFonts.dmSans(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.secondary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Pressable(
                      pressedScale: 0.95,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          final selected = allNotes.where((n) => _selectedNoteIds.contains(n.id)).toList();
                          showNotesRagModal(context, notes: selected);
                        },
                        icon: const Icon(LucideIcons.brain, size: 14),
                        label: Text(
                          'Ask Group RAG AI',
                          style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      tooltip: 'Clear selection',
                      icon: Icon(LucideIcons.x, size: 15, color: subtextColor),
                      onPressed: () => setState(() => _selectedNoteIds.clear()),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNoteItem(
    NoteItem note,
    bool isDark,
    Color primaryTextColor,
    Color subtextColor,
    Color accentColor,
  ) {
    final isTorn = _tearingNoteIds.contains(note.id);
    final isSelected = _selectedNoteIds.contains(note.id);

    return DeckledPaperTear(
      isTorn: isTorn,
      onTearComplete: () {
        _tearingNoteIds.remove(note.id);
        ref.read(notesProvider.notifier).removeNote(note.id);
      },
      child: BentoPod(
        style: note.isPinned ? PodTextureStyle.glass : PodTextureStyle.paper,
        showWaxSeal: true,
        onTap: () {
          if (_isSelectionMode) {
            SanctuaryHapticEngine.dialDetent();
            setState(() {
              if (isSelected) {
                _selectedNoteIds.remove(note.id);
              } else {
                _selectedNoteIds.add(note.id);
              }
            });
          } else {
            openEntryEditor(context, EntryKind.note, editing: note);
          }
        },
        child: Stack(
          children: [
            _buildNoteCardContent(note, isDark, primaryTextColor, subtextColor, accentColor),
            if (_isSelectionMode)
              Positioned(
                top: 0,
                right: 0,
                child: AnimatedContainer(
                  duration: Motion.standard,
                  curve: Motion.settle,
                  padding: const EdgeInsets.all(4),
                  decoration: edBox(
                    color: isSelected ? const Color(0xFF8E2433) : (isDark ? const Color(0xFF1E1A1A) : const Color(0xFFEDE6DF)),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSelected ? LucideIcons.check : LucideIcons.circle,
                    size: 14,
                    color: isSelected ? Colors.white : Colors.transparent,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCardContent(
    NoteItem note,
    bool isDark,
    Color primaryTextColor,
    Color subtextColor,
    Color accentColor,
  ) {
    final c = CardInk.of(context);
    final notesFont = ref.watch(appSettingsProvider).fontFamilyNotes;
    final globalFont = ref.watch(appSettingsProvider).fontFamilyGlobal;
    final effectiveFont = notesFont == 'Default' ? globalFont : notesFont;
    final hasAudio = note.excerpt.contains('🎙️') ||
        note.tag == 'Voice Memo' ||
        note.content.contains('🎙️') ||
        (note.audioAttachmentUrl != null && note.audioAttachmentUrl!.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // One quiet line on top: tag and date, then pin and a menu.
        Row(
          children: [
            Expanded(
              child: Text(
                [note.tag, note.date].where((s) => s.trim().isNotEmpty).join(' · '),
                style: c.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Tooltip(
              message: note.isPinned ? 'Unpin' : 'Pin',
              child: Pressable(
                pressedScale: 0.8,
                hoverLift: 0,
                onTap: () {
                  SanctuaryHapticEngine.escapementTick();
                  ref.read(notesProvider.notifier).togglePin(note.id);
                },
                child: SizedBox(
                  width: 34,
                  height: 34,
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 380),
                      switchInCurve: Motion.settle,
                      transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
                      child: Icon(
                        note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                        key: ValueKey(note.isPinned),
                        size: 15,
                        color: note.isPinned ? c.mark : c.muted.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 34,
              height: 34,
              child: PopupMenuButton<String>(
                tooltip: 'More',
                padding: EdgeInsets.zero,
                icon: Icon(LucideIcons.ellipsis, size: 17, color: c.muted),
                color: isDark ? const Color(0xFF141111) : Colors.white,
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onSelected: (action) {
                  switch (action) {
                    case 'ask':
                      widget.onOpenAiModal(note.title);
                    case 'rag':
                      showNotesRagModal(context, notes: [note]);
                    case 'evolve':
                      showWorkflowEvolutionDialog(context, title: note.title, content: note.content);
                    case 'review':
                      showPressureTestDialog(context, title: note.title, content: note.content);
                    case 'delete':
                      SanctuaryHapticEngine.sealImpression();
                      setState(() => _tearingNoteIds.add(note.id));
                  }
                },
                itemBuilder: (_) => [
                  for (final (value, label, icon) in [
                    ('ask', 'Ask Nodo', LucideIcons.sparkles),
                    ('rag', 'Ask questions about this note', LucideIcons.brain),
                    ('evolve', 'Turn into a plan', LucideIcons.arrowUpRight),
                    ('review', 'Review the plan', LucideIcons.zap),
                    ('delete', 'Delete note', LucideIcons.scissors),
                  ])
                    PopupMenuItem(
                      value: value,
                      child: Row(
                        children: [
                          Icon(icon, size: 16, color: value == 'delete' ? c.mark : c.muted),
                          const SizedBox(width: 12),
                          Text(label, style: c.body.copyWith(fontSize: 14, color: value == 'delete' ? c.mark : c.ink)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (note.coverUrl != null && note.coverUrl!.isNotEmpty) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 120,
              width: double.infinity,
              child: note.coverUrl!.startsWith('http')
                  ? Image.network(note.coverUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink())
                  : Image.file(File(note.coverUrl!), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          note.title.isEmpty ? 'Untitled' : note.title,
          style: notesFont == 'Default' && globalFont == 'Default'
              ? c.title.copyWith(fontSize: 20)
              : AppTypography.getStyle(effectiveFont, fontSize: 19, fontWeight: FontWeight.bold, color: c.ink),
        ),
        if (note.excerpt.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            note.excerpt,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.getStyle(effectiveFont, fontSize: 14, color: c.muted, height: 1.5),
          ),
        ],
        if (hasAudio) ...[
          const SizedBox(height: 8),
          AudioCassettePlayer(
            title: note.title,
            audioPath: note.audioAttachmentUrl,
            totalDuration: note.audioAttachmentDuration != null
                ? Duration(seconds: note.audioAttachmentDuration!)
                : AudioCassettePlayer.parseDuration('${note.excerpt} ${note.content}'),
          ),
        ],
        const SizedBox(height: 12),
        Text('In ${note.space}', style: c.meta.copyWith(fontSize: 12.5), maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }

  void _showNotesFontPicker(
    BuildContext context,
    bool isDark,
    Color primaryTextColor,
    Color subtextColor,
    Color accentColor,
  ) {
    SanctuaryHapticEngine.dialDetent();
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF141210) : const Color(0xFFFFFDF8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final currentFont = ref.watch(appSettingsProvider).fontFamilyNotes;
        final globalFont = ref.watch(appSettingsProvider).fontFamilyGlobal;
        final allOptions = ['Default', ...AppTypography.availableFonts];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Notes Section Typography',
                      style: GoogleFonts.bodoniModa(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 18),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                Text(
                  'Select a font dedicated to your notes, or follow universal settings.',
                  style: GoogleFonts.dmSans(fontSize: 12, color: subtextColor),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: allOptions.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: isDark ? const Color(0xFF262220) : const Color(0xFFE8DFC8),
                    ),
                    itemBuilder: (context, i) {
                      final opt = allOptions[i];
                      final isSel = currentFont == opt;
                      final label = opt == 'Default' ? 'Universal Font ($globalFont)' : opt;

                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        title: Text(
                          label,
                          style: opt == 'Default'
                              ? GoogleFonts.dmSans(fontSize: 14, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: primaryTextColor)
                              : AppTypography.getStyle(opt, fontSize: 14, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: primaryTextColor),
                        ),
                        subtitle: opt == 'Default'
                            ? null
                            : Text(
                                AppTypography.fontDescriptions[opt] ?? '',
                                style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor),
                              ),
                        trailing: isSel
                            ? Icon(LucideIcons.check, size: 16, color: accentColor)
                            : null,
                        onTap: () {
                          SanctuaryHapticEngine.dialDetent();
                          ref.read(appSettingsProvider.notifier).setFontFamilyNotes(opt);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
