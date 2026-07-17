import 'package:alitapricelist/core/router/android_system_back.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveAndroidSystemBack', () {
    test('pops router when canPop', () {
      expect(
        resolveAndroidSystemBack(
          routerCanPop: true,
          matchedLocation: '/profile',
          canChooseSalesMode: false,
          exitPromptActive: false,
        ),
        AndroidSystemBackDecision.popRouter,
      );
    });

    test('admin on home without stack returns to sales hub', () {
      expect(
        resolveAndroidSystemBack(
          routerCanPop: false,
          matchedLocation: '/',
          canChooseSalesMode: true,
          exitPromptActive: false,
        ),
        AndroidSystemBackDecision.goSalesHub,
      );
    });

    test('non-admin on home asks confirm then exits', () {
      expect(
        resolveAndroidSystemBack(
          routerCanPop: false,
          matchedLocation: '/',
          canChooseSalesMode: false,
          exitPromptActive: false,
        ),
        AndroidSystemBackDecision.confirmExit,
      );
      expect(
        resolveAndroidSystemBack(
          routerCanPop: false,
          matchedLocation: '/',
          canChooseSalesMode: false,
          exitPromptActive: true,
        ),
        AndroidSystemBackDecision.exitApp,
      );
    });

    test('sales hub requires double back to exit', () {
      expect(
        resolveAndroidSystemBack(
          routerCanPop: false,
          matchedLocation: '/sales_hub',
          canChooseSalesMode: true,
          exitPromptActive: false,
        ),
        AndroidSystemBackDecision.confirmExit,
      );
    });

    test('orphan non-root goes home instead of exiting', () {
      expect(
        resolveAndroidSystemBack(
          routerCanPop: false,
          matchedLocation: '/order_history',
          canChooseSalesMode: false,
          exitPromptActive: false,
        ),
        AndroidSystemBackDecision.goHome,
      );
    });

    test('login exits immediately', () {
      expect(
        resolveAndroidSystemBack(
          routerCanPop: false,
          matchedLocation: '/login',
          canChooseSalesMode: false,
          exitPromptActive: false,
        ),
        AndroidSystemBackDecision.exitApp,
      );
    });
  });
}
