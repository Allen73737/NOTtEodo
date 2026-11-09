import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../motion/motion.dart';
import '../services/local_store.dart';
import '../state/app_settings.dart';
import 'editorial_kit.dart';
import 'editorial_mode.dart';

/// Asks once, after sign-in, which way the app should look, showing a live miniature
/// of each. The choice can be changed any time with "Aa" or in Settings.
class ViewStyleChooser extends ConsumerStatefulWidget {
  const ViewStyleChooser({super.key});

  static const _flag = 'view_style_chosen';

  static bool get needed => LocalStore().isReady && LocalStore().readBool(_flag) != true;

  /// Shows the chooser if the user has not picked a style on this device yet.
  static Future<void> showIfNeeded(BuildContext context) async {
    if (!needed) return;
    await Navigator.of(context).push(PageRouteBuilder<void>(
      opaque: true,
      transitionDuration: Motion.entrance,
      pageBuilder: (_, __, ___) => const ViewStyleChooser(),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: CurvedAnimation(parent: a, curve: Motion.silk), child: child),
    ));
  }

  @override
  ConsumerState<ViewStyleChooser> createState() => _ViewStyleChooserState();
}

class _ViewStyleChooserState extends ConsumerState<ViewStyleChooser> {
  late String _choice = ref.read(appSettingsProvider).cardStyle;

  void _confirm() {
    LocalStore().writeBool(ViewStyleChooser._flag, true);
    if (ref.read(appSettingsProvider).cardStyle != _choice) {
      toggleViewStyle(context, ref, to: _choice);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ed = Ed.of(context);
    final wide = MediaQuery.sizeOf(context).width > 640;
    Widget option(String style, Widget preview) {
      final selected = _choice == style;
      return Semantics(
        button: true,
        selected: selected,
        label: '${viewStyleName(style)}. ${viewStyleDescription(style)}',
        excludeSemantics: true,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _choice = style);
          },
          child: AnimatedScale(
            duration: Motion.standard,
            curve: Motion.settle,
            scale: selected ? 1 : 0.94,
            child: AnimatedOpacity(
              duration: Motion.standard,
              opacity: selected ? 1 : 0.55,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(aspectRatio: 260 / 392, child: FittedBox(child: preview)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text(viewStyleName(style), style: ed.title.copyWith(fontSize: 24)),
                      const SizedBox(width: 10),
                      AnimatedOpacity(
                        duration: Motion.standard,
                        opacity: selected ? 1 : 0,
                        child: Text('✓', style: ed.title.copyWith(fontSize: 22, color: ed.accent)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(viewStyleDescription(style), style: ed.meta),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final options = [
      option('editorial', const _EditorialPreview()),
      option('bento', const _CardsPreview()),
    ];

    return Scaffold(
      backgroundColor: ed.paper,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
          children: [
            Reveal(style: RevealStyle.drop, child: Text('ONE LAST THING', style: ed.label.copyWith(color: ed.accent))),
            const SizedBox(height: 10),
            Reveal(style: RevealStyle.focus, child: Text('How should\nyour pages look?', style: ed.display)),
            const SizedBox(height: 10),
            Text('Both show everything the app can do. Switch any time with “Aa” at the top of the screen.', style: ed.standfirst),
            const SizedBox(height: 28),
            if (wide)
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: options[0]),
                const SizedBox(width: 28),
                Expanded(child: options[1]),
              ])
            else
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: options[0]),
                const SizedBox(width: 16),
                Expanded(child: options[1]),
              ]),
            const SizedBox(height: 32),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                onPressed: _confirm,
                style: FilledButton.styleFrom(
                  backgroundColor: ed.ink,
                  foregroundColor: ed.paper,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  shape: const StadiumBorder(),
                ),
                child: Text('Use ${viewStyleName(_choice)}', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A miniature of an editorial page, drawn at a fixed size and scaled to fit.
class _EditorialPreview extends StatelessWidget {
  const _EditorialPreview();

  @override
  Widget build(BuildContext context) {
    final ed = Ed.of(context);
    Widget row(String mark, String title, String meta, {bool done = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 22, child: Text(mark, style: ed.entry.copyWith(fontSize: 14, color: done ? ed.accent : ed.muted))),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    style: ed.entry.copyWith(
                      fontSize: 14,
                      color: done ? ed.faint : ed.ink,
                      decoration: done ? TextDecoration.lineThrough : null,
                      decorationColor: ed.faint,
                    )),
                Text(meta, style: ed.meta.copyWith(fontSize: 11)),
              ]),
            ),
          ]),
        );
    return SizedBox(
      width: 260,
      height: 392,
      child: ColoredBox(
        color: ed.paper,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('MONDAY 9 NOVEMBER', style: ed.label.copyWith(fontSize: 9)),
            const SizedBox(height: 6),
            Text('Good morning.', style: ed.display.copyWith(fontSize: 28)),
            const SizedBox(height: 4),
            Text('3 tasks due, 2 habits to do.', style: ed.standfirst.copyWith(fontSize: 12)),
            const SizedBox(height: 14),
            Text('AGENDA', style: ed.label.copyWith(fontSize: 9)),
            row('09:30', 'Design review', '45 min'),
            row('○', 'Call the bank', '2:00 PM'),
            row('●', 'Morning run', 'Done', done: true),
            const Spacer(),
            Text('₹12,400', style: ed.figure.copyWith(fontSize: 24)),
            Text('spent this month', style: ed.meta.copyWith(fontSize: 11)),
          ]),
        ),
      ),
    );
  }
}

