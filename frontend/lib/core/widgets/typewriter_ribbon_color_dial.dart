import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TypewriterRibbonColorDial extends StatefulWidget {
  final ValueChanged<Color> onColorSelected;

  const TypewriterRibbonColorDial({super.key, required this.onColorSelected});

  @override
  State<TypewriterRibbonColorDial> createState() => _TypewriterRibbonColorDialState();
}

class _TypewriterRibbonColorDialState extends State<TypewriterRibbonColorDial> {
  bool _isBlackRibbon = true;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _isBlackRibbon = !_isBlackRibbon);
        widget.onColorSelected(_isBlackRibbon ? const Color(0xFF16282C) : const Color(0xFFBA1A1A));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2E2E2E)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isBlackRibbon ? const Color(0xFF16282C) : const Color(0xFFBA1A1A),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _isBlackRibbon ? 'BLACK RIBBON' : 'RED RIBBON',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
