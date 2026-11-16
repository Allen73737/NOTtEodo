import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../motion/sanctuary_motion_engine.dart';

class MarkdownAccessoryToolbar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onVoiceDictate;
  final VoidCallback? onAttachImage;

  const MarkdownAccessoryToolbar({
    super.key,
    required this.controller,
    this.onVoiceDictate,
    this.onAttachImage,
  });

  static void applyFormat(TextEditingController controller, String formatType) {
    final text = controller.text;
    final selection = controller.selection.isValid
        ? controller.selection
        : TextSelection.collapsed(offset: text.length);
    final start = selection.start.clamp(0, text.length);
    final end = selection.end.clamp(0, text.length);
    final selectedText = (start < end) ? text.substring(start, end) : '';

    String newText;
    int newCursorPos;

    switch (formatType) {
      case 'bold':
        final wrapped = '**${selectedText.isEmpty ? 'bold text' : selectedText}**';
        newText = text.replaceRange(start, end, wrapped);
        newCursorPos = selectedText.isEmpty ? start + 2 : start + wrapped.length;
        break;
      case 'italic':
        final wrapped = '*${selectedText.isEmpty ? 'italic text' : selectedText}*';
        newText = text.replaceRange(start, end, wrapped);
        newCursorPos = selectedText.isEmpty ? start + 1 : start + wrapped.length;
        break;
      case 'checkbox':
        final lineStart = text.lastIndexOf('\n', start - 1) + 1;
        newText = '${text.substring(0, lineStart)}- [ ] ${text.substring(lineStart)}';
        newCursorPos = start + 6;
        break;
      case 'heading':
        final lineStart = text.lastIndexOf('\n', start - 1) + 1;
        newText = '${text.substring(0, lineStart)}## ${text.substring(lineStart)}';
        newCursorPos = start + 3;
        break;
      case 'quote':
        final lineStart = text.lastIndexOf('\n', start - 1) + 1;
        newText = '${text.substring(0, lineStart)}> ${text.substring(lineStart)}';
        newCursorPos = start + 2;
        break;
      case 'bullet':
        final lineStart = text.lastIndexOf('\n', start - 1) + 1;
        newText = '${text.substring(0, lineStart)}- ${text.substring(lineStart)}';
        newCursorPos = start + 2;
        break;
      case 'numbered':
        final lineStart = text.lastIndexOf('\n', start - 1) + 1;
        newText = '${text.substring(0, lineStart)}1. ${text.substring(lineStart)}';
        newCursorPos = start + 3;
        break;
      case 'link':
        final title = selectedText.isEmpty ? 'link title' : selectedText;
        final wrapped = '[$title](https://)';
        newText = text.replaceRange(start, end, wrapped);
        newCursorPos = start + wrapped.length - 1;
        break;
      case 'code':
        if (selectedText.contains('\n')) {
          final wrapped = '```\n$selectedText\n```';
          newText = text.replaceRange(start, end, wrapped);
          newCursorPos = start + wrapped.length;
        } else {
          final wrapped = '`${selectedText.isEmpty ? 'code' : selectedText}`';
          newText = text.replaceRange(start, end, wrapped);
          newCursorPos = selectedText.isEmpty ? start + 1 : start + wrapped.length;
        }
        break;
      default:
        return;
    }

    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursorPos.clamp(0, newText.length)),
    );
    SanctuaryHapticEngine.selection();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final barBg = isDark ? const Color(0xFF141211) : const Color(0xFFF3ECE6);
    final border = isDark ? const Color(0xFF282421) : const Color(0xFFE2D6CB);
    final iconColor = isDark ? const Color(0xFFE8DFD7) : const Color(0xFF2E2A27);

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: barBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        children: [
          _ToolButton(
            icon: LucideIcons.bold,
            tooltip: 'Bold',
            color: iconColor,
            onTap: () => applyFormat(controller, 'bold'),
          ),
          _ToolButton(
            icon: LucideIcons.italic,
            tooltip: 'Italic',
            color: iconColor,
            onTap: () => applyFormat(controller, 'italic'),
          ),
          _ToolButton(
            icon: LucideIcons.checkSquare,
            tooltip: 'Checkbox',
            color: iconColor,
            onTap: () => applyFormat(controller, 'checkbox'),
          ),
          _ToolButton(
            icon: LucideIcons.heading,
            tooltip: 'Heading',
            color: iconColor,
            onTap: () => applyFormat(controller, 'heading'),
          ),
          _ToolButton(
            icon: LucideIcons.list,
            tooltip: 'Bullet List',
            color: iconColor,
            onTap: () => applyFormat(controller, 'bullet'),
          ),
          _ToolButton(
            icon: LucideIcons.listOrdered,
            tooltip: 'Numbered List',
            color: iconColor,
            onTap: () => applyFormat(controller, 'numbered'),
          ),
          _ToolButton(
            icon: LucideIcons.quote,
            tooltip: 'Blockquote',
            color: iconColor,
            onTap: () => applyFormat(controller, 'quote'),
          ),
          _ToolButton(
            icon: LucideIcons.code,
            tooltip: 'Inline / Block Code',
            color: iconColor,
            onTap: () => applyFormat(controller, 'code'),
          ),
          _ToolButton(
            icon: LucideIcons.link2,
            tooltip: 'Link',
            color: iconColor,
            onTap: () => applyFormat(controller, 'link'),
          ),
          if (onAttachImage != null)
            _ToolButton(
              icon: LucideIcons.image,
              tooltip: 'Attach Image',
              color: iconColor,
              onTap: onAttachImage!,
            ),
          if (onVoiceDictate != null)
            _ToolButton(
              icon: LucideIcons.mic,
              tooltip: 'Dictate Speech',
              color: const Color(0xFFD9725B),
              onTap: onVoiceDictate!,
            ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }
}
