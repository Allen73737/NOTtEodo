import 'dart:math';
import 'package:flutter/foundation.dart';

/// Binaural Spatial 3D Ambient Sound Sanctuary
/// Synthesizes and coordinates ambient acoustic landscapes (antique clock escapement,
/// crackling hearth, rain on glass, graphite sketching) with 360-degree spatial azimuth panning.
enum AmbientSoundType {
  clockEscapement,
  hearthFireplace,
  rainOnGlass,
  graphiteSketching,
}

class SpatialSoundSource {
  final AmbientSoundType type;
  double volume; // 0.0 to 1.0
  double panAngle; // 0 to 360 degrees
  bool isEnabled;

  SpatialSoundSource({
    required this.type,
    this.volume = 0.5,
    this.panAngle = 0.0,
    this.isEnabled = false,
  });
}

class SpatialAmbientSoundService extends ChangeNotifier {
  static final SpatialAmbientSoundService _instance = SpatialAmbientSoundService._internal();
  factory SpatialAmbientSoundService() => _instance;
  SpatialAmbientSoundService._internal();

  final Map<AmbientSoundType, SpatialSoundSource> _sources = {
    AmbientSoundType.clockEscapement: SpatialSoundSource(
      type: AmbientSoundType.clockEscapement,
      volume: 0.6,
      panAngle: 315.0, // Top left
    ),
    AmbientSoundType.hearthFireplace: SpatialSoundSource(
      type: AmbientSoundType.hearthFireplace,
      volume: 0.5,
      panAngle: 135.0, // Bottom right
    ),
    AmbientSoundType.rainOnGlass: SpatialSoundSource(
      type: AmbientSoundType.rainOnGlass,
      volume: 0.7,
      panAngle: 0.0, // Front Center
    ),
    AmbientSoundType.graphiteSketching: SpatialSoundSource(
      type: AmbientSoundType.graphiteSketching,
      volume: 0.4,
      panAngle: 45.0, // Top right
    ),
  };

  bool _masterActive = false;
  bool get isMasterActive => _masterActive;
  Map<AmbientSoundType, SpatialSoundSource> get sources => _sources;

  void toggleMaster() {
    _masterActive = !_masterActive;
    notifyListeners();
  }

  void toggleSource(AmbientSoundType type) {
    final src = _sources[type];
    if (src != null) {
      src.isEnabled = !src.isEnabled;
      notifyListeners();
    }
  }

  void setSourceVolume(AmbientSoundType type, double vol) {
    final src = _sources[type];
    if (src != null) {
      src.volume = vol.clamp(0.0, 1.0);
      notifyListeners();
    }
  }

  void setSourceAngle(AmbientSoundType type, double angleDegrees) {
    final src = _sources[type];
    if (src != null) {
      src.panAngle = angleDegrees % 360.0;
      notifyListeners();
    }
  }

  /// Calculates stereo left/right gain factors based on virtual 360-degree pan angle
  Map<String, double> getStereoGains(AmbientSoundType type) {
    final src = _sources[type];
    if (src == null || !src.isEnabled || !_masterActive) {
      return {'left': 0.0, 'right': 0.0};
    }
    final rad = src.panAngle * (pi / 180.0);
    // Pan law calculation
    final leftGain = (cos(rad) * 0.5 + 0.5) * src.volume;
    final rightGain = (sin(rad) * 0.5 + 0.5) * src.volume;
    return {'left': leftGain, 'right': rightGain};
  }
}
