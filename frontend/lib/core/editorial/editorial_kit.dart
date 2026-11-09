import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/app_colors.dart';
import '../motion/motion.dart';
import '../state/app_settings.dart';
import '../widgets/app_toast_engine.dart';
import 'editorial_mode.dart';

/// The editorial view: type on paper. No cards, borders, fills or shadows — hierarchy
/// comes from size, weight, colour and space alone, and things arrive with motion.
///
/// Every module's editorial screen is built from these pieces so the whole app reads
/// as one publication.

/// Whether the user picked the editorial view.
bool watchEditorial(WidgetRef ref) => ref.watch(appSettingsProvider.select((s) => s.cardStyle == 'editorial'));

/// Colours and type for the editorial view, resolved for the current brightness.
///
/// Muted and accent tones are chosen to keep at least 4.5:1 contrast on the paper
/// colour, so even the smallest editorial text stays readable.
class Ed {
  final bool dark;
  final Color paper;
  final Color ink;
  final Color muted;
  final Color faint;
  final Color accent;

  const Ed._(this.dark, this.paper, this.ink, this.muted, this.faint, this.accent);

  factory Ed.of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark
        ? Ed._(true, AppColors.darkBackground, AppColors.darkTextPrimary, const Color(0xFFA6A096), const Color(0xFF5C574F), accentFor(true))
        : Ed._(false, AppColors.background, AppColors.primary, const Color(0xFF6B635A), const Color(0xFFB9AFA5), accentFor(false));
  }

  /// Headline face chosen in Settings (classic serif by default).
  static TextStyle _headline({required double fontSize, double? height, FontWeight? fontWeight, double? letterSpacing, Color? color}) =>
      GoogleFonts.getFont(EditorialMode.headlineFamily, fontSize: fontSize, height: height, fontWeight: fontWeight, letterSpacing: letterSpacing, color: color);

  /// Masthead headline.
  TextStyle get display => _headline(fontSize: 40, height: 1.05, fontWeight: FontWeight.w600, letterSpacing: -0.8, color: ink);

  /// Section or detail-page title.
  TextStyle get title => _headline(fontSize: 26, height: 1.15, fontWeight: FontWeight.w600, letterSpacing: -0.3, color: ink);

  /// Large numerals for figures (totals, counts).
  TextStyle get figure => _headline(fontSize: 34, height: 1, fontWeight: FontWeight.w500, color: ink);

  /// One list entry's headline.
  TextStyle get entry => GoogleFonts.dmSans(fontSize: 17, height: 1.35, fontWeight: FontWeight.w500, color: ink);

  /// Reading text.
  TextStyle get body => GoogleFonts.dmSans(fontSize: 16, height: 1.6, color: ink);

  /// Secondary line under an entry.
  TextStyle get meta => GoogleFonts.dmSans(fontSize: 13.5, height: 1.4, color: muted);

  /// Small capitals used for kickers and section labels.
  TextStyle get label => GoogleFonts.dmSans(fontSize: 12, height: 1.2, fontWeight: FontWeight.w700, letterSpacing: 1.6, color: muted);

  /// Standfirst under a masthead.
  TextStyle get standfirst => GoogleFonts.dmSans(fontSize: 16, height: 1.5, color: muted);

  /// Tappable text.
  TextStyle get action => GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600, color: accent);
}

/// Bottom space so the last line clears the floating dock.
const double kEditorialBottomInset = 140;

/// A full editorial screen: masthead (kicker, headline, standfirst, optional action)
/// followed by [slivers]. Pull down to dismiss the keyboard.
class EditorialPage extends StatelessWidget {
  final String kicker;
  final String title;
  final String? standfirst;
  final String? actionLabel;
  final VoidCallback? onAction;
  final List<Widget> slivers;
  final ScrollController? controller;

