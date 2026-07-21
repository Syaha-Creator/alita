import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:alitapricelist/core/enums/sales_mode.dart';
import 'package:alitapricelist/features/indirect/logic/sales_mode_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SalesModeNotifier', () {
    test('starts direct by default', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = SalesModeNotifier();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(notifier.state, SalesMode.direct);
    });

    test('loads persisted indirect mode', () async {
      SharedPreferences.setMockInitialValues({'sales_mode_v1': 'indirect'});
      final notifier = SalesModeNotifier();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(notifier.state, SalesMode.indirect);
    });

    test('setMode persists across instances', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = SalesModeNotifier();
      await Future.delayed(const Duration(milliseconds: 50));

      await notifier.setMode(SalesMode.indirect);
      expect(notifier.state, SalesMode.indirect);

      final notifier2 = SalesModeNotifier();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(notifier2.state, SalesMode.indirect);
    });

    test('setMode called before initial load finishes does not get '
        'clobbered by the in-flight load', () async {
      // Disk has 'direct' persisted — setMode(indirect) races ahead of the
      // constructor-triggered _load() reading that stale value.
      SharedPreferences.setMockInitialValues({'sales_mode_v1': 'direct'});
      final racing = SalesModeNotifier();
      // No delay — setMode() must itself await the in-flight load.
      await racing.setMode(SalesMode.indirect);

      expect(racing.state, SalesMode.indirect);

      final verify = SalesModeNotifier();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(verify.state, SalesMode.indirect);
    });
  });
}
