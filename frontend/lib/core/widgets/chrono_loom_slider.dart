import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class ChronoLoomSlider extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const ChronoLoomSlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<ChronoLoomSlider> createState() => _ChronoLoomSliderState();
}

class _ChronoLoomSliderState extends State<ChronoLoomSlider> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF000000) : const Color(0xFFFAF7F0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD9725B).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.tune, size: 20, color: Color(0xFFD9725B)),
          const SizedBox(width: 12),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: const Color(0xFFD9725B),
                inactiveTrackColor: const Color(0xFFD9725B).withValues(alpha: 0.2),
                thumbColor: const Color(0xFFFE8F77),
                overlayColor: const Color(0xFFD9725B).withValues(alpha: 0.15),
                trackHeight: 6,
              ),
              child: Slider(
                value: widget.value,
                onChanged: (val) {
                  HapticFeedback.selectionClick();
                  widget.onChanged(val);
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(widget.value * 24).toInt()}:00',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF16282C),
            ),
          ),
        ],
      ),
    );
  }
}
