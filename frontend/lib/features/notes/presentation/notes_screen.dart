import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/state/sanctuary_state.dart';
import '../../../core/widgets/bento_pod.dart';
import '../../../core/widgets/ink_signature_canvas.dart';
import 'notes_graph_view.dart';

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

  void _showAddNoteDialog(BuildContext context, bool isDark) {
    final titleController = TextEditingController();
    final excerptController = TextEditingController();
    String space = 'Academic Space';
    String tag = 'Research';

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final dialogBg = isDark ? const Color(0xFF000000) : AppColors.surfaceContainerHigh;
            final textColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
            final borderColor = isDark ? const Color(0xFF1E1E1E) : AppColors.outlineVariant;

            return Dialog(
              backgroundColor: dialogBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: borderColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Compose Sanctuary Note', style: GoogleFonts.bodoniModa(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                        IconButton(
                          icon: Icon(LucideIcons.x, color: isDark ? Colors.white70 : AppColors.onSurface, size: 20),
                          onPressed: () => Navigator.pop(dialogCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Note title...',
                        hintStyle: TextStyle(color: isDark ? Colors.white38 : AppColors.onSurfaceVariant),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF080808) : Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: excerptController,
                      maxLines: 3,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Key thoughts or excerpt...',
                        hintStyle: TextStyle(color: isDark ? Colors.white38 : AppColors.onSurfaceVariant),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF080808) : Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: space,
                            dropdownColor: isDark ? const Color(0xFF080808) : Colors.white,
                            style: TextStyle(color: textColor),
                            decoration: InputDecoration(
                              labelText: 'Knowledge Space',
                              labelStyle: TextStyle(color: isDark ? Colors.white70 : AppColors.onSurfaceVariant),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: ['Academic Space', 'Travel Space', 'Design Space', 'Wardrobe Space', 'Personal Sanctuary']
                                .map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setDialogState(() => space = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFFE8927C) : AppColors.primary,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          if (titleController.text.trim().isNotEmpty) {
                            ref.read(notesProvider.notifier).addNote(
                                  title: titleController.text.trim(),
                                  space: space,
                                  tag: tag,
                                  excerpt: excerptController.text.trim().isNotEmpty
                                      ? excerptController.text.trim()
                                      : 'Archived into $space',
                                );
                            Navigator.pop(dialogCtx);
                          }
                        },
                        child: const Text('Enshrine Note', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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

    final filteredNotes = _selectedSpace == 'All Spaces'
        ? allNotes
        : allNotes.where((n) => n.space == _selectedSpace).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Screen Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TACTILE KNOWLEDGE SANCTUARY', style: AppTypography.labelSm),
                    const SizedBox(height: 4),
                    Text(
                      'Notes & Spaces',
                      style: GoogleFonts.bodoniModa(fontSize: 28, fontWeight: FontWeight.bold, color: primaryTextColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${allNotes.length} enshrined notes across ${spacesList.length - 1} spaces',
                      style: GoogleFonts.dmSans(fontSize: 13, color: subtextColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Digital Ink Canvas',
                    icon: Icon(LucideIcons.penTool, color: accentColor, size: 18),
                    onPressed: () => setState(() => _showInkCanvas = !_showInkCanvas),
                  ),
                  IconButton(
                    tooltip: 'Dual Canvas Split Mode',
                    icon: Icon(LucideIcons.columns, color: _showDualCanvas ? accentColor : primaryTextColor, size: 18),
                    onPressed: () => setState(() => _showDualCanvas = !_showDualCanvas),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _showGraphView ? accentColor : (isDark ? const Color(0xFF1E1E1E) : AppColors.primary),
                      foregroundColor: _showGraphView ? (isDark ? Colors.black : Colors.white) : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    onPressed: () => setState(() => _showGraphView = !_showGraphView),
                    icon: const Icon(LucideIcons.network, size: 14),
                    label: Text(_showGraphView ? 'List' : 'Mind Map', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Add Note quick action bar
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _showAddNoteDialog(context, isDark),
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('Add Note', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),

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
                    onSelected: (val) => setState(() => _selectedSpace = space),
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
                Expanded(child: _buildNoteCard(filteredNotes[0], isDark, primaryTextColor, subtextColor, accentColor)),
                const SizedBox(width: 12),
                Expanded(child: _buildNoteCard(filteredNotes[1], isDark, primaryTextColor, subtextColor, accentColor)),
              ],
            )
          else if (filteredNotes.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF000000) : Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? const Color(0xFF1E1E1E) : Colors.black12),
              ),
              child: Column(
                children: [
                  Icon(LucideIcons.fileText, size: 40, color: accentColor.withValues(alpha: 0.6)),
                  const SizedBox(height: 12),
                  Text('No notes in this space', style: GoogleFonts.bodoniModa(fontSize: 18, color: primaryTextColor)),
                  const SizedBox(height: 4),
                  Text('Tap "Add Note" or use the central + dial to seal a new thought.', style: GoogleFonts.dmSans(fontSize: 13, color: subtextColor)),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredNotes.length,
              itemBuilder: (context, idx) {
                final note = filteredNotes[idx];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildNoteCard(note, isDark, primaryTextColor, subtextColor, accentColor),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(
    NoteItem note,
    bool isDark,
    Color primaryTextColor,
    Color subtextColor,
    Color accentColor,
  ) {
    return BentoPod(
      style: PodTextureStyle.paper,
      showWaxSeal: true,
      child: Column(
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
                    icon: Icon(LucideIcons.trash2, size: 14, color: isDark ? Colors.white30 : Colors.black26),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      ref.read(notesProvider.notifier).removeNote(note.id);
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(note.title, style: GoogleFonts.bodoniModa(fontSize: 18, fontWeight: FontWeight.bold, color: primaryTextColor)),
          const SizedBox(height: 6),
          Text(note.excerpt, style: GoogleFonts.dmSans(fontSize: 13, color: subtextColor, height: 1.5)),
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
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: accentColor),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => widget.onOpenAiModal(note.title),
                icon: Icon(LucideIcons.sparkles, size: 12, color: accentColor),
                label: Text('Ask Note AI', style: GoogleFonts.dmSans(fontSize: 11, color: accentColor, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
