import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme/app_colors.dart';
import '../systems/aesthetic_audio_service.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';

/// A vintage-luxury analogue cassette tape & waveform audio player widget.
/// Built for interactive audio playback in Notes, Journal Reflections, and Editor views.
class AudioCassettePlayer extends StatefulWidget {
  final String title;
  final Duration totalDuration;
  final String? audioPath;
  final VoidCallback? onCompleted;

  const AudioCassettePlayer({
    super.key,
    this.title = 'Voice Note Recording',
    this.totalDuration = const Duration(seconds: 24),
    this.audioPath,
    this.onCompleted,
  });

  /// Factory helper that parses duration from voice note excerpts like "🎙️ (00:18)" or "[01:30]"
  static Duration parseDuration(String text, {Duration fallback = const Duration(seconds: 20)}) {
    final reg = RegExp(r'(\d{1,2}):(\d{2})');
    final match = reg.firstMatch(text);
    if (match != null) {
      final mins = int.tryParse(match.group(1) ?? '0') ?? 0;
      final secs = int.tryParse(match.group(2) ?? '20') ?? 20;
      final total = (mins * 60) + secs;
      if (total > 0) return Duration(seconds: total);
    }
    return fallback;
  }

  @override
  State<AudioCassettePlayer> createState() => _AudioCassettePlayerState();
}

class _AudioCassettePlayerState extends State<AudioCassettePlayer> with TickerProviderStateMixin {
  late final AnimationController _spoolController;
  late final AnimationController _waveController;

  Timer? _progressTimer;
  Duration _currentPosition = Duration.zero;
  bool _isPlaying = false;
  double _playbackSpeed = 1.0;

  static const List<double> _waveformHeights = [
    0.35, 0.65, 0.90, 0.45, 0.75, 0.55, 0.85, 1.0, 0.60, 0.40,
    0.70, 0.95, 0.50, 0.80, 0.30, 0.65, 0.88, 0.52, 0.72, 0.42,
  ];

  @override
  void initState() {
    super.initState();
    _spoolController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    const MethodChannel('notteodo/voice_recorder').setMethodCallHandler((call) async {
      if (call.method == 'onPlaybackComplete' && mounted) {
        setState(() {
          _isPlaying = false;
          _currentPosition = Duration.zero;
          _spoolController.stop();
          _waveController.stop();
          _progressTimer?.cancel();
        });
        widget.onCompleted?.call();
      }
    });
  }

