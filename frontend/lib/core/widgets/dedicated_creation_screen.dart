import 'package:flutter/material.dart';

import 'entry_editor.dart';

/// The shell's "new entry" sheet: opens the [EntryEditor] for the module in view.
class DedicatedCreationScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final kind = EntryKindInfo.forModule(activeIndex);
    return EntryEditor(
      // A fresh form whenever the sheet opens for a different module.
      key: ValueKey(kind),
      kind: kind,
      onClose: onClose,
      onSaved: (title) => onItemSaved(title),
    );
  }
}
