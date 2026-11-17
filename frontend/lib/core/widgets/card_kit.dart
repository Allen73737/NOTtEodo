import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../motion/motion.dart';

/// The card view's building blocks. Each card gets one small label, one large figure,
/// at most one oxblood mark (a meter or an action), and no boxes inside it.
///
/// Things arrive in sequence: the card deals in, the figure counts up, the meter
/// draws and catches the light once, and rows rise one after another.

/// Colours for content inside a [BentoPod], resolved for the current brightness.
class CardInk {
  final bool dark;
  final Color ink;
  final Color muted;

  /// Accent for lines and small marks: oxblood on ivory, blush on black.
  final Color mark;

  /// Fill for actions: oxblood in both modes.
  final Color fill;
  final Color onFill;
  final Color track;
  final Color hairline;

  const CardInk._(this.dark, this.ink, this.muted, this.mark, this.fill, this.onFill, this.track, this.hairline);

  factory CardInk.of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark
        ? const CardInk._(true, Color(0xFFF6F3ED), Color(0xFFA89C9C), Color(0xFFE2B6BB), Color(0xFF8E2433), Color(0xFFF6F3ED),
            Color(0xFF2A1F21), Color(0xFF221C1D))
        : const CardInk._(false, Color(0xFF1A1614), Color(0xFF6B605A), Color(0xFF7A1F2B), Color(0xFF7A1F2B), Color(0xFFFFFFFF),
            Color(0xFFEADFD9), Color(0xFFEDE6DF));
  }

  TextStyle get label => GoogleFonts.dmSans(fontSize: 13, height: 1.3, fontWeight: FontWeight.w500, color: muted);
  TextStyle get figure => GoogleFonts.bodoniModa(fontSize: 36, height: 1.05, fontWeight: FontWeight.w700, color: ink);
  TextStyle get figureSmall => GoogleFonts.bodoniModa(fontSize: 27, height: 1.05, fontWeight: FontWeight.w700, color: ink);
  TextStyle get title => GoogleFonts.bodoniModa(fontSize: 19, height: 1.2, fontWeight: FontWeight.w700, color: ink);
  TextStyle get body => GoogleFonts.dmSans(fontSize: 14.5, height: 1.4, fontWeight: FontWeight.w500, color: ink);
  TextStyle get meta => GoogleFonts.dmSans(fontSize: 13, height: 1.4, color: muted);
}

/// The one label at the top of a card, in sentence case, with an optional note on the right.
class CardLabel extends StatelessWidget {
  final String text;
  final String? trailing;

  const CardLabel(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    final c = CardInk.of(context);
    return Row(
      children: [
        Expanded(child: Text(text, style: c.label, maxLines: 1, overflow: TextOverflow.ellipsis)),
        if (trailing != null) ...[
          const SizedBox(width: 10),
          AnimatedSwitcher(
            duration: Motion.standard,
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(a), child: child),
            ),
            child: Text(trailing!, key: ValueKey(trailing), style: c.label),
          ),
        ],
      ],
    );
  }
}

/// The card's large figure: counts up on arrival and rolls when it changes. An optional
/// [unit] sits beside it in small body type ("3 of 5  done").
class CardFigure extends StatelessWidget {
  final String value;
  final String? unit;
  final bool small;

  const CardFigure(this.value, {super.key, this.unit, this.small = false});

  @override
  Widget build(BuildContext context) {
    final c = CardInk.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Flexible(child: CountUpText(value, style: small ? c.figureSmall : c.figure)),
          if (unit != null) ...[
            const SizedBox(width: 7),
            Text(unit!, style: c.meta.copyWith(fontSize: 14)),
          ],
        ],
      ),
    );
  }
}

/// A thin progress line. It draws in from the left when it arrives, a glint runs along
/// it once, and later changes glide to the new length.
class CardMeter extends StatelessWidget {
  final double fraction;

  /// Past the limit (e.g. over budget): the line runs full and pulses once.
  final bool over;

  const CardMeter({super.key, required this.fraction, this.over = false});