  const EditorialPage({
    super.key,
    required this.kicker,
    required this.title,
    this.standfirst,
    this.actionLabel,
    this.onAction,
    required this.slivers,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final ed = Ed.of(context);
    return ColoredBox(
      color: ed.paper,
      child: CustomScrollView(
        controller: controller,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
            sliver: SliverToBoxAdapter(
              child: EditorialMasthead(
                kicker: kicker,
                title: title,
                standfirst: standfirst,
                actionLabel: actionLabel,
                onAction: onAction,
              ),
            ),
          ),
          ...slivers.map((s) => SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 24), sliver: s)),
          const SliverToBoxAdapter(child: SizedBox(height: kEditorialBottomInset)),
        ],
      ),
    );
  }
}

class EditorialMasthead extends StatelessWidget {
  final String kicker;
  final String title;
  final String? standfirst;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EditorialMasthead({
    super.key,
    required this.kicker,
    required this.title,
    this.standfirst,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final ed = Ed.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Reveal(style: RevealStyle.drop, child: Text(kicker.toUpperCase(), style: ed.label)),
            ),
            if (actionLabel != null) EditorialAction(label: actionLabel!, onTap: onAction),
          ],
        ),
        const SizedBox(height: 10),
        Reveal(
          style: RevealStyle.focus,
          child: Semantics(header: true, child: Text(title, style: ed.display)),
        ),
        if (standfirst != null) ...[
          const SizedBox(height: 10),
          Reveal(
            style: RevealStyle.fade,
            child: AnimatedSwitcher(
              duration: Motion.standard,
              child: Text(standfirst!, key: ValueKey(standfirst), style: ed.standfirst),
            ),
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }
}

/// Plain coloured text that reacts to a press by dimming, e.g. "New  →".
class EditorialAction extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool muted;

  const EditorialAction({super.key, required this.label, this.onTap, this.muted = false});

  @override
  State<EditorialAction> createState() => _EditorialActionState();
}

class _EditorialActionState extends State<EditorialAction> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final ed = Ed.of(context);
    final style = widget.muted ? ed.action.copyWith(color: ed.muted, fontWeight: FontWeight.w500) : ed.action;
    return Semantics(
      button: true,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                widget.onTap!();
              },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Align(
            widthFactor: 1,
            child: AnimatedOpacity(
              duration: Motion.quick,
              opacity: _down ? 0.45 : 1,
              child: Text(widget.label, style: style),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small-caps label above a group of entries, with an optional count and action.
class EditorialSectionLabel extends StatelessWidget {
  final String text;
  final int? count;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EditorialSectionLabel(this.text, {super.key, this.count, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    final ed = Ed.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: text.toUpperCase()),
                  if (count != null) TextSpan(text: '   $count', style: ed.label.copyWith(color: ed.faint)),
                ]),
                style: ed.label,
              ),
            ),
          ),
          if (actionLabel != null) EditorialAction(label: actionLabel!, onTap: onAction, muted: true),
        ],
      ),
    );
  }
}

/// A borderless search line. Typing filters; the clear word appears once there is text.
class EditorialSearch extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const EditorialSearch({super.key, required this.hint, required this.onChanged});

  @override
  State<EditorialSearch> createState() => _EditorialSearchState();
}

class _EditorialSearchState extends State<EditorialSearch> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ed = Ed.of(context);
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            onChanged: (v) {
              setState(() {});
              widget.onChanged(v);
            },
            style: ed.entry.copyWith(fontWeight: FontWeight.w400),
            cursorColor: ed.accent,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              isDense: true,
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              hintText: widget.hint,
              hintStyle: ed.entry.copyWith(fontWeight: FontWeight.w400, color: ed.faint),
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: Motion.quick,
          child: _controller.text.isEmpty
              ? const SizedBox.shrink()
              : EditorialAction(
                  label: 'Clear',
                  muted: true,
                  onTap: () {
                    _controller.clear();
                    setState(() {});
                    widget.onChanged('');
                  },
                ),
        ),
      ],
    );
  }
}

