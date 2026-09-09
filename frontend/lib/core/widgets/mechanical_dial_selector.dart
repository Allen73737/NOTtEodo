import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/app_colors.dart';

class MechanicalDialSelector extends StatefulWidget {
  final List<String> options;
  final ValueChanged<String> onSelected;

  const MechanicalDialSelector({
    super.key,
    required this.options,
    required this.onSelected,
  });

  @override
  State<MechanicalDialSelector> createState() => _MechanicalDialSelectorState();
}

class _MechanicalDialSelectorState extends State<MechanicalDialSelector> {
  int _selectedIndex = 0;

  void _nextOption() {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedIndex = (_selectedIndex + 1) % widget.options.length;
    });
    widget.onSelected(widget.options[_selectedIndex]);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _nextOption,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.tune, size: 14, color: AppColors.secondary),
            const SizedBox(width: 6),
            Text(
              widget.options[_selectedIndex],
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary),
            ),
          ],
        ),
      ),
    );
  }
}
