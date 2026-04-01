import 'dart:convert';
import 'dart:io';

import 'package:alitapricelist/core/services/storage_service.dart';
import 'package:alitapricelist/features/pricelist/data/models/product.dart';
import 'package:alitapricelist/features/pricelist/logic/master_data_provider.dart';
import 'package:alitapricelist/features/pricelist/logic/product_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/mock_app_support_dir.dart';
import '../../../helpers/real_http_client_zone.dart';

/// Mocktail: contoh dependency terpisah (pola yang sama bisa dipakai jika
/// nanti API/cache di-injeksi).
class MockProductPredicate extends Mock {
  bool interested(Product p);
}

Product _sampleProduct({
  String id = '1',
  String kasur = 'Foam Deluxe',
  String ukuran = '180x200',
  double price = 1_000_000,
  String description = 'Deskripsi kasur empuk',
  String divan = 'Tanpa Divan',
  String headboard = 'Tanpa Headboard',
  String sorong = 'Tanpa Sorong',
}) {
  return Product(
    id: id,
    name: '$kasur $ukuran',
    price: price,
    imageUrl: 'https://example.com/p.png',
    category: 'Cat',
    description: description,
    channel: 'Direct',
    brand: 'BrandX',
    kasur: kasur,
    ukuran: ukuran,
    divan: divan,
    headboard: headboard,
    sorong: sorong,
    isSet: false,
    pricelist: price,
    eupKasur: price,
    eupDivan: 0,
    eupHeadboard: 0,
    eupSorong: 0,
    plKasur: 0,
    plDivan: 0,
    plHeadboard: 0,
    plSorong: 0,
  );
}

