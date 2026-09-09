import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/app_colors.dart';

class CalligraphyInkWellSelector extends StatefulWidget {
  final List<Color> colors;
  final ValueChanged<Color> onColorSelected;

  const CalligraphyInkWellSelector({
    super.key,
    required this.colors,
    required this.onColorSelected,
  });

  @override
  State<CalligraphyInkWellSelector> createState() => _CalligraphyInkWellSelectorState();
}

class _CalligraphyInkWellSelectorState extends State<CalligraphyInkWellSelector> {
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.colors.first;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: widget.colors.map((c) {
        final isSelected = c == _selectedColor;

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _selectedColor = c);
            widget.onColorSelected(c);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isSelected ? 28 : 22,
            height: isSelected ? 28 : 22,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.secondary : Colors.white.withValues(alpha: 0.4),
                width: isSelected ? 2.5 : 1.0,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: c.withValues(alpha: 0.6),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
