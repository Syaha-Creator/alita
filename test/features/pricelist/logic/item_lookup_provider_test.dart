import 'dart:convert';

import 'package:alitapricelist/core/services/api_client.dart';
import 'package:alitapricelist/features/pricelist/logic/item_lookup_provider.dart';
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
      () => mockApi.get(
        '/pl_lookup_item_nums',
        timeout: any(named: 'timeout'),
      ),
    ).thenAnswer((_) async => response);
  }

  group('itemLookupProvider', () {
    test('groups results by lowercased tipe', () async {
      mockGet(
        http.Response(
          jsonEncode({
            'status': 'success',
            'result': [
              {'tipe': 'Kasur', 'ukuran': '160x200', 'item_num': 'K-1'},
              {'tipe': 'kasur', 'ukuran': '180x200', 'item_num': 'K-2'},
              {'tipe': 'Divan', 'ukuran': '160x200', 'item_num': 'D-1'},
            ],
          }),
          200,
        ),
      );

      final result = await buildContainer().read(itemLookupProvider.future);

      expect(result.keys, containsAll(['kasur', 'divan']));
      expect(result['kasur'], hasLength(2));
      expect(result['divan'], hasLength(1));
    });

    test('returns empty map on non-200 response', () async {
      mockGet(http.Response('Server error', 500));

      final result = await buildContainer().read(itemLookupProvider.future);

      expect(result, isEmpty);
    });

    test('returns empty map when status is not success', () async {
      mockGet(http.Response(jsonEncode({'status': 'error'}), 200));

      final result = await buildContainer().read(itemLookupProvider.future);

      expect(result, isEmpty);
    });

    test('does not throw when the API call itself throws', () async {
      when(
        () => mockApi.get(
          '/pl_lookup_item_nums',
          timeout: any(named: 'timeout'),
        ),
      ).thenThrow(Exception('network down'));

      final result = await buildContainer().read(itemLookupProvider.future);

      expect(result, isEmpty);
    });
  });
}
