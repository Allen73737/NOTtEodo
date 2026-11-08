import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SpendConstellationRadar extends StatefulWidget {
  final Map<String, double> categorySums;
  final double totalAmount;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final bool isDark;

  const SpendConstellationRadar({
    super.key,
    required this.categorySums,
    required this.totalAmount,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.isDark,
  });

  @override
  State<SpendConstellationRadar> createState() => _SpendConstellationRadarState();
}

class _SpendConstellationRadarState extends State<SpendConstellationRadar> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  static const List<String> _radarCategories = [
    'Clothing',
    'Food & Dining',
    'Travel & Stay',
    'Study & Books',
    'General',
  ];

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final primaryTextColor = isDark ? const Color(0xFFF5F2EB) : const Color(0xFF1C1917);
    final subtextColor = isDark ? const Color(0xFFA6A096) : const Color(0xFF635F59);
    final cyanAccent = isDark ? const Color(0xFF86CBB0) : const Color(0xFF5A947E);
    const emerald = Color(0xFF34D399);

    // Compute category fractions
    final double maxVal = widget.categorySums.values.fold<double>(1.0, math.max);
    final Map<String, double> normalized = {};
    for (final cat in _radarCategories) {
      final sum = widget.categorySums[cat] ?? 0.0;
      normalized[cat] = (sum / (maxVal > 0 ? maxVal : 1.0)).clamp(0.12, 1.0);
    }

    // Determine dominant axis
    String dominantCategory = 'Balanced';
    double dominantAmount = 0.0;
    widget.categorySums.forEach((k, v) {
      if (v > dominantAmount) {
        dominantAmount = v;
        dominantCategory = k;
      }
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF000000) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFDDD6CA),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                  child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: cyanAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: cyanAccent.withValues(alpha: 0.3)),
                    ),
                    child: Icon(LucideIcons.compass, color: cyanAccent, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CELESTIAL SPEND RADAR',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.6,
                          color: cyanAccent,
                        ),
                      ),
                      Text(
                        'Capital Allocation Constellation',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                        ),
                      ),
                    ],
                  )),
                ],
              )),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: emerald.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'DOMINANT: ${dominantCategory.toUpperCase()}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    color: emerald,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Radar Graphic
          Center(
            child: SizedBox(
              width: 260,
              height: 240,
              child: AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _RadarConstellationPainter(
                      categories: _radarCategories,
                      normalizedValues: normalized,
                      selectedCategory: widget.selectedCategory,
                      isDark: isDark,
                      cyanColor: cyanAccent,
                      emeraldColor: emerald,
                      rotationAngle: _rotationController.value * 2 * math.pi,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Category Quick-Pivot Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _radarCategories.map((c) {
                final isSelected = widget.selectedCategory.toLowerCase() == c.toLowerCase();
                final sum = widget.categorySums[c] ?? 0.0;
                final pct = widget.totalAmount > 0 ? (sum / widget.totalAmount * 100).toInt() : 0;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.onCategorySelected(isSelected ? 'All' : c);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? cyanAccent : (isDark ? const Color(0xFF0A0A0A) : Colors.white),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? cyanAccent : (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFDDD6CA)),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            c,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected ? Colors.white : primaryTextColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$pct%',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white70 : subtextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _RadarConstellationPainter extends CustomPainter {
  final List<String> categories;
  final Map<String, double> normalizedValues;
  final String selectedCategory;
  final bool isDark;
  final Color cyanColor;
  final Color emeraldColor;
  final double rotationAngle;

  _RadarConstellationPainter({
    required this.categories,
    required this.normalizedValues,
    required this.selectedCategory,
    required this.isDark,
    required this.cyanColor,
    required this.emeraldColor,
    required this.rotationAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) * 0.38;
    final n = categories.length;

    // 1. Concentric Astrolabe Web Rings (25%, 50%, 75%, 100%)
    final ringPaint = Paint()
      ..color = (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFDDD6CA)).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (int step = 1; step <= 4; step++) {
      final r = maxRadius * (step / 4.0);
      final webPath = Path();
      for (int i = 0; i < n; i++) {
        final a = (i * 2 * math.pi / n) - (math.pi / 2);
        final p = Offset(center.dx + r * math.cos(a), center.dy + r * math.sin(a));
        if (i == 0) {
          webPath.moveTo(p.dx, p.dy);
        } else {
          webPath.lineTo(p.dx, p.dy);
        }
      }
      webPath.close();
      canvas.drawPath(webPath, ringPaint);
    }

    // 2. Radial Axis Spokes
    final spokePaint = Paint()
      ..color = (isDark ? const Color(0xFF242424) : const Color(0xFFB5AEA2)).withValues(alpha: 0.5)
      ..strokeWidth = 0.9;

    final List<Offset> vertexPoints = [];

    for (int i = 0; i < n; i++) {
      final a = (i * 2 * math.pi / n) - (math.pi / 2);
      final endP = Offset(center.dx + maxRadius * math.cos(a), center.dy + maxRadius * math.sin(a));
      canvas.drawLine(center, endP, spokePaint);

      // Data polygon vertex
      final cat = categories[i];
      final val = normalizedValues[cat] ?? 0.2;
      final dataP = Offset(center.dx + maxRadius * val * math.cos(a), center.dy + maxRadius * val * math.sin(a));
      vertexPoints.add(dataP);

      // Label at spoke tip
      final isSel = selectedCategory.toLowerCase() == cat.toLowerCase();
      final labelP = Offset(center.dx + (maxRadius + 16) * math.cos(a), center.dy + (maxRadius + 16) * math.sin(a));

      final tp = TextPainter(
        text: TextSpan(
          text: cat.split(' ').first.toUpperCase(),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 9,
            fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
            color: isSel ? cyanColor : (isDark ? const Color(0xFFA6A096) : const Color(0xFF635F59)),
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(labelP.dx - tp.width / 2, labelP.dy - tp.height / 2));
    }

    // 3. Data Constellation Polygon Fill & Stroke
    final polyPath = Path();
    for (int i = 0; i < vertexPoints.length; i++) {
      if (i == 0) {
        polyPath.moveTo(vertexPoints[i].dx, vertexPoints[i].dy);
      } else {
        polyPath.lineTo(vertexPoints[i].dx, vertexPoints[i].dy);
      }
    }
    polyPath.close();

    final fillPaint = Paint()
      ..color = cyanColor.withValues(alpha: 0.20)
      ..style = PaintingStyle.fill;
    canvas.drawPath(polyPath, fillPaint);

    final strokePaint = Paint()
      ..color = cyanColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(polyPath, strokePaint);

    // 4. Celestial Star Nodes at Vertices
    for (int i = 0; i < vertexPoints.length; i++) {
      final p = vertexPoints[i];
      final nodeGlow = Paint()
        ..color = cyanColor.withValues(alpha: 0.4)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p, 6.0, nodeGlow);

      final nodeCore = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p, 3.0, nodeCore);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarConstellationPainter oldDelegate) {
    return oldDelegate.normalizedValues != normalizedValues ||
        oldDelegate.selectedCategory != selectedCategory ||
        oldDelegate.rotationAngle != rotationAngle;
  }
}
