import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/editorial/editorial_kit.dart';
import '../../../core/state/sanctuary_state.dart';
import '../../../core/utils/date_labels.dart';
import '../../../core/widgets/entry_editor.dart';

/// Every tag on a note: its own tag plus any `#hashtags` in the text.
List<String> noteTags(NoteItem n) {
  final tags = <String>{if (n.tag.trim().isNotEmpty && n.tag != 'Note') n.tag.trim().toLowerCase(), ...hashtagsIn(n.body)};
  return tags.toList();
}

/// Titles linked from a note with `[[Title]]`.
List<String> noteLinks(String text) =>
    RegExp(r'\[\[([^\[\]]{1,80})\]\]').allMatches(text).map((m) => m.group(1)!.trim()).toSet().toList();

/// Notes as an index of headlines. Search across everything, filter by tag, hold a
/// note for options, tap to read it.
class NotesEditorialView extends ConsumerStatefulWidget {
  const NotesEditorialView({super.key});

  @override
  ConsumerState<NotesEditorialView> createState() => _NotesEditorialViewState();
}

class _NotesEditorialViewState extends ConsumerState<NotesEditorialView> {
  String _query = '';
  String _tag = 'All';

  void _menu(NoteItem n) {
    final notes = ref.read(notesProvider.notifier);
    showEditorialMenu(context, title: n.title.isEmpty ? 'Untitled' : n.title, subtitle: 'Edited ${n.date}', items: [
      EditorialMenuItem('Read', () => pushEditorial(context, NoteReader(noteId: n.id))),
      EditorialMenuItem('Edit', () => openEntryEditor(context, EntryKind.note, editing: n)),
      EditorialMenuItem(n.isPinned ? 'Unpin' : 'Pin to top', () => notes.togglePin(n.id)),
      EditorialMenuItem('Delete', () => notes.deleteNote(n.id), destructive: true),
    ]);
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
    final tabs = ['All', 'Pinned', ...topTags];
    if (!tabs.contains(_tag)) _tag = 'All';

    final q = _query.toLowerCase();
    final shown = all.where((n) {
      if (_tag == 'Pinned' && !n.isPinned) return false;
      if (_tag.startsWith('#') && !noteTags(n).contains(_tag.substring(1))) return false;
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
              if (all.isNotEmpty) EditorialTabs(options: tabs, selected: _tag, onSelected: (t) => setState(() => _tag = t)),
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
        else
          SliverList.builder(
            itemCount: shown.length,
            itemBuilder: (context, i) {
              final n = shown[i];
              final tags = noteTags(n).take(3).map((t) => '#$t');
              return EditorialEntry(
                key: ValueKey(n.id),
                id: n.id,
                title: n.title.isEmpty ? 'Untitled' : n.title,
                meta: [
                  if (n.excerpt.isNotEmpty) n.excerpt,
                  [n.date, ...tags].join('  ·  '),
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
            },
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
      kicker: [note.space == 'General Space' ? 'Note' : note.space, 'edited ${note.date}'].join('  ·  '),
      title: note.title.isEmpty ? 'Untitled' : note.title,
      actions: [
        (note.isPinned ? 'Unpin' : 'Pin', () => ref.read(notesProvider.notifier).togglePin(note.id)),
        ('Edit', () => openEntryEditor(context, EntryKind.note, editing: note)),
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
    for (final m in RegExp(r'\[\[([^\[\]]{1,80})\]\]').allMatches(text)) {
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
