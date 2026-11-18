import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../performance/sanctuary_motion_engine.dart';
import 'app_toast_engine.dart';
import '../state/sanctuary_state.dart';

class SharedContentDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> sharedData;

  const SharedContentDialog({super.key, required this.sharedData});

  static Future<void> show(BuildContext context, Map<String, dynamic> sharedData) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SharedContentDialog(sharedData: sharedData),
    );
  }

  @override
  ConsumerState<SharedContentDialog> createState() => _SharedContentDialogState();
}

class _SharedContentDialogState extends ConsumerState<SharedContentDialog> {
  late final String _text;
  late final String _subject;
  late final String? _uri;
  late final List<String> _uris;

  @override
  void initState() {
    super.initState();
    _text = (widget.sharedData['text'] as String? ?? '').trim();
    _subject = (widget.sharedData['subject'] as String? ?? '').trim();
    _uri = widget.sharedData['uri'] as String?;
    _uris = (widget.sharedData['uris'] as List?)?.map((e) => e.toString()).toList() ??
        (_uri != null ? [_uri] : const []);
  }

  void _saveToNotes() {
    SanctuaryHapticEngine.selection();
    final title = _subject.isNotEmpty
        ? _subject
        : (_text.isNotEmpty ? _text.split('\n').first : 'Shared Note');
    final content = _uris.isNotEmpty
        ? '$_text\n\n${_uris.map((u) => '![Shared Media]($u)').join('\n')}'
        : _text;

    ref.read(notesProvider.notifier).addNote(
          title: title.length > 60 ? '${title.substring(0, 57)}...' : title,
          space: 'General Space',
          tag: 'Shared',
          excerpt: _text.isNotEmpty ? _text : 'Shared content from external app',
          content: content,
          coverUrl: _uris.isNotEmpty ? _uris.first : null,
        );

    AppToastEngine().notify(
      title: 'Saved to Notes',
      message: 'Created note "$title"',
    );
    Navigator.of(context).pop();
  }

  void _addToTasks() {
    SanctuaryHapticEngine.selection();
    final title = _text.isNotEmpty ? _text : (_subject.isNotEmpty ? _subject : 'Shared Task');
    ref.read(tasksProvider.notifier).addTask(
          title: title.length > 80 ? '${title.substring(0, 77)}...' : title,
          space: 'General Space',
          priority: 'Medium Priority',
        );

    AppToastEngine().notify(
      title: 'Added to Tasks',
      message: 'Created task "$title"',
    );
    Navigator.of(context).pop();
  }

  void _pinToMoodboard() {
    SanctuaryHapticEngine.selection();
    final title = _subject.isNotEmpty ? _subject : (_text.isNotEmpty ? _text : 'Shared Inspiration');
    final imageUrl = _uris.isNotEmpty ? _uris.first : '';

    ref.read(moodboardProvider.notifier).addPin(
          title: title.length > 50 ? '${title.substring(0, 47)}...' : title,
          imageUrl: imageUrl,
          note: 'Shared inspiration',
        );

    AppToastEngine().notify(
      title: 'Pinned to Moodboard',
      message: 'Added new visual inspiration',
    );
    Navigator.of(context).pop();
  }

  void _addToJournal() {
    SanctuaryHapticEngine.selection();
    final title = _subject.isNotEmpty ? _subject : 'Shared Reflection';
    ref.read(journalProvider.notifier).addMemoir(
          title: title,
          excerpt: _text.isNotEmpty ? _text : 'Captured from external application',
          mood: 'Reflective',
        );

    AppToastEngine().notify(
      title: 'Added to Journal',
      message: 'Reflection recorded',
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F0E0D) : const Color(0xFFF7F3EE);
    final cardBg = isDark ? const Color(0xFF1B1816) : Colors.white;
    final textColor = isDark ? const Color(0xFFF5EFEB) : const Color(0xFF1A1817);
    final subtextColor = isDark ? const Color(0xFF9E958E) : const Color(0xFF7A7067);
    final border = isDark ? const Color(0xFF2E2723) : const Color(0xFFE8DFD7);
    const terracotta = Color(0xFF8E2433);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: subtextColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF181414) : const Color(0xFFF2ECE6)),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.share2, size: 18, color: terracotta),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Share to NOTtEodo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Choose a destination for this content',
                      style: TextStyle(fontSize: 13, color: subtextColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Preview Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                if (_uris.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _uris.first.startsWith('http')
                        ? Image.network(
                            _uris.first,
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(LucideIcons.image, size: 28),
                          )
                        : (_uris.first.startsWith('content://') || _uris.first.startsWith('file://'))
                            ? Container(
                                width: 52,
                                height: 52,
                                color: terracotta.withValues(alpha: 0.1),
                                child: const Icon(LucideIcons.image, color: terracotta, size: 24),
                              )
                            : Image.file(
                                File(_uris.first),
                                width: 52,
                                height: 52,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(LucideIcons.image, size: 28),
                              ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_subject.isNotEmpty)
                        Text(
                          _subject,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      Text(
                        _text.isNotEmpty ? _text : (_uris.isNotEmpty ? '${_uris.length} shared media file(s)' : 'Shared item'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: subtextColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Action Options Grid
          _ShareOptionTile(
            icon: LucideIcons.fileText,
            title: 'Save to Notes',
            subtitle: 'Format as reference note with rich content',
            color: const Color(0xFF8E2433),
            onTap: _saveToNotes,
          ),
          const SizedBox(height: 8),
          _ShareOptionTile(
            icon: LucideIcons.checkSquare,
            title: 'Add to Tasks',
            subtitle: 'Create a new action item in your queue',
            color: const Color(0xFF4A90E2),
            onTap: _addToTasks,
          ),
          const SizedBox(height: 8),
          _ShareOptionTile(
            icon: LucideIcons.image,
            title: 'Pin to Moodboard',
            subtitle: 'Add to visual inspiration board',
            color: const Color(0xFF9B51E0),
            onTap: _pinToMoodboard,
          ),
          const SizedBox(height: 8),
          _ShareOptionTile(
            icon: LucideIcons.bookOpen,
            title: 'Add to Journal',
            subtitle: 'Reflect and capture into personal diary',
            color: const Color(0xFF27AE60),
            onTap: _addToJournal,
          ),
        ],
      ),
    );
  }
}

class _ShareOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ShareOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1B1816) : Colors.white;
    final textColor = isDark ? const Color(0xFFF5EFEB) : const Color(0xFF1A1817);
    final subtextColor = isDark ? const Color(0xFF9E958E) : const Color(0xFF7A7067);

    return Material(
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF181414) : const Color(0xFFF2ECE6)),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: subtextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, size: 18, color: subtextColor),
            ],
          ),
        ),
      ),
    );
  }
}
