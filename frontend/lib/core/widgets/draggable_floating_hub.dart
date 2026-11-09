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
import '../state/sanctuary_state.dart';
import '../utils/date_labels.dart';
import 'voice_studio_modal.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';

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

  String _generateDynamicSuggestion() {
    final settings = ref.read(appSettingsProvider);
    final name = settings.displayName.trim().isNotEmpty ? settings.displayName.trim() : 'Curator';
    final tasks = ref.read(tasksProvider);
    final habits = ref.read(habitsProvider);
    final now = DateTime.now();

    final overdue = tasks.where((t) => !t.completed && t.isOverdue(now)).toList();
    if (overdue.isNotEmpty) {
      final taskTitle = overdue.first.title.length <= 22 ? overdue.first.title : '${overdue.first.title.substring(0, 22)}...';
      return '$name, you have an overdue task: "$taskTitle". Shall we conquer it?';
    }

    final pendingHabits = habits.where((h) => !h.completedToday).toList();
    if (pendingHabits.isNotEmpty && settings.activeStreak > 0) {
      final habitTitle = pendingHabits.first.title.length <= 20 ? pendingHabits.first.title : '${pendingHabits.first.title.substring(0, 20)}...';
      return '$name, your ${settings.activeStreak}d streak is on the line! Care to complete "$habitTitle"?';
    }

    final urgentTasks = tasks.where((t) => !t.completed && (t.priority.toLowerCase() == 'urgent' || t.priority.toLowerCase() == 'high')).toList();
    if (urgentTasks.isNotEmpty) {
      final taskTitle = urgentTasks.first.title.length <= 22 ? urgentTasks.first.title : '${urgentTasks.first.title.substring(0, 22)}...';
      return '$name, top priority: "$taskTitle". Ready to focus together?';
    }

    if (now.hour >= 20) {
      return 'Good evening, $name. How was your day? Ready to write an evening reflection?';
    }

    if (now.hour < 11) {
      return 'Good morning, $name! Shall we map out your key commitments for today?';
    }

    const fallbacks = [
      'Do you want to review your top priority task for today?',
      'Do you want to log a quick expense or check your budget?',
      'Would you like to write a quick reflection in your journal?',
      'Should we start a 25-minute focus session together?',
    ];
    final rand = Random();
    return fallbacks[rand.nextInt(fallbacks.length)];
  }

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

      setState(() {
        _currentSuggestion = _generateDynamicSuggestion();
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

    final media = MediaQuery.of(context);
    final screenSize = media.size;
    final padding = media.padding;

    final aiPos = _aiPosition ?? const Offset(200, 500);
    final voicePos = _voicePosition ?? const Offset(280, 560);

    // Compute screen-safe positioning for proactive speech bubble
    final double bubbleWidth = min(280.0, max(180.0, screenSize.width - 32.0));
    final double preferredLeft = aiPos.dx + 29.0 - (bubbleWidth / 2.0);
    final double maxLeft = max(16.0, screenSize.width - bubbleWidth - 16.0);
    final double bubbleLeft = preferredLeft.clamp(16.0, maxLeft);

    final bool isNearTop = aiPos.dy < (padding.top + 95.0);
    final double bubbleTop = isNearTop
        ? (aiPos.dy + 66.0).clamp(padding.top + 10.0, screenSize.height - 120.0)
        : (aiPos.dy - 74.0).clamp(padding.top + 10.0, screenSize.height - 120.0);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 1. PROACTIVE SUGGESTION SPEECH BUBBLE (CLAMPS SAFELY TO SCREEN BOUNDS)
        if (_currentSuggestion != null)
          Positioned(
            left: bubbleLeft,
            top: bubbleTop,
            child: AnimatedOpacity(
              opacity: _currentSuggestion != null ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: bubbleWidth,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: edBox(
                    color: isDark ? const Color(0xFF1E1A17) : const Color(0xFFFFFDF8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.6),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      SanctuaryHapticEngine.nodoTap();
                      widget.onOpenAi();
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.sparkles, size: 14, color: accentColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _currentSuggestion!,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                              color: isDark ? const Color(0xFFF5F2EB) : const Color(0xFF1B1917),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(() => _currentSuggestion = null),
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Icon(
                              LucideIcons.x,
                              size: 13,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

        // 2. ANIMATED ROAMING "NODO" AI COMPANION (58x58 ORB)
        Positioned(
          left: aiPos.dx,
          top: aiPos.dy,
          child: GestureDetector(
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
                decoration: edBox(
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
                            decoration: edBox(
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
                            decoration: edBox(
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
                                fontSize: 11,
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
          ),

        // 3. DRAGGABLE FLOATING VOICE ASSISTANT DIAL
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
                decoration: edBox(
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
                      decoration: edBox(
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
                      decoration: edBox(
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