/// A miniature of the card view.
class _CardsPreview extends StatelessWidget {
  const _CardsPreview();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final card = dark ? const Color(0xFF111111) : Colors.white;
    final ink = dark ? const Color(0xFFF6F3ED) : const Color(0xFF1C1917);
    final muted = dark ? const Color(0xFFA6A096) : const Color(0xFF6B635A);
    const accent = Color(0xFFD9725B);
    const gold = Color(0xFFD9725B);
    Widget pod({required Widget child, Color? tint}) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: tint ?? card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: dark ? const Color(0xFF222222) : const Color(0xFFE8E3D8)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: dark ? 0.4 : 0.06), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: child,
        );
    TextStyle t(double size, {Color? c, FontWeight w = FontWeight.w600}) => GoogleFonts.dmSans(fontSize: size, color: c ?? ink, fontWeight: w);
    return SizedBox(
      width: 260,
      height: 392,
      child: ColoredBox(
        color: dark ? Colors.black : const Color(0xFFFAF5F2),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Good morning', style: GoogleFonts.bodoniModa(fontSize: 22, fontWeight: FontWeight.w700, color: ink)),
            const SizedBox(height: 10),
            pod(
              tint: accent.withValues(alpha: dark ? 0.25 : 0.12),
              child: Row(children: [
                const Icon(Icons.local_fire_department, color: accent, size: 22),
                const SizedBox(width: 8),
                Text('12-day streak', style: t(13)),
              ]),
            ),
            Row(children: [
              Expanded(
                child: pod(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.check_circle_outline, color: accent, size: 18),
                    const SizedBox(height: 6),
                    Text('3 tasks', style: t(13)),
                    Text('due today', style: t(10, c: muted, w: FontWeight.w400)),
                  ]),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: pod(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.account_balance_wallet_outlined, color: gold, size: 18),
                    const SizedBox(height: 6),
                    Text('₹12.4k', style: t(13)),
                    Text('this month', style: t(10, c: muted, w: FontWeight.w400)),
                  ]),
                ),
              ),
            ]),
            pod(
              child: Row(children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Container(
                      height: 22,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(color: accent.withValues(alpha: 0.2 + i * 0.1), borderRadius: BorderRadius.circular(5)),
                    ),
                  ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
