import 'dart:convert';
import 'dart:typed_data';

/// Steganographic Carrier Image Vault
/// Encodes encrypted payloads into pixel Least Significant Bits (LSB)
/// of raw raster image buffers, enabling invisible, air-gapped data carriage.
class SteganographyCarrierVault {
  static const String _magicHeader = 'NVSTG:';

  /// Encodes a secret text payload into a raw RGBA pixel byte array.
  /// Returns a modified copy of the pixel buffer.
  static Uint8List encodePayload({
    required Uint8List rgbaPixels,
    required String secretPayload,
  }) {
    final fullString = '$_magicHeader$secretPayload\u0000';
    final payloadBytes = utf8.encode(fullString);
    final output = Uint8List.fromList(rgbaPixels);

    final totalBits = payloadBytes.length * 8;
    if (totalBits > output.length) {
      throw ArgumentError(
        'Image capacity (${output.length} bytes) cannot store $totalBits bits.',
      );
    }

    int bitIndex = 0;
    for (int byte in payloadBytes) {
      for (int b = 7; b >= 0; b--) {
        final bit = (byte >> b) & 1;
        // Inject into lowest bit of output byte
        output[bitIndex] = (output[bitIndex] & 0xFE) | bit;
        bitIndex++;
      }
    }

    return output;
  }

  /// Extracts and decodes an embedded payload from raw RGBA pixel buffer.
  /// Returns null if no valid magic header is found.
  static String? decodePayload({required Uint8List rgbaPixels}) {
    final decodedBytes = <int>[];
    int currentByte = 0;
    int bitCount = 0;

    for (int i = 0; i < rgbaPixels.length; i++) {
      final bit = rgbaPixels[i] & 1;
      currentByte = (currentByte << 1) | bit;
      bitCount++;

      if (bitCount == 8) {
        if (currentByte == 0) {
          // Null terminator reached
          break;
        }
        decodedBytes.add(currentByte);
        currentByte = 0;
        bitCount = 0;

        // Quick fail check if header doesn't match
        if (decodedBytes.length == _magicHeader.length) {
          final prefix = utf8.decode(decodedBytes, allowMalformed: true);
          if (prefix != _magicHeader) {
            return null;
          }
        }
      }
    }

    try {
      final decodedString = utf8.decode(decodedBytes);
      if (decodedString.startsWith(_magicHeader)) {
        return decodedString.substring(_magicHeader.length);
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
