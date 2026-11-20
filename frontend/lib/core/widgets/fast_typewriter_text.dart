import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import '../motion/reveal.dart';
import '../utils/text_cleaner.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';

/// Renders an AI reply word by word: each word clears from a soft blur into sharp
/// text a moment after the one before, so the reply reads as if it is being said. The
/// whole reply is laid out from the start, so nothing reflows as it appears; a tap
/// shows the rest at once. Renders structured markdown, bold, bullets and code.
class FastTypewriterText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  /// Kept for callers that tune the pace; the gap between words is derived from it.
  final Duration charInterval;
  final VoidCallback? onComplete;
  final bool autoStart;

  const FastTypewriterText({
    super.key,
    required this.text,
    this.style,
    this.charInterval = const Duration(milliseconds: 14),
    this.onComplete,
    this.autoStart = true,
  });

  @override
  State<FastTypewriterText> createState() => _FastTypewriterTextState();
}

class _FastTypewriterTextState extends State<FastTypewriterText> with SingleTickerProviderStateMixin {
  late String _cleanedText;
  late final Ticker _ticker = createTicker(_tick);
  Duration _elapsed = Duration.zero;
  late int _words;
  bool _isComplete = false;

  /// How long one word takes to clear.
  static const _settle = 420.0;

  /// The gap between words: brisk, and quicker still for long replies so none takes
  /// more than a few seconds to finish.
  double get _gap {
    final base = widget.charInterval.inMicroseconds / 1000 * 2.4;
    if (_words == 0) return base;
    final cap = 2600 / _words;
    return base < cap ? base : cap;
  }

  @override
  void initState() {
    super.initState();
    _load();
    if (widget.autoStart) {
      _start();
    } else {
      _isComplete = true;
    }
  }

  void _load() {
    _cleanedText = SanctuaryTextCleaner.clean(widget.text);
    _words = RegExp(r'\S+').allMatches(_cleanedText).length;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isComplete && Motion.reduced(context)) {
      _ticker.stop();
      _isComplete = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onComplete?.call());
    }
  }

  @override
  void didUpdateWidget(FastTypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _ticker.stop();
      _load();
      _isComplete = false;
      _start();
    }
  }

  void _start() {
    _elapsed = Duration.zero;
    if (_cleanedText.isEmpty) {
      _isComplete = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onComplete?.call());
      return;
    }
    _ticker.start();
  }

  void _tick(Duration elapsed) {
    setState(() => _elapsed = elapsed);
    if (elapsed.inMilliseconds > _words * _gap + _settle) _completeImmediately();
  }

  /// How far word [i] has cleared, 0 to 1.
  double _reveal(int i) {
    if (_isComplete) return 1;
    final t = (_elapsed.inMicroseconds / 1000 - i * _gap) / _settle;
    return Curves.easeOutCubic.transform(t.clamp(0.0, 1.0));
  }

  void _completeImmediately() {
    if (_isComplete) return;
    _ticker.stop();
    setState(() => _isComplete = true);
    widget.onComplete?.call();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _completeImmediately,
      child: _StructuredMarkdownRenderer(
        text: _cleanedText,
        baseStyle: widget.style ?? GoogleFonts.dmSans(fontSize: 13, height: 1.45, color: Colors.white),
        reveal: _isComplete ? null : _reveal,
      ),
    );
  }
}

/// Styles a word part-way through clearing: faint and blurred, sharpening as [p] nears 1.
TextStyle _clearing(TextStyle style, double p) {
  if (p >= 1) return style;
  final color = style.color ?? Colors.white;
  return style.copyWith(
    foreground: Paint()
      ..color = color.withValues(alpha: color.a * p)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 0.01 + 3.2 * (1 - p)),
  );
}

/// Renders structured markdown blocks, bullet points, headers, and emphasis cleanly.
class _StructuredMarkdownRenderer extends StatelessWidget {
  final String text;
  final TextStyle baseStyle;

  /// While a reply is still appearing, how far each word (counted through the whole
  /// reply) has cleared; null once it is all shown.
  final double Function(int word)? reveal;

