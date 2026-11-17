import 'package:flutter/material.dart';

import 'reveal.dart';
import 'rolling_text.dart';

/// A figure that counts up from zero the first time it comes into view, then rolls
/// its digits like an odometer whenever the value changes.
///
/// Works on any text with one number in it — "₹18,420", "12 days", "3 of 5" — keeping
/// the currency sign, words, decimals and digit grouping as written.
class CountUpText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Duration delay;
  final Duration duration;

  const CountUpText(
    this.text, {
    super.key,
    this.style,
    this.delay = const Duration(milliseconds: 120),
    this.duration = const Duration(milliseconds: 1250),
  });

  @override
  Widget build(BuildContext context) {
    final tabular = (style ?? const TextStyle()).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    return Reveal.builder(
      delay: delay,
      duration: duration,
      builder: (context, t) {
        if (t >= 1) return RollingText(text, style: tabular);
        return Semantics(
          label: text,
          child: ExcludeSemantics(
            child: Text(countUpString(text, Motion.silk.transform(t)), style: tabular, maxLines: 1, softWrap: false),
          ),
        );
      },
    );
  }
}

final _number = RegExp(r'\d[\d,]*(\.\d+)?');

/// [text] with its first number scaled by [t] (0…1), formatted like the original.
String countUpString(String text, double t) {
  final m = _number.firstMatch(text);
  if (m == null) return text;
  final raw = m.group(0)!;
  final decimals = m.group(1) == null ? 0 : m.group(1)!.length - 1;
  final value = double.tryParse(raw.replaceAll(',', ''));
  if (value == null) return text;

  final fixed = (value * t.clamp(0.0, 1.0)).toStringAsFixed(decimals);
  final parts = fixed.split('.');
  var whole = parts[0];
  if (raw.contains(',')) {
    final groups = raw.split('.').first.split(',');
    // Lakh-style grouping (1,00,000) uses pairs after the last three digits.
    final indian = groups.length > 2 && groups.sublist(1, groups.length - 1).every((g) => g.length == 2);
    whole = _group(whole, indian);
  }
  final shown = parts.length > 1 ? '$whole.${parts[1]}' : whole;
  return text.replaceRange(m.start, m.end, shown);
}

String _group(String digits, bool indian) {
  if (digits.length <= 3) return digits;
  final head = digits.substring(0, digits.length - 3), tail = digits.substring(digits.length - 3);
  final step = indian ? 2 : 3;
  final out = <String>[];
  for (var end = head.length; end > 0; end -= step) {
    out.insert(0, head.substring((end - step).clamp(0, head.length), end));
  }
  return '${out.join(',')},$tail';
}
