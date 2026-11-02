import 'package:flutter/material.dart';
import '../widgets/masonry.dart';
import 'reveal.dart';

/// A column whose children animate when they join or leave.
///
/// Children are matched across rebuilds by their [Key]: a new key grows in and slides
/// into place; a key that disappears stays on screen just long enough to fade, drift
/// away and collapse its space, so the rest of the list closes up smoothly instead of
/// jumping. Keys must be unique among siblings (e.g. `ValueKey(item.id)`).
class MotionColumn extends StatefulWidget {
  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;

  /// Gap below each child (collapses together with a leaving child).
  final double spacing;

  /// More than one column lays children out as a Pinterest-style [Masonry] board.
  final int columns;

  /// Horizontal gap between masonry columns.
  final double columnSpacing;

  /// When set, the column count adapts to the available width so tiles stay at least
  /// this wide — one column on phones, a masonry board on tablets and desktops.
  final double? minTileWidth;

  const MotionColumn({
    super.key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.spacing = 0,
    this.columns = 1,
    this.columnSpacing = 12,
    this.minTileWidth,
  });

  @override
  State<MotionColumn> createState() => _MotionColumnState();
}

class _Entry {
  final Key key;
  Widget child;
  final AnimationController controller;
  bool leaving = false;

  _Entry(this.key, this.child, this.controller);
}

class _MotionColumnState extends State<MotionColumn> with TickerProviderStateMixin {
  final List<_Entry> _entries = [];

  AnimationController _controller({required double value}) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 460),
        reverseDuration: const Duration(milliseconds: 320),
        value: value,
      );

  Key _keyOf(Widget w, int index) {
    assert(w.key != null, 'MotionColumn children need keys to animate correctly.');
    return w.key ?? ValueKey<int>(index);
  }

  @override
  void initState() {
    super.initState();
    // Initial children are already choreographed by their own entrances.
    for (var i = 0; i < widget.children.length; i++) {
      final w = widget.children[i];
      _entries.add(_Entry(_keyOf(w, i), w, _controller(value: 1)));
    }
  }

  @override
  void didUpdateWidget(MotionColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    final reduced = Motion.reduced(context);
    final incoming = <Key, Widget>{
      for (var i = 0; i < widget.children.length; i++) _keyOf(widget.children[i], i): widget.children[i],
    };

    // Children that left: play their exit, then drop them.
    for (final entry in _entries) {
      if (!incoming.containsKey(entry.key) && !entry.leaving) {
        entry.leaving = true;
        if (reduced) {
          entry.controller.value = 0;
          WidgetsBinding.instance.addPostFrameCallback((_) => _drop(entry));
        } else {
          entry.controller.reverse().whenComplete(() => _drop(entry));
        }
      }
    }

    // Merge: follow the new order, keeping leaving entries near where they were.
    final byKey = {for (final e in _entries) e.key: e};
    final merged = <_Entry>[];
    var oldCursor = 0;
    for (final MapEntry(key: key, value: child) in incoming.entries) {
      final existing = byKey[key];
      if (existing != null) {
        // Carry over any leaving entries that sat before this one previously.
        final oldIndex = _entries.indexOf(existing);
        for (; oldCursor < oldIndex; oldCursor++) {
          if (_entries[oldCursor].leaving) merged.add(_entries[oldCursor]);
        }
        oldCursor = oldIndex + 1;
        existing
          ..child = child
          ..leaving = false;
        if (existing.controller.status == AnimationStatus.reverse) existing.controller.forward();
        merged.add(existing);
      } else {
        final entry = _Entry(key, child, _controller(value: reduced ? 1 : 0));
        if (!reduced) entry.controller.forward();
        merged.add(entry);
      }
    }
    for (; oldCursor < _entries.length; oldCursor++) {
      if (_entries[oldCursor].leaving) merged.add(_entries[oldCursor]);
    }
    _entries
      ..clear()
      ..addAll(merged);
  }

  void _drop(_Entry entry) {
    if (!mounted || !entry.leaving) return;
    setState(() => _entries.remove(entry));
    entry.controller.dispose();
  }

  @override
  void dispose() {
    for (final e in _entries) {
      e.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minTile = widget.minTileWidth;
    if (minTile != null) {
      return LayoutBuilder(
        builder: (context, constraints) => _layout(Masonry.columnsFor(constraints.maxWidth, minTileWidth: minTile)),
      );
    }
    return _layout(widget.columns);
  }

  Widget _layout(int columns) {
    final masonry = columns > 1;
    final children = [
      for (final entry in _entries)
        KeyedSubtree(
          key: entry.key,
          child: _EntryTransition(
            controller: entry.controller,
            leaving: entry.leaving,
            // Masonry spaces its own runs; a column carries the gap inside each row
            // so the gap collapses together with a leaving row.
            spacing: masonry ? 0 : widget.spacing,
            child: entry.child,
          ),
        ),
    ];

    if (masonry) {
      return Masonry(
        columns: columns,
        spacing: widget.columnSpacing,
        runSpacing: widget.spacing,
        children: children,
      );
    }
    return Column(
      crossAxisAlignment: widget.crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

class _EntryTransition extends StatelessWidget {
  final AnimationController controller;
  final bool leaving;
  final double spacing;
  final Widget child;

  const _EntryTransition({
    required this.controller,
    required this.leaving,
    required this.spacing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final size = CurvedAnimation(
      parent: controller,
      curve: Motion.silk,
      reverseCurve: const Interval(0.0, 0.75, curve: Curves.easeInOutCubic),
    );
    return AnimatedBuilder(
      animation: controller,
      child: Padding(padding: EdgeInsets.only(bottom: spacing), child: child),
      builder: (context, child) {
        final v = controller.value;
        // Leaving rows drift aside as they fade; arriving rows rise into the gap.
        final opacity = leaving ? Curves.easeIn.transform(((v - 0.35) / 0.65).clamp(0.0, 1.0)) : Curves.easeOut.transform(v);
        final offset = leaving ? Offset((1 - v) * 48, 0) : Offset(0, (1 - Motion.silk.transform(v)) * 14);
        return SizeTransition(
          sizeFactor: size,
          axisAlignment: -1,
          child: Opacity(
            opacity: opacity,
            child: Transform.translate(offset: offset, child: child),
          ),
        );
      },
    );
  }
}
