import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ai/ai_widgets.dart';
import '../../../core/editorial/editorial_kit.dart';
import '../../../core/services/document_ingestion_service.dart';
import '../../../core/state/app_settings.dart';
import '../../../core/state/sanctuary_state.dart';
import '../../../core/utils/date_labels.dart';
import '../../../core/widgets/entry_editor.dart';
import '../../../core/widgets/executive_dossier_dialog.dart';
import '../../../core/widgets/pressure_test_dialog.dart';
import '../../../core/widgets/workflow_evolution_dialog.dart';
import 'notes_graph_view.dart';
import 'notes_rag_modal.dart';

/// Every tag on a note: its own tag plus any `#hashtags` in the text.
List<String> noteTags(NoteItem n) {
  final tags = <String>{if (n.tag.trim().isNotEmpty && n.tag != 'Note') n.tag.trim().toLowerCase(), ...hashtagsIn(n.body)};
  return tags.toList();
}

/// Titles linked from a note with `[[Title]]`.
final _noteLink = RegExp(r'\[\[([^\[\]]{1,80})\]\]');

List<String> noteLinks(String text) => _noteLink.allMatches(text).map((m) => m.group(1)!.trim()).toSet().toList();

/// Notes as an index of headlines. Search across everything, filter by group, space
/// or tag, hold a note for options (including moving it into a group), tap to read it.
class NotesEditorialView extends ConsumerStatefulWidget {
  const NotesEditorialView({super.key});

  @override
  ConsumerState<NotesEditorialView> createState() => _NotesEditorialViewState();
}

class _NotesEditorialViewState extends ConsumerState<NotesEditorialView> {
  String _query = '';
  String _tag = 'All';

  static const _smart = 'Smart groups';

  void _menu(NoteItem n) {
    final notes = ref.read(notesProvider.notifier);
    showEditorialMenu(context, title: n.title.isEmpty ? 'Untitled' : n.title, subtitle: 'Edited ${n.date}', items: [
      EditorialMenuItem('Read', () => pushEditorial(context, NoteReader(noteId: n.id))),
      EditorialMenuItem('Edit', () => openEntryEditor(context, EntryKind.note, editing: n, startEditing: true)),
      EditorialMenuItem('Copy text', () => copyToClipboard('${n.title}\n\n${n.body}', what: 'Note')),
      EditorialMenuItem('Ask about this note', () => showNotesRagModal(context, notes: [n])),
      EditorialMenuItem(n.isPinned ? 'Unpin' : 'Pin to top', () => notes.togglePin(n.id)),
      EditorialMenuItem(n.group == null ? 'Add to a group…' : 'Move to another group…', () => _chooseGroup(n)),
      if (n.group != null) EditorialMenuItem('Take out of "${n.group}"', () => notes.setGroup([n.id], null)),
      EditorialMenuItem('Delete', () => notes.deleteNote(n.id), destructive: true),
    ]);
  }

  /// Picks an existing group for [n], or names a new one.
  void _chooseGroup(NoteItem n) {
    final notes = ref.read(notesProvider.notifier);
    final groups = notes.groups.where((g) => g != n.group).toList();
    Future<void> newGroup() async {
      final name = await showEditorialPrompt(context, title: 'New group', hint: 'Group name', confirmLabel: 'Group');
      if (name != null && name.trim().isNotEmpty) notes.setGroup([n.id], name.trim());
    }

    if (groups.isEmpty) {
      newGroup();
      return;
    }
    showEditorialMenu(context, title: 'Group', subtitle: n.title, items: [
      for (final g in groups) EditorialMenuItem(g, () => notes.setGroup([n.id], g)),
      EditorialMenuItem('New group…', newGroup),
    ]);
  }

  Future<void> _import() async {
    final doc = await DocumentIngestionService().pickAndParseDocument();
    if (doc == null) return;
    final note = DocumentIngestionService().toNoteItem(doc);
    ref.read(notesProvider.notifier).addNote(title: note.title, content: note.content, space: note.space, tag: note.tag, excerpt: note.excerpt);
  }

