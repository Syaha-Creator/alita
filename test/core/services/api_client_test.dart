import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alitapricelist/core/services/api_client.dart';

void main() {
  final client = ApiClient.instance;

  setUpAll(() {
    dotenv.testLoad(fileInput: '''
API_BASE_URL=https://test.example.com
CLIENT_ID=test-client-id
CLIENT_SECRET=test-client-secret
''');
  });

  group('buildUri', () {
    test('full URL is preserved as-is', () {
      final uri = client.buildUri('https://example.com/api/data');
      expect(uri.scheme, 'https');
      expect(uri.host, 'example.com');
      expect(uri.path, '/api/data');
    });

    test('merges extra query params', () {
      final uri = client.buildUri(
        'https://example.com/data',
        {'page': '2', 'limit': '10'},
      );
      expect(uri.queryParameters['page'], '2');
      expect(uri.queryParameters['limit'], '10');
    });

    test('preserves existing query params from URL', () {
      final uri = client.buildUri(
        'https://example.com/data?existing=true',
        {'extra': 'val'},
      );
      expect(uri.queryParameters['existing'], 'true');
      expect(uri.queryParameters['extra'], 'val');
    });

    test('handles URL with no extra query', () {
      final uri = client.buildUri('https://example.com/test');
      expect(uri.toString(), contains('example.com'));
      expect(uri.path, '/test');
    });

    test('handles URL with existing query and no extra', () {
      final uri = client.buildUri('https://example.com/test?a=1');
      expect(uri.queryParameters['a'], '1');
    });
  });

  group('buildAuthUri', () {
    test('injects auth credentials from AppConfig', () {
      final uri = client.buildAuthUri(
        'https://example.com/api',
        'test-token-123',
      );
      expect(uri.queryParameters['access_token'], 'test-token-123');
    });

    test('merges extra query with auth query', () {
      final uri = client.buildAuthUri(
        'https://example.com/api',
        'tok',
        {'area': 'Jakarta'},
      );
      expect(uri.queryParameters['access_token'], 'tok');
      expect(uri.queryParameters['area'], 'Jakarta');
    });
  });
}
