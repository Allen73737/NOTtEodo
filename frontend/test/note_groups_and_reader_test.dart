import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:notteodo/core/state/sanctuary_state.dart';
import 'package:notteodo/core/widgets/entry_editor.dart';
import 'package:notteodo/core/widgets/rich_note_text.dart';

Future<void> _pumpFrames(WidgetTester tester, [int n = 20]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  group('manual note groups', () {
    late ProviderContainer c;
    late NotesNotifier notes;

    setUp(() {
      c = ProviderContainer();
      notes = c.read(notesProvider.notifier);
    });
    tearDown(() => c.dispose());

    test('dropping one note on another groups them, and later drops join that group', () {
      final a = notes.addNote(title: 'Flights', space: 'Travel Space', tag: '', excerpt: '');
      final b = notes.addNote(title: 'Hotels', space: 'Travel Space', tag: '', excerpt: '');
      final d = notes.addNote(title: 'Packing list', space: 'Personal Space', tag: '', excerpt: '');

      expect(notes.groupTogether(a.id, b.id, newName: 'Lisbon trip'), 'Lisbon trip');
      // The target is grouped now, so a third note joins it whatever name is offered.
      expect(notes.groupTogether(d.id, b.id, newName: 'Ignored'), 'Lisbon trip');

      final byId = {for (final n in c.read(notesProvider)) n.id: n};
      expect([byId[a.id]!.group, byId[b.id]!.group, byId[d.id]!.group], everyElement('Lisbon trip'));
      expect(notes.groups, ['Lisbon trip']);
    });

    test('rename, take out and ungroup keep the notes themselves', () {
      final a = notes.addNote(title: 'One', space: 'General Space', tag: '', excerpt: '');
      final b = notes.addNote(title: 'Two', space: 'General Space', tag: '', excerpt: '');
      notes.setGroup([a.id, b.id], 'Ideas');

      notes.renameGroup('Ideas', 'Big ideas');
      expect(c.read(notesProvider).where((n) => n.group == 'Big ideas').length, 2);

      notes.setGroup([a.id], null);
      expect(c.read(notesProvider).firstWhere((n) => n.id == a.id).group, isNull);

      notes.ungroup('Big ideas');
      expect(c.read(notesProvider).every((n) => n.group == null), isTrue);
      expect(c.read(notesProvider).length, 2);
    });

    test('a group survives a save and editing the note', () {
      final a = notes.addNote(title: 'Kept', space: 'General Space', tag: '', excerpt: '');
      notes.setGroup([a.id], 'Shelf');
      notes.updateNote(a.id, content: 'Changed body');

      final saved = c.read(notesProvider).firstWhere((n) => n.id == a.id);
      expect(saved.group, 'Shelf');
      expect(NoteItem.fromJson(saved.toJson()).group, 'Shelf');
      expect(NoteItem.fromJson({...saved.toJson(), 'group': '  '}).group, isNull);
    });
  });

  test('checklist lines toggle in place', () {
    const text = 'Shopping\n- [ ] milk\n- [x] eggs';
    expect(RichNoteText.toggleLine(text, 1), 'Shopping\n- [x] milk\n- [x] eggs');
    expect(RichNoteText.toggleLine(text, 2), 'Shopping\n- [ ] milk\n- [ ] eggs');
    expect(RichNoteText.toggleLine(text, 9), text);
  });

  testWidgets('an existing note opens read-only, and its tools appear only after Edit', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final c = ProviderContainer();
    addTearDown(c.dispose);
    final longBody = List.generate(120, (i) => 'Line $i of a long note.').join('\n');
    final note = c.read(notesProvider.notifier).addNote(title: 'Long read', space: 'General Space', tag: '', excerpt: '', content: longBody);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        home: Scaffold(body: EntryEditor(kind: EntryKind.note, editing: note, readFirst: true, onClose: () {})),
      ),
    ));
    await _pumpFrames(tester);

    expect(find.text('VIEW'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('AI Tools ▾'), findsNothing);

    // A long note scrolls in the expanded view.
    final lastLine = find.text('Line 119 of a long note.');
    expect(lastLine.hitTestable(), findsNothing);
    await tester.dragUntilVisible(lastLine, find.byType(SingleChildScrollView).first, const Offset(0, -400));
    await _pumpFrames(tester, 4);
    expect(lastLine.hitTestable(), findsOneWidget);

    await tester.tap(find.text('Edit'));
    await _pumpFrames(tester, 8);
    expect(find.text('EDIT'), findsOneWidget);
    expect(find.byType(TextFormField), findsWidgets);
    expect(find.text('AI Tools ▾'), findsOneWidget);

    // Cancel goes back to reading without saving.
    await tester.enterText(find.byType(TextFormField).first, 'Unsaved title');
    await tester.tap(find.text('Cancel'));
    await _pumpFrames(tester, 8);
    expect(find.text('VIEW'), findsOneWidget);
    expect(find.text('Long read'), findsOneWidget);
    expect(c.read(notesProvider).firstWhere((n) => n.id == note.id).title, 'Long read');
  });

  testWidgets('closing with unsaved typing asks first; closing a clean form does not', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final c = ProviderContainer();
    addTearDown(c.dispose);
    var closed = 0;
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(home: Scaffold(body: EntryEditor(kind: EntryKind.task, onClose: () => closed++))),
    ));
    await _pumpFrames(tester);

    await tester.tap(find.byTooltip('Close'));
    await _pumpFrames(tester, 4);
    expect(closed, 1);
    expect(find.text('Discard changes?'), findsNothing);

    await tester.enterText(find.byType(TextFormField).first, 'Half-written task');
    await tester.tap(find.byTooltip('Close'));
    await _pumpFrames(tester, 6);
    expect(find.text('Discard changes?'), findsOneWidget);
    expect(closed, 1);

    await tester.tap(find.text('Keep editing'));
    await _pumpFrames(tester, 6);
    expect(closed, 1);
    expect(find.text('Half-written task'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await _pumpFrames(tester, 6);
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Discard')));
    await _pumpFrames(tester, 6);
    expect(closed, 2);
  });
}
