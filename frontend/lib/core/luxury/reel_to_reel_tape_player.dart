import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Soundwave Ribbon Tape Player for Acoustic Memoirs
/// Renders vintage reel-to-reel magnetic tape spools that spin with physical inertia
/// accompanied by an analog needle VU meter.
class ReelToReelTapePlayer extends StatefulWidget {
  final String title;
  final String durationText;
  final bool isPlaying;
  final VoidCallback onTogglePlay;

  const ReelToReelTapePlayer({
    super.key,
    required this.title,
    this.durationText = '03:42',
    required this.isPlaying,
    required this.onTogglePlay,
  });

  @override
  State<ReelToReelTapePlayer> createState() => _ReelToReelTapePlayerState();
}

class _ReelToReelTapePlayerState extends State<ReelToReelTapePlayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _spoolController;

  @override
  void initState() {
    super.initState();
    _spoolController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    if (widget.isPlaying) _spoolController.repeat();
  }

  @override
  void didUpdateWidget(covariant ReelToReelTapePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _spoolController.repeat();
    } else if (!widget.isPlaying && oldWidget.isPlaying) {
      _spoolController.stop();
    }
  }

  @override
  void dispose() {
    _spoolController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const goldColor = Color(0xFFEAB368);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131316) : const Color(0xFFF7F3EB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: goldColor.withValues(alpha: 0.35), width: 1.2),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 14, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title.toUpperCase(),
                style: GoogleFonts.dmSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: goldColor,
                ),
              ),
              Text(
                widget.durationText,
                style: GoogleFonts.courierPrime(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Dual Spool Reel Chamber
          SizedBox(
            height: 90,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Left Spool (Source Tape)
                AnimatedBuilder(
                  animation: _spoolController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: -_spoolController.value * 2 * pi,
                      child: _buildTapeSpool(radius: 34, tapeFill: 0.7),
                    );
                  },
                ),

                // Center Analog VU Needle Meter
                _buildAnalogVUMeter(isDark),

                // Right Spool (Takeup Tape)
                AnimatedBuilder(
                  animation: _spoolController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: -_spoolController.value * 2 * pi,
                      child: _buildTapeSpool(radius: 34, tapeFill: 0.4),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Play / Pause Master Button
          IconButton(
            icon: Icon(
              widget.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
              size: 38,
              color: goldColor,
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              widget.onTogglePlay();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTapeSpool({required double radius, required double tapeFill}) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF2A1C12), // Magnetic Brown Tape Pack
        border: Border.all(color: const Color(0xFFC0C5CC), width: 2.0),
      ),
      child: Center(
        child: Container(
          width: radius * 0.7,
          height: radius * 0.7,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFE2E4E8),
          ),
          child: const Icon(Icons.star, size: 14, color: Color(0xFF555B66)),
        ),
      ),
    );
  }

  Widget _buildAnalogVUMeter(bool isDark) {
    return Container(
      width: 54,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7EA),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black45, width: 1.0),
      ),
      child: Center(
        child: Text(
          'VU -3dB',
          style: GoogleFonts.courierPrime(
            fontSize: 8.5,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
