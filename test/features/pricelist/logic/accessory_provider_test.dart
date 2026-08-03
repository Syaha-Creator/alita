import 'dart:convert';

import 'package:alitapricelist/core/services/api_client.dart';
import 'package:alitapricelist/features/pricelist/logic/accessory_provider.dart';
import 'package:alitapricelist/features/pricelist/logic/product_provider.dart'
    show effectiveAreaProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApi;

  setUpAll(() {
    registerFallbackValue(const Duration(seconds: 15));
  });

  setUp(() {
    mockApi = MockApiClient();
  });

  ProviderContainer buildContainer({String area = 'Palembang'}) {
    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(mockApi),
        effectiveAreaProvider.overrideWithValue(area),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  void mockGet(http.Response response, {String area = 'Palembang'}) {
    when(
      () => mockApi.get(
        '/pl_accessories',
        queryParams: {'area': area},
        timeout: any(named: 'timeout'),
      ),
    ).thenAnswer((_) async => response);
  }

  group('accessoryProvider', () {
    test('requests the effective area as a query param', () async {
      mockGet(
        http.Response(jsonEncode({'status': 'success', 'result': []}), 200),
        area: 'Palembang',
      );

      await buildContainer(area: 'Palembang').read(accessoryProvider.future);

      verify(
        () => mockApi.get(
          '/pl_accessories',
          queryParams: {'area': 'Palembang'},
          timeout: any(named: 'timeout'),
        ),
      ).called(1);
    });

    test('returns empty list without calling the API when area is empty',
        () async {
      final result =
          await buildContainer(area: '').read(accessoryProvider.future);

      expect(result, isEmpty);
      verifyNever(
        () => mockApi.get(any(), queryParams: any(named: 'queryParams')),
      );
    });

    test(
      'de-duplicates by itemNum within the same area, but keeps rows from '
      'other areas out entirely (pricelist differs per area — regression: '
      'previously deduped globally and could silently show the wrong '
      "area's price)",
      () async {
        mockGet(
          http.Response(
            jsonEncode({
              'status': 'success',
              'result': [
                {
                  'tipe': 'Kaki',
                  'item_num': 'ACC-1',
                  'ukuran': '10cm',
                  'pricelist': '50000',
                  'area': 'Palembang',
                },
                // Duplicate itemNum, same area — last one should win.
                {
                  'tipe': 'Kaki',
                  'item_num': 'ACC-1',
                  'ukuran': '10cm',
                  'pricelist': '60000',
                  'area': 'Palembang',
                },
                // Same itemNum but a DIFFERENT area with a different price —
                // must be excluded entirely, not merged/overwritten.
                {
                  'tipe': 'Kaki',
                  'item_num': 'ACC-1',
                  'ukuran': '10cm',
                  'pricelist': '999999',
                  'area': 'Jabodetabek',
                },
                {
                  'tipe': 'Sandaran',
                  'item_num': 'ACC-2',
                  'ukuran': '-',
                  'pricelist': 75000,
                  'area': 'Palembang',
                },
              ],
            }),
            200,
          ),
        );

        final result =
            await buildContainer().read(accessoryProvider.future);

        expect(result, hasLength(2));
        final byId = {for (final a in result) a.itemNum: a};
        expect(byId['ACC-1']!.pricelist, 60000);
        expect(byId['ACC-2']!.pricelist, 75000);
      },
    );

    test('accepts rows without an area field as-is (legacy API shape)',
        () async {
      mockGet(
        http.Response(
          jsonEncode({
            'status': 'success',
            'result': [
              {'tipe': 'Kaki', 'item_num': 'ACC-1', 'ukuran': '10cm', 'pricelist': 50000},
            ],
          }),
          200,
        ),
      );

      final result = await buildContainer().read(accessoryProvider.future);

      expect(result, hasLength(1));
    });

    test('returns empty list on non-200 response', () async {
      mockGet(http.Response('Server error', 500));

      final result = await buildContainer().read(accessoryProvider.future);

      expect(result, isEmpty);
    });

    test('returns empty list on malformed response body', () async {
      mockGet(http.Response('not json', 200));

      final result = await buildContainer().read(accessoryProvider.future);

      expect(result, isEmpty);
    });

    test('returns empty list when status is not success and no data key',
        () async {
      mockGet(http.Response(jsonEncode({'status': 'error'}), 200));

      final result = await buildContainer().read(accessoryProvider.future);

      expect(result, isEmpty);
    });

    test('does not throw when the API call itself throws', () async {
      when(
        () => mockApi.get(
          '/pl_accessories',
          queryParams: {'area': 'Palembang'},
          timeout: any(named: 'timeout'),
        ),
      ).thenThrow(Exception('network down'));

      final result = await buildContainer().read(accessoryProvider.future);

      expect(result, isEmpty);
    });
  });
}
