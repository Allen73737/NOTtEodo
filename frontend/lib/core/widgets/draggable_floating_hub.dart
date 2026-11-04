import '../services/ai_intent_dispatcher.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/theme/app_colors.dart';
import '../platform/browser_bridge.dart';
import '../services/nlp_date_parser.dart';
import '../utils/date_labels.dart';
import '../performance/sanctuary_motion_engine.dart';

/// Draggable, floating interactive hub providing:
/// 1. A floating, movable Personal AI Assistant button (opens 7-tier Groq AI chatbox)
/// 2. A floating, movable Voice Assistant dial (instant speech dictation & NLP task/note capture)
class DraggableFloatingHub extends ConsumerStatefulWidget {
  final VoidCallback onOpenAi;
  final bool isMobile;

  const DraggableFloatingHub({
    super.key,
    required this.onOpenAi,
    this.isMobile = false,
  });

  @override
  ConsumerState<DraggableFloatingHub> createState() => _DraggableFloatingHubState();
}

class _DraggableFloatingHubState extends ConsumerState<DraggableFloatingHub> {
  // Positions for the two floating elements
  Offset? _aiPosition;
  Offset? _voicePosition;
  bool _isDraggingAi = false;
  bool _isDraggingVoice = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    // Default positions: bottom right, above bottom dock
    if (_aiPosition == null) {
      final defaultBottom = widget.isMobile ? 144.0 : 88.0;
      const defaultRight = 18.0;
      _aiPosition = Offset(
        size.width - 150 - defaultRight,
        size.height - defaultBottom - 48 - padding.bottom,
      );
    }

