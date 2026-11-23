import 'package:flutter/material.dart';
import '../../../core/widgets/any_image.dart';
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
import '../../../core/tour/spotlight_tour.dart';
import '../../../core/ai/text_intelligence.dart';
import '../../../core/editorial/editorial_kit.dart' show hashtagsIn, showEditorialPrompt;

class NotesScreen extends ConsumerStatefulWidget {
  final Function(String) onOpenAiModal;

  const NotesScreen({super.key, required this.onOpenAiModal});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  bool _showDualCanvas = false;
  bool _showInkCanvas = false;
  String _selectedSpace = 'All Spaces';

  /// Group notes by meaning instead of by space.
  bool _smartGroups = false;
  final Set<String> _tearingNoteIds = {};
  bool _isSelectionMode = false;
  final Set<String> _selectedNoteIds = {};

  /// The note being dragged onto another to group them, if any.
  String? _draggingId;

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

  /// Text the smart grouper reads: the title and hashtags count double, and the
  /// default "Note" tag is left out so it does not pull every note together.
  static String _groupingText(NoteItem n) {
    final tags = hashtagsIn(n.body).join(' ');
    final tag = n.tag == 'Note' ? '' : n.tag;
    return '${n.title} ${n.title} $tag $tag $tags $tags ${n.body}';
  }

  /// A name for a new group made of [notes]: their shared topic, else a number.
  String _suggestGroupName(List<NoteItem> notes) {
    final counts = <String, int>{};
    for (final n in notes) {
      for (final t in TextIntelligence.topicsOf(_groupingText(n)).take(2)) {
        counts[t] = (counts[t] ?? 0) + 1;
      }
    }
    final shared = counts.entries.where((e) => e.value == notes.length).map((e) => e.key);
    if (shared.isNotEmpty) return shared.first;
    final taken = ref.read(notesProvider.notifier).groups.toSet();
    var i = taken.length + 1;
    while (taken.contains('Group $i')) {
      i++;
    }
    return 'Group $i';
  }

