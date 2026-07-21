import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alitapricelist/core/config/app_config.dart';

void main() {
  setUp(() {
    dotenv.testLoad(fileInput: '');
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