  void _groupMenu(String group, List<NoteItem> members) {
    final notes = ref.read(notesProvider.notifier);
    showEditorialMenu(context, title: group, subtitle: '${members.length} ${members.length == 1 ? 'note' : 'notes'}', items: [
      EditorialMenuItem('Ask about this group', () => showNotesRagModal(context, notes: members)),
      EditorialMenuItem('Rename', () async {
        final name = await showEditorialPrompt(context, title: 'Rename group', initial: group);
        if (name != null && name.trim().isNotEmpty) {
          notes.renameGroup(group, name.trim());
          if (mounted) setState(() => _tag = name.trim());
        }
      }),
      EditorialMenuItem('Ungroup', () => notes.ungroup(group), destructive: true),
    ]);
  }

  Widget _entry(NoteItem n) {
    final tags = noteTags(n).take(3).map((t) => '#$t');
    return EditorialEntry(
      key: ValueKey(n.id),
      id: n.id,
      title: n.title.isEmpty ? 'Untitled' : n.title,
      meta: [
        if (n.excerpt.isNotEmpty) n.excerpt,
        [n.date, if (n.group != null && _tag != n.group) n.group!, ...tags].join('  ·  '),
      ].join('\n'),
      leading: n.isPinned ? '✦' : null,
      leadingColor: Ed.of(context).accent,
      maxLines: 2,
      onTap: () => pushEditorial(context, NoteReader(noteId: n.id)),
      onLongPress: () => _menu(n),
      onSwipeRight: EditorialSwipe(
        label: n.isPinned ? 'Unpin' : 'Pin',
        onSwipe: () => ref.read(notesProvider.notifier).togglePin(n.id),
      ),
      onSwipeLeft: EditorialSwipe(label: 'Delete', removes: true, onSwipe: () => ref.read(notesProvider.notifier).deleteNote(n.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(notesProvider);
    final tagCounts = <String, int>{};
    for (final n in all) {
      for (final t in noteTags(n)) {
        tagCounts[t] = (tagCounts[t] ?? 0) + 1;
      }
    }
    final topTags = (tagCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).take(8).map((e) => '#${e.key}');
    final groups = ref.read(notesProvider.notifier).groups;
    final spaces = {for (final n in all) n.space}.toList()..sort();
    final aiOn = ref.watch(appSettingsProvider.select((s) => s.smartSuggestions));
    // Groups first (they were made by hand), then spaces and tags.
    final tabs = [
      'All',
      'Pinned',
      if (aiOn && all.length >= 3) _smart,
      ...groups,
      if (spaces.length > 1) ...spaces,
      ...topTags,
    ];
    if (!tabs.contains(_tag)) _tag = 'All';
    final isGroup = groups.contains(_tag);

    final q = _query.toLowerCase();
    final shown = all.where((n) {
      if (_tag == 'Pinned' && !n.isPinned) return false;
      if (_tag.startsWith('#') && !noteTags(n).contains(_tag.substring(1))) return false;
      if (isGroup && n.group != _tag) return false;
      if (spaces.contains(_tag) && !isGroup && n.space != _tag) return false;
      return q.isEmpty || n.title.toLowerCase().contains(q) || n.body.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });

    return EditorialPage(
      kicker: 'Notes',
      title: 'Notebook',
      standfirst: all.isEmpty ? 'Ideas, lists and things to remember.' : '${all.length} ${all.length == 1 ? 'note' : 'notes'}.',
      actionLabel: 'Write',
      onAction: () => openEntryEditor(context, EntryKind.note),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EditorialSearch(hint: 'Search notes', onChanged: (v) => setState(() => _query = v)),
              if (all.isNotEmpty)
                Wrap(
                  spacing: 20,
                  children: [
                    EditorialAction(label: 'Ask your notes', muted: true, onTap: () => showNotesRagModal(context, notes: shown.isEmpty ? all : shown)),
                    EditorialAction(label: 'Map of notes', muted: true, onTap: () => openNotesMap(context, onOpenNote: (n) => pushEditorial(context, NoteReader(noteId: n.id)))),
                    EditorialAction(label: 'Briefing', muted: true, onTap: () => showExecutiveDossierDialog(context)),
                    EditorialAction(label: 'Import a document', muted: true, onTap: _import),
                  ],
                ),
              if (all.isNotEmpty) EditorialTabs(options: tabs, selected: _tag, onSelected: (t) => setState(() => _tag = t)),
              if (isGroup)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: EditorialAction(label: 'Group options  →', muted: true, onTap: () => _groupMenu(_tag, shown)),
                ),
            ],
          ),
        ),
        if (shown.isEmpty)
          SliverToBoxAdapter(
            child: all.isEmpty
                ? EditorialEmpty(
                    title: 'A blank page.',
                    message: 'Write anything. Use #tags to group notes, "- [ ]" for a checklist and [[Note title]] to link notes.',
                    actionLabel: 'Write the first note  →',
                    onAction: () => openEntryEditor(context, EntryKind.note),
                  )
                : const EditorialEmpty(title: 'No matches.', message: 'Try another word or tag.'),
          )
        else if (_tag == _smart)
          SliverToBoxAdapter(
            child: SmartGroupsView<NoteItem>(
              items: shown.where((n) => n.group == null).toList(),
              kind: 'notes',
              textOf: (n) => '${n.title} ${n.title} ${noteTags(n).join(' ')} ${n.body}',
              itemBuilder: _entry,
              onKeepGroup: (label, members) {
                ref.read(notesProvider.notifier).setGroup(members.map((n) => n.id), label);
                setState(() => _tag = label);
              },
            ),
          )
        else
          SliverList.builder(
            itemCount: shown.length,
            itemBuilder: (context, i) => _entry(shown[i]),
          ),
      ],
    );
  }
}