  Future<String?> _askGroupName(String suggestion, {String title = 'Name this group'}) async {
    final name = await showEditorialPrompt(context, title: title, hint: 'Group name', initial: suggestion, confirmLabel: 'Group');
    final trimmed = name?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  /// Puts [ids] in a group, then offers to undo it.
  void _applyGroup(Iterable<String> ids, String group) {
    final notifier = ref.read(notesProvider.notifier);
    final targets = ids.toSet();
    final before = {for (final n in ref.read(notesProvider)) if (targets.contains(n.id)) n.id: n.group};
    notifier.setGroup(targets, group);
    SanctuaryHapticEngine.sealImpression();
    AppToastEngine().notify(
      title: 'Grouped in "$group"',
      message: '${before.length} ${before.length == 1 ? 'note' : 'notes'} now sit together.',
      actionLabel: 'Undo',
      onAction: () => before.forEach((id, g) => notifier.setGroup([id], g)),
    );
  }

  /// One note dropped on another: join its group, or start a new one together.
  Future<void> _dropOnNote(String draggedId, NoteItem target) async {
    final notes = ref.read(notesProvider);
    final dragged = notes.where((n) => n.id == draggedId).firstOrNull;
    if (dragged == null || dragged.id == target.id) return;
    if (target.group != null) {
      if (dragged.group != target.group) _applyGroup([dragged.id], target.group!);
      return;
    }
    final name = await _askGroupName(_suggestGroupName([dragged, target]));
    if (name != null && mounted) _applyGroup([dragged.id, target.id], name);
  }

  Future<void> _groupSelected() async {
    final selected = ref.read(notesProvider).where((n) => _selectedNoteIds.contains(n.id)).toList();
    if (selected.isEmpty) return;
    final name = await _askGroupName(_suggestGroupName(selected));
    if (name == null || !mounted) return;
    _applyGroup(selected.map((n) => n.id), name);
    setState(() {
      _selectedNoteIds.clear();
      _isSelectionMode = false;
    });
  }

  Future<void> _groupMenu(String group, List<NoteItem> members, String action) async {
    final notifier = ref.read(notesProvider.notifier);
    switch (action) {
      case 'rename':
        final name = await _askGroupName(group, title: 'Rename group');
        if (name != null) notifier.renameGroup(group, name);
      case 'ask':
        showNotesRagModal(context, notes: members);
      case 'select':
        setState(() {
          _isSelectionMode = true;
          _selectedNoteIds
            ..clear()
            ..addAll(members.map((n) => n.id));
        });
      case 'ungroup':
        notifier.ungroup(group);
        AppToastEngine().notify(
          title: 'Group removed',
          message: 'The notes from "$group" are still here, ungrouped.',
          actionLabel: 'Undo',
          onAction: () => notifier.setGroup(members.map((n) => n.id), group),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    final accentColor = isDark ? const Color(0xFFD0485A) : AppColors.secondary;

    final allNotes = ref.watch(notesProvider);
    final aiOn = ref.watch(appSettingsProvider.select((s) => s.smartSuggestions));

    // Extract dynamic spaces
    final Set<String> spacesSet = {'All Spaces'};
    for (final note in allNotes) {
      spacesSet.add(note.space);
    }
    final spacesList = spacesSet.toList();
    // A space that lost its last note falls back to every note.
    if (!spacesSet.contains(_selectedSpace)) _selectedSpace = 'All Spaces';

    final filteredNotes = (_selectedSpace == 'All Spaces'
        ? [...allNotes]
        : allNotes.where((n) => n.space == _selectedSpace).toList())
      ..sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });

    Widget note(NoteItem n) => _buildNoteItem(n, isDark, primaryTextColor, subtextColor, accentColor);

    return Stack(
      children: [
        SingleChildScrollView(
          physics: SanctuaryMotionEngine.fluidPhysics,
          padding: EdgeInsets.fromLTRB(20, 16, 20, cardDockClearance(context) + 24),
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
                    TourTarget(id: 'page.primary', child: CardAction(label: 'New note', icon: LucideIcons.plus, onTap: () => _showAddNoteDialog(context, isDark))),
                  ],
                ),
                const SizedBox(height: 10),
                TourTarget(id: 'notes.tools', child: SingleChildScrollView(
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
                      if (allNotes.isNotEmpty)
                        tool('Ask your notes', LucideIcons.brain, () => showNotesRagModal(context, notes: filteredNotes)),
                      tool('Import a document (PDF, MD, TXT, CSV)', LucideIcons.fileUp, () => _importDocument(context)),
                      tool('Handwriting', LucideIcons.penTool, () => setState(() => _showInkCanvas = !_showInkCanvas), on: _showInkCanvas),
                      tool('Two notes side by side', LucideIcons.columns, () => setState(() => _showDualCanvas = !_showDualCanvas), on: _showDualCanvas),
                      tool('Note font', LucideIcons.type, () => _showNotesFontPicker(context, isDark, primaryTextColor, subtextColor, accentColor)),
                      tool('Map of notes', LucideIcons.network, () => openNotesMap(context)),
                      const SizedBox(width: 8),
                      CardLink(label: 'Weekly summary', onTap: () => showExecutiveDossierDialog(context)),
                    ],
                  ),
                )),
              ],
            );
          }),
          const SizedBox(height: 14),
          // Digital Ink Signature Canvas
          if (_showInkCanvas) ...[
            InkSignatureCanvas(onClose: () => setState(() => _showInkCanvas = false)),
            const SizedBox(height: 20),
          ],

          // Space words (and AI groups when smart suggestions are on).
          TourTarget(id: 'notes.spaces', child: CardTabs(
            options: [if (aiOn) 'Smart groups', ...spacesList.map((s) => s == 'All Spaces' ? 'All' : s)],
            selected: _smartGroups && aiOn ? 'Smart groups' : (_selectedSpace == 'All Spaces' ? 'All' : _selectedSpace),
            onSelected: (choice) {
              SanctuaryHapticEngine.dialDetent();
              setState(() {
                _smartGroups = choice == 'Smart groups';
                if (!_smartGroups) _selectedSpace = choice == 'All' ? 'All Spaces' : choice;
              });
            },
          )),
          const SizedBox(height: 16),

          if (aiOn && _smartGroups && filteredNotes.isNotEmpty)
            _smartGroupsSection(filteredNotes, note)
          // Dual Canvas Split-Screen View Mode
          else if (_showDualCanvas && filteredNotes.length >= 2)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: note(filteredNotes[0])),
                const SizedBox(width: 12),
                Expanded(child: note(filteredNotes[1])),
              ],
            )
          else if (filteredNotes.isEmpty)
            const EmptyState(
              icon: LucideIcons.fileText,
              title: 'No notes in this space',
              message: 'Tap "New note" or use the + dial to capture a new thought.',
            )
          else
            ..._groupedBoard(filteredNotes, note, accentColor),
        ].revealed(),
          ),
        ),
        // While a note is held, a strip above the dock explains the drop, and takes a
        // grouped note out of its group.
        if (_draggingId != null) _ungroupDropZone(allNotes, isDark, accentColor),
        if (_isSelectionMode && _selectedNoteIds.isNotEmpty && _draggingId == null)
          Positioned(
            bottom: cardDockClearance(context),
            left: 16,
            right: 16,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 520),
                padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
                decoration: edBox(
                  opaque: true,
                  color: isDark ? const Color(0xFF0E0C0C) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: accentColor, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.18),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Text(
                      '${_selectedNoteIds.length} selected',
                      style: GoogleFonts.dmSans(fontSize: 12.5, fontWeight: FontWeight.bold, color: accentColor),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _groupSelected,
                      icon: Icon(LucideIcons.folderPlus, size: 15, color: primaryTextColor),
                      label: Text('Group', style: GoogleFonts.dmSans(fontSize: 12.5, fontWeight: FontWeight.bold, color: primaryTextColor)),
                    ),
                    const SizedBox(width: 2),
                    Pressable(
                      pressedScale: 0.95,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          final selected = allNotes.where((n) => _selectedNoteIds.contains(n.id)).toList();
                          showNotesRagModal(context, notes: selected);
                        },
                        icon: const Icon(LucideIcons.brain, size: 14),
                        label: Text('Ask AI', style: GoogleFonts.dmSans(fontSize: 12.5, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Clear selection',
                      icon: Icon(LucideIcons.x, size: 16, color: subtextColor),
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

  /// A Keep-style board: two or more columns of notes, each as tall as its text.
  Widget _board(List<Widget> children) => MotionColumn(spacing: 0, minTileWidth: 158, columnSpacing: 12, children: children);

  Widget _tile(NoteItem n, Widget Function(NoteItem) note) => Builder(
        key: ValueKey(n.id),
        builder: (context) => Reveal(
          style: RevealStyle.slideIn,
          distance: 18,
          child: Padding(padding: const EdgeInsets.only(bottom: 12), child: _draggable(n, note(n))),
        ),
      );

  /// The groups made by hand come first, each under its name; the other notes follow.
  List<Widget> _groupedBoard(List<NoteItem> notes, Widget Function(NoteItem) note, Color accent) {
    final byGroup = <String, List<NoteItem>>{};
    final loose = <NoteItem>[];
    for (final n in notes) {
      n.group == null ? loose.add(n) : byGroup.putIfAbsent(n.group!, () => []).add(n);
    }
    final c = CardInk.of(context);
    return [
      if (byGroup.isEmpty && notes.length > 1)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text('Hold a note and drop it on another to group them.', style: c.meta.copyWith(fontSize: 12.5)),
        ),
      for (final MapEntry(key: group, value: members) in byGroup.entries) ...[
        _groupHeader(group, members, accent),
        _board([for (final n in members) _tile(n, note)]),
        const SizedBox(height: 8),
      ],
      if (loose.isNotEmpty) ...[
        if (byGroup.isNotEmpty)
          Padding(padding: const EdgeInsets.only(top: 4, bottom: 10), child: CardLabel('Other notes · ${loose.length}')),
        _board([for (final n in loose) _tile(n, note)]),
      ],
    ];
  }

  Widget _groupHeader(String group, List<NoteItem> members, Color accent) {
    final c = CardInk.of(context);
    return DragTarget<String>(
      onWillAcceptWithDetails: (d) => !members.any((n) => n.id == d.data),
      onAcceptWithDetails: (d) => _applyGroup([d.data], group),
      builder: (context, candidates, _) => AnimatedContainer(
        duration: Motion.standard,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(12, 4, 0, 4),
        decoration: edBox(
          color: candidates.isNotEmpty ? accent.withValues(alpha: 0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: candidates.isNotEmpty ? accent : Colors.transparent, width: 1.2),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.folder, size: 16, color: accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                candidates.isNotEmpty ? 'Drop to add to $group' : group,
                style: GoogleFonts.bodoniModa(fontSize: 19, fontWeight: FontWeight.bold, color: c.ink),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text('${members.length}', style: c.meta.copyWith(fontSize: 13)),
            PopupMenuButton<String>(
              tooltip: 'Group options',
              icon: Icon(LucideIcons.ellipsis, size: 17, color: c.muted),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              onSelected: (a) => _groupMenu(group, members, a),
              itemBuilder: (_) => [
                for (final (value, label, icon) in [
                  ('rename', 'Rename group', LucideIcons.pencil),
                  ('ask', 'Ask AI about this group', LucideIcons.brain),
                  ('select', 'Select these notes', LucideIcons.checkSquare),
                  ('ungroup', 'Ungroup', LucideIcons.folderMinus),
                ])
                  PopupMenuItem(
                    value: value,
                    child: Row(children: [
                      Icon(icon, size: 16, color: c.muted),
                      const SizedBox(width: 12),
                      Text(label, style: c.body.copyWith(fontSize: 14, color: c.ink)),
                    ]),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// A note card that can be held and dropped on another note (or a group) to group them.
  Widget _draggable(NoteItem n, Widget card) {
    if (_isSelectionMode) return card;
    final accent = CardInk.of(context).mark;
    return LayoutBuilder(builder: (context, box) {
      return DragTarget<String>(
        onWillAcceptWithDetails: (d) => d.data != n.id,
        onAcceptWithDetails: (d) => _dropOnNote(d.data, n),
        builder: (context, candidates, _) {
          final over = candidates.isNotEmpty;
          return LongPressDraggable<String>(
            data: n.id,
            hapticFeedbackOnStart: true,
            onDragStarted: () => setState(() => _draggingId = n.id),
            onDragEnd: (_) => setState(() => _draggingId = null),
            feedback: _dragFeedback(n, box.maxWidth),
            childWhenDragging: Opacity(opacity: 0.3, child: card),
            child: AnimatedScale(
              scale: over ? 0.96 : 1,
              duration: Motion.standard,
              curve: Motion.settle,
              child: Stack(
                children: [
                  card,
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        opacity: over ? 1 : 0,
                        duration: Motion.standard,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: accent, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              n.group == null ? 'Group together' : 'Add to ${n.group}',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.bold, color: accent),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  Widget _dragFeedback(NoteItem n, double width) {
    final c = CardInk.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: Transform.rotate(
        angle: -0.025,
        child: Container(
          width: width.isFinite ? width : 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141111) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: c.mark, width: 1.4),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.7 : 0.22), blurRadius: 30, offset: const Offset(0, 14))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(n.title.isEmpty ? 'Untitled' : n.title, style: c.title.copyWith(fontSize: 17), maxLines: 2, overflow: TextOverflow.ellipsis),
              if (n.excerpt.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(n.excerpt, style: c.meta.copyWith(fontSize: 13), maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _ungroupDropZone(List<NoteItem> all, bool isDark, Color accent) {
    final dragged = all.where((n) => n.id == _draggingId).firstOrNull;
    final from = dragged?.group;
    return Positioned(
      left: 16,
      right: 16,
      bottom: cardDockClearance(context),
      child: Center(
        child: DragTarget<String>(
          onWillAcceptWithDetails: (_) => from != null,
          onAcceptWithDetails: (d) {
            final notifier = ref.read(notesProvider.notifier);
            notifier.setGroup([d.data], null);
            AppToastEngine().notify(
              title: 'Taken out of "$from"',
              message: '"${dragged!.title}" is no longer grouped.',
              actionLabel: 'Undo',
              onAction: () => notifier.setGroup([d.data], from),
            );
          },
          builder: (context, candidates, _) {
            final hot = candidates.isNotEmpty;
            final ink = hot ? Colors.white : accent;
            return AnimatedContainer(
              duration: Motion.standard,
              constraints: const BoxConstraints(maxWidth: 520),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: hot ? accent : (isDark ? const Color(0xFF0E0C0C) : Colors.white),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: accent, width: 1.2),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.16), blurRadius: 24, offset: const Offset(0, 8))],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(from != null ? LucideIcons.folderMinus : LucideIcons.folderPlus, size: 16, color: ink),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      from != null ? 'Drop here to take it out of "$from"' : 'Drop on another note or a group',
                      style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.bold, color: ink),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Suggested groups for the notes not yet grouped by hand; any of them can be kept.
  Widget _smartGroupsSection(List<NoteItem> notes, Widget Function(NoteItem) note) {
    final loose = notes.where((n) => n.group == null).toList();
    if (loose.isEmpty) {
      return const EmptyState(
        icon: LucideIcons.folder,
        title: 'Every note is in a group',
        message: 'Smart groups suggest groups for the notes you have not grouped yet.',
      );
    }
    return SmartGroupsView<NoteItem>(
      items: loose,
      kind: 'notes',
      textOf: _groupingText,
      groupLayout: _board,
      onKeepGroup: (label, members) {
        _applyGroup(members.map((n) => n.id), label);
        setState(() => _smartGroups = false);
      },
      itemBuilder: (n) => _tile(n, note),
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
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 16),
        // Holding a note picks it up to group it, so it does not lift a preview.
        peek: false,
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
                          Flexible(child: Text(label, style: c.body.copyWith(fontSize: 14, color: value == 'delete' ? c.mark : c.ink))),
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
              child: AnyImage(note.coverUrl!, fit: BoxFit.cover),
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
            maxLines: 8,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.getStyle(effectiveFont, fontSize: 14, color: c.muted, height: 1.5),
          ),
        ],
        if (hasAudio) ...[
          const SizedBox(height: 8),
          // The cassette needs room; a narrow board tile shows a quiet label instead.
          LayoutBuilder(builder: (context, box) => box.maxWidth < 240
              ? Row(children: [
                  Icon(LucideIcons.mic, size: 13, color: c.mark),
                  const SizedBox(width: 6),
                  Text('Voice memo', style: c.meta.copyWith(fontSize: 12.5)),
                ])
              : AudioCassettePlayer(
            title: note.title,
            audioPath: note.audioAttachmentUrl,
            totalDuration: note.audioAttachmentDuration != null
                ? Duration(seconds: note.audioAttachmentDuration!)
                : AudioCassettePlayer.parseDuration('${note.excerpt} ${note.content}'),
          )),
        ],
        const SizedBox(height: 12),
        Text(note.space, style: c.meta.copyWith(fontSize: 12.5), maxLines: 1, overflow: TextOverflow.ellipsis),
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
