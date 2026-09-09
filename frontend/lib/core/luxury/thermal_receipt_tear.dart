import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Thermal Receipt Tear Effect for Expenses
/// Procedural ivory thermal paper slip emerging from a recessed mechanical slot
/// with perforation creases and a swipe-to-tear gesture on expense split settlement.
class ThermalReceiptTear extends StatefulWidget {
  final String title;
  final String amount;
  final List<String> lineItems;
  final VoidCallback? onTorn;

  const ThermalReceiptTear({
    super.key,
    required this.title,
    required this.amount,
    required this.lineItems,
    this.onTorn,
  });

  @override
  State<ThermalReceiptTear> createState() => _ThermalReceiptTearState();
}

class _ThermalReceiptTearState extends State<ThermalReceiptTear>
    with SingleTickerProviderStateMixin {
  late AnimationController _rollController;
  double _tearDragOffset = 0.0;
  bool _isTorn = false;

  @override
  void initState() {
    super.initState();
    _rollController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _rollController.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_isTorn) return;
    setState(() {
      _tearDragOffset += details.primaryDelta ?? 0;
      if (_tearDragOffset.abs() > 120.0) {
        _isTorn = true;
        HapticFeedback.heavyImpact();
        widget.onTorn?.call();
      }
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!_isTorn) {
      setState(() => _tearDragOffset = 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isTorn) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mechanical Receipt Dispenser Slot
        Container(
          height: 8,
          width: 260,
          decoration: BoxDecoration(
            color: const Color(0xFF18181A),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.black, width: 1.5),
            boxShadow: const [
              BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
        ),

        // Emerging Thermal Paper Slip
        SizeTransition(
          sizeFactor: CurvedAnimation(parent: _rollController, curve: Curves.easeOutCubic),
          axisAlignment: -1.0,
          child: GestureDetector(
            onHorizontalDragUpdate: _onHorizontalDragUpdate,
            onHorizontalDragEnd: _onHorizontalDragEnd,
            child: Transform.translate(
              offset: Offset(_tearDragOffset, 0),
              child: Transform.rotate(
                angle: (_tearDragOffset / 200) * 0.15,
                child: Container(
                  width: 250,
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.all(18),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFAF7EE),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          'SANCTUARY SETTLEMENT',
                          style: GoogleFonts.libreBarcode39Text(fontSize: 26, color: Colors.black87),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Text(
                          widget.title.toUpperCase(),
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      const Divider(height: 16, thickness: 0.8, color: Colors.black26),
                      ...widget.lineItems.map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            item,
                            style: GoogleFonts.courierPrime(fontSize: 11, color: Colors.black87),
                          ),
                        ),
                      ),
                      const Divider(height: 16, thickness: 0.8, color: Colors.black26),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('TOTAL', style: GoogleFonts.courierPrime(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black)),
                          Text(widget.amount, style: GoogleFonts.courierPrime(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          '<< SWIPE TO TEAR RECEIPT >>',
                          style: GoogleFonts.dmSans(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: const Color(0xFFE8927C),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Perforated Jagged Bottom Edge
                      CustomPaint(
                        size: const Size(214, 8),
                        painter: _PerforationZigZagPainter(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PerforationZigZagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFDDD7C8)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const toothW = 6.0;
    final path = Path()..moveTo(0, 0);

    for (double x = 0; x < size.width; x += toothW) {
      path.lineTo(x + (toothW / 2), 6);
      path.lineTo(x + toothW, 0);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