/// A row of words that filter a list. The chosen word is ink with a small accent dot
/// beneath it that glides between choices; the rest are muted.
class EditorialTabs extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  const EditorialTabs({super.key, required this.options, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final ed = Ed.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
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
                  padding: const EdgeInsets.only(right: 22, top: 10, bottom: 6),
                  child: Column(
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: Motion.standard,
                        curve: Motion.silk,
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: o == selected ? FontWeight.w700 : FontWeight.w500,
                          color: o == selected ? ed.ink : ed.muted,
                        ),
                        child: Text(o),
                      ),
                      const SizedBox(height: 6),
                      AnimatedScale(
                        duration: Motion.standard,
                        curve: Motion.settle,
                        scale: o == selected ? 1 : 0,
                        child: SizedBox(
                          width: 4,
                          height: 4,
                          child: DecoratedBox(decoration: BoxDecoration(color: ed.accent, shape: BoxShape.circle)),
                        ),
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

/// What a swipe on an [EditorialEntry] does.
class EditorialSwipe {
  final String label;
  final VoidCallback onSwipe;

  /// Removes the row (e.g. delete). Otherwise the row springs back after [onSwipe].
  final bool removes;

  const EditorialSwipe({required this.label, required this.onSwipe, this.removes = false});
}

/// One item in an editorial list: an optional leading mark, a headline, a muted meta
/// line and an optional trailing figure. No box around it — just space.
///
/// Swipe right for [onSwipeRight] (usually complete), left for [onSwipeLeft] (usually
/// delete). Long-press opens [onLongPress] (usually a menu). The swipe reveals the
/// action as text, not a coloured panel.
class EditorialEntry extends StatefulWidget {
  final String id;
  final String title;
  final String? meta;
  final String? leading;
  final Color? leadingColor;
  final String? trailing;
  final bool done;
  final bool emphasised;
  final int maxLines;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onLeadingTap;
  final EditorialSwipe? onSwipeRight;
  final EditorialSwipe? onSwipeLeft;
  final Widget? below;

  const EditorialEntry({
    super.key,
    required this.id,
    required this.title,
    this.meta,
    this.leading,
    this.leadingColor,
    this.trailing,
    this.done = false,
    this.emphasised = false,
    this.maxLines = 2,
    this.onTap,
    this.onLongPress,
    this.onLeadingTap,
    this.onSwipeRight,
    this.onSwipeLeft,
    this.below,
  });

  @override
  State<EditorialEntry> createState() => _EditorialEntryState();
}

class _EditorialEntryState extends State<EditorialEntry> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final ed = Ed.of(context);
    final titleStyle = widget.emphasised ? ed.title.copyWith(fontSize: 21) : ed.entry;

    Widget row = Padding(
      padding: EdgeInsets.symmetric(vertical: EditorialMode.rowPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.leading != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onLeadingTap == null
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      widget.onLeadingTap!();
                    },
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 44, minHeight: 24),
                child: Padding(
                  padding: const EdgeInsets.only(right: 14, top: 1),
                  child: AnimatedSwitcher(
                    duration: Motion.standard,
                    switchInCurve: Motion.settle,
                    transitionBuilder: (c, a) => ScaleTransition(scale: a, child: FadeTransition(opacity: a, child: c)),
                    child: Text(
                      widget.leading!,
                      key: ValueKey(widget.leading),
                      style: ed.entry.copyWith(color: widget.leadingColor ?? ed.muted, fontFeatures: const [FontFeature.tabularFigures()]),
                    ),
                  ),
                ),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedDefaultTextStyle(
                  duration: Motion.standard,
                  curve: Motion.silk,
                  style: titleStyle.copyWith(
                    color: widget.done ? ed.faint : ed.ink,
                    decoration: widget.done ? TextDecoration.lineThrough : TextDecoration.none,
                    decorationColor: ed.faint,
                  ),
                  child: Text(widget.title, maxLines: widget.maxLines, overflow: TextOverflow.ellipsis),
                ),
                if (widget.meta != null && widget.meta!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(widget.meta!, style: ed.meta, maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                if (widget.below != null)
                  AnimatedSize(duration: Motion.standard, curve: Motion.silk, alignment: Alignment.topLeft, child: widget.below!),
              ],
            ),
          ),
          if (widget.trailing != null)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 1),
              child: Text(
                widget.trailing!,
                style: ed.entry.copyWith(
                  color: widget.done ? ed.faint : ed.ink,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
        ],
      ),
    );

    row = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress == null
          ? null
          : () {
              HapticFeedback.mediumImpact();
              setState(() => _down = false);
              widget.onLongPress!();
            },
      child: AnimatedOpacity(duration: Motion.quick, opacity: _down ? 0.55 : 1, child: row),
    );

    final right = widget.onSwipeRight, left = widget.onSwipeLeft;
    if ((right != null || left != null) && EditorialMode.swipeActions) {
      row = Dismissible(
        key: ValueKey('swipe-${widget.id}'),
        direction: right != null && left != null
            ? DismissDirection.horizontal
            : (right != null ? DismissDirection.startToEnd : DismissDirection.endToStart),
        dismissThresholds: const {DismissDirection.startToEnd: 0.3, DismissDirection.endToStart: 0.3},
        background: _SwipeLabel(label: right?.label ?? '', alignment: Alignment.centerLeft, color: ed.accent),
        secondaryBackground: _SwipeLabel(label: left?.label ?? '', alignment: Alignment.centerRight, color: ed.accent),
        confirmDismiss: (direction) async {
          final swipe = direction == DismissDirection.startToEnd ? right : left;
          if (swipe == null) return false;
          HapticFeedback.mediumImpact();
          if (swipe.removes && EditorialMode.confirmDeletes) {
            return await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text('${swipe.label}?'),
                    content: Text(widget.title),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(swipe.label)),
                    ],
                  ),
                ) ??
                false;
          }
          if (swipe.removes) return true;
          swipe.onSwipe();
          return false;
        },
        onDismissed: (direction) => (direction == DismissDirection.startToEnd ? right : left)?.onSwipe(),
        child: row,
      );
    }

    return Semantics(
      container: true,
      label: [widget.title, if (widget.meta != null) widget.meta!, if (widget.trailing != null) widget.trailing!, if (widget.done) 'done']
          .join(', '),
      customSemanticsActions: {
        if (right != null) CustomSemanticsAction(label: right.label): right.onSwipe,
        if (left != null) CustomSemanticsAction(label: left.label): left.onSwipe,
        if (widget.onLongPress != null) const CustomSemanticsAction(label: 'More options'): widget.onLongPress!,
      },
      child: Reveal(style: RevealStyle.slideIn, child: row),
    );
  }
}

