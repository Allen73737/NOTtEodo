import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/text_cleaner.dart';

/// High-performance, ultra-fast typewriter text renderer for AI responses.
/// Renders structured markdown, bold highlights, bullet lanes, and key takeaways
/// at an exhilarating 15ms pace with instant tap-to-complete.
class FastTypewriterText extends StatefulWidget {
  final String text;
  final TextStyle? style;
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

class _FastTypewriterTextState extends State<FastTypewriterText> {
  late String _cleanedText;
  int _charCount = 0;
  Timer? _timer;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _cleanedText = SanctuaryTextCleaner.clean(widget.text);
    if (widget.autoStart) {
      _startTyping();
    } else {
      _charCount = _cleanedText.length;
      _isComplete = true;
    }
  }

  @override
  void didUpdateWidget(FastTypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _timer?.cancel();
      _cleanedText = SanctuaryTextCleaner.clean(widget.text);
      _charCount = 0;
      _isComplete = false;
      _startTyping();
    }
  }

  void _startTyping() {
    if (_cleanedText.isEmpty) {
      setState(() => _isComplete = true);
      widget.onComplete?.call();
      return;
    }

    // Step size increases with text length to maintain exhilarating speed
    final stepSize = _cleanedText.length > 500 ? 5 : (_cleanedText.length > 200 ? 3 : 2);

    _timer = Timer.periodic(widget.charInterval, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _charCount = (_charCount + stepSize).clamp(0, _cleanedText.length);
        if (_charCount >= _cleanedText.length) {
          _isComplete = true;
          timer.cancel();
          widget.onComplete?.call();
        }
      });
    });
  }

  void _completeImmediately() {
    if (!_isComplete) {
      _timer?.cancel();
      setState(() {
        _charCount = _cleanedText.length;
        _isComplete = true;
      });
      widget.onComplete?.call();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentText = _cleanedText.substring(0, _charCount);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _completeImmediately,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _StructuredMarkdownRenderer(
            text: currentText,
            baseStyle: widget.style ?? GoogleFonts.dmSans(fontSize: 13, height: 1.45, color: Colors.white),
            isTyping: !_isComplete,
          ),
          if (!_isComplete)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Tap to reveal all',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: Colors.white38,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Renders structured markdown blocks, bullet points, headers, and emphasis cleanly.
class _StructuredMarkdownRenderer extends StatelessWidget {
  final String text;
  final TextStyle baseStyle;
  final bool isTyping;

  const _StructuredMarkdownRenderer({
    required this.text,
    required this.baseStyle,
    required this.isTyping,
  });

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final widgets = <Widget>[];

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
            child: Text(
              headingText,
              style: GoogleFonts.spaceGrotesk(
                fontSize: baseStyle.fontSize != null ? baseStyle.fontSize! + 2 : 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF86CBB0),
                letterSpacing: 0.2,
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
                const Padding(
                  padding: EdgeInsets.only(top: 5, right: 8),
                  child: Icon(Icons.circle, size: 5, color: Color(0xFF86CBB0)),
                ),
                Expanded(
                  child: _RichSpanText(
                    text: bulletContent,
                    baseStyle: baseStyle,
                  ),
                ),
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
                Text(
                  '$num. ',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: baseStyle.fontSize != null ? baseStyle.fontSize! - 1 : 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF86CBB0),
                  ),
                ),
                Expanded(
                  child: _RichSpanText(
                    text: content,
                    baseStyle: baseStyle,
                  ),
                ),
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
            child: _RichSpanText(
              text: line,
              baseStyle: baseStyle,
            ),
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

  const _RichSpanText({required this.text, required this.baseStyle});

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'(\*\*([^*]+)\*\*|`([^`]+)`)');
    int lastIndex = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: baseStyle,
        ));
      }

      if (match.group(2) != null) {
        // Bold
        spans.add(TextSpan(
          text: match.group(2),
          style: baseStyle.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ));
      } else if (match.group(3) != null) {
        // Inline code
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              match.group(3)!,
              style: GoogleFonts.jetBrainsMono(
                fontSize: baseStyle.fontSize != null ? baseStyle.fontSize! - 1 : 12,
                color: const Color(0xFF86CBB0),
              ),
            ),
          ),
        ));
      }
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: baseStyle,
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}