  @override
  Widget build(BuildContext context) {
    final c = CardInk.of(context);
    final target = over ? 1.0 : fraction.clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Reveal.builder(
        delay: const Duration(milliseconds: 260),
        duration: const Duration(milliseconds: 1500),
        builder: (context, t) => TweenAnimationBuilder<double>(
          tween: Tween(end: target),
          duration: const Duration(milliseconds: 700),
          curve: Motion.silk,
          builder: (context, f, _) => CustomPaint(
            size: const Size(double.infinity, 3),
            painter: _MeterPainter(
              fraction: f * Motion.silk.transform((t / 0.7).clamp(0.0, 1.0)),
              glint: ((t - 0.55) / 0.45).clamp(0.0, 1.0),
              track: c.track,
              fill: c.mark,
              shine: c.dark ? Colors.white : const Color(0xFFFFE9EC),
            ),
          ),
        ),
      ),
    );
  }
}

class _MeterPainter extends CustomPainter {
  final double fraction;
  final double glint;
  final Color track, fill, shine;

  _MeterPainter({required this.fraction, required this.glint, required this.track, required this.fill, required this.shine});

  @override
  void paint(Canvas canvas, Size size) {
    final r = Radius.circular(size.height);
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, r), Paint()..color = track);
    if (fraction <= 0) return;
    final bar = Rect.fromLTWH(0, 0, size.width * fraction, size.height);
    canvas.drawRRect(RRect.fromRectAndRadius(bar, r), Paint()..color = fill);
    if (glint > 0 && glint < 1) {
      final x = bar.width * glint;
      final band = Rect.fromLTWH(x - 40, 0, 80, size.height);
      canvas.save();
      canvas.clipRRect(RRect.fromRectAndRadius(bar, r));
      canvas.drawRect(
        band,
        Paint()
          ..shader = LinearGradient(colors: [shine.withValues(alpha: 0), shine.withValues(alpha: 0.75), shine.withValues(alpha: 0)])
              .createShader(band),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_MeterPainter old) =>
      old.fraction != fraction || old.glint != glint || old.track != track || old.fill != fill;
}

/// The card's single action: an oxblood button that sinks when pressed.
class CardAction extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  const CardAction({super.key, required this.label, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    final c = CardInk.of(context);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Pressable(
        pressedScale: 0.94,
        hoverLift: 1.5,
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: c.fill,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: c.fill.withValues(alpha: c.dark ? 0.35 : 0.22), blurRadius: 14, offset: const Offset(0, 5))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 15, color: c.onFill), const SizedBox(width: 7)],
              Text(label, style: GoogleFonts.dmSans(fontSize: 13.5, fontWeight: FontWeight.w700, color: c.onFill)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A quiet text link inside a card, e.g. "Ask Nodo about it  →". The arrow nudges on press.
class CardLink extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const CardLink({super.key, required this.label, required this.onTap});

  @override
  State<CardLink> createState() => _CardLinkState();
}

class _CardLinkState extends State<CardLink> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final c = CardInk.of(context);
    return Semantics(
      button: true,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.label, style: c.body.copyWith(fontSize: 13.5, fontWeight: FontWeight.w700, color: c.mark)),
              AnimatedPadding(
                duration: Motion.quick,
                curve: Motion.settle,
                padding: EdgeInsets.only(left: _down ? 12 : 7),
                child: Text('→', style: c.body.copyWith(fontSize: 13.5, color: c.mark)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Words that filter a card's list. The chosen word is ink with an oxblood dot that
/// grows beneath it; the others are muted.
class CardTabs extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  const CardTabs({super.key, required this.options, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final c = CardInk.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final o in options)
            Semantics(
              button: true,
              selected: o == selected,
              label: o,
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelected(o);
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 18, 4),
                  child: Column(
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: Motion.standard,
                        curve: Motion.silk,
                        style: c.meta.copyWith(
                          fontSize: 13.5,
                          fontWeight: o == selected ? FontWeight.w700 : FontWeight.w500,
                          color: o == selected ? c.ink : c.muted,
                        ),
                        child: Text(o),
                      ),
                      const SizedBox(height: 4),
                      AnimatedScale(
                        duration: const Duration(milliseconds: 420),
                        curve: Motion.settle,
                        scale: o == selected ? 1 : 0,
                        child: Container(width: 4, height: 4, decoration: BoxDecoration(color: c.mark, shape: BoxShape.circle)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A faint hairline between a card's figure and its list.
class CardRule extends StatelessWidget {
  const CardRule({super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Container(height: 1, color: CardInk.of(context).hairline),
      );
}