class _SwipeLabel extends StatelessWidget {
  final String label;
  final Alignment alignment;
  final Color color;

  const _SwipeLabel({required this.label, required this.alignment, required this.color});

  @override
  Widget build(BuildContext context) {
    final ed = Ed.of(context);
    return Align(
      alignment: alignment,
      child: Text(label, style: ed.action.copyWith(color: color, letterSpacing: 0.4)),
    );
  }
}

/// Shown when a list is empty: a serif line, a hint and one clear next step.
class EditorialEmpty extends StatelessWidget {
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EditorialEmpty({super.key, required this.title, required this.message, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    final ed = Ed.of(context);
    return Reveal(
      style: RevealStyle.rise,
      child: Padding(
        padding: const EdgeInsets.only(top: 36, bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: ed.title.copyWith(fontStyle: FontStyle.italic, fontWeight: FontWeight.w400)),
            const SizedBox(height: 8),
            Text(message, style: ed.standfirst),
            if (actionLabel != null) ...[
              const SizedBox(height: 8),
              EditorialAction(label: actionLabel!, onTap: onAction),
            ],
          ],
        ),
      ),
    );
  }
}

/// A large figure with a caption, for totals and counts.
class EditorialFigure extends StatelessWidget {
  final String value;
  final String caption;

  const EditorialFigure({super.key, required this.value, required this.caption});

  @override
  Widget build(BuildContext context) {
    final ed = Ed.of(context);
    return Semantics(
      label: '$value $caption',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSwitcher(
            duration: Motion.standard,
            transitionBuilder: (c, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(position: Tween(begin: const Offset(0, 0.25), end: Offset.zero).animate(a), child: c),
            ),
            child: Text(value, key: ValueKey(value), style: ed.figure),
          ),
          const SizedBox(height: 4),
          Text(caption, style: ed.meta),
        ],
      ),
    );
  }
}

/// A one-line typographic meter: a thin ink rule, as long as [fraction] of the width.
/// It is the only drawn line the editorial view allows, and only where a ratio matters.
class EditorialMeter extends StatelessWidget {
  final double fraction;
  final bool over;

