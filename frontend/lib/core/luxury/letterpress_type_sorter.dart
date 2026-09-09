import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Letterpress Lead Type Composing Stick Sorter
/// Gutenberg lead typography chase animation: items extrude into metallic lead
/// type blocks that slide across a brass composing stick when re-sorting.
class LetterpressTypeSorter extends StatefulWidget {
  final List<String> items;
  final ValueChanged<List<String>> onReordered;

  const LetterpressTypeSorter({
    super.key,
    required this.items,
    required this.onReordered,
  });

  @override
  State<LetterpressTypeSorter> createState() => _LetterpressTypeSorterState();
}

class _LetterpressTypeSorterState extends State<LetterpressTypeSorter> {
  late List<String> _currentList;

  @override
  void initState() {
    super.initState();
    _currentList = List.from(widget.items);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131210),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6B5820), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: ReorderableListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        // ignore: deprecated_member_use
        onReorder: (oldIndex, newIndex) {
          HapticFeedback.selectionClick();
          setState(() {
            if (newIndex > oldIndex) newIndex--;
            final item = _currentList.removeAt(oldIndex);
            _currentList.insert(newIndex, item);
          });
          widget.onReordered(_currentList);
        },
        children: [
          for (int i = 0; i < _currentList.length; i++)
            Container(
              key: ValueKey(_currentList[i]),
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF38383B), Color(0xFF222224)],
                ),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF555558), width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    offset: Offset(0, 2),
                    blurRadius: 3,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.drag_indicator, size: 16, color: Color(0xFFD4AF37)),
                  const SizedBox(width: 10),
                  Text(
                    '${i + 1}.',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      color: const Color(0xFFD4AF37),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _currentList[i],
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: const Color(0xFFE8E6DF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
