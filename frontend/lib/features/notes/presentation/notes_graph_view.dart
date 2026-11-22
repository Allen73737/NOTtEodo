import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/bento_pod.dart';
import '../../../core/widgets/entry_editor.dart';
import '../../../core/state/sanctuary_state.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';

/// Opens the map of notes as its own page, laid out inside the safe area.
Future<void> openNotesMap(BuildContext context, {ValueChanged<NoteItem>? onOpenNote}) {
  return Navigator.of(context).push(MaterialPageRoute(
    builder: (ctx) => Scaffold(
      backgroundColor: Theme.of(ctx).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: NotesGraphView(fullScreen: true, onClose: () => Navigator.of(ctx).pop(), onOpenNote: onOpenNote),
        ),
      ),
    ),
  ));
}

/// A map of every note, grouped around its space, with `[[links]]` drawn between notes.
/// Pinch or drag to explore; tap a dot to see it, then open it.
class NotesGraphView extends ConsumerStatefulWidget {
  final VoidCallback onClose;

  /// Fills the available height (as a page) instead of sitting inline as a card.
  final bool fullScreen;

  /// What opening a note does. Defaults to the note's expanded view.
  final ValueChanged<NoteItem>? onOpenNote;

  const NotesGraphView({super.key, required this.onClose, this.fullScreen = false, this.onOpenNote});

  @override
  ConsumerState<NotesGraphView> createState() => _NotesGraphViewState();
}

class _GraphNode {
  final String title;
  final bool isSpace;
  final NoteItem? note;
  Offset pos = Offset.zero;

  _GraphNode(this.title, {this.isSpace = false, this.note});
}

class _NotesGraphViewState extends ConsumerState<NotesGraphView> {
  _GraphNode? _selected;
  List<_GraphNode> _nodes = const [];
  final _transform = TransformationController();

  static final _link = RegExp(r'\[\[([^\[\]]{1,80})\]\]');

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  /// Spaces sit on a ring; each space's notes orbit it in their own small ring, so
  /// nothing leaves the canvas whatever its size.
  (List<_GraphNode>, List<(int, int, bool)>) _layout(List<NoteItem> notes, Size size) {
    const pad = 44.0;
    final nodes = <_GraphNode>[];
    final edges = <(int, int, bool)>[];
    final bySpace = <String, List<NoteItem>>{};
    for (final n in notes) {
      bySpace.putIfAbsent(n.space, () => []).add(n);
    }
    final spaces = bySpace.keys.toList()..sort();
    final center = size.center(Offset.zero);
    final half = min(size.width, size.height) / 2 - pad;
    final orbit = spaces.length == 1 ? half * 0.7 : half * 0.34;
    final ring = spaces.length == 1 ? 0.0 : max(0.0, half - orbit);
    final titleIndex = <String, int>{};

    for (var s = 0; s < spaces.length; s++) {
      final angle = -pi / 2 + 2 * pi * s / spaces.length;
      final hub = center + Offset(cos(angle), sin(angle)) * ring;
      final spaceIdx = nodes.length;
      nodes.add(_GraphNode(spaces[s], isSpace: true)..pos = hub);
      final members = bySpace[spaces[s]]!;
      for (var i = 0; i < members.length; i++) {
        // Large spaces wrap onto a second and third ring instead of piling up.
        final perRing = max(6, (2 * pi * orbit / 34).floor());
        final layer = i ~/ perRing;
        final inLayer = min(perRing, members.length - layer * perRing);
        final a = angle + 2 * pi * (i % perRing) / inLayer + layer * 0.35;
        final r = orbit * (1 - layer * 0.3).clamp(0.4, 1.0);
        final p = hub + Offset(cos(a), sin(a)) * r;
        final node = _GraphNode(members[i].title.isEmpty ? 'Untitled' : members[i].title, note: members[i])
          ..pos = Offset(p.dx.clamp(pad, size.width - pad), p.dy.clamp(pad, size.height - pad));
        titleIndex[members[i].title.trim().toLowerCase()] = nodes.length;
        edges.add((spaceIdx, nodes.length, false));
        nodes.add(node);
      }
    }

    // [[Title]] links between notes.
    for (var i = 0; i < nodes.length; i++) {
      final note = nodes[i].note;
      if (note == null) continue;
      for (final m in _link.allMatches(note.body)) {
        final j = titleIndex[m.group(1)!.trim().toLowerCase()];
        if (j != null && j != i) edges.add((i, j, true));
      }
    }
    return (nodes, edges);
  }

  void _open(NoteItem note) {
    if (widget.onOpenNote != null) {
      widget.onOpenNote!(note);
    } else {
      openEntryEditor(context, EntryKind.note, editing: note);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? const Color(0xFFF4F1EA) : AppColors.primary;
    final subtextColor = isDark ? const Color(0xFFB8C5C8) : AppColors.onSurfaceVariant;
    final accentColor = isDark ? const Color(0xFFD0485A) : AppColors.secondary;
    final notes = ref.watch(notesProvider);
    final spaceCount = notes.map((n) => n.space).toSet().length;

    final header = Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MAP OF NOTES', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: accentColor)),
              Text(
                notes.isEmpty ? 'Nothing to map yet' : '${notes.length} notes · $spaceCount ${spaceCount == 1 ? 'space' : 'spaces'}',
                style: GoogleFonts.bodoniModa(fontSize: 20, fontWeight: FontWeight.bold, color: primaryTextColor),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Reset view',
          icon: Icon(LucideIcons.scan, color: subtextColor, size: 18),
          onPressed: () => setState(() {
            _transform.value = Matrix4.identity();
            _selected = null;
          }),
        ),
        IconButton(tooltip: 'Close', icon: Icon(LucideIcons.x, color: primaryTextColor, size: 20), onPressed: widget.onClose),
      ],
    );

