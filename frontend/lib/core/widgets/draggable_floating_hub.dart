import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'nodo_avatar_widget.dart';
import '../../app/theme/app_colors.dart';
import '../performance/sanctuary_motion_engine.dart';
import '../platform/browser_bridge.dart';
import '../services/nlp_date_parser.dart';
import '../state/app_settings.dart';
import '../utils/date_labels.dart';
import 'voice_studio_modal.dart';

/// Draggable, roaming interactive hub providing:
/// 1. "Nodo": Animated AI Assistant companion with NOTtEodo N monogram & neural pulse,
///    which roams organically across the screen offering proactive, helpful suggestions.
/// 2. Floating Voice Assistant dial for instant speech dictation and quick capture.
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

class _DraggableFloatingHubState extends ConsumerState<DraggableFloatingHub>
    with TickerProviderStateMixin {
  // Positions for the two floating elements
  Offset? _aiPosition;
  Offset? _voicePosition;
  bool _isDraggingAi = false;
  bool _isDraggingVoice = false;

  // Animation Controllers for Nodo
  late AnimationController _orbitController;
  late AnimationController _pulseController;
  late AnimationController _walkBobController;

  // Roaming & proactive suggestions
  Timer? _roamingTimer;
  Timer? _suggestionTimer;
  String? _currentSuggestion;
  final bool _isRoamingMoving = false;

  static const List<String> _nodoSuggestions = [
    'Do you want to review your top priority task for today?',
    'Do you want to log a quick expense or check your budget?',
    'Would you like to write a quick reflection in your journal?',
    'Do you want to check off a habit and protect your streak?',
    'Should we start a 25-minute focus session together?',
    'Need help prioritizing your afternoon commitments?',
  ];

  @override
  void initState() {
    super.initState();

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _walkBobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Keep Nodo docked and calm - no unprompted roaming
    _startSuggestionCycle();
  }

  @override
  void dispose() {
    _roamingTimer?.cancel();
    _suggestionTimer?.cancel();
    _orbitController.dispose();
    _pulseController.dispose();
    _walkBobController.dispose();
    super.dispose();
  }

  void _startSuggestionCycle() {
    _suggestionTimer?.cancel();
    // Show an interactive question every 28 seconds
    _suggestionTimer = Timer.periodic(const Duration(seconds: 28), (_) {
      if (!mounted) return;
      final settings = ref.read(appSettingsProvider);
      if (!settings.nodoCompanionEnabled) return;

      final rand = Random();
      setState(() {
        _currentSuggestion = _nodoSuggestions[rand.nextInt(_nodoSuggestions.length)];
      });

      // Auto dismiss bubble after 8 seconds
      Timer(const Duration(seconds: 8), () {
        if (mounted && _currentSuggestion != null) {
          setState(() => _currentSuggestion = null);
        }
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    // Default positions: bottom right, above bottom dock
    if (_aiPosition == null) {
      final defaultBottom = widget.isMobile ? 136.0 : 88.0;
      const defaultRight = 18.0;
      _aiPosition = Offset(
        size.width - 64 - defaultRight,
        size.height - defaultBottom - 64 - padding.bottom,
      );
    }

    if (_voicePosition == null) {
      final defaultBottom = widget.isMobile ? 76.0 : 24.0;
      const defaultRight = 20.0;
      _voicePosition = Offset(
        size.width - 50 - defaultRight,
        size.height - defaultBottom - 50 - padding.bottom,
      );
    }
  }

  Offset _clampPosition(Offset target, Size itemSize) {
    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    const minX = 12.0;
    final maxX = max(minX, screenSize.width - itemSize.width - 12.0);
    final minY = padding.top + 48.0;
    final maxY = max(minY, screenSize.height - itemSize.height - padding.bottom - 60.0);

    return Offset(
      target.dx.clamp(minX, maxX),
      target.dy.clamp(minY, maxY),
    );
  }

  Future<void> _triggerVoiceCapture() async {
    SanctuaryHapticEngine.dialDetent();
    await VoiceStudioModal.show(
      context,
      ref,
      onOpenAi: widget.onOpenAi,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? const Color(0xFFE8927C) : AppColors.secondary;

    final aiPos = _aiPosition ?? const Offset(200, 500);
    final voicePos = _voicePosition ?? const Offset(280, 560);

    return Stack(
      children: [
        // 1. ANIMATED ROAMING "NODO" AI COMPANION
        Positioned(
          left: aiPos.dx,
          top: aiPos.dy,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Proactive Suggestion Speech Bubble
              if (_currentSuggestion != null) ...[
                AnimatedOpacity(
                  opacity: _currentSuggestion != null ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    constraints: const BoxConstraints(maxWidth: 220),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1A17) : const Color(0xFFFFFDF8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.5),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: InkWell(
                      onTap: () {
                        SanctuaryHapticEngine.nodoTap();
                        widget.onOpenAi();
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.sparkles, size: 12, color: accentColor),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _currentSuggestion!,
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFFF5F2EB) : const Color(0xFF1B1917),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => setState(() => _currentSuggestion = null),
                            child: Icon(
                              LucideIcons.x,
                              size: 11,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              // The Animated Circular Nodo Icon
              GestureDetector(
                onPanStart: (_) {
                  setState(() {
                    _isDraggingAi = true;
                    _currentSuggestion = null;
                  });
                  SanctuaryHapticEngine.selection();
                },
                onPanUpdate: (details) {
                  setState(() {
                    _aiPosition = _clampPosition(
                      aiPos + details.delta,
                      const Size(64, 64),
                    );
                  });
                },
                onPanEnd: (_) {
                  setState(() => _isDraggingAi = false);
                  SanctuaryHapticEngine.selection();
                },
                onTap: () {
                  if (!_isDraggingAi) {
                    SanctuaryHapticEngine.nodoTap();
                    widget.onOpenAi();
                  }
                },
                child: AnimatedBuilder(
                  animation: Listenable.merge([_pulseController, _orbitController, _walkBobController]),
                  builder: (context, child) {
                    final pulse = 0.96 + 0.08 * _pulseController.value;
                    final bobY = _isRoamingMoving ? sin(_walkBobController.value * pi * 2) * 3.5 : 0.0;

                    return Transform.translate(
                      offset: Offset(0, bobY),
                      child: Transform.scale(
                        scale: _isDraggingAi ? 1.12 : pulse,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: isDark ? 0.45 : 0.22),
                          blurRadius: _isDraggingAi ? 24 : 14,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Animated Neural Orbit Ring
                        RotationTransition(
                          turns: _orbitController,
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: accentColor.withValues(alpha: 0.35),
                                width: 1.2,
                                strokeAlign: BorderSide.strokeAlignOutside,
                              ),
                            ),
                          ),
                        ),

                        // Core Animated Nodo Avatar
                        NodoAvatarWidget(
                          size: 48,
                          emotion: _isRoamingMoving
                              ? NodoEmotion.thinking
                              : (ref.watch(appSettingsProvider).aiPersona == 'sarcastic'
                                  ? NodoEmotion.sarcastic
                                  : NodoEmotion.neutral),
                        ),

                        // Mini "NODO" pill badge underneath
                        Positioned(
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E1A17) : const Color(0xFF2C2520),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: accentColor.withValues(alpha: 0.6),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              'NODO',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 7.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.1,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 2. DRAGGABLE FLOATING VOICE ASSISTANT DIAL
        Positioned(
          left: voicePos.dx,
          top: voicePos.dy,
          child: GestureDetector(
            onPanStart: (_) {
              setState(() => _isDraggingVoice = true);
              SanctuaryHapticEngine.selection();
            },
            onPanUpdate: (details) {
              setState(() {
                _voicePosition = _clampPosition(
                  voicePos + details.delta,
                  const Size(50, 50),
                );
              });
            },
            onPanEnd: (_) {
              setState(() => _isDraggingVoice = false);
              SanctuaryHapticEngine.selection();
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
                width: 50,
                height: 50,
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
                    Container(
                      width: 36,
                      height: 36,
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
                      size: 20,
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
