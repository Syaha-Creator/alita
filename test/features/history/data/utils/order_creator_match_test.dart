import 'package:alitapricelist/features/history/data/utils/order_creator_match.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isOrderCreator', () {
    test('matches auth userId', () {
      expect(
        isOrderCreator(orderCreator: '42', authUserId: 42, profileId: 99),
        isTrue,
      );
    });

    test('matches profile.id when auth userId differs (checkout creator)', () {
      expect(
        isOrderCreator(orderCreator: '99', authUserId: 42, profileId: 99),
        isTrue,
      );
    });

    test('rejects unrelated ids', () {
      expect(
        isOrderCreator(orderCreator: '7', authUserId: 42, profileId: 99),
        isFalse,
      );
    });

    test('matches when backend returns creator as display name', () {
      expect(
        isOrderCreator(
          orderCreator: 'Muhammad  Akbar',
          authUserId: 42,
          profileId: 99,
          profileName: 'Muhammad Akbar',
        ),
        isTrue,
      );
    });

    test('name soft-match when creator id empty uses creator_name', () {
      expect(
        isOrderCreator(
          orderCreator: '',
          orderCreatorName: 'Budi Santoso',
          authUserId: 1,
          profileName: 'Budi',
        ),
        isTrue,
      );
    });

    test('rejects unrelated name in creator', () {
      expect(
        isOrderCreator(
          orderCreator: 'Siti Aminah',
          authUserId: 42,
          profileName: 'Muhammad Akbar',
        ),
        isFalse,
      );
    });

    test(
        'matches auth login name when CWE profile name differs from creator',
        () {
      // creator di SP sering dari users.name (login), sementara profile.name
      // dari contact_work_experiences bisa beda ejaan/format.
      expect(
        isOrderCreator(
          orderCreator: 'Agnes Rossi',
          orderCreatorName: 'Agnes Rossi',
          authUserId: 42,
          profileId: 99,
          profileName: 'Agnes R. Trisna Lestari', // CWE — tidak soft-match
          authUserName: 'Agnes Rossi', // login — cocok
        ),
        isTrue,
      );
    });

    test('matches sales_code when names differ', () {
      expect(
        isOrderCreator(
          orderCreator: 'Nama Di SP',
          authUserId: 42,
          profileId: 99,
          profileName: 'Nama Dari CWE',
          authUserName: 'Nama Login Lain',
          orderSalesCode: 'JKT-001',
          userSalesCode: 'jkt-001',
        ),
        isTrue,
      );
    });

    test('rejects when names and sales_code all differ', () {
      expect(
        isOrderCreator(
          orderCreator: 'Nama Di SP',
          authUserId: 42,
          profileId: 99,
          profileName: 'Nama Dari CWE',
          authUserName: 'Nama Login Lain',
          orderSalesCode: 'JKT-001',
          userSalesCode: 'BDG-999',
        ),
        isFalse,
      );
    });
  });
}
