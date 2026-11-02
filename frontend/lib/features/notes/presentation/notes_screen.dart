import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
  final Set<String> _tearingNoteIds = {};

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

    return SingleChildScrollView(
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
              children: spacesList.map((space) {
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
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Dual Canvas Split-Screen View Mode
          if (_showDualCanvas && filteredNotes.length >= 2)
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

    return DeckledPaperTear(
      isTorn: isTorn,
      onTearComplete: () {
        _tearingNoteIds.remove(note.id);
        ref.read(notesProvider.notifier).removeNote(note.id);
      },
      child: BentoPod(
        style: note.isPinned ? PodTextureStyle.glass : PodTextureStyle.paper,
        showWaxSeal: true,
        onTap: () => openEntryEditor(context, EntryKind.note, editing: note),
        child: _buildNoteCardContent(note, isDark, primaryTextColor, subtextColor, accentColor),
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
            Pressable(pressedScale: 0.95, hoverLift: 0, child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: accentColor),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => widget.onOpenAiModal(note.title),
              icon: Icon(LucideIcons.sparkles, size: 12, color: accentColor),
              label: Text('Ask Note AI', style: GoogleFonts.dmSans(fontSize: 11, color: accentColor, fontWeight: FontWeight.bold)),
            )),
          ],
        ),
      ],
    );
  }
}
