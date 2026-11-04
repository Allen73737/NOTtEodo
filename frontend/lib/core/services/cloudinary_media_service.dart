import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../enterprise/sanctuary_logger.dart';
import 'sanctuary_supabase_service.dart';

/// Result of a successful Cloudinary upload.
class CloudinaryUploadResult {
  final String secureUrl;
  final String publicId;
  final int bytes;
  final int? width;
  final int? height;
  final String? format;

  const CloudinaryUploadResult({
    required this.secureUrl,
    required this.publicId,
    required this.bytes,
    this.width,
    this.height,
    this.format,
  });

  /// Generates a fast, responsive thumbnail URL with on-the-fly cropping and optimization.
  String thumbnailUrl({int width = 300, int height = 300}) =>
      CloudinaryMediaService.getTransformedUrl(secureUrl, 'c_fill,w_$width,h_$height,q_auto,f_auto');

  /// Generates an avatar/circle-cropped URL.
  String avatarUrl({int size = 160}) =>
      CloudinaryMediaService.getTransformedUrl(secureUrl, 'c_thumb,g_face,w_$size,h_$size,r_max,q_auto,f_auto');
}

/// Secure Cloudinary Media Service for NOTtEodo.
///
/// Features:
/// 1. Zero secret keys on device (all signatures generated via `cloudinary-sign` Supabase Edge Function).
/// 2. Sandboxed per-user folder paths: `users/${user.id}/${category}/`.
/// 3. Automatic privacy protection (EXIF/GPS metadata stripped).
/// 4. Direct uploads straight to Cloudinary CDN (bypassing Supabase bandwidth limits).
class CloudinaryMediaService {
  static final CloudinaryMediaService _instance = CloudinaryMediaService._internal();
  factory CloudinaryMediaService() => _instance;
  CloudinaryMediaService._internal();

  /// Uploads raw image/media bytes to Cloudinary with backend cryptographic signature.
  /// [category] can be 'wardrobe', 'moodboard', 'notes', 'spaces', 'avatars', or 'documents'.
  Future<CloudinaryUploadResult?> uploadBytes({
    required Uint8List bytes,
    required String filename,
    String category = 'media',
  }) async {
    final supabase = SanctuarySupabaseService();
    if (!supabase.isConnectedToCloud) {
      SanctuaryLogger().warn('Cloudinary', 'User must be signed in to upload media.');
      return null;
    }

    try {
      // 1. Request secure HMAC signature from Supabase Edge Function
      final signData = await supabase.invokeFunction('cloudinary-sign', {
        'task': 'upload_signature',
        'category': category,
      }).timeout(const Duration(seconds: 15));

      final uploadUrl = signData['upload_url']?.toString();
      final apiKey = signData['api_key']?.toString();
      final timestamp = signData['timestamp'];
      final folder = signData['folder']?.toString();
      final transformation = signData['transformation']?.toString();
      final signature = signData['signature']?.toString();

      if (uploadUrl == null || apiKey == null || timestamp == null || signature == null) {
        throw StateError('Incomplete upload credentials from signature service.');
      }

      // 2. Perform direct multipart upload to Cloudinary CDN
      final uri = Uri.parse(uploadUrl);
      final request = http.MultipartRequest('POST', uri)
        ..fields['api_key'] = apiKey
        ..fields['timestamp'] = timestamp.toString()
        ..fields['signature'] = signature;

      if (folder != null) request.fields['folder'] = folder;
      if (transformation != null) request.fields['transformation'] = transformation;

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
      ));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode != 200 && streamedResponse.statusCode != 201) {
        SanctuaryLogger().error('Cloudinary', 'Upload failed (${streamedResponse.statusCode}): $responseBody');
        return null;
      }

      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      final result = CloudinaryUploadResult(
        secureUrl: json['secure_url']?.toString() ?? '',
        publicId: json['public_id']?.toString() ?? '',
        bytes: (json['bytes'] as num?)?.toInt() ?? bytes.length,
        width: (json['width'] as num?)?.toInt(),
        height: (json['height'] as num?)?.toInt(),
        format: json['format']?.toString(),
      );

      SanctuaryLogger().info('Cloudinary', 'Uploaded ${result.publicId} (${result.bytes} bytes)');
      return result;
    } catch (e, st) {
      SanctuaryLogger().error('Cloudinary', 'Error during signed upload: $e', error: e, stackTrace: st);
      return null;
    }
  }

  /// Inserts on-the-fly transformations into a standard Cloudinary secure URL.
  static String getTransformedUrl(String originalUrl, String transformation) {
    if (!originalUrl.contains('res.cloudinary.com') || !originalUrl.contains('/image/upload/')) {
      return originalUrl;
    }
    return originalUrl.replaceFirst('/image/upload/', '/image/upload/$transformation/');
  }
}
