import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/app_colors.dart';
import '../motion/motion.dart';

class InkSignatureCanvas extends StatefulWidget {
  final VoidCallback onClose;

  const InkSignatureCanvas({super.key, required this.onClose});

  @override
  State<InkSignatureCanvas> createState() => _InkSignatureCanvasState();
}

class _InkSignatureCanvasState extends State<InkSignatureCanvas> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;

    return Container(
      height: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF000000) : const Color(0xFFFAF7F0),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.secondary, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('DIGITAL INK SIGNATURE & SKETCH', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: AppColors.secondary)),
              Row(
                children: [
                  Pressable(pressedScale: 0.95, hoverLift: 0, child: TextButton(
                    onPressed: () => setState(() {
                      _strokes.clear();
                      _currentStroke.clear();
                    }),
                    child: Text('Clear', style: GoogleFonts.dmSans(color: AppColors.secondary, fontSize: 11)),
                  )),
                  IconButton(icon: Icon(Icons.close, color: primaryTextColor, size: 18), onPressed: widget.onClose),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: GestureDetector(
                onPanStart: (details) {
                  setState(() {
                    _currentStroke = [details.localPosition];
                    _strokes.add(_currentStroke);
                  });
                },
                onPanUpdate: (details) {
                  setState(() {
                    _currentStroke.add(details.localPosition);
                  });
                },
                child: CustomPaint(
                  painter: _InkPainter(strokes: _strokes, isDark: isDark),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InkPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final bool isDark;

  _InkPainter({required this.strokes, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = isDark ? const Color(0xFF1B3035) : Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final linePaint = Paint()
      ..color = isDark ? const Color(0xFFF4F1EA) : AppColors.primary
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (var stroke in strokes) {
      for (int i = 0; i < stroke.length - 1; i++) {
        canvas.drawLine(stroke[i], stroke[i + 1], linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _InkPainter oldDelegate) => true;
}