Future<void> _untilMasterDataReady(ProviderContainer c) async {
  for (var i = 0; i < 300; i++) {
    if (!c.read(masterDataProvider).isLoading) return;
    await Future<void>.delayed(Duration.zero);
  }
  fail('masterDataProvider stayed loading');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory appSupportDir;

  setUpAll(() {
    registerFallbackValue(SortOption.newest);
    registerFallbackValue(_sampleProduct());
    appSupportDir =
        Directory.systemTemp.createTempSync('alita_pricelist_products_');
    setMockApplicationSupportDirectory(appSupportDir.path);
    dotenv.testLoad(fileInput: '''
API_BASE_URL=https://stubbed-http.test
CLIENT_ID_ANDROID=cid
CLIENT_SECRET_ANDROID=sec
CLIENT_ID_IOS=cid
CLIENT_SECRET_IOS=sec
''');
  });

  tearDownAll(() {
    if (appSupportDir.existsSync()) {
      appSupportDir.deleteSync(recursive: true);
    }
    dotenv.testLoad(fileInput: '''
API_BASE_URL=https://test.example.com
CLIENT_ID_ANDROID=test-cid
CLIENT_SECRET_ANDROID=test-sec
CLIENT_ID_IOS=test-cid
CLIENT_SECRET_IOS=test-sec
''');
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.clearAll();
  });

  tearDown(() async {
    await StorageService.clearAll();
  });

  group('mapFilteredPlRawListToProducts', () {
    test('maps minimal API row to Product', () {
      final raw = [
        {
          'id': 42,
          'kasur': 'Spring',
          'ukuran': '160',
          'end_user_price': 2500000,
          'series': 'Gold',
          'channel': 'Retail',
          'brand': 'Acme',
        },
      ];
      final list = mapFilteredPlRawListToProducts(raw, 'Ch', 'Br');
      expect(list, hasLength(1));
      expect(list.single.id, '42');
      expect(list.single.kasur, 'Spring');
      expect(list.single.price, 2_500_000);
      expect(list.single.category, 'Gold');
    });

    test('parses disc fraction keys', () {
      final raw = [
        {
          'id': 1,
          'kasur': 'K',
          'ukuran': 'U',
          'end_user_price': 100,
          'disc_1': 10,
        },
      ];
      final p = mapFilteredPlRawListToProducts(raw, 'c', 'b').single;
      expect(p.disc1, closeTo(0.1, 0.0001));
    });

    test('parses end_user_price from string and bonus qty from string', () {
      final raw = [
        {
          'id': 7,
          'kasur': 'K',
          'ukuran': 'U',
          'end_user_price': '2500000',
          'bonus_1': 'Bantal',
          'qty_bonus1': '3',
          'pl_bonus_1': 50000,
        },
      ];
      final p = mapFilteredPlRawListToProducts(raw, 'c', 'b').single;
      expect(p.price, 2_500_000);
      expect(p.bonus1, 'Bantal');
      expect(p.qtyBonus1, 3);
      expect(p.plBonus1, 50000);
    });
  });

  group('mocktail predicate (pattern)', () {
    test('when/verify on Product predicate', () {
      final pred = MockProductPredicate();
      final p = _sampleProduct();
      when(() => pred.interested(any())).thenReturn(true);
      expect(pred.interested(p), true);
      verify(() => pred.interested(any())).called(1);
    });
  });

  group('filteredProductsProvider', () {
    ProviderContainer buildContainer(List<Product> products) {
      return ProviderContainer(
        overrides: [
          productListProvider.overrideWith(
            (ref) async => ProductListLoadResult(products: products),
          ),
          selectedChannelProvider.overrideWith((ref) => 'Direct'),
          selectedBrandProvider.overrideWith((ref) => 'BrandX'),
          selectedAreaProvider.overrideWith((ref) => 'Jakarta'),
          searchQueryProvider.overrideWith((ref) => ''),
          sortOptionProvider.overrideWith((ref) => SortOption.newest),
        ],
      );
    }

    test('empty when channel not selected', () {
      final c = ProviderContainer(
        overrides: [
          productListProvider.overrideWith(
            (ref) async => ProductListLoadResult(
              products: [_sampleProduct()],
            ),
          ),
          selectedChannelProvider.overrideWith((ref) => null),
          selectedBrandProvider.overrideWith((ref) => 'B'),
          selectedAreaProvider.overrideWith((ref) => 'Jakarta'),
        ],
      );
      addTearDown(c.dispose);
      expect(c.read(filteredProductsProvider), isEmpty);
    });

    test('search filters grouped products by name or description', () async {
      final p1 = _sampleProduct(
        id: '1',
        kasur: 'Alpha',
        description: 'tidak cocok',
      );
      final p2 = _sampleProduct(
        id: '2',
        kasur: 'Beta',
        description: 'foam premium',
      );
      final c = ProviderContainer(
        overrides: [
          productListProvider.overrideWith(
            (ref) async => ProductListLoadResult(products: [p1, p2]),
          ),
          selectedChannelProvider.overrideWith((ref) => 'Direct'),
          selectedBrandProvider.overrideWith((ref) => 'BrandX'),
          selectedAreaProvider.overrideWith((ref) => 'Jakarta'),
          searchQueryProvider.overrideWith((ref) => 'foam'),
          sortOptionProvider.overrideWith((ref) => SortOption.newest),
        ],
      );
      addTearDown(c.dispose);
      await c.read(productListProvider.future);
      final out = c.read(filteredProductsProvider);
      expect(out, hasLength(1));
      expect(out.single.description.toLowerCase(), contains('foam'));
    });

    test('sort price low to high', () async {
      final c = buildContainer([
        _sampleProduct(id: 'a', kasur: 'Hi', price: 500),
        _sampleProduct(id: 'b', kasur: 'Lo', price: 100),
      ]);
      addTearDown(c.dispose);
      await c.read(productListProvider.future);
      c.read(sortOptionProvider.notifier).state = SortOption.priceLowToHigh;
      final out = c.read(filteredProductsProvider);
      expect(out, hasLength(2));
      expect(out.first.price, lessThan(out.last.price));
    });

    test('grouping picks lowest price per kasur name', () async {
      final c = buildContainer([
        _sampleProduct(id: '1', kasur: 'Same', price: 900),
        _sampleProduct(id: '2', kasur: 'Same', price: 400),
      ]);
      addTearDown(c.dispose);
      await c.read(productListProvider.future);
      final out = c.read(filteredProductsProvider);
      expect(out, hasLength(1));
      expect(out.single.price, 400);
    });

    test('grouping uses divan label when kasur is Tanpa Kasur', () async {
      final c = buildContainer([
        _sampleProduct(
          id: '1',
          kasur: 'Tanpa Kasur',
          divan: 'Divan Deluxe',
          price: 300,
        ),
      ]);
      addTearDown(c.dispose);
      await c.read(productListProvider.future);
      final out = c.read(filteredProductsProvider);
      expect(out.single.name.toLowerCase(), contains('divan deluxe'));
    });

    test('sort price high to low', () async {
      final c = buildContainer([
        _sampleProduct(id: 'a', kasur: 'Hi', price: 900),
        _sampleProduct(id: 'b', kasur: 'Lo', price: 100),
      ]);
      addTearDown(c.dispose);
      await c.read(productListProvider.future);
      c.read(sortOptionProvider.notifier).state = SortOption.priceHighToLow;
      final out = c.read(filteredProductsProvider);
      expect(out.first.price, greaterThan(out.last.price));
    });
  });

  group('effectiveAreaProvider', () {
    test('Spring Air brand forces Nasional', () {
      final c = ProviderContainer(
        overrides: [
          selectedAreaProvider.overrideWith((ref) => 'Jakarta'),
          selectedBrandProvider.overrideWith((ref) => 'Spring Air Pro'),
        ],
      );
      addTearDown(c.dispose);
      expect(c.read(effectiveAreaProvider), 'Nasional');
    });

    test('Therapedic brand forces Nasional', () {
      final c = ProviderContainer(
        overrides: [
          selectedAreaProvider.overrideWith((ref) => 'Bandung'),
          selectedBrandProvider.overrideWith((ref) => 'Therapedic X'),
        ],
      );
      addTearDown(c.dispose);
      expect(c.read(effectiveAreaProvider), 'Nasional');
    });

    test('Sleep Spa brand forces Nasional', () {
      final c = ProviderContainer(
        overrides: [
          selectedAreaProvider.overrideWith((ref) => 'Surabaya'),
          selectedBrandProvider.overrideWith((ref) => 'Sleep Spa Line'),
        ],
      );
      addTearDown(c.dispose);
      expect(c.read(effectiveAreaProvider), 'Nasional');
    });
  });

  group('areasProvider', () {
    test('merges name and area keys uniquely', () async {
      SharedPreferences.setMockInitialValues({
        'token_migrated_v1': true,
        'master_areas_cache': jsonEncode([
          {'name': 'Jakarta Pusat'},
          {'area': 'Bandung'},
          {'name': 'Jakarta Pusat'},
        ]),
        'master_channels_cache': '[]',
        'master_brands_cache': '[]',
      });

      final c = ProviderContainer();
      addTearDown(c.dispose);
      await _untilMasterDataReady(c);

      final areas = c.read(areasProvider);
      expect(areas.toSet(), {'Jakarta Pusat', 'Bandung'});
    });
  });

  group('channelsProvider', () {
    test('returns unique non-empty channel names', () async {
      SharedPreferences.setMockInitialValues({
        'token_migrated_v1': true,
        'master_areas_cache': '[]',
        'master_channels_cache': jsonEncode([
          {'id': 1, 'channel': 'Retail'},
          {'id': 2, 'channel': 'Retail'},
          {'channel': ''},
        ]),
        'master_brands_cache': '[]',
      });

      final c = ProviderContainer();
      addTearDown(c.dispose);
      await _untilMasterDataReady(c);

      expect(c.read(channelsProvider), ['Retail']);
    });
  });

  group('isFilterCompleteProvider', () {
    test('false when channel missing', () {
      final c = ProviderContainer(
        overrides: [
          selectedChannelProvider.overrideWith((ref) => null),
          selectedBrandProvider.overrideWith((ref) => 'B'),
        ],
      );
      addTearDown(c.dispose);
      expect(c.read(isFilterCompleteProvider), isFalse);
    });

    test('false when brand missing', () {
      final c = ProviderContainer(
        overrides: [
          selectedChannelProvider.overrideWith((ref) => 'Direct'),
          selectedBrandProvider.overrideWith((ref) => null),
        ],
      );
      addTearDown(c.dispose);
      expect(c.read(isFilterCompleteProvider), isFalse);
    });

    test('true when both set', () {
      final c = ProviderContainer(
        overrides: [
          selectedChannelProvider.overrideWith((ref) => 'Direct'),
          selectedBrandProvider.overrideWith((ref) => 'X'),
        ],
      );
      addTearDown(c.dispose);
      expect(c.read(isFilterCompleteProvider), isTrue);
    });
  });

  group('brandsProvider', () {
    test('filters brands by selected channel id', () async {
      SharedPreferences.setMockInitialValues({
        'token_migrated_v1': true,
        'master_areas_cache': '[]',
        'master_channels_cache': jsonEncode([
          {'id': 5, 'channel': 'Wholesale'},
        ]),
        'master_brands_cache': jsonEncode([
          {'brand': 'B-Ok', 'pl_channel_id': 5},
          {'brand': 'B-Other', 'pl_channel_id': 99},
        ]),
      });

      final c = ProviderContainer(
        overrides: [
          selectedChannelProvider.overrideWith((ref) => 'Wholesale'),
        ],
      );
      addTearDown(c.dispose);

      await _untilMasterDataReady(c);

      final brands = c.read(brandsProvider);
      expect(brands, contains('B-Ok'));
      expect(brands, isNot(contains('B-Other')));
    });

    test('returns empty when selected channel id cannot be resolved', () async {
      SharedPreferences.setMockInitialValues({
        'token_migrated_v1': true,
        'master_areas_cache': '[]',
        'master_channels_cache': jsonEncode([
          {'id': 5, 'channel': 'Wholesale'},
        ]),
        'master_brands_cache': jsonEncode([
          {'brand': 'B-Ok', 'pl_channel_id': 5},
        ]),
      });

      final c = ProviderContainer(
        overrides: [
          selectedChannelProvider.overrideWith((ref) => 'Unknown Channel'),
        ],
      );
      addTearDown(c.dispose);

      await _untilMasterDataReady(c);
      expect(c.read(brandsProvider), isEmpty);
    });
  });

  group('productListProvider — stale disk cache', () {
    test('returns cached rows when HTTP is stubbed non-200', () async {
      final p = _sampleProduct(id: '99');
      final key = StorageService.pricelistCacheStorageKey(
        'Jakarta',
        'Direct',
        'BrandX',
      );
      await StorageService.savePricelistProductRows(key, [p.toJson()]);

      final c = ProviderContainer(
        overrides: [
          selectedAreaProvider.overrideWith((ref) => 'Jakarta'),
          selectedChannelProvider.overrideWith((ref) => 'Direct'),
          selectedBrandProvider.overrideWith((ref) => 'BrandX'),
        ],
      );
      addTearDown(c.dispose);

      final result = await c.read(productListProvider.future);
      expect(result.isFromStaleCache, isTrue);
      expect(result.products, hasLength(1));
      expect(result.products.single.id, '99');
    });

    test('tryLoadStale skips rows that fail Product.fromJson', () async {
      final key = StorageService.pricelistCacheStorageKey(
        'Jakarta',
        'Direct',
        'BrandX',
      );
      await StorageService.savePricelistProductRows(key, [
        {'not_a_valid_product_key': true},
      ]);

      final c = ProviderContainer(
        overrides: [
          selectedAreaProvider.overrideWith((ref) => 'Jakarta'),
          selectedChannelProvider.overrideWith((ref) => 'Direct'),
          selectedBrandProvider.overrideWith((ref) => 'BrandX'),
        ],
      );
      addTearDown(c.dispose);

      await expectLater(
        c.read(productListProvider.future),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('productListProvider — local HttpServer', () {
    test('HTTP 200 with data object maps products and marks fresh cache',
        () async {
      await runWithRealHttpClient(() async {
        late HttpServer server;
        server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(() async {
          await server.close(force: true);
        });

        server.listen((req) async {
          if (req.uri.path.contains('filtered_pl')) {
            req.response.statusCode = 200;
            req.response.headers.contentType = ContentType.json;
            req.response.write(jsonEncode({
              'data': [
                {
                  'id': 501,
                  'kasur': 'Server Kasur',
                  'ukuran': '160',
                  'end_user_price': 111,
                  'channel': 'Direct',
                  'brand': 'BrandX',
                },
              ],
            }));
          } else {
            req.response.statusCode = 404;
          }
          await req.response.close();
        });

        dotenv.testLoad(fileInput: '''
API_BASE_URL=http://127.0.0.1:${server.port}
CLIENT_ID_ANDROID=cid
CLIENT_SECRET_ANDROID=sec
CLIENT_ID_IOS=cid
CLIENT_SECRET_IOS=sec
''');
        addTearDown(() {
          dotenv.testLoad(fileInput: '''
API_BASE_URL=https://stubbed-http.test
CLIENT_ID_ANDROID=cid
CLIENT_SECRET_ANDROID=sec
CLIENT_ID_IOS=cid
CLIENT_SECRET_IOS=sec
''');
        });

        final c = ProviderContainer(
          overrides: [
            selectedAreaProvider.overrideWith((ref) => 'Jakarta'),
            selectedChannelProvider.overrideWith((ref) => 'Direct'),
            selectedBrandProvider.overrideWith((ref) => 'BrandX'),
          ],
        );
        addTearDown(c.dispose);

        final result = await c.read(productListProvider.future);
        expect(result.isFromStaleCache, isFalse);
        expect(result.products, hasLength(1));
        expect(result.products.single.id, '501');
        expect(result.products.single.kasur, 'Server Kasur');
      });
    });

    test('HTTP 200 with top-level JSON list is accepted', () async {
      await runWithRealHttpClient(() async {
        late HttpServer server;
        server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(() async {
          await server.close(force: true);
        });

        server.listen((req) async {
          req.response.statusCode = 200;
          req.response.headers.contentType = ContentType.json;
          req.response.write(jsonEncode([
            {
              'id': 9,
              'kasur': 'List Root',
              'ukuran': '200',
              'end_user_price': 50,
            },
          ]));
          await req.response.close();
        });

        dotenv.testLoad(fileInput: '''
API_BASE_URL=http://127.0.0.1:${server.port}
CLIENT_ID_ANDROID=cid
CLIENT_SECRET_ANDROID=sec
CLIENT_ID_IOS=cid
CLIENT_SECRET_IOS=sec
''');
        addTearDown(() {
          dotenv.testLoad(fileInput: '''
API_BASE_URL=https://stubbed-http.test
CLIENT_ID_ANDROID=cid
CLIENT_SECRET_ANDROID=sec
CLIENT_ID_IOS=cid
CLIENT_SECRET_IOS=sec
''');
        });

        final c = ProviderContainer(
          overrides: [
            selectedAreaProvider.overrideWith((ref) => 'Jakarta'),
            selectedChannelProvider.overrideWith((ref) => 'Direct'),
            selectedBrandProvider.overrideWith((ref) => 'BrandX'),
          ],
        );
        addTearDown(c.dispose);

        final result = await c.read(productListProvider.future);
        expect(result.products.single.kasur, 'List Root');
      });
    });

    test('throws when HTTP 200 body decodes to null and cache empty', () async {
      await runWithRealHttpClient(() async {
        late HttpServer server;
        server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(() async {
          await server.close(force: true);
        });

        server.listen((req) async {
          req.response.statusCode = 200;
          req.response.write('null');
          await req.response.close();
        });

        dotenv.testLoad(fileInput: '''
API_BASE_URL=http://127.0.0.1:${server.port}
CLIENT_ID_ANDROID=cid
CLIENT_SECRET_ANDROID=sec
CLIENT_ID_IOS=cid
CLIENT_SECRET_IOS=sec
''');
        addTearDown(() {
          dotenv.testLoad(fileInput: '''
API_BASE_URL=https://stubbed-http.test
CLIENT_ID_ANDROID=cid
CLIENT_SECRET_ANDROID=sec
CLIENT_ID_IOS=cid
CLIENT_SECRET_IOS=sec
''');
        });

        final c = ProviderContainer(
          overrides: [
            selectedAreaProvider.overrideWith((ref) => 'Jakarta'),
            selectedChannelProvider.overrideWith((ref) => '__NullBodyCh__'),
            selectedBrandProvider.overrideWith((ref) => '__NullBodyBr__'),
          ],
        );
        addTearDown(c.dispose);

        await expectLater(
          c.read(productListProvider.future),
          throwsA(isA<Exception>()),
        );
      });
    });
  });

  group('productListProvider — HTTP failure without cache', () {
    test('throws when API non-200 and no disk snapshot', () async {
      // Kombinasi unik agar tidak memuat snapshot dari tes HttpServer lain.
      final c = ProviderContainer(
        overrides: [
          selectedAreaProvider.overrideWith((ref) => 'Jakarta'),
          selectedChannelProvider.overrideWith((ref) => '__NoCacheChannel__'),
          selectedBrandProvider.overrideWith((ref) => '__NoCacheBrand__'),
        ],
      );
      addTearDown(c.dispose);

      await expectLater(
        c.read(productListProvider.future),
        throwsA(isA<Exception>()),
      );
    });
  });
}
