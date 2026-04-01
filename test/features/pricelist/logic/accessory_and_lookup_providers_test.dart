import 'dart:convert';
import 'dart:io';

import 'package:alitapricelist/features/pricelist/logic/accessory_provider.dart';
import 'package:alitapricelist/features/pricelist/logic/item_lookup_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/real_http_client_zone.dart';

/// Mocktail sanity — provider tetap memakai [ApiClient] statis; respons HTTP
/// dikendalikan lewat [HttpServer] lokal atau URL mati.
class _MockPricelistSideEffect extends Mock {
  Future<void> ping();
}

const _dotenvStub = '''
API_BASE_URL=https://stubbed-http.test
CLIENT_ID_ANDROID=cid
CLIENT_SECRET_ANDROID=sec
CLIENT_ID_IOS=cid
CLIENT_SECRET_IOS=sec
''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'token_migrated_v1': true});
  });

  tearDown(() {
    dotenv.testLoad(fileInput: _dotenvStub);
  });

  tearDownAll(() {
    dotenv.testLoad(fileInput: _dotenvStub);
  });

  group('accessoryProvider', () {
    test('mocktail + empty body when stub host returns non-200', () async {
      dotenv.testLoad(fileInput: _dotenvStub);
      final m = _MockPricelistSideEffect();
      when(() => m.ping()).thenAnswer((_) async {});
      await m.ping();
      verify(() => m.ping()).called(1);

      final c = ProviderContainer();
      addTearDown(c.dispose);
      final list = await c.read(accessoryProvider.future);
      expect(list, isEmpty);
    });

    test('parses result list on HTTP 200', () async {
      await runWithRealHttpClient(() async {
        late HttpServer server;
        server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(() async {
          await server.close(force: true);
        });

        server.listen((req) async {
          if (req.uri.path.contains('pl_accessories')) {
            req.response.statusCode = 200;
            req.response.headers.contentType = ContentType.json;
            req.response.write(jsonEncode({
              'status': 'success',
              'result': [
                {
                  'tipe': 'kasur',
                  'item_num': 'ACC-1',
                  'ukuran': '180',
                  'pricelist': 150000,
                },
                {
                  'tipe': 'kasur',
                  'item_num': 'ACC-1',
                  'ukuran': '180',
                  'pricelist': 99,
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

        final c = ProviderContainer();
        addTearDown(c.dispose);
        final list = await c.read(accessoryProvider.future);
        expect(list, hasLength(1));
        expect(list.single.itemNum, 'ACC-1');
        // Duplikat item_num: entri terakhir menang (dedupe map).
        expect(list.single.pricelist, 99);
      });
    });

    test('accepts data list when status is not success', () async {
      await runWithRealHttpClient(() async {
        late HttpServer server;
        server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(() async {
          await server.close(force: true);
        });

        server.listen((req) async {
          req.response.statusCode = 200;
          req.response.headers.contentType = ContentType.json;
          req.response.write(jsonEncode({
            'status': 'pending',
            'data': [
              {
                'tipe': 'divan',
                'item_num': 'D-9',
                'ukuran': '180',
                'pricelist': '2000',
              },
            ],
          }));
          await req.response.close();
        });

        dotenv.testLoad(fileInput: '''
API_BASE_URL=http://127.0.0.1:${server.port}
CLIENT_ID_ANDROID=cid
CLIENT_SECRET_ANDROID=sec
CLIENT_ID_IOS=cid
CLIENT_SECRET_IOS=sec
''');

        final c = ProviderContainer();
        addTearDown(c.dispose);
        final list = await c.read(accessoryProvider.future);
        expect(list.single.itemNum, 'D-9');
        expect(list.single.pricelist, 2000);
      });
    });

    test('returns empty when body is not a JSON object', () async {
      await runWithRealHttpClient(() async {
        late HttpServer server;
        server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(() async {
          await server.close(force: true);
        });

        server.listen((req) async {
          req.response.statusCode = 200;
          req.response.write('"nope"');
          await req.response.close();
        });

        dotenv.testLoad(fileInput: '''
API_BASE_URL=http://127.0.0.1:${server.port}
CLIENT_ID_ANDROID=cid
CLIENT_SECRET_ANDROID=sec
CLIENT_ID_IOS=cid
CLIENT_SECRET_IOS=sec
''');

        final c = ProviderContainer();
        addTearDown(c.dispose);
        expect(await c.read(accessoryProvider.future), isEmpty);
      });
    });
  });

  group('itemLookupProvider', () {
    test('returns empty map when HTTP stubbed non-200', () async {
      dotenv.testLoad(fileInput: _dotenvStub);
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect(await c.read(itemLookupProvider.future), isEmpty);
    });

    test('groups by lowercase tipe on HTTP 200', () async {
      await runWithRealHttpClient(() async {
        late HttpServer server;
        server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(() async {
          await server.close(force: true);
        });

        server.listen((req) async {
          if (req.uri.path.contains('pl_lookup_item_nums')) {
            req.response.statusCode = 200;
            req.response.headers.contentType = ContentType.json;
            req.response.write(jsonEncode({
              'status': 'success',
              'result': [
                {
                  'tipe': 'Kasur',
                  'ukuran': '180',
                  'item_num': 'L-1',
                  'jenis_kain': 'Knit',
                  'warna_kain': 'Abu',
                },
                {
                  'tipe': 'kasur',
                  'ukuran': '200',
                  'item_num': 'L-2',
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

        final c = ProviderContainer();
        addTearDown(c.dispose);
        final map = await c.read(itemLookupProvider.future);
        expect(map.keys, contains('kasur'));
        expect(map['kasur'], hasLength(2));
      });
    });

    test('returns empty when status is not success', () async {
      await runWithRealHttpClient(() async {
        late HttpServer server;
        server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(() async {
          await server.close(force: true);
        });

        server.listen((req) async {
          req.response.statusCode = 200;
          req.response.headers.contentType = ContentType.json;
          req.response.write(jsonEncode({
            'status': 'error',
            'result': [],
          }));
          await req.response.close();
        });

        dotenv.testLoad(fileInput: '''
API_BASE_URL=http://127.0.0.1:${server.port}
CLIENT_ID_ANDROID=cid
CLIENT_SECRET_ANDROID=sec
CLIENT_ID_IOS=cid
CLIENT_SECRET_IOS=sec
''');

        final c = ProviderContainer();
        addTearDown(c.dispose);
        expect(await c.read(itemLookupProvider.future), isEmpty);
      });
    });

    test('uses network-error path when connection is refused', () async {
      await runWithRealHttpClient(() async {
        dotenv.testLoad(fileInput: '''
API_BASE_URL=http://127.0.0.1:65431
CLIENT_ID_ANDROID=cid
CLIENT_SECRET_ANDROID=sec
CLIENT_ID_IOS=cid
CLIENT_SECRET_IOS=sec
''');

        final c = ProviderContainer();
        addTearDown(c.dispose);
        expect(await c.read(itemLookupProvider.future), isEmpty);
      });
    });
  });
}
