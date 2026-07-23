import 'package:flutter_test/flutter_test.dart';

import 'package:alitapricelist/core/router/app_router.dart';

void main() {
  group('isAllowedDeepLinkPath', () {
    test('allows verified product deep link paths', () {
      expect(isAllowedDeepLinkPath('/product/123'), true);
      expect(isAllowedDeepLinkPath('/product/abc-def'), true);
    });

    test('rejects paths outside the verified associated-domain allowlist',
        () {
      expect(isAllowedDeepLinkPath('/checkout'), false);
      expect(isAllowedDeepLinkPath('/approval_detail'), false);
      expect(isAllowedDeepLinkPath('/order_detail'), false);
      expect(isAllowedDeepLinkPath('/'), false);
      expect(isAllowedDeepLinkPath('/products'), false);
      expect(isAllowedDeepLinkPath(''), false);
    });
  });
}
