import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'reveal.dart';

/// A headline whose words flip up into place one after another on a perspective
/// hinge, each clearing from a blur as it lands. Plays once, when first built.
class KineticText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration delay;

  const KineticText(this.text, {super.key, required this.style, this.delay = Duration.zero});

  @override
  State<KineticText> createState() => _KineticTextState();
}

class _KineticTextState extends State<KineticText> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (Motion.reduced(context)) {
      _c.value = 1;
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final words = widget.text.split(' ');
    final step = words.length <= 1 ? 0.0 : 0.45 / (words.length - 1);
    return Semantics(
      label: widget.text,
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Wrap(
          children: [
            for (var i = 0; i < words.length; i++)
              _word(
                '${words[i]}${i == words.length - 1 ? '' : ' '}',
                Motion.settle.transform(((_c.value - i * step) / 0.55).clamp(0.0, 1.0)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _word(String w, double p) {
    final m = Matrix4.identity()
      ..setEntry(3, 2, 0.002)
      ..translateByDouble(0, (1 - p) * 18, 0, 1)
      ..rotateX((1 - p) * 1.3);
    final blur = (1 - p.clamp(0.0, 1.0)) * 6;
    return Opacity(
      opacity: (p * 1.4).clamp(0.0, 1.0),
      child: Transform(
        alignment: Alignment.bottomCenter,
        transform: m,
        child: ImageFiltered(
          enabled: blur > 0.05,
          imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Text(w, style: widget.style),
        ),
      ),
    );
  }
}
