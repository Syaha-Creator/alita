import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:alitapricelist/core/enums/sales_mode.dart';
import 'package:alitapricelist/features/indirect/logic/sales_mode_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SalesModeNotifier', () {
    test('starts direct by default', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(salesModeProvider); // trigger lazy build()

      await Future.delayed(const Duration(milliseconds: 50));
      expect(container.read(salesModeProvider), SalesMode.direct);
    });

    test('loads persisted indirect mode', () async {
      SharedPreferences.setMockInitialValues({'sales_mode_v1': 'indirect'});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(salesModeProvider); // trigger lazy build()

      await Future.delayed(const Duration(milliseconds: 50));
      expect(container.read(salesModeProvider), SalesMode.indirect);
    });

    test('setMode persists across instances', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(salesModeProvider); // trigger lazy build()
      await Future.delayed(const Duration(milliseconds: 50));

      await container.read(salesModeProvider.notifier).setMode(
            SalesMode.indirect,
          );
      expect(container.read(salesModeProvider), SalesMode.indirect);

      // "Instance baru" disimulasikan lewat container Riverpod terpisah —
      // notifier baru harus baca ulang dari SharedPreferences yang sudah
      // di-persist oleh container pertama di atas.
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);
      container2.read(salesModeProvider); // trigger lazy build()
      await Future.delayed(const Duration(milliseconds: 50));
      expect(container2.read(salesModeProvider), SalesMode.indirect);
    });

    test('setMode called before initial load finishes does not get '
        'clobbered by the in-flight load', () async {
      // Disk has 'direct' persisted — setMode(indirect) races ahead of the
      // build()-triggered _load() reading that stale value.
      SharedPreferences.setMockInitialValues({'sales_mode_v1': 'direct'});
      final racing = ProviderContainer();
      addTearDown(racing.dispose);
      // No delay — setMode() must itself await the in-flight load. Reading
      // `.notifier` both triggers build() (kicking off `_load()`) AND gives
      // us the instance to call setMode() on, same tick.
      final racingNotifier = racing.read(salesModeProvider.notifier);
      await racingNotifier.setMode(SalesMode.indirect);

      expect(racing.read(salesModeProvider), SalesMode.indirect);

      final verify = ProviderContainer();
      addTearDown(verify.dispose);
      verify.read(salesModeProvider); // trigger lazy build()
      await Future.delayed(const Duration(milliseconds: 50));
      expect(verify.read(salesModeProvider), SalesMode.indirect);
    });
  });
}
