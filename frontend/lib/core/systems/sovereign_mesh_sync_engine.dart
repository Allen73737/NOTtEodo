import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Mesh Peer Packet
class MeshPeerPacket {
  final String senderPeerId;
  final String payloadType;
  final String encryptedData;
  final int timestamp;
  final String packetHash;

  MeshPeerPacket({
    required this.senderPeerId,
    required this.payloadType,
    required this.encryptedData,
    required this.timestamp,
    required this.packetHash,
  });

  Map<String, dynamic> toJson() => {
        'peer': senderPeerId,
        'type': payloadType,
        'data': encryptedData,
        'ts': timestamp,
        'hash': packetHash,
      };

  factory MeshPeerPacket.fromJson(Map<String, dynamic> json) => MeshPeerPacket(
        senderPeerId: json['peer'] as String,
        payloadType: json['type'] as String,
        encryptedData: json['data'] as String,
        timestamp: json['ts'] as int,
        packetHash: json['hash'] as String,
      );
}

/// Sovereign Mesh P2P Sync Engine
/// Models ad-hoc offline broadcast packets for zero-router Bluetooth LE / Wi-Fi Direct sync.
class SovereignMeshSyncEngine {
  final String peerId;
  final List<MeshPeerPacket> _packetLog = [];

  SovereignMeshSyncEngine({required this.peerId});

  List<MeshPeerPacket> get packetLog => List.unmodifiable(_packetLog);

  /// Broadcasts an encrypted payload to the local ad-hoc mesh
  MeshPeerPacket broadcastPayload({
    required String payloadType,
    required String encryptedData,
  }) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rawForHash = '$peerId:$payloadType:$encryptedData:$ts';
    final hash = sha256.convert(utf8.encode(rawForHash)).toString();

    final packet = MeshPeerPacket(
      senderPeerId: peerId,
      payloadType: payloadType,
      encryptedData: encryptedData,
      timestamp: ts,
      packetHash: hash,
    );

    _packetLog.add(packet);
    return packet;
  }

  /// Ingests and verifies an incoming mesh peer packet
  bool ingestIncomingPacket(MeshPeerPacket packet) {
    final rawForHash =
        '${packet.senderPeerId}:${packet.payloadType}:${packet.encryptedData}:${packet.timestamp}';
    final computedHash = sha256.convert(utf8.encode(rawForHash)).toString();

    if (computedHash != packet.packetHash) {
      return false; // Tampered or corrupted packet
    }

    // Avoid duplicate replay
    if (_packetLog.any((p) => p.packetHash == packet.packetHash)) {
      return true;
    }

    _packetLog.add(packet);
    return true;
  }
}
