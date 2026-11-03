import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SovereignVaultRotaryDial extends StatefulWidget {
  final double currentBudget;
  final ValueChanged<double> onBudgetChanged;
  final bool isDark;

  const SovereignVaultRotaryDial({
    super.key,
    required this.currentBudget,
    required this.onBudgetChanged,
    required this.isDark,
  });

  @override
  State<SovereignVaultRotaryDial> createState() => _SovereignVaultRotaryDialState();
}

class _SovereignVaultRotaryDialState extends State<SovereignVaultRotaryDial> {
  double _currentAngle = 0.0;
  double _lastDragAngle = 0.0;
  int _lastTickStep = 0;

  static const double _minBudget = 10000.0;
  static const double _maxBudget = 100000.0;
  static const double _budgetStep = 2500.0;

  @override
  void initState() {
    super.initState();
    _syncAngleFromBudget(widget.currentBudget);
  }

  @override
  void didUpdateWidget(covariant SovereignVaultRotaryDial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentBudget != oldWidget.currentBudget) {
      _syncAngleFromBudget(widget.currentBudget);
    }
  }

  void _syncAngleFromBudget(double budget) {
    final ratio = ((budget - _minBudget) / (_maxBudget - _minBudget)).clamp(0.0, 1.0);
    _currentAngle = ratio * 2 * math.pi;
  }

  void _onPanStart(DragStartDetails details, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final pos = details.localPosition - center;
    _lastDragAngle = math.atan2(pos.dy, pos.dx);
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final pos = details.localPosition - center;
    final angle = math.atan2(pos.dy, pos.dx);

    var delta = angle - _lastDragAngle;
    if (delta > math.pi) delta -= 2 * math.pi;
    if (delta < -math.pi) delta += 2 * math.pi;

    _lastDragAngle = angle;

    setState(() {
      _currentAngle = (_currentAngle + delta) % (2 * math.pi);
      if (_currentAngle < 0) _currentAngle += 2 * math.pi;

      final ratio = _currentAngle / (2 * math.pi);
      final rawBudget = _minBudget + ratio * (_maxBudget - _minBudget);
      final steppedBudget = (rawBudget / _budgetStep).round() * _budgetStep;
      final clamped = steppedBudget.clamp(_minBudget, _maxBudget);

      final currentStep = (clamped / _budgetStep).round();
      if (currentStep != _lastTickStep) {
        _lastTickStep = currentStep;
        HapticFeedback.selectionClick();
      }

      widget.onBudgetChanged(clamped);
    });
  }

  void _setPreset(double val) {
    HapticFeedback.mediumImpact();
    setState(() {
      _syncAngleFromBudget(val);
      widget.onBudgetChanged(val);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final primaryTextColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cyanGlow = isDark ? const Color(0xFF86CBB0) : const Color(0xFF5A947E);
    const dialDiameter = 190.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF000000) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFDDD6CA),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                  child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: cyanGlow.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: cyanGlow.withValues(alpha: 0.3)),
                    ),
                    child: Icon(LucideIcons.shieldCheck, color: cyanGlow, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ROTARY VAULT COMBINATION DIAL',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.6,
                          color: cyanGlow,
                        ),
                      ),
                      Text(
                        'Treasury Allocation Calibrator',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14.5,
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
                  color: const Color(0xFF34D399).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(color: Color(0xFF34D399), shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text(
                      'SECURED',
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 9.5, fontWeight: FontWeight.bold, color: const Color(0xFF34D399)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Rotary Combination Wheel
          LayoutBuilder(
            builder: (context, constraints) {
              const size = Size(dialDiameter, dialDiameter);
              return GestureDetector(
                onPanStart: (d) => _onPanStart(d, size),
                onPanUpdate: (d) => _onPanUpdate(d, size),
                child: SizedBox(
                  width: dialDiameter,
                  height: dialDiameter,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Knurled Steel Bezel & Degree Hashes
                      CustomPaint(
                        size: size,
                        painter: _RotaryDialPainter(
                          angle: _currentAngle,
                          isDark: isDark,
                          accentColor: cyanGlow,
                        ),
                      ),

                      // Center Hub Readout
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'MONTHLY CEILING',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: subtextColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'â‚¹${widget.currentBudget.toInt()}',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: primaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'DRAG TO ROTATE',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 7.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.0,
                              color: cyanGlow,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // Quick Presets Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPresetChip('â‚¹15k (Lean)', 15000.0, isDark, cyanGlow),
                const SizedBox(width: 8),
                _buildPresetChip('â‚¹25k (Sovereign)', 25000.0, isDark, cyanGlow),
                const SizedBox(width: 8),
                _buildPresetChip('â‚¹50k (Expansion)', 50000.0, isDark, cyanGlow),
                const SizedBox(width: 8),
                _buildPresetChip('â‚¹100k (Imperial)', 100000.0, isDark, cyanGlow),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String label, double val, bool isDark, Color accent) {
    final isSelected = (widget.currentBudget - val).abs() < 1.0;
    return InkWell(
      onTap: () => _setPreset(val),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? accent : (isDark ? const Color(0xFF0A0A0A) : const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? accent : (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFDDD6CA)),
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF262621)),
          ),
        ),
      ),
    );
  }
}

