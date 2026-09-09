import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/app_colors.dart';

class FlipClockWidget extends StatefulWidget {
  const FlipClockWidget({super.key});

  @override
  State<FlipClockWidget> createState() => _FlipClockWidgetState();
}

class _FlipClockWidgetState extends State<FlipClockWidget> {
  int _secondsLeft = 1500; // 25 min Pomodoro
  bool _isRunning = false;
  Timer? _timer;

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_secondsLeft > 0) {
          setState(() => _secondsLeft--);
        } else {
          t.cancel();
          setState(() => _isRunning = false);
        }
      });
    }
    setState(() => _isRunning = !_isRunning);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mins = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final secs = (_secondsLeft % 60).toString().padLeft(2, '0');

    return GestureDetector(
      onTap: _toggleTimer,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.secondary, width: 1),
        ),
        child: Row(
          children: [
            Text('⏱️ $mins:$secs', style: GoogleFonts.bodoniModa(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(width: 4),
            Text(_isRunning ? 'FOCUS' : 'START', style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.secondary)),
          ],
        ),
      ),
    );
  }
}
