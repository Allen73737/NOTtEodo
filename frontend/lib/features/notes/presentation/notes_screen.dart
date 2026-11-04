import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/state/sanctuary_state.dart';
import '../../../core/widgets/bento_pod.dart';
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
    final accentColor = isDark ? const Color(0xFFE8927C) : AppColors.secondary;

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
          // Screen Header
          // Screen Header with Unified Curator Toolbar
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 620;

              final titleCol = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('WORKSPACE', style: AppTypography.labelSm),
                  const SizedBox(height: 4),
                  Text(
                    'Notes',
                    style: GoogleFonts.bodoniModa(fontSize: isNarrow ? 26 : 28, fontWeight: FontWeight.bold, color: primaryTextColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${allNotes.length} notes across ${spacesList.length - 1} categories',
                    style: GoogleFonts.dmSans(fontSize: 13, color: subtextColor),
                  ),
                ],
              );

              final toolbar = SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF141312) : const Color(0xFFF7F4EC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isDark ? const Color(0xFF26221C) : const Color(0xFFE4DDCB), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: _isSelectionMode ? 'Exit Selection Mode' : 'Multi-Select / Group Notes',
                            icon: Icon(
                              _isSelectionMode ? LucideIcons.checkSquare2 : LucideIcons.checkSquare,
                              color: _isSelectionMode ? const Color(0xFFD4AF37) : (isDark ? Colors.white60 : AppColors.onSurfaceVariant),
                              size: 16,
                            ),
                            padding: const EdgeInsets.all(7),
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              SanctuaryHapticEngine.dialDetent();
                              setState(() {
                                _isSelectionMode = !_isSelectionMode;
                                if (!_isSelectionMode) _selectedNoteIds.clear();
                              });
                            },
                          ),
                          const SizedBox(width: 2),
                          IconButton(
                            tooltip: 'Import Document from Device (PDF, MD, TXT, CSV)',
                            icon: Icon(
                              LucideIcons.fileUp,
                              color: isDark ? Colors.white60 : AppColors.onSurfaceVariant,
                              size: 16,
                            ),
                            padding: const EdgeInsets.all(7),
                            constraints: const BoxConstraints(),
                            onPressed: () => _importDocument(context),
                          ),
                          const SizedBox(width: 2),
                          IconButton(
                            tooltip: 'Digital Ink Canvas',
                            icon: Icon(LucideIcons.penTool, color: _showInkCanvas ? accentColor : (isDark ? Colors.white60 : AppColors.onSurfaceVariant), size: 16),
                            padding: const EdgeInsets.all(7),
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              SanctuaryHapticEngine.dialDetent();
                              setState(() => _showInkCanvas = !_showInkCanvas);
                            },
                          ),
                          const SizedBox(width: 2),
                          IconButton(
                            tooltip: 'Dual Canvas Split Mode',
                            icon: Icon(LucideIcons.columns, color: _showDualCanvas ? accentColor : (isDark ? Colors.white60 : AppColors.onSurfaceVariant), size: 16),
                            padding: const EdgeInsets.all(7),
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              SanctuaryHapticEngine.dialDetent();
                              setState(() => _showDualCanvas = !_showDualCanvas);
                            },
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              SanctuaryHapticEngine.dialDetent();
                              setState(() => _showGraphView = !_showGraphView);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _showGraphView ? accentColor.withValues(alpha: 0.2) : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.network, size: 13, color: _showGraphView ? accentColor : (isDark ? Colors.white70 : AppColors.onSurface)),
                                  const SizedBox(width: 5),
                                  Text(
                                    _showGraphView ? 'List' : 'Mind Map',
                                    style: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      color: _showGraphView ? accentColor : (isDark ? Colors.white70 : AppColors.onSurface),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Pressable(
                      pressedScale: 0.95,
                      hoverLift: 0,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: isDark ? const Color(0xFF26221C) : const Color(0xFFE4DDCB)),
                          foregroundColor: isDark ? Colors.white70 : AppColors.onSurface,
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => showExecutiveDossierDialog(context),
                        icon: const Icon(LucideIcons.fileSpreadsheet, size: 14),
                        label: const Text('Weekly Dossier', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Pressable(pressedScale: 0.95, hoverLift: 0, child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => _showAddNoteDialog(context, isDark),
                      icon: const Icon(LucideIcons.plus, size: 15),
                      label: const Text('Add Note', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                    )),
                  ],
                ),
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleCol,
                    const SizedBox(height: 14),
                    toolbar,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: titleCol),
                  const SizedBox(width: 14),
                  toolbar,
                ],
              );
            },
          ),
          const SizedBox(height: 18),

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

          // Space Filter Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                if (aiOn) Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    avatar: Icon(LucideIcons.sparkles, size: 14, color: _smartGroups ? accentColor : subtextColor),
                    label: const Text('Smart groups'),
                    tooltip: 'Group notes by what they are about',
                    selected: _smartGroups,
                    showCheckmark: false,
                    selectedColor: accentColor.withValues(alpha: isDark ? 0.25 : 0.15),
                    backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white.withValues(alpha: 0.6),
                    labelStyle: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: _smartGroups ? FontWeight.bold : FontWeight.w500,
                      color: _smartGroups ? accentColor : (isDark ? Colors.white70 : AppColors.onSurface),
                    ),
                    side: BorderSide(color: _smartGroups ? accentColor : (isDark ? const Color(0xFF2C2C2C) : Colors.black12)),
                    onSelected: (v) {
                      SanctuaryHapticEngine.dialDetent();
                      setState(() => _smartGroups = v);
                    },
                  ),
                ),
                ...spacesList.map((space) {
                final isSelected = _selectedSpace == space;
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(space),
                    selected: isSelected,
                    selectedColor: accentColor.withValues(alpha: isDark ? 0.25 : 0.15),
                    backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white.withValues(alpha: 0.6),
                    labelStyle: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? accentColor : (isDark ? Colors.white70 : AppColors.onSurface),
                    ),
                    side: BorderSide(
                      color: isSelected ? accentColor : (isDark ? const Color(0xFF2C2C2C) : Colors.black12),
                    ),
                    onSelected: (val) {
                      SanctuaryHapticEngine.dialDetent();
                      setState(() => _selectedSpace = space);
                    },
                  ),
                );
              }),
              ],
            ),
          ),
          const SizedBox(height: 20),

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
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF141720) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD4AF37), width: 1.4),
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
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_selectedNoteIds.length} Selected',
                        style: GoogleFonts.spaceGrotesk(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFFD4AF37)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Pressable(
                      pressedScale: 0.95,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
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
                          style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.bold),
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
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFD4AF37) : (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE8E3D8)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  note.tag,
                  style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.bold, color: accentColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                Text(note.date, style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor)),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(
                    note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    size: 15,
                    color: note.isPinned ? const Color(0xFFD4AF37) : (isDark ? Colors.white38 : Colors.black38),
                  ),
                  tooltip: note.isPinned ? 'Unpin Lapis Lazuli Plaque' : 'Pin as Lapis Lazuli Plaque',
                  onPressed: () {
                    SanctuaryHapticEngine.escapementTick();
                    ref.read(notesProvider.notifier).togglePin(note.id);
                  },
                ),
                IconButton(
                  icon: Icon(LucideIcons.scissors, size: 14, color: isDark ? Colors.white30 : Colors.black26),
                  tooltip: 'Delete note',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    SanctuaryHapticEngine.sealImpression();
                    setState(() => _tearingNoteIds.add(note.id));
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(note.title, style: GoogleFonts.bodoniModa(fontSize: 18, fontWeight: FontWeight.bold, color: primaryTextColor)),
        const SizedBox(height: 6),
        Text(
          note.excerpt,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.dmSans(fontSize: 13, color: subtextColor, height: 1.5),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Text(
              'Space: ${note.space}',
              style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, color: primaryTextColor),
              overflow: TextOverflow.ellipsis,
            ),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                Pressable(
                  pressedScale: 0.95,
                  hoverLift: 0,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => showWorkflowEvolutionDialog(
                      context,
                      title: note.title,
                      content: note.content,
                    ),
                    icon: const Icon(LucideIcons.arrowUpRight, size: 11, color: Color(0xFF10B981)),
                    label: Text(
                      'Evolve',
                      style: GoogleFonts.dmSans(fontSize: 10.5, color: const Color(0xFF10B981), fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Pressable(
                  pressedScale: 0.95,
                  hoverLift: 0,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => showPressureTestDialog(
                      context,
                      title: note.title,
                      content: note.content,
                    ),
                    icon: const Icon(LucideIcons.zap, size: 11, color: Color(0xFFF59E0B)),
                    label: Text(
                      'Pressure Test',
                      style: GoogleFonts.dmSans(fontSize: 10.5, color: const Color(0xFFF59E0B), fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Pressable(
                  pressedScale: 0.95,
                  hoverLift: 0,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: const Color(0xFFD4AF37).withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => showNotesRagModal(context, notes: [note]),
                    icon: const Icon(LucideIcons.brain, size: 11, color: Color(0xFFD4AF37)),
                    label: Text(
                      'RAG AI',
                      style: GoogleFonts.dmSans(fontSize: 10.5, color: const Color(0xFFD4AF37), fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Pressable(
                  pressedScale: 0.95,
                  hoverLift: 0,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: accentColor),
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => widget.onOpenAiModal(note.title),
                    icon: Icon(LucideIcons.sparkles, size: 11, color: accentColor),
                    label: Text(
                      'Ask AI',
                      style: GoogleFonts.dmSans(fontSize: 10.5, color: accentColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
