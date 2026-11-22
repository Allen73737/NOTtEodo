import 'package:flutter/material.dart';

import 'any_image.dart';

/// Note text set for reading: `# headings`, `- [ ]` checklists (tappable when
/// [onToggleLine] is given), `-`/`*` bullets, numbered lines, `**bold**`, `_italic_`
/// and `![caption](path)` images. Anything else reads as plain paragraphs.
class RichNoteText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Color accent;
  final Color muted;

  /// Called with the line index of a checklist item that was tapped.
  final ValueChanged<int>? onToggleLine;

  const RichNoteText({
    super.key,
    required this.text,
    required this.style,
    required this.accent,
    required this.muted,
    this.onToggleLine,
  });

  static final _check = RegExp(r'^\s*[-*]\s\[( |x|X)\]\s?(.*)$');
  static final _heading = RegExp(r'^\s*(#{1,3})\s+(.*)$');
  static final _bullet = RegExp(r'^\s*[-*•]\s+(.*)$');
  static final _numbered = RegExp(r'^\s*(\d{1,3})[.)]\s+(.*)$');
  static final _imageLine = RegExp(r'^\s*!\[([^\]]*)\]\(([^)]+)\)\s*$');
  static final _inline = RegExp(r'\*\*(.+?)\*\*|(?<![\w*])_(.+?)_(?!\w)');

  /// Flips the checkbox on line [index] of [text].
  static String toggleLine(String text, int index) {
    final lines = text.split('\n');
    if (index < 0 || index >= lines.length) return text;
    final line = lines[index];
    lines[index] = line.contains('[ ]') ? line.replaceFirst('[ ]', '[x]') : line.replaceFirst(RegExp(r'\[[xX]\]'), '[ ]');
    return lines.join('\n');
  }

  List<InlineSpan> _spans(String line) {
    final spans = <InlineSpan>[];
    var last = 0;
    for (final m in _inline.allMatches(line)) {
      if (m.start > last) spans.add(TextSpan(text: line.substring(last, m.start)));
      spans.add(m.group(1) != null
          ? TextSpan(text: m.group(1), style: const TextStyle(fontWeight: FontWeight.w700))
          : TextSpan(text: m.group(2), style: const TextStyle(fontStyle: FontStyle.italic)));
      last = m.end;
    }
    if (last < line.length) spans.add(TextSpan(text: line.substring(last)));
    return spans;
  }

  Widget _image(String path, String caption) {
    final fallback = Text(caption.isEmpty ? path : caption, style: style.copyWith(color: muted, fontStyle: FontStyle.italic));
    final img = AnyImage(path, fallback: fallback);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: ConstrainedBox(constraints: const BoxConstraints(maxHeight: 360), child: img),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final blocks = <Widget>[];
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final check = _check.firstMatch(line);
      final head = _heading.firstMatch(line);
      final image = _imageLine.firstMatch(line);
      final bullet = _bullet.firstMatch(line);
      final number = _numbered.firstMatch(line);

      Widget marked(String mark, String body, {Color? markColor, TextStyle? bodyStyle}) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 26, child: Text(mark, style: style.copyWith(color: markColor ?? muted))),
                Expanded(child: Text.rich(TextSpan(children: _spans(body)), style: bodyStyle ?? style)),
              ],
            ),
          );

      if (check != null) {
        final done = check.group(1) != ' ';
        final row = marked(
          done ? '☑' : '☐',
          check.group(2) ?? '',
          markColor: done ? accent : muted,
          bodyStyle: style.copyWith(
            color: done ? muted : null,
            decoration: done ? TextDecoration.lineThrough : null,
            decorationColor: muted,
          ),
        );
        blocks.add(onToggleLine == null
            ? row
            : Semantics(
                checked: done,
                child: InkWell(borderRadius: BorderRadius.circular(8), onTap: () => onToggleLine!(i), child: row),
              ));
      } else if (head != null) {
        final level = head.group(1)!.length;
        blocks.add(Padding(
          padding: EdgeInsets.only(top: level == 1 ? 18 : 12, bottom: 4),
          child: Semantics(
            header: true,
            child: Text.rich(
              TextSpan(children: _spans(head.group(2)!)),
              style: style.copyWith(fontSize: (style.fontSize ?? 16) + (level == 1 ? 7 : level == 2 ? 4 : 2), fontWeight: FontWeight.w700, height: 1.25),
            ),
          ),
        ));
      } else if (image != null) {
        blocks.add(_image(image.group(2)!.trim(), image.group(1)!.trim()));
      } else if (bullet != null) {
        blocks.add(marked('•', bullet.group(1)!, markColor: accent));
      } else if (number != null) {
        blocks.add(marked('${number.group(1)}.', number.group(2)!));
      } else if (line.trim().isEmpty) {
        blocks.add(const SizedBox(height: 10));
      } else {
        blocks.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text.rich(TextSpan(children: _spans(line)), style: style),
        ));
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: blocks);
  }
}
