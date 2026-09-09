import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Mechanical Split-Flap Schedule Board
/// Solari di Udine style mechanical departure/schedule board with 3D perspective
/// flip animation and physical split hairline divider.
class SplitFlapBoard extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Color? cardColor;
  final Color? textColor;

  const SplitFlapBoard({
    super.key,
    required this.text,
    this.style,
    this.cardColor,
    this.textColor,
  });

  @override
  State<SplitFlapBoard> createState() => _SplitFlapBoardState();
}

class _SplitFlapBoardState extends State<SplitFlapBoard>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  String _previousText = '';
  String _targetText = '';

  @override
  void initState() {
    super.initState();
    _targetText = widget.text;
    _previousText = widget.text;
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
  }

  @override
  void didUpdateWidget(covariant SplitFlapBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _previousText = oldWidget.text;
      _targetText = widget.text;
      _flipController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chars = _targetText.toUpperCase().split('');
    final prevChars = _previousText.toUpperCase().split('');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(chars.length, (idx) {
        final currentC = chars[idx];
        final prevC = idx < prevChars.length ? prevChars[idx] : ' ';

        return _SingleSplitFlapChar(
          currentChar: currentC,
          previousChar: prevC,
          animation: _flipController,
          cardColor: widget.cardColor,
          textColor: widget.textColor,
        );
      }),
    );
  }
}

class _SingleSplitFlapChar extends StatelessWidget {
  final String currentChar;
  final String previousChar;
  final Animation<double> animation;
  final Color? cardColor;
  final Color? textColor;

  const _SingleSplitFlapChar({
    required this.currentChar,
    required this.previousChar,
    required this.animation,
    this.cardColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final flapBg = cardColor ?? (isDark ? const Color(0xFF161618) : const Color(0xFF262626));
    final textC = textColor ?? Colors.white;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      width: 22,
      height: 32,
      decoration: BoxDecoration(
        color: flapBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black45, width: 0.8),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Stack(
        children: [
          // Centered Display Character
          Center(
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                final displayChar = animation.value < 0.5 ? previousChar : currentChar;
                return Text(
                  displayChar,
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: textC,
                  ),
                );
              },
            ),
          ),

          // Horizontal Split Flap Crease Line
          Center(
            child: Container(
              height: 1,
              color: Colors.black.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
