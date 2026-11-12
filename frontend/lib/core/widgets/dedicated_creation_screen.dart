import 'package:flutter/material.dart';

import 'entry_editor.dart';

/// The shell's "new entry" sheet: opens the [EntryEditor] with a live kind-switcher
/// so curators can seamlessly create notes, tasks, expenses, events, habits, and more.
class DedicatedCreationScreen extends StatefulWidget {
  final int activeIndex;
  final VoidCallback onClose;
  final Function(String) onItemSaved;

  const DedicatedCreationScreen({
    super.key,
    required this.activeIndex,
    required this.onClose,
    required this.onItemSaved,
  });

  @override
  State<DedicatedCreationScreen> createState() => _DedicatedCreationScreenState();
}

class _DedicatedCreationScreenState extends State<DedicatedCreationScreen> {
  late EntryKind _currentKind;
  String _cachedTitle = '';

  @override
  void initState() {
    super.initState();
    _currentKind = EntryKindInfo.forModule(widget.activeIndex);
  }

  @override
  void didUpdateWidget(DedicatedCreationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeIndex != widget.activeIndex) {
      setState(() {
        _currentKind = EntryKindInfo.forModule(widget.activeIndex);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return EntryEditor(
      key: ValueKey(_currentKind),
      kind: _currentKind,
      initialTitle: _cachedTitle,
      onClose: widget.onClose,
      onSaved: widget.onItemSaved,
      onTitleChanged: (t) => _cachedTitle = t,
      onKindChanged: (newKind) {
        setState(() {
          _currentKind = newKind;
        });
      },
    );
  }
}
