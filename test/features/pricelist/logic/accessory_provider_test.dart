import 'dart:convert';

import 'package:alitapricelist/core/services/api_client.dart';
import 'package:alitapricelist/features/pricelist/logic/accessory_provider.dart';
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

  ProviderContainer buildContainer() {
    final container = ProviderContainer(
      overrides: [apiClientProvider.overrideWithValue(mockApi)],
    );
    addTearDown(container.dispose);
    return container;
  }

  void mockGet(http.Response response) {
    when(
      () => mockApi.get('/pl_accessories', timeout: any(named: 'timeout')),
    ).thenAnswer((_) async => response);
  }

  group('accessoryProvider', () {
    test('parses accessories and de-duplicates by itemNum', () async {
      mockGet(
        http.Response(
          jsonEncode({
            'status': 'success',
            'result': [
              {'tipe': 'Kaki', 'item_num': 'ACC-1', 'ukuran': '10cm', 'pricelist': '50000'},
              {'tipe': 'Kaki', 'item_num': 'ACC-1', 'ukuran': '10cm', 'pricelist': '60000'},
              {'tipe': 'Sandaran', 'item_num': 'ACC-2', 'ukuran': '-', 'pricelist': 75000},
            ],
          }),
          200,
        ),
      );

      final result = await buildContainer().read(accessoryProvider.future);

      expect(result, hasLength(2));
      final byId = {for (final a in result) a.itemNum: a};
      // Last occurrence of a duplicate itemNum wins (Map overwrite semantics).
      expect(byId['ACC-1']!.pricelist, 60000);
      expect(byId['ACC-2']!.pricelist, 75000);
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
        () => mockApi.get('/pl_accessories', timeout: any(named: 'timeout')),
      ).thenThrow(Exception('network down'));

      final result = await buildContainer().read(accessoryProvider.future);

      expect(result, isEmpty);
    });
  });
}
