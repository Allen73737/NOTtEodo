import 'dart:math' as math;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Pinterest-style masonry: each child drops into the currently shortest column, so
/// cards of different heights interlock instead of sitting in rigid rows.
class Masonry extends MultiChildRenderObjectWidget {
  final int columns;
  final double spacing;
  final double runSpacing;

  const Masonry({
    super.key,
    required this.columns,
    this.spacing = 12,
    this.runSpacing = 12,
    super.children,
  }) : assert(columns > 0);

  /// Column count that keeps cards between roughly [minTileWidth] and twice that.
  static int columnsFor(double width, {double minTileWidth = 240, int maxColumns = 4}) =>
      (width / minTileWidth).floor().clamp(1, maxColumns);

  @override
  RenderMasonry createRenderObject(BuildContext context) =>
      RenderMasonry(columns: columns, spacing: spacing, runSpacing: runSpacing);

  @override
  void updateRenderObject(BuildContext context, RenderMasonry renderObject) {
    renderObject
      ..columns = columns
      ..spacing = spacing
      ..runSpacing = runSpacing;
  }
}

class MasonryParentData extends ContainerBoxParentData<RenderBox> {}

class RenderMasonry extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, MasonryParentData>, RenderBoxContainerDefaultsMixin<RenderBox, MasonryParentData> {
  RenderMasonry({required int columns, required double spacing, required double runSpacing})
      : _columns = columns,
        _spacing = spacing,
        _runSpacing = runSpacing;

  int _columns;
  set columns(int v) {
    if (v == _columns) return;
    _columns = v;
    markNeedsLayout();
  }

  double _spacing;
  set spacing(double v) {
    if (v == _spacing) return;
    _spacing = v;
    markNeedsLayout();
  }

  double _runSpacing;
  set runSpacing(double v) {
    if (v == _runSpacing) return;
    _runSpacing = v;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! MasonryParentData) child.parentData = MasonryParentData();
  }

  double _tileWidth(double maxWidth) => (maxWidth - _spacing * (_columns - 1)) / _columns;

  @override
  void performLayout() {
    final maxWidth = constraints.maxWidth;
    assert(maxWidth.isFinite, 'Masonry needs a bounded width.');
    final tile = _tileWidth(maxWidth);
    final heights = List<double>.filled(_columns, 0);
    final placed = List<bool>.filled(_columns, false);

    var child = firstChild;
    while (child != null) {
      child.layout(BoxConstraints.tightFor(width: tile), parentUsesSize: true);
      var col = 0;
      for (var c = 1; c < _columns; c++) {
        if (heights[c] < heights[col] - 0.5) col = c;
      }
      final top = heights[col] + (placed[col] && child.size.height > 0 ? _runSpacing : 0);
      (child.parentData! as MasonryParentData).offset = Offset(col * (tile + _spacing), top);
      if (child.size.height > 0) {
        heights[col] = top + child.size.height;
        placed[col] = true;
      }
      child = (child.parentData! as MasonryParentData).nextSibling;
    }
    size = constraints.constrain(Size(maxWidth, heights.fold(0.0, math.max)));
  }

  @override
  double computeMinIntrinsicWidth(double height) => 0;

  @override
  double computeMaxIntrinsicWidth(double height) => 0;

  @override
  double computeMinIntrinsicHeight(double width) => _intrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(double width) => _intrinsicHeight(width);

  double _intrinsicHeight(double width) {
    final tile = _tileWidth(width);
    final heights = List<double>.filled(_columns, 0);
    var child = firstChild;
    while (child != null) {
      var col = 0;
      for (var c = 1; c < _columns; c++) {
        if (heights[c] < heights[col]) col = c;
      }
      heights[col] += child.getMaxIntrinsicHeight(tile) + _runSpacing;
      child = (child.parentData! as MasonryParentData).nextSibling;
    }
    return math.max(0, heights.fold(0.0, math.max) - _runSpacing);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) => defaultPaint(context, offset);
}
