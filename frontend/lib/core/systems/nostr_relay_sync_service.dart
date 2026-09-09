import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Nostr Protocol Event (NIP-01 compliant structure)
class NostrEvent {
  final String id;
  final String pubkey;
  final int createdAt;
  final int kind; // Kind 30023 = Long-form content, Kind 4 = Encrypted DM
  final List<List<String>> tags;
  final String content;
  final String sig;

  const NostrEvent({
    required this.id,
    required this.pubkey,
    required this.createdAt,
    required this.kind,
    required this.tags,
    required this.content,
    required this.sig,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'pubkey': pubkey,
        'created_at': createdAt,
        'kind': kind,
        'tags': tags,
        'content': content,
        'sig': sig,
      };
}

/// Censorship-Resistant Nostr Micro-Relay Sync Service
/// Creates encrypted, sovereign offsite backup events for publication
/// to private, decentralized Nostr relays worldwide.
class NostrRelaySyncService {
  final String publicKeyHex;

  const NostrRelaySyncService({required this.publicKeyHex});

  /// Constructs a signed-format event for note archival
  NostrEvent createEncryptedNoteEvent({
    required String noteTitle,
    required String encryptedCiphertext,
  }) {
    final nowEpoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final tags = [
      ['d', 'notteodo-sanctuary'],
      ['title', noteTitle],
      ['client', 'Notteodo Haute Horlogerie'],
    ];

    // Canonical serialization for event ID
    final serialized = jsonEncode([
      0,
      publicKeyHex,
      nowEpoch,
      30023,
      tags,
      encryptedCiphertext,
    ]);

    final eventId = sha256.convert(utf8.encode(serialized)).toString();

    // Simulated Schnorr signature
    final sigHash = sha256.convert(utf8.encode('$eventId:$publicKeyHex')).toString();

    return NostrEvent(
      id: eventId,
      pubkey: publicKeyHex,
      createdAt: nowEpoch,
      kind: 30023,
      tags: tags,
      content: encryptedCiphertext,
      sig: sigHash,
    );
  }
}
