import 'package:alitapricelist/features/pricelist/data/models/product.dart';
import 'package:alitapricelist/features/pricelist/logic/product_display_image_provider.dart';
import 'package:alitapricelist/features/product/logic/brand_spec_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const product = Product(
    id: '1',
    name: 'Comforta Deluxe 180',
    price: 1,
    imageUrl: 'https://placeholder/alita.png',
    category: 'c',
    kasur: 'K',
    ukuran: '180',
    divan: 'Tanpa Divan',
    headboard: 'Tanpa Headboard',
    sorong: 'Tanpa Sorong',
    isSet: false,
    pricelist: 1,
    eupKasur: 1,
    eupDivan: 0,
    eupHeadboard: 0,
    eupSorong: 0,
    plKasur: 0,
    plDivan: 0,
    plHeadboard: 0,
    plSorong: 0,
  );

  test('uses Comforta spec image when name matches', () async {
    final container = ProviderContainer(
      overrides: [
        brandSpecProvider.overrideWith(
          (ref) async => [
            {
              'name': 'Comforta',
              'image': 'https://cdn.example/comforta.png',
            },
          ],
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(brandSpecProvider.future);

    final url = container.read(productDisplayImageProvider(product));
    expect(url, 'https://cdn.example/comforta.png');
  });

  test('falls back to product.imageUrl when no spec match', () async {
    final container = ProviderContainer(
      overrides: [
        brandSpecProvider.overrideWith((ref) async => []),
      ],
    );
    addTearDown(container.dispose);

    await container.read(brandSpecProvider.future);

    final url = container.read(productDisplayImageProvider(product));
    expect(url, product.imageUrl);
  });
}