  const EditorialMeter({super.key, required this.fraction, this.over = false});

  @override
  Widget build(BuildContext context) {
    final ed = Ed.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: LayoutBuilder(
        builder: (context, c) => Align(
          alignment: Alignment.centerLeft,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: fraction.clamp(0.0, 1.0)),
            duration: Motion.entrance,
            curve: Motion.silk,
            builder: (context, v, _) => SizedBox(
              width: c.maxWidth * v,
              height: 2,
              child: ColoredBox(color: over ? ed.accent : ed.ink.withValues(alpha: 0.7)),
            ),
          ),
        ),
      ),
    );
  }
}

/// One option in an [showEditorialMenu].
class EditorialMenuItem {
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  const EditorialMenuItem(this.label, this.onTap, {this.destructive = false});
}

/// A plain sheet of text actions under a serif heading.
Future<void> showEditorialMenu(BuildContext context, {required String title, String? subtitle, required List<EditorialMenuItem> items}) {
  final ed = Ed.of(context);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: ed.paper,
    elevation: 0,
    showDragHandle: false,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: ed.title, maxLines: 2, overflow: TextOverflow.ellipsis),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle, style: ed.meta),
            ],
            const SizedBox(height: 14),
            for (var i = 0; i < items.length; i++)
              Reveal(
                style: RevealStyle.slideIn,
                child: Semantics(
                  button: true,
                  child: InkResponse(
                    containedInkWell: true,
                    highlightShape: BoxShape.rectangle,
                    splashColor: Colors.transparent,
                    highlightColor: ed.ink.withValues(alpha: 0.04),
                    onTap: () {
                      Navigator.pop(ctx);
                      items[i].onTap();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      child: SizedBox(
                        width: double.infinity,
                        child: Text(
                          items[i].label,
                          style: ed.entry.copyWith(color: items[i].destructive ? ed.accent : ed.ink, fontWeight: FontWeight.w400),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 4),
            EditorialAction(label: 'Cancel', muted: true, onTap: () => Navigator.pop(ctx)),
          ],
        ),
      ),
    ),
  );
}

/// Asks for one line of text. Returns null when cancelled.
Future<String?> showEditorialPrompt(
  BuildContext context, {
  required String title,
  String? hint,
  String initial = '',
  TextInputType keyboard = TextInputType.text,
  String confirmLabel = 'Save',
}) {
  final ed = Ed.of(context);
  final controller = TextEditingController(text: initial);
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: ed.paper,
    elevation: 0,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: ed.title),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: keyboard,
                textCapitalization: keyboard == TextInputType.text ? TextCapitalization.sentences : TextCapitalization.none,
                style: ed.entry.copyWith(fontSize: 19, fontWeight: FontWeight.w400),
                cursorColor: ed.accent,
                onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
                decoration: InputDecoration(
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  hintText: hint,
                  hintStyle: ed.entry.copyWith(fontSize: 19, fontWeight: FontWeight.w400, color: ed.faint),
                ),
              ),
              Row(
                children: [
                  EditorialAction(label: 'Cancel', muted: true, onTap: () => Navigator.pop(ctx)),
                  const Spacer(),
                  EditorialAction(label: confirmLabel, onTap: () => Navigator.pop(ctx, controller.text.trim())),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  ).whenComplete(controller.dispose);
}

/// Opens [page] with the editorial transition: a fade with a short rise.
Future<T?> pushEditorial<T>(BuildContext context, Widget page) {
  return Navigator.of(context).push<T>(PageRouteBuilder<T>(
    transitionDuration: Motion.standard,
    reverseTransitionDuration: Motion.exit,
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (context, animation, _, child) {
      if (Motion.reduced(context)) return FadeTransition(opacity: animation, child: child);
      final curved = CurvedAnimation(parent: animation, curve: Motion.silk, reverseCurve: Motion.exitCurve);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(position: Tween(begin: const Offset(0, 0.03), end: Offset.zero).animate(curved), child: child),
      );
    },
  ));
}

