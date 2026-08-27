import 'package:flutter_test/flutter_test.dart';

import 'package:alitapricelist/core/config/app_env.dart';

void main() {
  group('AppEnv.resolve', () {
    test('explicit production wins over staging URL', () {
      expect(
        AppEnv.resolve(
          explicit: 'production',
          apiBaseUrl: AppEnv.stagingApiBaseUrl,
        ),
        AppEnv.production,
      );
    });

    test('explicit staging / prod aliases', () {
      expect(
        AppEnv.resolve(explicit: 'stage', apiBaseUrl: ''),
        AppEnv.staging,
      );
      expect(
        AppEnv.resolve(explicit: 'prod', apiBaseUrl: ''),
        AppEnv.production,
      );
    });

    test('infers staging from API_BASE_URL when APP_ENV empty', () {
      expect(
        AppEnv.resolve(
          explicit: '',
          apiBaseUrl: AppEnv.stagingApiBaseUrl,
        ),
        AppEnv.staging,
      );
    });

    test('infers production from non-staging Alita host', () {
      expect(
        AppEnv.resolve(
          explicit: '',
          apiBaseUrl: AppEnv.productionApiBaseUrl,
        ),
        AppEnv.production,
      );
    });
  });

  group('AppEnv.paperPaymentPath', () {
    test('staging → paper_id_staging', () {
      expect(
        AppEnv.paperPaymentPath(appEnv: AppEnv.staging),
        'paper_id_staging',
      );
    });

    test('production → payper_id', () {
      expect(
        AppEnv.paperPaymentPath(appEnv: AppEnv.production),
        'payper_id',
      );
    });

    test('override wins', () {
      expect(
        AppEnv.paperPaymentPath(
          appEnv: AppEnv.production,
          overridePath: 'paper_id_custom',
        ),
        'paper_id_custom',
      );
    });
  });

  group('AppEnv.assertConsistent', () {
    test('throws when production points at staging host', () {
      expect(
        () => AppEnv.assertConsistent(
          appEnv: AppEnv.production,
          apiBaseUrl: AppEnv.stagingApiBaseUrl,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('throws when staging points at production host', () {
      expect(
        () => AppEnv.assertConsistent(
          appEnv: AppEnv.staging,
          apiBaseUrl: AppEnv.productionApiBaseUrl,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('allows matching pairs', () {
      expect(
        () => AppEnv.assertConsistent(
          appEnv: AppEnv.staging,
          apiBaseUrl: AppEnv.stagingApiBaseUrl,
        ),
        returnsNormally,
      );
      expect(
        () => AppEnv.assertConsistent(
          appEnv: AppEnv.production,
          apiBaseUrl: AppEnv.productionApiBaseUrl,
        ),
        returnsNormally,
      );
    });
  });
}
