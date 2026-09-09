import 'dart:math' as math;

/// Analog Tape Saturation State
class TapeSaturationState {
  final double wowAndFlutter;
  final double tapeHissDb;
  final double magneticReelTension;
  final bool isPlaying;

  const TapeSaturationState({
    required this.wowAndFlutter,
    required this.tapeHissDb,
    required this.magneticReelTension,
    required this.isPlaying,
  });
}

/// Analog Master-Tape Acoustic Saturation Generator
/// Synthesizes analog wow-and-flutter, magnetic reel tension acoustics,
/// and subtle acoustic tape saturation reacting to typing cadence.
class AnalogTapeSaturationEngine {
  bool _isPlaying = false;
  double _keystrokeVelocity = 0.0;

  bool get isPlaying => _isPlaying;

  void startTapeHead() {
    _isPlaying = true;
  }

  void stopTapeHead() {
    _isPlaying = false;
  }

  void registerKeystroke() {
    _keystrokeVelocity = (_keystrokeVelocity + 0.25).clamp(0.0, 1.0);
  }

  TapeSaturationState computeState(double elapsedSeconds) {
    if (!_isPlaying) {
      return const TapeSaturationState(
        wowAndFlutter: 0.0,
        tapeHissDb: -96.0,
        magneticReelTension: 0.0,
        isPlaying: false,
      );
    }

    // Decay velocity gently
    _keystrokeVelocity = (_keystrokeVelocity * 0.96).clamp(0.0, 1.0);

    // Wow (0.5 - 2Hz) and Flutter (5 - 10Hz) harmonics
    final wow = math.sin(elapsedSeconds * 2.0 * math.pi * 0.8) * 0.015;
    final flutter = math.sin(elapsedSeconds * 2.0 * math.pi * 7.5) * 0.008;

    return TapeSaturationState(
      wowAndFlutter: (wow + flutter) * (1.0 + _keystrokeVelocity * 0.5),
      tapeHissDb: -62.0 + (_keystrokeVelocity * 4.0),
      magneticReelTension: 0.5 + (_keystrokeVelocity * 0.35),
      isPlaying: true,
    );
  }
}
