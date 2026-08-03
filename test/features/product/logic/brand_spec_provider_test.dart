import 'package:alitapricelist/features/product/logic/brand_spec_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('brandSpecProvider', () {
    // NOTE: AppConfig.brandSpecApis is entirely sourced from
    // String.fromEnvironment (see app_config.dart) — there is no DI seam to
    // inject fake brand credentials/host into this provider without a
    // broader AppConfig refactor, which is out of scope here. In the test
    // environment (no --dart-define), every brand's isConfigured is false,
    // so this test can only exercise the "no brand configured" guard path.
    // The per-brand fetch/merge logic (_fetchOne) is otherwise untestable
    // without that refactor.
    test('returns an empty list when no brand API is configured', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container.read(brandSpecProvider.future);

      expect(result, isEmpty);
    });
  });
}
