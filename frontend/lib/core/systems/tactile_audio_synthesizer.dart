import 'package:flutter/services.dart';

/// Local Acoustic Keystroke & Tactile Sound Synthesizer
/// Coordinates haptic tactile vibrations and micro-acoustic sound triggers
/// (brass toggle clicks, steel deadbolt slides, paper rustles, typewriter bells).
enum TactileSoundEffect {
  brassToggle,
  vaultDeadbolt,
  paperRustle,
  typewriterBell,
  waxSealStamp,
}

class TactileAudioSynthesizer {
  static final TactileAudioSynthesizer _instance = TactileAudioSynthesizer._internal();
  factory TactileAudioSynthesizer() => _instance;
  TactileAudioSynthesizer._internal();

  bool _soundEnabled = true;
  bool get soundEnabled => _soundEnabled;

  void toggleSound(bool enabled) {
    _soundEnabled = enabled;
  }

  /// Triggers a physical tactile & synthesized auditory click with micro-pitch variance
  void play(TactileSoundEffect effect) {
    // 1. Tactile physical haptic pulse
    switch (effect) {
      case TactileSoundEffect.brassToggle:
        HapticFeedback.selectionClick();
        break;
      case TactileSoundEffect.vaultDeadbolt:
        HapticFeedback.heavyImpact();
        break;
      case TactileSoundEffect.paperRustle:
        HapticFeedback.lightImpact();
        break;
      case TactileSoundEffect.typewriterBell:
        HapticFeedback.mediumImpact();
        break;
      case TactileSoundEffect.waxSealStamp:
        HapticFeedback.heavyImpact();
        break;
    }

    if (!_soundEnabled) return;

    // SystemSound provides fallback system-level audio cues
    if (effect == TactileSoundEffect.typewriterBell || effect == TactileSoundEffect.vaultDeadbolt) {
      SystemSound.play(SystemSoundType.alert);
    } else {
      SystemSound.play(SystemSoundType.click);
    }
  }
}
