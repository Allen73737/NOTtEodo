import 'dart:math';
import 'package:flutter/material.dart';

/// Interactive Relationship & Dependency Graph with Force Physics
/// Runs a 2D Verlet / Coulomb-Hooke force-directed simulation
/// linking cross-module entities (Notes, Tasks, Expenses, Wardrobe items).
class GraphNode {
  final String id;
  final String label;
  final Color color;
  Offset position;
  Offset velocity;

  GraphNode({
    required this.id,
    required this.label,
    required this.color,
    required this.position,
    this.velocity = Offset.zero,
  });
}

class GraphEdge {
  final String sourceId;
  final String targetId;
  final double targetLength;

  GraphEdge({required this.sourceId, required this.targetId, this.targetLength = 65.0});
}

class ForceDirectedKnowledgeGraph extends StatefulWidget {
  final List<GraphNode> initialNodes;
  final List<GraphEdge> edges;
  final ValueChanged<GraphNode>? onNodeTap;

  const ForceDirectedKnowledgeGraph({
    super.key,
    required this.initialNodes,
    required this.edges,
    this.onNodeTap,
  });

  @override
  State<ForceDirectedKnowledgeGraph> createState() => _ForceDirectedKnowledgeGraphState();
}

class _ForceDirectedKnowledgeGraphState extends State<ForceDirectedKnowledgeGraph>
    with SingleTickerProviderStateMixin {
  late AnimationController _physicsController;
  late List<GraphNode> _nodes;
  GraphNode? _draggedNode;

  @override
  void initState() {
    super.initState();
    _nodes = List.from(widget.initialNodes);
    _physicsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_stepPhysics)..repeat();
  }

  @override
  void dispose() {
    _physicsController.dispose();
    super.dispose();
  }

  void _stepPhysics() {
    // 1. Coulomb Repulsion between all node pairs
    for (int i = 0; i < _nodes.length; i++) {
      for (int j = i + 1; j < _nodes.length; j++) {
        final n1 = _nodes[i];
        final n2 = _nodes[j];
        final delta = n1.position - n2.position;
        final dist = max(delta.distance, 15.0);
        final force = (500.0 / (dist * dist)).clamp(0.0, 8.0);
        final normalized = delta / dist;

        if (n1 != _draggedNode) n1.position += normalized * force;
        if (n2 != _draggedNode) n2.position -= normalized * force;
      }
    }

    // 2. Hooke Spring Attraction along edges
    for (final edge in widget.edges) {
      final s = _nodes.firstWhere((n) => n.id == edge.sourceId, orElse: () => _nodes[0]);
      final t = _nodes.firstWhere((n) => n.id == edge.targetId, orElse: () => _nodes[0]);
      if (s == t) continue;

      final delta = t.position - s.position;
      final dist = delta.distance;
      final displacement = dist - edge.targetLength;
      final force = displacement * 0.04;
      final normalized = dist > 0 ? (delta / dist) : Offset.zero;

      if (s != _draggedNode) s.position += normalized * force;
      if (t != _draggedNode) t.position -= normalized * force;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanDown: (details) {
        final pos = details.localPosition;
        for (final node in _nodes) {
          if ((node.position - pos).distance < 24) {
            _draggedNode = node;
            widget.onNodeTap?.call(node);
            break;
          }
        }
      },
      onPanUpdate: (details) {
        if (_draggedNode != null) {
          _draggedNode!.position = details.localPosition;
          setState(() {});
        }
      },
      onPanEnd: (_) => _draggedNode = null,
      child: CustomPaint(
        size: Size.infinite,
        painter: _GraphPainter(nodes: _nodes, edges: widget.edges),
      ),
    );
  }
}

class _GraphPainter extends CustomPainter {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;

  _GraphPainter({required this.nodes, required this.edges});

  @override
  void paint(Canvas canvas, Size size) {
    final edgePaint = Paint()
      ..color = const Color(0xFFEAB368).withValues(alpha: 0.35)
      ..strokeWidth = 1.2;

    // Draw Edges
    for (final edge in edges) {
      final s = nodes.firstWhere((n) => n.id == edge.sourceId, orElse: () => nodes[0]);
      final t = nodes.firstWhere((n) => n.id == edge.targetId, orElse: () => nodes[0]);
      canvas.drawLine(s.position, t.position, edgePaint);
    }

    // Draw Nodes
    for (final node in nodes) {
      // Glow
      canvas.drawCircle(
        node.position,
        14.0,
        Paint()..color = node.color.withValues(alpha: 0.25),
      );
      // Core
      canvas.drawCircle(
        node.position,
        8.0,
        Paint()..color = node.color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GraphPainter oldDelegate) => true;
}
