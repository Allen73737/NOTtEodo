import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/bento_pod.dart';
import '../../../core/widgets/app_toast_engine.dart';
import '../../../core/state/sanctuary_state.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';

class NotesGraphView extends ConsumerStatefulWidget {
  final VoidCallback onClose;

  const NotesGraphView({super.key, required this.onClose});

  @override
  ConsumerState<NotesGraphView> createState() => _NotesGraphViewState();
}

class _NotesGraphViewState extends ConsumerState<NotesGraphView> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  String? _selectedNodeTitle;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? const Color(0xFFF4F1EA) : AppColors.primary;
    final subtextColor = isDark ? const Color(0xFFB8C5C8) : AppColors.onSurfaceVariant;
    final accentColor = isDark ? const Color(0xFFE8927C) : AppColors.secondary;

    final notes = ref.watch(notesProvider);

    // Build dynamic nodes and edges from real user notes
    final List<Map<String, dynamic>> nodes = [];
    final List<List<int>> edges = [];

    final spaces = notes.map((n) => n.space).toSet().toList();
    final spaceIndexMap = <String, int>{};

    // Position spaces along a central circle
    for (var i = 0; i < spaces.length; i++) {
      final space = spaces[i];
      final angle = (2 * pi * i) / (spaces.isEmpty ? 1 : spaces.length);
      final x = 0.5 + 0.25 * cos(angle);
      final y = 0.5 + 0.25 * sin(angle);
      final nodeIdx = nodes.length;
      spaceIndexMap[space] = nodeIdx;
      nodes.add({
        'title': space,
        'type': 'space',
        'x': x.clamp(0.15, 0.85),
        'y': y.clamp(0.15, 0.85),
        'color': accentColor,
      });
    }

    // Position notes orbiting their space
    for (var i = 0; i < notes.length; i++) {
      final note = notes[i];
      final spaceIdx = spaceIndexMap[note.space];
      final angle = (2 * pi * i) / (notes.isEmpty ? 1 : notes.length) + 0.3;
      final dist = 0.15 + (i % 3) * 0.05;
      final originX = spaceIdx != null ? (nodes[spaceIdx]['x'] as double) : 0.5;
      final originY = spaceIdx != null ? (nodes[spaceIdx]['y'] as double) : 0.5;
      final x = originX + dist * cos(angle);
      final y = originY + dist * sin(angle);
      final noteNodeIdx = nodes.length;
      nodes.add({
        'title': note.title,
        'type': 'note',
        'x': x.clamp(0.1, 0.9),
        'y': y.clamp(0.1, 0.9),
        'color': (i % 2 == 0) ? const Color(0xFF86CBB0) : const Color(0xFFEAB368),
      });

      if (spaceIdx != null) {
        edges.add([spaceIdx, noteNodeIdx]);
      }
    }

    return BentoPod(
      style: PodTextureStyle.glass,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('KNOWLEDGE GRAPH', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.secondary)),
                  Text('Connected Notes', style: GoogleFonts.bodoniModa(fontSize: 20, fontWeight: FontWeight.bold, color: primaryTextColor)),
                ],
              ),
              IconButton(
                icon: Icon(Icons.close, color: primaryTextColor, size: 20),
                onPressed: widget.onClose,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Interactive Graph Canvas
          SizedBox(
            height: 320,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: notes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.network, size: 36, color: accentColor.withValues(alpha: 0.6)),
                          const SizedBox(height: 10),
                          Text(
                            'Knowledge Constellation Clear',
                            style: GoogleFonts.bodoniModa(fontSize: 15, fontWeight: FontWeight.bold, color: primaryTextColor),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Create notes and spaces to generate your neural thought map.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.spectral(fontSize: 12.5, fontStyle: FontStyle.italic, color: subtextColor),
                          ),
                        ],
                      ),
                    )
                  : AnimatedBuilder(
                      animation: _animController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _GraphPainter(
                            nodes: nodes,
                            edges: edges,
                            progress: _animController.value,
                            isDark: isDark,
                            selectedNode: _selectedNodeTitle,
                          ),
                          child: GestureDetector(
                            onTapUp: (details) {
                              final size = context.size;
                              if (size == null) return;
                              final pos = details.localPosition;

                              for (var n in nodes) {
                                final nx = (n['x'] as double) * size.width;
                                final ny = (n['y'] as double) * size.height;
                                final dist = sqrt(pow(pos.dx - nx, 2) + pow(pos.dy - ny, 2));
                                if (dist < 30) {
                                  setState(() {
                                    _selectedNodeTitle = n['title'] as String;
                                  });
                                  AppToastEngine().showToast(
                                    context,
                                    title: n['title'] as String,
                                    message: 'Inspecting ${n['type'].toString().toUpperCase()} node in Knowledge Mind Map.',
                                  );
                                  break;
                                }
                              }
                            },
                          ),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(height: 12),

          // Selected Node Context Footer
          if (_selectedNodeTitle != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: edBox(
                color: AppColors.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Active Star: $_selectedNodeTitle', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                  Text('Tap outside to reset', style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _GraphPainter extends CustomPainter {
  final List<Map<String, dynamic>> nodes;
  final List<List<int>> edges;
  final double progress;
  final bool isDark;
  final String? selectedNode;

  _GraphPainter({
    required this.nodes,
    required this.edges,
    required this.progress,
    required this.isDark,
    this.selectedNode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes.isEmpty) return;

    final linePaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.12)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final activeLinePaint = Paint()
      ..color = AppColors.secondary.withValues(alpha: 0.4)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    // 1. Draw Edges
    for (final edge in edges) {
      if (edge[0] >= nodes.length || edge[1] >= nodes.length) continue;
      final n1 = nodes[edge[0]];
      final n2 = nodes[edge[1]];

      final p1 = Offset(n1['x'] * size.width, n1['y'] * size.height);
      final p2 = Offset(n2['x'] * size.width, n2['y'] * size.height);

      final isEdgeSelected = selectedNode != null &&
          (n1['title'] == selectedNode || n2['title'] == selectedNode);

      canvas.drawLine(p1, p2, isEdgeSelected ? activeLinePaint : linePaint);
    }

    // 2. Draw Nodes
    for (final n in nodes) {
      final p = Offset(n['x'] * size.width, n['y'] * size.height);
      final isSpace = n['type'] == 'space';
      final isSelected = selectedNode != null && n['title'] == selectedNode;
      final nodeColor = n['color'] as Color;

      // Glow halo
      final glowPaint = Paint()
        ..color = nodeColor.withValues(alpha: isSelected ? 0.35 : 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(p, isSpace ? 18 : 12, glowPaint);

      // Core dot
      final corePaint = Paint()
        ..color = nodeColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p, isSpace ? 9 : 6, corePaint);

      // Label text
      final textSpan = TextSpan(
        text: n['title'] as String,
        style: GoogleFonts.dmSans(
          fontSize: isSpace ? 11 : 9.5,
          fontWeight: isSpace ? FontWeight.bold : FontWeight.w500,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      );
      final tp = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 100);
      tp.paint(canvas, Offset(p.dx - tp.width / 2, p.dy + (isSpace ? 12 : 8)));
    }
  }

  @override
  bool shouldRepaint(covariant _GraphPainter oldDelegate) => true;
}
