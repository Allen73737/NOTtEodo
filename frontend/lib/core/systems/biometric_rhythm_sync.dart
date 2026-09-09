import 'package:flutter/foundation.dart';

/// Dynamic Focus Biometric Heart-Rate Sync
/// Coordinates circadian rhythms and biometric heart-rate variability signals
/// to dynamically optimize Pomodoro intervals (e.g. 25m vs 15m) and soften UI contrast.
enum CircadianState {
  peakAlertness, // 25m Focus / 5m Break
  gentlePacing,   // 20m Focus / 6m Break
  deepRestoration // 15m Focus / 8m Break
}

class BiometricRhythmSync extends ChangeNotifier {
  static final BiometricRhythmSync _instance = BiometricRhythmSync._internal();
  factory BiometricRhythmSync() => _instance;
  BiometricRhythmSync._internal();

  int _simulatedHeartRateBpm = 72;
  CircadianState _state = CircadianState.peakAlertness;

  int get heartRateBpm => _simulatedHeartRateBpm;
  CircadianState get currentState => _state;

  int get focusMinutes {
    switch (_state) {
      case CircadianState.peakAlertness:
        return 25;
      case CircadianState.gentlePacing:
        return 20;
      case CircadianState.deepRestoration:
        return 15;
    }
  }

  int get breakMinutes {
    switch (_state) {
      case CircadianState.peakAlertness:
        return 5;
      case CircadianState.gentlePacing:
        return 6;
      case CircadianState.deepRestoration:
        return 8;
    }
  }

  void updateHeartRate(int bpm) {
    _simulatedHeartRateBpm = bpm;
    if (bpm > 88) {
      _state = CircadianState.deepRestoration; // High exertion / stress: switch to short sprints
    } else if (bpm > 75) {
      _state = CircadianState.gentlePacing;
    } else {
      _state = CircadianState.peakAlertness;
    }
    notifyListeners();
  }
}