    final canvas = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: notes.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.network, size: 36, color: accentColor.withValues(alpha: 0.6)),
                  const SizedBox(height: 10),
                  Text('Write a few notes to see them mapped.', textAlign: TextAlign.center, style: GoogleFonts.dmSans(fontSize: 13, color: subtextColor)),
                ],
              ),
            )
          : LayoutBuilder(builder: (context, box) {
              final size = Size(box.maxWidth, box.maxHeight);
              final (nodes, edges) = _layout(notes, size);
              _nodes = nodes;
              return InteractiveViewer(
                transformationController: _transform,
                minScale: 0.6,
                maxScale: 4,
                boundaryMargin: const EdgeInsets.all(120),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (d) {
                    _GraphNode? hit;
                    var best = 28.0;
                    for (final n in _nodes) {
                      final dist = (n.pos - d.localPosition).distance;
                      if (dist < best) {
                        best = dist;
                        hit = n;
                      }
                    }
                    setState(() => _selected = hit);
                  },
                  child: CustomPaint(
                    size: size,
                    painter: _GraphPainter(nodes: nodes, edges: edges, isDark: isDark, accent: accentColor, selected: _selected?.title),
                  ),
                ),
              );
            }),
    );

    final footer = AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: _selected == null
          ? Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text('Tap a dot to see it. Pinch or drag to explore.', style: GoogleFonts.dmSans(fontSize: 12, color: subtextColor)),
            )
          : Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
              decoration: edBox(color: accentColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Icon(_selected!.isSpace ? LucideIcons.folder : LucideIcons.fileText, size: 15, color: accentColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _selected!.isSpace
                          ? '${_selected!.title} · ${notes.where((n) => n.space == _selected!.title).length} notes'
                          : _selected!.title,
                      style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.bold, color: primaryTextColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_selected!.note != null)
                    TextButton(onPressed: () => _open(_selected!.note!), child: Text('Open', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, color: accentColor))),
                ],
              ),
            ),
    );

    if (widget.fullScreen) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [header, const SizedBox(height: 12), Expanded(child: canvas), footer],
      );
    }
    return BentoPod(
      style: PodTextureStyle.glass,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [header, const SizedBox(height: 12), SizedBox(height: 360, child: canvas), footer],
      ),
    );
  }
}

class _GraphPainter extends CustomPainter {
  final List<_GraphNode> nodes;
  final List<(int, int, bool)> edges;
  final bool isDark;
  final Color accent;
  final String? selected;

  _GraphPainter({required this.nodes, required this.edges, required this.isDark, required this.accent, this.selected});

  @override
  void paint(Canvas canvas, Size size) {
    final ink = isDark ? Colors.white : Colors.black;
    final line = Paint()
      ..color = ink.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    final linkLine = Paint()
      ..color = accent.withValues(alpha: 0.35)
      ..strokeWidth = 1.2;
    final active = Paint()
      ..color = accent.withValues(alpha: 0.7)
      ..strokeWidth = 1.8;

    for (final (a, b, isLink) in edges) {
      final hot = selected != null && (nodes[a].title == selected || nodes[b].title == selected);
      canvas.drawLine(nodes[a].pos, nodes[b].pos, hot ? active : (isLink ? linkLine : line));
    }

    for (final n in nodes) {
      final hot = n.title == selected;
      canvas.drawCircle(
        n.pos,
        n.isSpace ? 18 : 11,
        Paint()
          ..color = accent.withValues(alpha: hot ? 0.35 : 0.12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(n.pos, n.isSpace ? 9 : 5.5, Paint()..color = n.isSpace ? accent : accent.withValues(alpha: 0.75));

      final tp = TextPainter(
        text: TextSpan(
          text: n.title,
          style: GoogleFonts.dmSans(
            fontSize: n.isSpace ? 11.5 : 10,
            fontWeight: n.isSpace || hot ? FontWeight.bold : FontWeight.w500,
            color: ink.withValues(alpha: n.isSpace || hot ? 0.9 : 0.65),
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: n.isSpace ? 120 : 92);
      // Labels stay on the canvas even for dots near an edge.
      final dx = (n.pos.dx - tp.width / 2).clamp(2.0, max(2.0, size.width - tp.width - 2)).toDouble();
      final below = n.pos.dy + (n.isSpace ? 13 : 8);
      final dy = below + tp.height > size.height - 2 ? n.pos.dy - (n.isSpace ? 13 : 8) - tp.height : below;
      tp.paint(canvas, Offset(dx, dy));
    }
  }

  @override
  bool shouldRepaint(covariant _GraphPainter old) => old.nodes != nodes || old.selected != selected || old.isDark != isDark;
}
