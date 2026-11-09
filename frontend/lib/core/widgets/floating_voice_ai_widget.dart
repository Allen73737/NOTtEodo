import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/theme/app_colors.dart';
import '../platform/browser_bridge.dart';
import '../services/nlp_date_parser.dart';
import '../utils/date_labels.dart';
import 'voice_studio_modal.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';

/// Strips date/time words so "call mom tomorrow at 5pm" becomes the title "Call mom".
String quickCaptureTitle(String text) {
  var t = ' ${text.trim()} ';
  for (final p in [
    RegExp(r'\b(remind me to|add task|add a task|task:?)\s+', caseSensitive: false),
    RegExp(r'\b(at|on|by)?\s*\d{1,2}(:\d{2})?\s?(am|pm)\b', caseSensitive: false),
    RegExp(r'\b(at|on|by)?\s*\d{1,2}:\d{2}\b', caseSensitive: false),
    RegExp(r'\bin \d+ ?(min|minute|minutes|h|hr|hrs|hour|hours|d|day|days|w|week|weeks)\b', caseSensitive: false),
    RegExp(r'\b(on|by|next)?\s*(today|tonight|tomorrow|tmrw|tmr|this evening|noon|midnight|morning|afternoon|evening)\b', caseSensitive: false),
    RegExp(r'\b(on|by|next)?\s*(mon|tue|wed|thu|fri|sat|sun)[a-z]*\b', caseSensitive: false),
  ]) {
    t = t.replaceAll(p, ' ');
  }
  t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
  return t.isEmpty ? text.trim() : '${t[0].toUpperCase()}${t.substring(1)}';
}

/// Floating quick-capture button: type or dictate a task with its due time in plain words.
class FloatingVoiceAiWidget extends ConsumerStatefulWidget {
  final double bottom;
  final double right;
  final double size;

  const FloatingVoiceAiWidget({
    super.key,
    this.bottom = 24,
    this.right = 20,
    this.size = 52,
  });

  @override
  ConsumerState<FloatingVoiceAiWidget> createState() => _FloatingVoiceAiWidgetState();
}

class _FloatingVoiceAiWidgetState extends ConsumerState<FloatingVoiceAiWidget> {
  Future<void> _openCapture() async {
    HapticFeedback.mediumImpact();
    await VoiceStudioModal.show(context, ref);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF000000) : AppColors.primary;

    return Positioned(
      bottom: widget.bottom,
      right: widget.right,
      child: RepaintBoundary(
        child: Tooltip(
          message: 'Quick capture',
          child: Semantics(
            button: true,
            label: 'Quick capture a task',
            child: GestureDetector(
              onTap: _openCapture,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: edBox(
                  shape: BoxShape.circle,
                  color: primaryColor,
                  border: Border.all(
                    color: isDark ? const Color(0xFF262626) : Colors.white.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(LucideIcons.zap, color: Colors.white, size: widget.size * 0.42),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickCaptureDialog extends StatefulWidget {
  const _QuickCaptureDialog();

  @override
  State<_QuickCaptureDialog> createState() => _QuickCaptureDialogState();
}

class _QuickCaptureDialogState extends State<_QuickCaptureDialog> {
  final _ctrl = TextEditingController();
  bool _listening = false;
  DateTime? _preview;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _dictate() async {
    setState(() => _listening = true);
    final heard = await listenOnce();
    if (!mounted) return;
    setState(() {
      _listening = false;
      if (heard != null && heard.isNotEmpty) {
        _ctrl.text = heard;
        _preview = NlpDateParser.tryParse(heard);
      }
    });
    if (heard == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Didn\'t catch that. Try again or type it.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _ctrl.text.trim().isEmpty ? '' : quickCaptureTitle(_ctrl.text);
    return AlertDialog(
      title: const Text('Quick capture'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _ctrl,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: 'e.g. Call mom tomorrow 5pm',
                suffixIcon: speechRecognitionSupported
                    ? IconButton(
                        tooltip: _listening ? 'Listening…' : 'Dictate',
                        icon: Icon(_listening ? LucideIcons.mic : LucideIcons.micOff,
                            color: _listening ? AppColors.secondary : null),
                        onPressed: _listening ? null : _dictate,
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _preview = NlpDateParser.tryParse(v)),
              onSubmitted: (v) => Navigator.pop(context, v),
            ),
            const SizedBox(height: 10),
            if (title.isNotEmpty)
              Text(
                _preview == null ? 'Task: "$title" (no due date)' : 'Task: "$title" · due ${DateLabels.dateTime(_preview!)}',
                style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.onSurfaceVariant),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, _ctrl.text), child: const Text('Add task')),
      ],
    );
  }
}