    if (_voicePosition == null) {
      final defaultBottom = widget.isMobile ? 86.0 : 26.0;
      const defaultRight = 18.0;
      _voicePosition = Offset(
        size.width - 52 - defaultRight,
        size.height - defaultBottom - 52 - padding.bottom,
      );
    }
  }

  Offset _clampPosition(Offset target, Size itemSize) {
    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    const minX = 12.0;
    final maxX = max(minX, screenSize.width - itemSize.width - 12.0);
    final minY = padding.top + 50.0;
    final maxY = max(minY, screenSize.height - itemSize.height - padding.bottom - 70.0);

    return Offset(
      target.dx.clamp(minX, maxX),
      target.dy.clamp(minY, maxY),
    );
  }

  Future<void> _triggerVoiceCapture() async {
    SanctuaryHapticEngine.dialDetent();
    final heard = await listenOnce();
    if (!mounted) return;

    if (heard != null && heard.trim().isNotEmpty) {
      await AiIntentDispatcher().dispatch(
        context,
        ref,
        heard.trim(),
        onOpenAiQuery: (_) => widget.onOpenAi(),
      );
    } else {
      // Fall back to quick capture dialog
      final typed = await showDialog<String>(
        context: context,
        builder: (_) => const QuickCaptureVoiceFallbackDialog(),
      );
      if (typed != null && typed.trim().isNotEmpty && mounted) {
        await AiIntentDispatcher().dispatch(
          context,
          ref,
          typed.trim(),
          onOpenAiQuery: (_) => widget.onOpenAi(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? const Color(0xFFE8927C) : AppColors.secondary;

    final aiPos = _aiPosition ?? const Offset(200, 500);
    final voicePos = _voicePosition ?? const Offset(280, 560);

    return Stack(
      children: [
        // 1. DRAGGABLE FLOATING PERSONAL AI ASSISTANT CHATBOX CAPSULE
        Positioned(
          left: aiPos.dx,
          top: aiPos.dy,
          child: GestureDetector(
            onPanStart: (_) {
              setState(() => _isDraggingAi = true);
              HapticFeedback.selectionClick();
            },
            onPanUpdate: (details) {
              setState(() {
                _aiPosition = _clampPosition(
                  aiPos + details.delta,
                  const Size(146, 44),
                );
              });
            },
            onPanEnd: (_) {
              setState(() => _isDraggingAi = false);
              HapticFeedback.selectionClick();
            },
            onTap: () {
              if (!_isDraggingAi) {
                HapticFeedback.mediumImpact();
                widget.onOpenAi();
              }
            },
            child: AnimatedScale(
              scale: _isDraggingAi ? 1.06 : 1.0,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutCubic,
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0C0A09) : const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2C2520) : const Color(0xFFE6DEC8),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? accentColor : Colors.black).withValues(alpha: isDark ? 0.35 : 0.16),
                      blurRadius: _isDraggingAi ? 24 : 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Glowing Neural Star Icon
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accentColor,
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(LucideIcons.sparkles, size: 14, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Text(
                              'AI ASSISTANT',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                                color: isDark ? const Color(0xFFF5F2EB) : const Color(0xFF1B1917),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF86CBB0),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Groq 7-Tier Cascade',
                          style: GoogleFonts.dmSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFFA6A096) : const Color(0xFF78716C),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      LucideIcons.move,
                      size: 11,
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.25),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // 2. DRAGGABLE FLOATING VOICE ASSISTANT DIAL
        Positioned(
          left: voicePos.dx,
          top: voicePos.dy,
          child: GestureDetector(
            onPanStart: (_) {
              setState(() => _isDraggingVoice = true);
              HapticFeedback.selectionClick();
            },
            onPanUpdate: (details) {
              setState(() {
                _voicePosition = _clampPosition(
                  voicePos + details.delta,
                  const Size(52, 52),
                );
              });
            },
            onPanEnd: (_) {
              setState(() => _isDraggingVoice = false);
              HapticFeedback.selectionClick();
            },
            onTap: () {
              if (!_isDraggingVoice) {
                _triggerVoiceCapture();
              }
            },
            child: AnimatedScale(
              scale: _isDraggingVoice ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutCubic,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF141210) : const Color(0xFF1E1A17),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.75),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: isDark ? 0.45 : 0.22),
                      blurRadius: _isDraggingVoice ? 20 : 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Subtle waveform background rings
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                    ),
                    const Icon(
                      LucideIcons.mic,
                      color: Colors.white,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class QuickCaptureVoiceFallbackDialog extends StatefulWidget {
  const QuickCaptureVoiceFallbackDialog({super.key});

  @override
  State<QuickCaptureVoiceFallbackDialog> createState() => _QuickCaptureVoiceFallbackDialogState();
}

class _QuickCaptureVoiceFallbackDialogState extends State<QuickCaptureVoiceFallbackDialog> {
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
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? const Color(0xFFF5F2EB) : const Color(0xFF1B1917);
    final accentColor = isDark ? const Color(0xFFE8927C) : AppColors.secondary;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF12100E) : const Color(0xFFFAF7F2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isDark ? const Color(0xFF2C2520) : const Color(0xFFE6DEC8),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(LucideIcons.mic, size: 16, color: accentColor),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Voice Capture',
                      style: GoogleFonts.bodoniModa(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _ctrl,
              autofocus: true,
              style: GoogleFonts.dmSans(color: primaryTextColor, fontSize: 14.5),
              decoration: InputDecoration(
                hintText: 'Speak or type: e.g. "Review proposal tomorrow 3pm"',
                hintStyle: GoogleFonts.spectral(fontSize: 13, fontStyle: FontStyle.italic),
                filled: true,
                fillColor: isDark ? const Color(0xFF080706) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: isDark ? const Color(0xFF2A2824) : AppColors.outlineVariant),
                ),
                suffixIcon: IconButton(
                  icon: Icon(_listening ? LucideIcons.radio : LucideIcons.mic, color: accentColor),
                  onPressed: _dictate,
                ),
              ),
              onChanged: (val) {
                setState(() => _preview = NlpDateParser.tryParse(val));
              },
              onSubmitted: (val) => Navigator.pop(context, val),
            ),
            if (_preview != null) ...[
              const SizedBox(height: 8),
              Text(
                'Detected due date: ${DateLabels.dateTime(_preview!)}',
                style: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFF86CBB0), fontWeight: FontWeight.bold),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, _ctrl.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF1E1A17) : AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Capture Task', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

