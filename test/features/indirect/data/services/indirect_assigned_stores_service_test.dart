import 'dart:io';

import 'package:alitapricelist/features/indirect/data/services/indirect_assigned_stores_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUp(() {
    dotenv.testLoad(fileInput: '''
INDIRECT_STORES_BASE_URL=https://indirect-stores.test
INDIRECT_API_KEY=test-api-key
INDIRECT_CLIENT_KEY=test-client-key
''');
  });

  group('IndirectAssignedStoresService.fetchBySalesCode — retry', () {
    test(
      'retries on a transient SocketException and succeeds on a later attempt',
      () async {
        var callCount = 0;
        final client = MockClient((request) async {
          callCount++;
          if (callCount < 3) {
            throw const SocketException('Connection reset by peer');
          }
          return http.Response(
            '{"status":true,"result":[]}',
            200,
          );
        });

        final service = IndirectAssignedStoresService(client: client);
        final result = await service.fetchBySalesCode('SC001');

        expect(result, isEmpty);
        expect(
          callCount,
          3,
          reason: 'Should retry twice after transient failures before '
              'the 3rd attempt succeeds.',
        );
      },
    );

    test(
      'gives up and rethrows after exhausting retries on persistent failure',
      () async {
        final client = MockClient((request) async {
          throw const SocketException('Connection reset by peer');
        });

        final service = IndirectAssignedStoresService(client: client);

        await expectLater(
          () => service.fetchBySalesCode('SC001'),
          throwsA(isA<SocketException>()),
        );
      },
    );

    test(
      'does not retry a deterministic non-200 response (no point retrying)',
      () async {
        var callCount = 0;
        final client = MockClient((request) async {
          callCount++;
          return http.Response('Not found', 404);
        });

        final service = IndirectAssignedStoresService(client: client);

        await expectLater(
          () => service.fetchBySalesCode('SC001'),
          throwsA(isA<Exception>()),
        );
        expect(callCount, 1);
      },
    );
  });
}
