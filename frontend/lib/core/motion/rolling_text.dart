import 'package:flutter/material.dart';
import 'reveal.dart';

/// Text whose digits roll like an odometer whenever the value changes — counts,
/// percentages and currency feel mechanical and alive instead of snapping.
///
/// Non-digit characters (₹, %, commas, words) cross-fade in place.
class RollingText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const RollingText(this.text, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    final effective = DefaultTextStyle.of(context).style.merge(style);
    final reduced = Motion.reduced(context);
    final chars = text.characters.toList();

    return Semantics(
      label: text,
      child: ExcludeSemantics(
        // Shrinks rather than overflowing when space is tight.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Key digits from the right so "99" → "100" rolls units, tens and adds hundreds.
              for (var i = 0; i < chars.length; i++)
                _RollingGlyph(
                  key: ValueKey(chars.length - i),
                  char: chars[i],
                  style: effective,
                  reduced: reduced,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RollingGlyph extends StatelessWidget {
  final String char;
  final TextStyle style;
  final bool reduced;

  const _RollingGlyph({super.key, required this.char, required this.style, required this.reduced});

  @override
  Widget build(BuildContext context) {
    final digit = int.tryParse(char);
    final glyph = Text(char, key: ValueKey(char), style: style);
    if (reduced) return glyph;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 520),
      switchInCurve: Motion.settle,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [...previous, if (current != null) current],
      ),
      transitionBuilder: (child, animation) {
        final incoming = child.key == ValueKey(char);
        if (digit == null) return FadeTransition(opacity: animation, child: child);
        // New digit rolls up from below; the old one exits upward.
        final offset = Tween<Offset>(
          begin: incoming ? const Offset(0, 0.65) : const Offset(0, -0.65),
          end: Offset.zero,
        ).animate(animation);
        return ClipRect(
          child: SlideTransition(
            position: offset,
            child: FadeTransition(opacity: animation, child: child),
          ),
        );
      },
      child: glyph,
    );
  }
}