// Precision CNC Dial Painter with Knurling & Bevels
class _RotaryDialPainter extends CustomPainter {
  final double angle;
  final bool isDark;
  final Color accentColor;

  _RotaryDialPainter({
    required this.angle,
    required this.isDark,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius - 16;
    final hubRadius = innerRadius - 28;

    // 1. Outer Knurled Ring (Damascus Teeth)
    final toothPaint = Paint()
      ..color = isDark ? const Color(0xFF283040) : const Color(0xFFDDD6CA)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    const teethCount = 48;
    for (int i = 0; i < teethCount; i++) {
      final a = (i * 2 * math.pi / teethCount);
      final p1 = Offset(center.dx + (outerRadius - 6) * math.cos(a), center.dy + (outerRadius - 6) * math.sin(a));
      final p2 = Offset(center.dx + outerRadius * math.cos(a), center.dy + outerRadius * math.sin(a));
      canvas.drawLine(p1, p2, toothPaint);
    }

    // 2. Dial Outer Track
    final trackPaint = Paint()
      ..color = isDark ? const Color(0xFF141414) : const Color(0xFFF1F5F9)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, innerRadius, trackPaint);

    // Track Border
    final trackBorder = Paint()
      ..color = isDark ? const Color(0xFF333F52) : const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, innerRadius, trackBorder);

    // 3. Rotating Calibration Hashmarks
    const hashCount = 36;
    final normalHashPaint = Paint()
      ..color = (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)).withValues(alpha: 0.6)
      ..strokeWidth = 1.0;

    final majorHashPaint = Paint()
      ..color = accentColor
      ..strokeWidth = 2.0;

    for (int i = 0; i < hashCount; i++) {
      final a = (i * 2 * math.pi / hashCount) + angle;
      final isMajor = i % 6 == 0;
      final len = isMajor ? 10.0 : 5.0;

      final p1 = Offset(center.dx + (innerRadius - 4) * math.cos(a), center.dy + (innerRadius - 4) * math.sin(a));
      final p2 =
          Offset(center.dx + (innerRadius - 4 - len) * math.cos(a), center.dy + (innerRadius - 4 - len) * math.sin(a));

      canvas.drawLine(p1, p2, isMajor ? majorHashPaint : normalHashPaint);
    }

    // 4. Center Vault Hub (Brushed Rhodium Cap)
    final hubPaint = Paint()
      ..color = isDark ? const Color(0xFF1E2430) : const Color(0xFFDDD6CA)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, hubRadius, hubPaint);

    final hubRim = Paint()
      ..color = isDark ? const Color(0xFF384357) : const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(center, hubRadius, hubRim);

    // 5. 12-o'clock Top Marker / Pointer
    final topPointer = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(center.dx, center.dy - innerRadius + 2);
    path.lineTo(center.dx - 5, center.dy - innerRadius - 7);
    path.lineTo(center.dx + 5, center.dy - innerRadius - 7);
    path.close();
    canvas.drawPath(path, topPointer);
  }

  @override
  bool shouldRepaint(covariant _RotaryDialPainter oldDelegate) {
    return oldDelegate.angle != angle || oldDelegate.isDark != isDark || oldDelegate.accentColor != accentColor;
  }
}
