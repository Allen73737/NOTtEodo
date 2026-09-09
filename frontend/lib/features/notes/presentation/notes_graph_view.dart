import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/bento_pod.dart';
import '../../../core/widgets/app_toast_engine.dart';

class NotesGraphView extends StatefulWidget {
  final VoidCallback onClose;

  const NotesGraphView({super.key, required this.onClose});

  @override
  State<NotesGraphView> createState() => _NotesGraphViewState();
}

class _NotesGraphViewState extends State<NotesGraphView> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  String? _selectedNodeTitle;

  final List<Map<String, dynamic>> _nodes = [
    {'title': 'Academic Space', 'type': 'space', 'x': 0.5, 'y': 0.4, 'color': AppColors.secondary},
    {'title': 'Computer Networks U1', 'type': 'note', 'x': 0.3, 'y': 0.25, 'color': const Color(0xFFEAB368)},
    {'title': 'Subnetting Cheat Sheet', 'type': 'pdf', 'x': 0.2, 'y': 0.45, 'color': const Color(0xFF9EBFDB)},
    {'title': 'OSI 7 Layer Summary', 'type': 'note', 'x': 0.4, 'y': 0.65, 'color': const Color(0xFF86CBB0)},
    {'title': 'Goa Trip 2026', 'type': 'space', 'x': 0.75, 'y': 0.6, 'color': AppColors.secondary},
    {'title': 'Villa Booking Slip', 'type': 'pdf', 'x': 0.85, 'y': 0.4, 'color': const Color(0xFF9EBFDB)},
    {'title': 'Linen Outfit Checklist', 'type': 'note', 'x': 0.7, 'y': 0.8, 'color': const Color(0xFF86CBB0)},
  ];

  final List<List<int>> _edges = [
    [0, 1], [0, 2], [0, 3], // Academic Space connections
    [4, 5], [4, 6],         // Goa Trip connections
    [0, 4],                 // Cross-space link
  ];

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
                  Text(isDark ? 'CELESTIAL CONSTELLATION MAP' : 'KNOWLEDGE GRAPH & MIND MAP', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.secondary)),
                  Text(isDark ? 'Starlight Note Stars' : 'Connected Notes & Spaces', style: GoogleFonts.bodoniModa(fontSize: 20, fontWeight: FontWeight.bold, color: primaryTextColor)),
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
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _GraphPainter(
                      nodes: _nodes,
                      edges: _edges,
                      progress: _animController.value,
                      isDark: isDark,
                      selectedNode: _selectedNodeTitle,
                    ),
                    child: GestureDetector(
                      onTapUp: (details) {
                        final size = context.size;
                        if (size == null) return;
                        final pos = details.localPosition;

                        for (var n in _nodes) {
                          final nx = n['x'] * size.width;
                          final ny = n['y'] * size.height;
                          final dist = sqrt(pow(pos.dx - nx, 2) + pow(pos.dy - ny, 2));
                          if (dist < 30) {
                            setState(() {
                              _selectedNodeTitle = n['title'];
                            });
                            AppToastEngine().showToast(
                              context,
                              title: n['title'],
                              message: 'Inspecting ${n['type'].toString().toUpperCase()} node connections in Knowledge Mind Map.',
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
              decoration: BoxDecoration(
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
    if (isDark) {
      // Constellation Starlight Sky Background
      final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.3);
      final Random rand = Random(12);
      for (int i = 0; i < 40; i++) {
        canvas.drawCircle(Offset(rand.nextDouble() * size.width, rand.nextDouble() * size.height), 1.2, starPaint);
      }
    }

    final edgePaint = Paint()
      ..color = (isDark ? const Color(0xFFE8927C).withValues(alpha: 0.4) : const Color(0xFFD5CEBA))
      ..strokeWidth = isDark ? 1.2 : 1.8;

    // Draw Edges
    for (var edge in edges) {
      final n1 = nodes[edge[0]];
      final n2 = nodes[edge[1]];

      final p1 = Offset(n1['x'] * size.width + sin(progress * 2 * pi) * 4, n1['y'] * size.height);
      final p2 = Offset(n2['x'] * size.width + cos(progress * 2 * pi) * 4, n2['y'] * size.height);

      canvas.drawLine(p1, p2, edgePaint);
    }

    // Draw Nodes
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (var n in nodes) {
      final isSel = selectedNode == n['title'];
      final pos = Offset(n['x'] * size.width + sin(progress * 2 * pi) * 4, n['y'] * size.height);

      final nodePaint = Paint()
        ..color = n['color'] as Color
        ..style = PaintingStyle.fill;

      // Glow halo for space nodes or selected node
      if (n['type'] == 'space' || isSel) {
        final glowPaint = Paint()
          ..color = (n['color'] as Color).withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
        canvas.drawCircle(pos, isSel ? 24 : 18, glowPaint);
      }

      canvas.drawCircle(pos, isSel ? 16 : 12, nodePaint);

      // Node Text Label
      textPainter.text = TextSpan(
        text: n['title'] as String,
        style: GoogleFonts.dmSans(
          fontSize: 10,
          fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
          color: isDark ? const Color(0xFFF4F1EA) : AppColors.primary,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(pos.dx - textPainter.width / 2, pos.dy + 14));
    }
  }

  @override
  bool shouldRepaint(covariant _GraphPainter oldDelegate) => true;
}