  const _StructuredMarkdownRenderer({
    required this.text,
    required this.baseStyle,
    this.reveal,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).brightness == Brightness.dark ? const Color(0xFFD0485A) : const Color(0xFF7A1F2B);
    final lines = text.split('\n');
    final widgets = <Widget>[];
    var word = 0;
    // Markers (bullets, numbers) appear with the first word of their line.
    Widget marker(Widget w, int first) {
      final r = reveal;
      return r == null ? w : Opacity(opacity: r(first), child: w);
    }
    Widget words(String s, TextStyle style) {
      final w = _RichSpanText(text: s, baseStyle: style, firstWord: word, reveal: reveal);
      word += RegExp(r'\S+').allMatches(s.replaceAll(RegExp(r'\*\*|`'), '')).length;
      return w;
    }

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 6));
        continue;
      }

      // 1. Heading (### or ##)
      if (trimmed.startsWith('### ') || trimmed.startsWith('## ') || trimmed.startsWith('# ')) {
        final headingText = trimmed.replaceFirst(RegExp(r'^#+\s*'), '');
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: words(
              headingText,
              GoogleFonts.dmSans(
                fontSize: baseStyle.fontSize != null ? baseStyle.fontSize! + 2 : 15,
                fontWeight: FontWeight.bold,
                color: baseStyle.color,
              ),
            ),
          ),
        );
      }
      // 2. Bullet point (• or - or *)
      else if (trimmed.startsWith('• ') || trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        final bulletContent = trimmed.substring(2).trim();
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                marker(
                  Padding(
                    padding: const EdgeInsets.only(top: 7, right: 9),
                    child: Icon(Icons.circle, size: 5, color: accent),
                  ),
                  word,
                ),
                Expanded(child: words(bulletContent, baseStyle)),
              ],
            ),
          ),
        );
      }
      // 3. Numbered list item (1. 2. etc)
      else if (RegExp(r'^\d+\.\s+').hasMatch(trimmed)) {
        final match = RegExp(r'^(\d+)\.\s+(.*)').firstMatch(trimmed);
        final num = match?.group(1) ?? '•';
        final content = match?.group(2) ?? trimmed;
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                marker(
                  Text(
                    '$num. ',
                    style: baseStyle.copyWith(
                      fontWeight: FontWeight.w700,
                      color: accent,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  word,
                ),
                Expanded(child: words(content, baseStyle)),
              ],
            ),
          ),
        );
      }
      // 4. Standard text line
      else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: words(line, baseStyle),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }
}

/// Parses inline bold (**text**) and code (`code`) into styled TextSpans.
class _RichSpanText extends StatelessWidget {
  final String text;
  final TextStyle baseStyle;

  /// Index of this text's first word within the whole reply, and how far each word has
  /// cleared (null when fully shown).
  final int firstWord;
  final double Function(int word)? reveal;

  const _RichSpanText({required this.text, required this.baseStyle, this.firstWord = 0, this.reveal});

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'(\*\*([^*]+)\*\*|`([^`]+)`)');
    int lastIndex = 0;
    var word = firstWord;
    final r = reveal;

    // Plain runs are split into words so each can clear on its own beat.
    void addText(String s, TextStyle style) {
      if (r == null) {
        spans.add(TextSpan(text: s, style: style));
        return;
      }
      for (final m in RegExp(r'\s*\S+\s*|\s+').allMatches(s)) {
        final piece = m.group(0)!;
        final p = piece.trim().isEmpty ? 1.0 : r(word++);
        spans.add(TextSpan(text: piece, style: _clearing(style, p)));
      }
    }

    for (final match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        addText(text.substring(lastIndex, match.start), baseStyle);
      }

      if (match.group(2) != null) {
        // Bold
        addText(match.group(2)!, baseStyle.copyWith(fontWeight: FontWeight.bold));
      } else if (match.group(3) != null) {
        // Inline code
        final p = r == null ? 1.0 : r(word);
        word += RegExp(r'\S+').allMatches(match.group(3)!).length;
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Opacity(
          opacity: p,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: edBox(
              color: (baseStyle.color ?? Colors.white).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              match.group(3)!,
              style: GoogleFonts.jetBrainsMono(
                fontSize: baseStyle.fontSize != null ? baseStyle.fontSize! - 1 : 12,
                color: baseStyle.color,
              ),
            ),
          ),
          ),
        ));
      }
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      addText(text.substring(lastIndex), baseStyle);
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}

