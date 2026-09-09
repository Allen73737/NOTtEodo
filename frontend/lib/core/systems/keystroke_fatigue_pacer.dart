import 'dart:math' as math;

/// Keystroke Interval Record
class KeystrokeInterval {
  final int timestampMs;
  final int flightTimeMs; // Time between release of key N and press of key N+1

  const KeystrokeInterval({
    required this.timestampMs,
    required this.flightTimeMs,
  });
}

/// Fine-Motor Keystroke Tremor & Cognitive Fatigue Pacer
/// Monitors typing flight-time variances and micro-jitter to detect cognitive fatigue
/// and suggest restorative pauses or voice dictation.
class KeystrokeFatiguePacer {
  final List<KeystrokeInterval> _intervals = [];
  int _lastPressTimestamp = 0;

  void recordKeyPress() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_lastPressTimestamp > 0) {
      final flight = (now - _lastPressTimestamp).clamp(10, 3000);
      _intervals.add(KeystrokeInterval(timestampMs: now, flightTimeMs: flight));
      if (_intervals.length > 50) {
        _intervals.removeAt(0);
      }
    }
    _lastPressTimestamp = now;
  }

  /// Evaluates fatigue index between 0.0 (fresh flow state) and 1.0 (exhausted/jittery)
  double get fatigueIndex {
    if (_intervals.length < 10) return 0.0;

    // Calculate flight time variance
    final mean = _intervals.map((e) => e.flightTimeMs).reduce((a, b) => a + b) / _intervals.length;
    double sumVariance = 0;
    for (final record in _intervals) {
      sumVariance += math.pow(record.flightTimeMs - mean, 2);
    }
    final stdDev = math.sqrt(sumVariance / _intervals.length);

    // High standard deviation and erratic flight times indicate cognitive fatigue
    final normalizedJitter = (stdDev / 180.0).clamp(0.0, 1.0);
    return normalizedJitter;
  }

  bool get shouldSuggestPause => fatigueIndex > 0.72;

  String get guidanceMessage {
    if (fatigueIndex > 0.72) {
      return 'Erratic keystroke dwell detected. A 5-minute tea ritual or eye rest is recommended.';
    } else if (fatigueIndex > 0.45) {
      return 'Cognitive tempo steady. Maintain posture and mindful breathing.';
    }
    return 'Pristine motor fluidity and flow state achieved.';
  }
}
