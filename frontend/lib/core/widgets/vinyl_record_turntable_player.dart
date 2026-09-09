import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VinylRecordTurntablePlayer extends StatefulWidget {
  final String title;

  const VinylRecordTurntablePlayer({super.key, required this.title});

  @override
  State<VinylRecordTurntablePlayer> createState() => _VinylRecordTurntablePlayerState();
}

class _VinylRecordTurntablePlayerState extends State<VinylRecordTurntablePlayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _togglePlay() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _rotationController.repeat();
      } else {
        _rotationController.stop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _togglePlay,
      child: AnimatedBuilder(
        animation: _rotationController,
        builder: (context, _) {
          return Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF111111),
              boxShadow: [
                BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 4)),
              ],
            ),
            child: Transform.rotate(
              angle: _rotationController.value * math.pi * 2,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFD9725B),
                    ),
                  ),
                  const CircleAvatar(radius: 4, backgroundColor: Colors.white),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