/// A full-screen reading page with a back word and optional actions, used for details.
class EditorialDetail extends StatelessWidget {
  final String kicker;
  final String title;
  final String? standfirst;
  final List<Widget> children;
  final List<(String, VoidCallback)> actions;

  const EditorialDetail({
    super.key,
    required this.kicker,
    required this.title,
    this.standfirst,
    required this.children,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final ed = Ed.of(context);
    return Scaffold(
      backgroundColor: ed.paper,
      body: SafeArea(
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    EditorialAction(label: '←  Back', muted: true, onTap: () => Navigator.maybePop(context)),
                    const Spacer(),
                    for (final (label, onTap) in actions) ...[
                      const SizedBox(width: 18),
                      EditorialAction(label: label, onTap: onTap),
                    ],
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              sliver: SliverToBoxAdapter(
                child: EditorialMasthead(kicker: kicker, title: title, standfirst: standfirst),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
              sliver: SliverList.list(children: children),
            ),
          ],
        ),
      ),
    );
  }
}

/// An inline "add" line: typing and pressing enter adds an item, then clears.
class EditorialAddLine extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onAdd;

  const EditorialAddLine({super.key, required this.hint, required this.onAdd});

  @override
  State<EditorialAddLine> createState() => _EditorialAddLineState();
}

class _EditorialAddLineState extends State<EditorialAddLine> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    final v = _controller.text.trim();
    if (v.isEmpty) return;
    HapticFeedback.lightImpact();
    widget.onAdd(v);
    _controller.clear();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final ed = Ed.of(context);
    return Row(
      children: [
        Padding(padding: const EdgeInsets.only(right: 14), child: Text('+', style: ed.entry.copyWith(color: ed.accent))),
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            onSubmitted: (_) => _submit(),
            textCapitalization: TextCapitalization.sentences,
            style: ed.entry.copyWith(fontWeight: FontWeight.w400),
            cursorColor: ed.accent,
            decoration: InputDecoration(
              isDense: true,
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              hintText: widget.hint,
              hintStyle: ed.entry.copyWith(fontWeight: FontWeight.w400, color: ed.faint),
            ),
          ),
        ),
      ],
    );
  }
}

/// Extracts `#tags` from free text, lower-cased and without the hash, in order of appearance.
final _hashtag = RegExp(r'(?:^|\s)#([\p{L}\p{N}_-]{2,30})', unicode: true);

List<String> hashtagsIn(String text) {
  final seen = <String>{};
  for (final m in _hashtag.allMatches(text)) {
    seen.add(m.group(1)!.toLowerCase());
  }
  return seen.toList();
}

/// A photo set straight on the page: no frame, no shadow. Remote URLs and local file
/// paths both work; anything unreadable collapses to nothing rather than a placeholder box.
class EditorialImage extends StatelessWidget {
  final String source;
  final double? height;
  final String? semanticLabel;

  const EditorialImage(this.source, {super.key, this.height, this.semanticLabel});

  @override
  Widget build(BuildContext context) {
    Widget none(BuildContext _, Object __, StackTrace? ___) => const SizedBox.shrink();
    final Widget image;
    if (source.startsWith('http://') || source.startsWith('https://') || kIsWeb) {
      image = Image.network(source, fit: BoxFit.cover, width: double.infinity, height: height, semanticLabel: semanticLabel, errorBuilder: none);
    } else {
      final file = File(source);
      if (!file.existsSync()) return const SizedBox.shrink();
      image = Image.file(file, fit: BoxFit.cover, width: double.infinity, height: height, semanticLabel: semanticLabel, errorBuilder: none);
    }
    return Reveal(
      style: RevealStyle.fade,
      child: ClipRRect(borderRadius: BorderRadius.circular(2), child: image),
    );
  }
}

/// Copies [text] to the clipboard and confirms it briefly.
Future<void> copyToClipboard(String text, {String what = 'Text'}) async {
  if (text.trim().isEmpty) return;
  await Clipboard.setData(ClipboardData(text: text.trim()));
  HapticFeedback.selectionClick();
  AppToastEngine().notify(title: '$what copied', message: text.trim().length > 60 ? '${text.trim().substring(0, 57)}…' : text.trim());
}
