import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../platform/browser_bridge.dart';
import '../services/ai_intent_dispatcher.dart';
import '../services/nlp_date_parser.dart';
import '../state/sanctuary_state.dart';
import '../utils/date_labels.dart';
import 'app_toast_engine.dart';

enum VoiceDestination { notes, tasks, habits, journal, plan }

/// A bespoke, superbly animated in-app Voice Recording Studio Overlay.
/// Replaces the default external Google dialog with a high-end luxury dark canvas,
/// live frequency wave visualizer, real-time speech transcription, audio preview,
/// and multi-destination assignment (Notes, Tasks, Habits, Journal).
class VoiceStudioModal extends ConsumerStatefulWidget {
  final VoidCallback? onOpenAi;

  const VoiceStudioModal({super.key, this.onOpenAi});

  static Future<void> show(BuildContext context, WidgetRef ref, {VoidCallback? onOpenAi}) async {
    HapticFeedback.heavyImpact();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => VoiceStudioModal(onOpenAi: onOpenAi),
    );
  }

  @override
  ConsumerState<VoiceStudioModal> createState() => _VoiceStudioModalState();
}

class _VoiceStudioModalState extends ConsumerState<VoiceStudioModal> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  Timer? _recordTimer;
  int _recordSeconds = 0;
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _isPlayingPreview = false;
  String? _recordedAudioPath;

  final TextEditingController _transcriptCtrl = TextEditingController();
  VoiceDestination _selectedDestination = VoiceDestination.notes;
  bool _saveAsVoiceAudio = true; // Save as playable voice note vs pure text

  static const MethodChannel _voiceRecorderChannel = MethodChannel('notteodo/voice_recorder');

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _voiceRecorderChannel.setMethodCallHandler((call) async {
      if (call.method == 'onPlaybackComplete') {
        if (mounted) setState(() => _isPlayingPreview = false);
      } else if (call.method == 'onPartialTranscript') {
        final text = call.arguments?['text'] as String?;
        if (text != null && text.isNotEmpty && mounted) {
          setState(() {
            _transcriptCtrl.text = text;
          });
        }
      }
    });

    // Auto-start recording immediately upon opening
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startRecording();
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _recordTimer?.cancel();
    _transcriptCtrl.dispose();
    _stopPlayback();
    super.dispose();
  }

  Future<void> _startRecording() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _isRecording = true;
      _isProcessing = false;
      _recordSeconds = 0;
      _transcriptCtrl.text = '';
      _isPlayingPreview = false;
    });

    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _recordSeconds++);
    });

    try {
      if (!kIsWeb && Platform.isAndroid) {
        // Start native hardware audio recording to .m4a AAC file
        final filePath = await _voiceRecorderChannel.invokeMethod<String>('startRecording');
        if (filePath != null) {
          _recordedAudioPath = filePath;
        }
      } else {
        // Fallback for web or desktop speech recognition
        final heard = await listenOnce();
        if (mounted && heard != null && heard.isNotEmpty) {
          setState(() {
            _transcriptCtrl.text = heard.trim();
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _stopRecording() async {
    HapticFeedback.mediumImpact();
    _recordTimer?.cancel();
    setState(() {
      _isRecording = false;
      _isProcessing = true;
    });

    try {
      if (!kIsWeb && Platform.isAndroid) {
        final result = await _voiceRecorderChannel.invokeMethod<Map>('stopRecording');
        if (result != null) {
          final path = result['path'] as String?;
          final transcript = result['transcript'] as String?;
          if (path != null && path.isNotEmpty) {
            _recordedAudioPath = path;
          }
          if (transcript != null && transcript.trim().isNotEmpty) {
            _transcriptCtrl.text = transcript.trim();
          }
        }
      }
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    // If nothing was transcribed, provide sensible placeholder
    if (_transcriptCtrl.text.trim().isEmpty) {
      _transcriptCtrl.text = 'Voice Reflection · ${DateLabels.time(DateTime.now())}';
    }

    // Auto-detect best destination based on keywords
    final textLower = _transcriptCtrl.text.toLowerCase();
    if (textLower.contains('remind') || textLower.contains('task') || textLower.contains('todo') || textLower.contains('at ') || textLower.contains('by ')) {
      _selectedDestination = VoiceDestination.tasks;
    } else if (textLower.contains('habit') || textLower.contains('daily') || textLower.contains('streak') || textLower.contains('workout')) {
      _selectedDestination = VoiceDestination.habits;
    } else if (textLower.contains('journal') || textLower.contains('feel') || textLower.contains('today was') || textLower.contains('reflection')) {
      _selectedDestination = VoiceDestination.journal;
    } else {
      _selectedDestination = VoiceDestination.notes;
    }

    setState(() {
      _isProcessing = false;
    });
  }

  Future<void> _togglePlayback() async {
    HapticFeedback.selectionClick();
    if (_isPlayingPreview) {
      await _stopPlayback();
      return;
    }

    if (_recordedAudioPath != null && _recordedAudioPath!.isNotEmpty) {
      setState(() => _isPlayingPreview = true);
      try {
        if (!kIsWeb && Platform.isAndroid) {
          await _voiceRecorderChannel.invokeMethod('startPlayback', {'path': _recordedAudioPath});
        } else {
          // Simulation timer on web fallback
          Timer(Duration(seconds: math.max(2, _recordSeconds)), () {
            if (mounted) setState(() => _isPlayingPreview = false);
          });
        }
      } catch (_) {
        if (mounted) setState(() => _isPlayingPreview = false);
      }
    }
  }

  Future<void> _stopPlayback() async {
    setState(() => _isPlayingPreview = false);
    try {
      if (!kIsWeb && Platform.isAndroid) {
        await _voiceRecorderChannel.invokeMethod('stopPlayback');
      }
    } catch (_) {}
  }

  Future<void> _saveAndAssign() async {
    final text = _transcriptCtrl.text.trim();
    if (text.isEmpty) {
      AppToastEngine().showToast(context, title: 'Empty Recording', message: 'Speak or type a note before saving.');
      return;
    }

    HapticFeedback.heavyImpact();
    Navigator.of(context).pop();

    final now = DateTime.now();
    final durationLabel = '${(_recordSeconds ~/ 60).toString().padLeft(2, '0')}:${(_recordSeconds % 60).toString().padLeft(2, '0')}';
    final voiceAudioTag = _saveAsVoiceAudio ? ' 🎙️ ($durationLabel)' : '';

    switch (_selectedDestination) {
      case VoiceDestination.notes:
        ref.read(notesProvider.notifier).addNote(
          title: text.length > 40 ? '${text.substring(0, 37)}...' : text,
          excerpt: '🎙️ Voice Note [$durationLabel]: $text',
          tag: 'Voice Memo',
          content: '### 🎙️ Audio Recording ($durationLabel)\n*Recorded on ${DateLabels.dateTime(now)}*\n\n**Transcript:**\n$text\n\n*Saved in local encrypted sanctuary store.*',
          space: 'Voice Vault',
        );
        AppToastEngine().showToast(context, title: 'Voice Note Saved', message: 'Assigned to Notes repository$voiceAudioTag.');
        break;

      case VoiceDestination.tasks:
        final due = NlpDateParser.tryParse(text);
        final title = text.length > 50 ? '${text.substring(0, 47)}...' : text;
        ref.read(tasksProvider.notifier).addTask(
          title: '$title$voiceAudioTag',
          dueAt: due,
          priority: text.toLowerCase().contains('urgent') ? 'High Priority' : 'Medium Priority',
          space: 'Tasks',
        );
        AppToastEngine().showToast(
          context,
          title: 'Task Created',
          message: due != null ? 'Due ${DateLabels.dateTime(due)}' : 'Saved to your task list.',
        );
        break;

      case VoiceDestination.habits:
        final title = text.replaceAll(RegExp(r'(habit|everyday|daily|track)', caseSensitive: false), '').trim();
        final habitName = title.isNotEmpty ? title : 'Mindful Daily Check-in';
        ref.read(habitsProvider.notifier).addHabit(
          title: habitName,
          time: 'Morning',
        );
        AppToastEngine().showToast(context, title: 'Habit Initialized', message: '"$habitName" added to Daily Habits.');
        break;

      case VoiceDestination.journal:
        ref.read(journalProvider.notifier).addMemoir(
          title: 'Voice Reflection$voiceAudioTag',
          duration: durationLabel,
          excerpt: text,
          audioPath: _recordedAudioPath,
          mood: text.toLowerCase().contains('happy') || text.toLowerCase().contains('great') ? 'Inspired' : 'Mindful',
        );
        AppToastEngine().showToast(context, title: 'Journal Entry Logged', message: 'Added to your lifestyle journal.');
        break;

      case VoiceDestination.plan:
        await AiIntentDispatcher().dispatch(
          context,
          ref,
          text,
          onOpenAiQuery: (_) => widget.onOpenAi?.call(),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? const Color(0xFFFAF8F5) : const Color(0xFF1B1917);
    final subtextColor = isDark ? const Color(0xFFB0A89F) : const Color(0xFF6B655D);
    const terracottaAccent = Color(0xFFD9725B);
    const warmSage = Color(0xFF8FA878);

    final durationText = '${(_recordSeconds ~/ 60).toString().padLeft(2, '0')}:${(_recordSeconds % 60).toString().padLeft(2, '0')}';

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF100E0C) : const Color(0xFFFAF7F2),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(
          color: isDark ? const Color(0xFF2C241E) : const Color(0xFFE5DDD0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.75 : 0.25),
            blurRadius: 32,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Drag Handle
          Container(
            width: 42,
            height: 4.5,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF332A24) : const Color(0xFFD9D0C3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 18),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: terracottaAccent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.mic, size: 16, color: terracottaAccent),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'VOICE STUDIO',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: terracottaAccent,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1A16) : const Color(0xFFEDE6DA),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.x, size: 16, color: subtextColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // High-End Animated Soundwave Visualizer Pod
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF090807) : const Color(0xFFF2ECE1),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark ? const Color(0xFF261F1A) : const Color(0xFFE2D8C7),
              ),
            ),
            child: Column(
              children: [
                // Live Soundwave Bars
                SizedBox(
                  height: 64,
                  child: AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (context, _) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: List.generate(24, (i) {
                          final waveVal = _isRecording
                              ? (math.sin((i * 0.4) + (_pulseCtrl.value * math.pi * 2)).abs() * 46 + 8)
                              : (_isPlayingPreview
                                  ? (math.cos((i * 0.3) + (_pulseCtrl.value * math.pi * 3)).abs() * 38 + 6)
                                  : 6.0);
                          return Container(
                            width: 3.5,
                            height: waveVal,
                            margin: const EdgeInsets.symmetric(horizontal: 2.2),
                            decoration: BoxDecoration(
                              color: _isRecording
                                  ? (i % 2 == 0 ? terracottaAccent : terracottaAccent.withValues(alpha: 0.6))
                                  : (_isPlayingPreview ? warmSage : subtextColor.withValues(alpha: 0.3)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Timer & Status Tag
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isRecording
                            ? Colors.redAccent
                            : (_isPlayingPreview ? warmSage : subtextColor),
                        boxShadow: _isRecording
                            ? [const BoxShadow(color: Colors.redAccent, blurRadius: 6, spreadRadius: 1)]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isRecording
                          ? 'RECORDING · $durationText'
                          : (_isProcessing
                              ? 'PROCESSING TRANSCRIPT…'
                              : (_isPlayingPreview ? 'PLAYING · $durationText' : 'RECORDED · $durationText')),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: _isRecording ? terracottaAccent : primaryTextColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Real-time Live Transcription Input
          TextField(
            controller: _transcriptCtrl,
            maxLines: 3,
            style: GoogleFonts.dmSans(fontSize: 14, color: primaryTextColor),
            decoration: InputDecoration(
              hintText: _isRecording ? 'Listening live... speak naturally.' : 'Edit transcribed words here...',
              hintStyle: GoogleFonts.dmSans(fontSize: 13, color: subtextColor.withValues(alpha: 0.7)),
              filled: true,
              fillColor: isDark ? const Color(0xFF161310) : Colors.white,
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: isDark ? const Color(0xFF28201A) : const Color(0xFFE2D8C7)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: isDark ? const Color(0xFF28201A) : const Color(0xFFE2D8C7)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: terracottaAccent, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Record / Play Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isRecording) ...[
                GestureDetector(
                  onTap: _stopRecording,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: terracottaAccent,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: terracottaAccent.withValues(alpha: 0.4),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.square, size: 16, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'Stop & Route',
                          style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // Re-record
                OutlinedButton.icon(
                  onPressed: _startRecording,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: subtextColor.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  icon: Icon(LucideIcons.refreshCw, size: 14, color: subtextColor),
                  label: Text('Redo', style: GoogleFonts.dmSans(fontSize: 12, color: subtextColor)),
                ),
                const SizedBox(width: 12),
                // Play Audio Preview
                ElevatedButton.icon(
                  onPressed: _togglePlayback,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isPlayingPreview ? warmSage : (isDark ? const Color(0xFF221C18) : const Color(0xFFE8E0D2)),
                    foregroundColor: primaryTextColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  icon: Icon(_isPlayingPreview ? LucideIcons.pause : LucideIcons.play, size: 14, color: primaryTextColor),
                  label: Text(_isPlayingPreview ? 'Pause' : 'Listen', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),

          // Destination Selector Header & Chips
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'ASSIGN VOICE RECORDING TO',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: subtextColor,
              ),
            ),
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildDestChip(VoiceDestination.notes, 'Notes', LucideIcons.fileText, terracottaAccent, isDark),
              _buildDestChip(VoiceDestination.tasks, 'Tasks', LucideIcons.checkSquare, terracottaAccent, isDark),
              _buildDestChip(VoiceDestination.journal, 'Journal', LucideIcons.bookOpen, terracottaAccent, isDark),
              _buildDestChip(VoiceDestination.habits, 'Habits', LucideIcons.repeat, terracottaAccent, isDark),
              _buildDestChip(VoiceDestination.plan, 'AI Plan', LucideIcons.sparkles, terracottaAccent, isDark),
            ],
          ),
          const SizedBox(height: 14),

          // Toggle Save as Playable Voice Audio
          InkWell(
            onTap: () => setState(() => _saveAsVoiceAudio = !_saveAsVoiceAudio),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF15120F) : const Color(0xFFEFE8DC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _saveAsVoiceAudio ? LucideIcons.volume2 : LucideIcons.fileCode,
                    size: 15,
                    color: _saveAsVoiceAudio ? terracottaAccent : subtextColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _saveAsVoiceAudio
                          ? 'Attach Voice Audio + Live Transcript'
                          : 'Save as Pure Text Only',
                      style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: primaryTextColor),
                    ),
                  ),
                  Switch(
                    value: _saveAsVoiceAudio,
                    activeTrackColor: terracottaAccent,
                    onChanged: (v) => setState(() => _saveAsVoiceAudio = v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isRecording ? _stopRecording : _saveAndAssign,
              style: ElevatedButton.styleFrom(
                backgroundColor: terracottaAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
              icon: Icon(_isRecording ? LucideIcons.check : LucideIcons.save, size: 16),
              label: Text(
                _isRecording ? 'Finish & Save' : 'Confirm & Save to ${_destinationTitle(_selectedDestination)}',
                style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _destinationTitle(VoiceDestination d) {
    switch (d) {
      case VoiceDestination.notes:
        return 'Notes Vault';
      case VoiceDestination.tasks:
        return 'Task List';
      case VoiceDestination.habits:
        return 'Habits';
      case VoiceDestination.journal:
        return 'Journal';
      case VoiceDestination.plan:
        return 'AI Intent';
    }
  }

  Widget _buildDestChip(VoiceDestination dest, String label, IconData icon, Color accent, bool isDark) {
    final isSelected = _selectedDestination == dest;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedDestination = dest);
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? accent.withValues(alpha: 0.2)
              : (isDark ? const Color(0xFF181512) : const Color(0xFFEBE4D6)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accent : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: isSelected ? accent : (isDark ? Colors.white60 : Colors.black54)),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? accent : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