  @override
  void dispose() {
    try {
      const MethodChannel('notteodo/voice_recorder').invokeMethod('stopPlayback');
    } catch (_) {}
    _spoolController.dispose();
    _waveController.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  void _togglePlayPause() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      _startPlayback();
    } else {
      _pausePlayback();
    }
  }

  void _startPlayback() {
    _spoolController.repeat();
    _waveController.repeat(reverse: true);

    // Subtle audio feedback tone
    AestheticAudioService().playHapticTone(type: 'click');

    // Hardware native audio playback if path is present
    if (widget.audioPath != null && widget.audioPath!.isNotEmpty) {
      try {
        const MethodChannel('notteodo/voice_recorder').invokeMethod('startPlayback', {'path': widget.audioPath});
      } catch (_) {}
    }

    final intervalMs = (100 / _playbackSpeed).round();
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      if (!mounted) return;
      setState(() {
        final nextMs = _currentPosition.inMilliseconds + 100;
        if (nextMs >= widget.totalDuration.inMilliseconds) {
          _currentPosition = Duration.zero;
          _isPlaying = false;
          _spoolController.stop();
          _waveController.stop();
          _progressTimer?.cancel();
          widget.onCompleted?.call();
        } else {
          _currentPosition = Duration(milliseconds: nextMs);
        }
      });
    });
  }

  void _pausePlayback() {
    _spoolController.stop();
    _waveController.stop();
    _progressTimer?.cancel();
    AestheticAudioService().playHapticTone(type: 'soft');
    try {
      const MethodChannel('notteodo/voice_recorder').invokeMethod('stopPlayback');
    } catch (_) {}
  }

  void _seekRelative(int seconds) {
    HapticFeedback.selectionClick();
    setState(() {
      final newSecs = (_currentPosition.inSeconds + seconds).clamp(0, widget.totalDuration.inSeconds);
      _currentPosition = Duration(seconds: newSecs);
    });
  }

  void _toggleSpeed() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_playbackSpeed == 1.0) {
        _playbackSpeed = 1.5;
      } else if (_playbackSpeed == 1.5) {
        _playbackSpeed = 2.0;
      } else {
        _playbackSpeed = 1.0;
      }
    });

    if (_isPlaying) {
      _startPlayback(); // restart timer with new interval
    }
  }

  String _formatMmSs(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    final terracotta = isDark ? const Color(0xFFE8927C) : AppColors.secondary;

    final progressRatio = widget.totalDuration.inMilliseconds > 0
        ? (_currentPosition.inMilliseconds / widget.totalDuration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: edBox(
        color: isDark ? const Color(0xFF141312) : const Color(0xFFFAF7F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF282522) : const Color(0xFFE5DDD0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Cassette Reel Window Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: edBox(
              color: isDark ? const Color(0xFF0C0B0A) : const Color(0xFFEFECE5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF201D1A) : const Color(0xFFDDD5C7),
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                // Left Spool
                _buildRotatingSpool(isLeft: true, isDark: isDark, terracotta: terracotta),
                const SizedBox(width: 10),

                // Center Tape Label & Waveform Window
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.cassetteTape, size: 13, color: terracotta),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              widget.title.toUpperCase(),
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                                color: subtextColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Animated Waveform Bars
                      AnimatedBuilder(
                        animation: _waveController,
                        builder: (context, _) {
                          return SizedBox(
                            height: 22,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: List.generate(_waveformHeights.length, (idx) {
                                final base = _waveformHeights[idx];
                                final animVal = _isPlaying
                                    ? math.sin((_waveController.value * math.pi * 2) + (idx * 0.4)).abs()
                                    : 0.0;
                                final height = (base * 16.0) + (animVal * 6.0);
                                final isPlayed = (idx / _waveformHeights.length) <= progressRatio;

                                return Container(
                                  width: 2.8,
                                  height: math.max(4.0, height),
                                  margin: const EdgeInsets.symmetric(horizontal: 1.2),
                                  decoration: edBox(
                                    color: isPlayed ? terracotta : subtextColor.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                );
                              }),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Right Spool
                _buildRotatingSpool(isLeft: false, isDark: isDark, terracotta: terracotta),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 2. Playback Scrubber & Time
          Row(
            children: [
              Text(
                _formatMmSs(_currentPosition),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: primaryTextColor,
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3.5,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    activeTrackColor: terracotta,
                    inactiveTrackColor: isDark ? const Color(0xFF262320) : const Color(0xFFDDD7CC),
                    thumbColor: terracotta,
                    overlayColor: terracotta.withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    value: progressRatio,
                    onChanged: (val) {
                      setState(() {
                        final totalMs = widget.totalDuration.inMilliseconds;
                        _currentPosition = Duration(milliseconds: (val * totalMs).round());
                      });
                    },
                  ),
                ),
              ),
              Text(
                _formatMmSs(widget.totalDuration),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: subtextColor,
                ),
              ),
            ],
          ),

          // 3. Audio Controls & Speed Switcher
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Speed selector pill
              InkWell(
                onTap: _toggleSpeed,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: edBox(
                    color: isDark ? const Color(0xFF1E1C1A) : const Color(0xFFE9E4DC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2B2824) : const Color(0xFFD6CFC3),
                    ),
                  ),
                  child: Text(
                    '${_playbackSpeed.toStringAsFixed(1)}x',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: terracotta,
                    ),
                  ),
                ),
              ),

              // Player Buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Rewind 5s
                  IconButton(
                    icon: const Icon(LucideIcons.rotateCcw, size: 16),
                    color: subtextColor,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    tooltip: 'Rewind 5s',
                    onPressed: () => _seekRelative(-5),
                  ),
                  const SizedBox(width: 8),

                  // Play / Pause Circle
                  GestureDetector(
                    onTap: _togglePlayPause,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: edBox(
                        shape: BoxShape.circle,
                        color: terracotta,
                        boxShadow: [
                          BoxShadow(
                            color: terracotta.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isPlaying ? LucideIcons.pause : LucideIcons.play,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Forward 5s
                  IconButton(
                    icon: const Icon(LucideIcons.rotateCw, size: 16),
                    color: subtextColor,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    tooltip: 'Forward 5s',
                    onPressed: () => _seekRelative(5),
                  ),
                ],
              ),

              // Mode badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: edBox(
                  color: terracotta.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isPlaying ? LucideIcons.radio : LucideIcons.mic,
                      size: 11,
                      color: terracotta,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isPlaying ? 'PLAYING' : 'AUDIO MEMO',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: terracotta,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRotatingSpool({
    required bool isLeft,
    required bool isDark,
    required Color terracotta,
  }) {
    return AnimatedBuilder(
      animation: _spoolController,
      builder: (context, _) {
        final rotation = _spoolController.value * 2 * math.pi;
        return Transform.rotate(
          angle: rotation,
          child: Container(
            width: 28,
            height: 28,
            decoration: edBox(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF1E1C1A) : const Color(0xFFDDD8CE),
              border: Border.all(
                color: _isPlaying ? terracotta : (isDark ? const Color(0xFF38332E) : const Color(0xFFC7C0B2)),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: edBox(
                      shape: BoxShape.circle,
                      color: isDark ? const Color(0xFF0C0B0A) : const Color(0xFFFAF7F2),
                    ),
                  ),
                  // Spool teeth/spokes
                  for (int i = 0; i < 3; i++)
                    Transform.rotate(
                      angle: (i * math.pi / 3),
                      child: Container(
                        width: 1.5,
                        height: 20,
                        color: isDark ? const Color(0xFF38332E) : const Color(0xFFB5AE9F),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

