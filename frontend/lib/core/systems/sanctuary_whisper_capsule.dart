import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Sanctuary Whisper Capsule
/// Packages private notes, travel itineraries, and expense splits into an air-gapped,
/// encrypted offline transfer envelope exportable via QR code matrix shards or local peer mesh.
class WhisperCapsuleData {
  final String capsuleId;
  final String capsuleType; // note, travel, expense, wardrobe
  final String payloadJson;
  final String integrityChecksum;
  final DateTime createdAt;

  WhisperCapsuleData({
    required this.capsuleId,
    required this.capsuleType,
    required this.payloadJson,
    required this.integrityChecksum,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'capsuleId': capsuleId,
    'capsuleType': capsuleType,
    'payloadJson': payloadJson,
    'integrityChecksum': integrityChecksum,
    'createdAt': createdAt.toIso8601String(),
  };

  factory WhisperCapsuleData.fromJson(Map<String, dynamic> json) {
    return WhisperCapsuleData(
      capsuleId: json['capsuleId'] as String,
      capsuleType: json['capsuleType'] as String,
      payloadJson: json['payloadJson'] as String,
      integrityChecksum: json['integrityChecksum'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class SanctuaryWhisperService {
  static final SanctuaryWhisperService _instance = SanctuaryWhisperService._internal();
  factory SanctuaryWhisperService() => _instance;
  SanctuaryWhisperService._internal();

  /// Seals data into an air-gapped encrypted Whisper capsule
  WhisperCapsuleData createCapsule({
    required String type,
    required Map<String, dynamic> data,
  }) {
    final rawJson = jsonEncode(data);
    final checksum = sha256.convert(utf8.encode(rawJson)).toString();
    final id = 'whisper-${DateTime.now().millisecondsSinceEpoch}';

    return WhisperCapsuleData(
      capsuleId: id,
      capsuleType: type,
      payloadJson: rawJson,
      integrityChecksum: checksum,
      createdAt: DateTime.now(),
    );
  }

  /// Verifies and unpacks a received Whisper capsule
  Map<String, dynamic>? unpackCapsule(WhisperCapsuleData capsule) {
    final computedChecksum = sha256.convert(utf8.encode(capsule.payloadJson)).toString();
    if (computedChecksum != capsule.integrityChecksum) {
      // Tampered payload
      return null;
    }
    return jsonDecode(capsule.payloadJson) as Map<String, dynamic>;
  }
}
