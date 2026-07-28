import 'package:alitapricelist/core/utils/product_image_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProductImageUtils.isAvifUrl', () {
    test('detects .avif extension case-insensitively', () {
      expect(
        ProductImageUtils.isAvifUrl(
          'https://www.isleep.co.id/rails/active_storage/blobs/redirect/abc/iSleep_Flex_SET_800x800px.avif',
        ),
        true,
      );
      expect(ProductImageUtils.isAvifUrl('https://cdn.example/photo.AVIF'), true);
    });

    test('returns false for non-avif urls', () {
      expect(ProductImageUtils.isAvifUrl('https://cdn.example/photo.jpg'), false);
      expect(ProductImageUtils.isAvifUrl(''), false);
    });
  });

  group('ProductImageUtils.resolveDisplayUrl', () {
    test('rewrites AVIF network photo through the JPEG-converting proxy', () {
      const avifUrl = 'https://www.isleep.co.id/path/iSleep_Flex_SET.avif';
      final resolved = ProductImageUtils.resolveDisplayUrl(avifUrl);

      final uri = Uri.parse(resolved);
      expect(uri.host, 'wsrv.nl');
      expect(uri.queryParameters['url'], avifUrl);
      expect(uri.queryParameters['output'], 'jpg');
    });

    test('leaves non-AVIF network photo untouched', () {
      const jpgUrl = 'https://cdn.example/photo.jpg';
      expect(ProductImageUtils.resolveDisplayUrl(jpgUrl), jpgUrl);
    });

    test('leaves asset:// uris untouched even if they contain .avif', () {
      const assetUri = '${ProductImageUtils.assetUriPrefix}assets/logo/x.avif';
      expect(ProductImageUtils.resolveDisplayUrl(assetUri), assetUri);
    });

    test('leaves synthetic placeholder urls untouched', () {
      const synthetic = 'https://picsum.photos/seed/99/400/600.avif';
      expect(ProductImageUtils.resolveDisplayUrl(synthetic), synthetic);
    });

    test('leaves empty url untouched', () {
      expect(ProductImageUtils.resolveDisplayUrl(''), '');
    });
  });
}
