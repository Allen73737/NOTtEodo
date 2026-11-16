import 'dart:convert';
import 'package:file_picker/file_picker.dart';

/// Reads text from a picked [PlatformFile] across Web, Android, iOS, and Desktop.
Future<String?> readPickedFileText(PlatformFile file) async {
  try {
    return await file.xFile.readAsString();
  } catch (_) {
    try {
      final bytes = await file.xFile.readAsBytes();
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      return null;
    }
  }
}

/// Universal file picker that returns string content.
Future<String?> pickAndReadTextFile({List<String>? allowedExtensions}) async {
  try {
    final List<PlatformFile> files = await FilePicker.pickFiles(
      type: allowedExtensions != null && allowedExtensions.isNotEmpty
          ? FileType.custom
          : FileType.any,
      allowedExtensions: allowedExtensions,
    );
    if (files.isEmpty) return null;
    return await readPickedFileText(files.first);
  } catch (_) {
    return null;
  }
}
