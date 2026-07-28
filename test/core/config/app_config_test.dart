import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alitapricelist/core/config/app_config.dart';

void main() {
  group('AppConfig env resolution', () {
    // Urutan penting: dotenv adalah singleton global — begitu `testLoad`
    // dipanggil, `isInitialized` tidak bisa direset lagi di tes lain.
    test('returns empty string, not a crash, when dotenv never loaded', () {
      // assertConfigured() harus melempar StateError yang jelas, bukan
      // NotInitializedError mentah dari package flutter_dotenv.
      expect(() => AppConfig.assertConfigured(), throwsA(isA<StateError>()));
    });

    test('falls back to dotenv when no --dart-define is set', () {
      // Regression: `String.fromEnvironment` dipanggil dengan key literal
      // per-getter (bukan lewat parameter `String key`) — variabel/parameter
      // membuatnya selalu balik defaultValue walau --dart-define diisi saat
      // build, sehingga fallback ke dotenv tak pernah tersentuh di release.
      dotenv.testLoad(fileInput: 'API_BASE_URL=https://dotenv.example/api');

      expect(AppConfig.apiBaseUrl, 'https://dotenv.example/api');
    });
  });

  group('BrandSpecApiConfig.isConfigured', () {
    test('true when accessToken, clientId, and clientSecret are all set',
        () {
      const config = BrandSpecApiConfig(
        brand: 'Spring Air',
        host: 'springair.co.id',
        accessToken: 'token',
        clientId: 'id',
        clientSecret: 'secret',
      );
      expect(config.isConfigured, isTrue);
    });

    test('false when any credential is empty', () {
      const missingToken = BrandSpecApiConfig(
        brand: 'Therapedic',
        host: 'therapedic.co.id',
        accessToken: '',
        clientId: 'id',
        clientSecret: 'secret',
      );
      const missingClientId = BrandSpecApiConfig(
        brand: 'Therapedic',
        host: 'therapedic.co.id',
        accessToken: 'token',
        clientId: '',
        clientSecret: 'secret',
      );
      const missingClientSecret = BrandSpecApiConfig(
        brand: 'Therapedic',
        host: 'therapedic.co.id',
        accessToken: 'token',
        clientId: 'id',
        clientSecret: '',
      );
      expect(missingToken.isConfigured, isFalse);
      expect(missingClientId.isConfigured, isFalse);
      expect(missingClientSecret.isConfigured, isFalse);
    });
  });

  test(
      'AppConfig.brandSpecApis lists Comforta, Spring Air, Therapedic, and iSleep',
      () {
    final brands = AppConfig.brandSpecApis.map((c) => c.brand).toList();
    expect(brands,
        containsAll(['Comforta', 'Spring Air', 'Therapedic', 'iSleep']));
  });
}
