import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../app/theme/app_colors.dart';

class FloatingVoiceAiWidget extends StatefulWidget {
  const FloatingVoiceAiWidget({super.key});

  @override
  State<FloatingVoiceAiWidget> createState() => _FloatingVoiceAiWidgetState();
}

class _FloatingVoiceAiWidgetState extends State<FloatingVoiceAiWidget> with SingleTickerProviderStateMixin {
  bool _isListening = false;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  void _toggleListening() {
    setState(() {
      _isListening = !_isListening;
    });

    if (_isListening) {
      _waveController.repeat(reverse: true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 4),
          content: Row(
            children: [
              const Icon(LucideIcons.mic, color: AppColors.secondary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text('🎙️ Listening... Speak naturally: "Add task review subnetting tomorrow at 5 PM"', style: GoogleFonts.dmSans(color: Colors.white, fontSize: 12)),
              ),
            ],
          ),
        ),
      );
    } else {
      _waveController.stop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.primary,
          content: Text('✨ Voice parsed: "Review Subnetting" scheduled for tomorrow!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 100,
      right: 20,
      child: GestureDetector(
        onTap: _toggleListening,
        child: AnimatedBuilder(
          animation: _waveController,
          builder: (context, child) {
            final waveValue = _isListening ? _waveController.value : 0.0;
            return Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isListening ? AppColors.secondary : AppColors.primary,
                boxShadow: [
                  BoxShadow(
                    color: (_isListening ? AppColors.secondary : AppColors.primary).withValues(alpha: 0.4 + waveValue * 0.3),
                    blurRadius: 16 + waveValue * 12,
                    spreadRadius: 2 + waveValue * 6,
                  ),
                ],
              ),
              child: Icon(
                _isListening ? LucideIcons.mic : LucideIcons.micOff,
                color: Colors.white,
                size: 24,
              ),
            );
          },
        ),
      ),
    );
  }
}
