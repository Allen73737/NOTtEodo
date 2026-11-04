import 'package:flutter_test/flutter_test.dart';
import 'package:notteodo/core/services/cloudinary_media_service.dart';

void main() {
  group('CloudinaryMediaService Tests', () {
    test('getTransformedUrl injects transformation parameter correctly', () {
      const original = 'https://res.cloudinary.com/qg5h6ol4/image/upload/v1793724630/users/123/wardrobe/outfit.png';
      final thumb = CloudinaryMediaService.getTransformedUrl(original, 'c_fill,w_300,h_300');
      expect(
        thumb,
        'https://res.cloudinary.com/qg5h6ol4/image/upload/c_fill,w_300,h_300/v1793724630/users/123/wardrobe/outfit.png',
      );
    });

    test('getTransformedUrl returns original if not a standard Cloudinary URL', () {
      const nonCloudinary = 'https://example.com/images/photo.png';
      final result = CloudinaryMediaService.getTransformedUrl(nonCloudinary, 'c_fill,w_300');
      expect(result, nonCloudinary);
    });

    test('CloudinaryUploadResult helpers produce expected transformation URLs', () {
      const result = CloudinaryUploadResult(
        secureUrl: 'https://res.cloudinary.com/qg5h6ol4/image/upload/v12345/users/abc/sample.jpg',
        publicId: 'users/abc/sample',
        bytes: 1024,
      );

      expect(
        result.thumbnailUrl(width: 400, height: 400),
        'https://res.cloudinary.com/qg5h6ol4/image/upload/c_fill,w_400,h_400,q_auto,f_auto/v12345/users/abc/sample.jpg',
      );

      expect(
        result.avatarUrl(size: 120),
        'https://res.cloudinary.com/qg5h6ol4/image/upload/c_thumb,g_face,w_120,h_120,r_max,q_auto,f_auto/v12345/users/abc/sample.jpg',
      );
    });
  });
}
