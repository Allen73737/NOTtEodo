import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../enterprise/sanctuary_logger.dart';

class DeviceMediaResult {
  final String path;
  final String name;
  final Uint8List? bytes;

  const DeviceMediaResult({
    required this.path,
    required this.name,
    this.bytes,
  });
}

class DeviceMediaService {
  static final DeviceMediaService _instance = DeviceMediaService._internal();
  factory DeviceMediaService() => _instance;
  DeviceMediaService._internal();

  final ImagePicker _picker = ImagePicker();

  /// Picks an image from device gallery or camera.
  Future<DeviceMediaResult?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (file == null) return null;

      Uint8List? bytes;
      try {
        bytes = await file.readAsBytes();
      } catch (_) {}

      return DeviceMediaResult(
        path: file.path,
        name: file.name,
        bytes: bytes,
      );
    } catch (e) {
      SanctuaryLogger().warn('DeviceMediaService', 'Failed to pick image: $e');
      return null;
    }
  }

  /// Picks multiple images from device.
  Future<List<DeviceMediaResult>> pickMultipleImages() async {
    try {
      final List<XFile> files = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      final List<DeviceMediaResult> results = [];
      for (final f in files) {
        Uint8List? bytes;
        try {
          bytes = await f.readAsBytes();
        } catch (_) {}
        results.add(DeviceMediaResult(path: f.path, name: f.name, bytes: bytes));
      }
      return results;
    } catch (e) {
      SanctuaryLogger().warn('DeviceMediaService', 'Failed to pick multiple images: $e');
      return [];
    }
  }
}