/// A note set as a page. Checklist lines ("- [ ]") can be ticked in place,
/// "# Heading" lines become headings and `[[Title]]` opens the linked note.
class NoteReader extends ConsumerWidget {
  final String noteId;

  const NoteReader({super.key, required this.noteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ed = Ed.of(context);
    final notes = ref.watch(notesProvider);
    final note = notes.where((n) => n.id == noteId).firstOrNull;
    if (note == null) {
      return EditorialDetail(kicker: 'Notes', title: 'Note deleted', children: [Text('It is in the Bin for 30 days.', style: ed.standfirst)]);
    }

    final lines = note.body.split('\n');
    final backlinks = notes
        .where((n) => n.id != note.id && noteLinks(n.body).any((t) => t.toLowerCase() == note.title.trim().toLowerCase()))
        .toList();

    void toggleLine(int index) {
      final updated = [...lines];
      final line = updated[index];
      updated[index] = line.contains('[ ]') ? line.replaceFirst('[ ]', '[x]') : line.replaceFirst(RegExp(r'\[[xX]\]'), '[ ]');
      HapticFeedback.selectionClick();
      ref.read(notesProvider.notifier).updateNote(note.id, content: updated.join('\n'));
    }

    void openLink(String title) {
      final target = notes.where((n) => n.title.trim().toLowerCase() == title.toLowerCase()).firstOrNull;
      if (target != null) {
        pushEditorial(context, NoteReader(noteId: target.id));
      } else {
        showEditorialMenu(context, title: '“$title” doesn\'t exist yet', items: [
          EditorialMenuItem('Create it', () {
            final created = ref.read(notesProvider.notifier).addNote(title: title, space: note.space, tag: '', excerpt: '');
            pushEditorial(context, NoteReader(noteId: created.id));
          }),
        ]);
      }
    }

    final checklist = RegExp(r'^\s*[-*]\s\[( |x|X)\]\s?(.*)$');
    final heading = RegExp(r'^\s*#{1,3}\s+(.*)$');

    final blocks = <Widget>[];
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final check = checklist.firstMatch(line);
      final head = heading.firstMatch(line);
      if (check != null) {
        final done = check.group(1) != ' ';
        blocks.add(Semantics(
          checked: done,
          label: check.group(2),
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => toggleLine(i),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 30, child: Text(done ? '●' : '○', style: ed.body.copyWith(color: done ? ed.accent : ed.muted))),
                  Expanded(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 260),
                      style: ed.body.copyWith(
                        color: done ? ed.faint : ed.ink,
                        decoration: done ? TextDecoration.lineThrough : null,
                        decorationColor: ed.faint,
                      ),
                      child: Text(check.group(2) ?? ''),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
      } else if (head != null) {
        blocks.add(Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 4),
          child: Semantics(header: true, child: Text(head.group(1)!, style: ed.title.copyWith(fontSize: 22))),
        ));
      } else if (line.trim().isEmpty) {
        blocks.add(const SizedBox(height: 12));
      } else {
        blocks.add(Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: _LinkedText(line, onLink: openLink)));
      }
    }

    final tags = noteTags(note);
    return EditorialDetail(
      kicker: [note.space == 'General Space' ? 'Note' : note.space, if (note.group != null) note.group!, 'edited ${note.date}'].join('  ·  '),
      title: note.title.isEmpty ? 'Untitled' : note.title,
      actions: [
        ('Copy', () => copyToClipboard('${note.title}\n\n${note.body}', what: 'Note')),
        ('Edit', () => openEntryEditor(context, EntryKind.note, editing: note, startEditing: true)),
        ('More', () => showEditorialMenu(context, title: note.title.isEmpty ? 'Untitled' : note.title, items: [
              EditorialMenuItem(note.isPinned ? 'Unpin' : 'Pin to top', () => ref.read(notesProvider.notifier).togglePin(note.id)),
              EditorialMenuItem('Ask about this note', () => showNotesRagModal(context, notes: [note])),
              EditorialMenuItem('Turn into a plan', () => showWorkflowEvolutionDialog(context, title: note.title, content: note.body)),
              EditorialMenuItem('Pressure-test it', () => showPressureTestDialog(
                    context,
                    title: note.title,
                    content: note.body,
                    onAppendToNote: (extra) => ref.read(notesProvider.notifier).updateNote(note.id, content: '${note.body}\n\n$extra'),
                  )),
              EditorialMenuItem('Delete', () {
                ref.read(notesProvider.notifier).deleteNote(note.id);
                Navigator.maybePop(context);
              }, destructive: true),
            ])),
      ],
      children: [
        if (tags.isNotEmpty)
          Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(tags.map((t) => '#$t').join('   '), style: ed.meta.copyWith(color: ed.accent))),
        ...blocks,
        if (backlinks.isNotEmpty) ...[
          const EditorialSectionLabel('Linked from'),
          for (final b in backlinks)
            EditorialEntry(id: 'bl-${b.id}', title: b.title, meta: b.date, onTap: () => pushEditorial(context, NoteReader(noteId: b.id))),
        ],
        const SizedBox(height: 32),
        Text('Created ${DateLabels.long(note.createdAt)}', style: ed.meta),
      ],
    );
  }
}

/// Body text where `[[Title]]` spans are tappable links.
class _LinkedText extends StatefulWidget {
  final String text;
  final ValueChanged<String> onLink;

  const _LinkedText(this.text, {required this.onLink});

  @override
  State<_LinkedText> createState() => _LinkedTextState();
}

class _LinkedTextState extends State<_LinkedText> {
  final List<TapGestureRecognizer> _recognizers = [];

  void _clear() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _clear();
    final ed = Ed.of(context);
    final text = widget.text;
    final spans = <InlineSpan>[];
    var last = 0;
    for (final m in _noteLink.allMatches(text)) {
      if (m.start > last) spans.add(TextSpan(text: text.substring(last, m.start)));
      final title = m.group(1)!.trim();
      final recognizer = TapGestureRecognizer()..onTap = () => widget.onLink(title);
      _recognizers.add(recognizer);
      spans.add(TextSpan(
        text: title,
        style: TextStyle(color: ed.accent, decoration: TextDecoration.underline, decorationColor: ed.accent.withValues(alpha: 0.4)),
        recognizer: recognizer,
      ));
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return Text.rich(TextSpan(children: spans), style: ed.body);
  }
}
