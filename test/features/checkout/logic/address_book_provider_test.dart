import 'package:alitapricelist/features/checkout/data/models/address_book_contact.dart';
import 'package:alitapricelist/features/checkout/data/services/address_book_service.dart';
import 'package:alitapricelist/features/checkout/logic/address_book_provider.dart';
import 'package:alitapricelist/features/profile/data/models/user_profile.dart';
import 'package:alitapricelist/features/profile/logic/profile_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAddressBookService extends Mock implements AddressBookService {}

UserProfile _profile({int areaId = 3}) => UserProfile(
      name: 'Tester',
      email: 'tester@test.com',
      workTitle: 'Staff',
      workPlaceName: 'HQ',
      areaName: 'Jakarta',
      areaId: areaId,
    );

void main() {
  late MockAddressBookService mockService;

  setUp(() {
    mockService = MockAddressBookService();
  });

  ProviderContainer buildContainer({UserProfile? profile}) {
    final container = ProviderContainer(
      overrides: [
        profileProvider.overrideWith((ref) async => profile),
        addressBookServiceProvider.overrideWithValue(mockService),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('addressBookContactsProvider', () {
    test('returns empty list when profile is null', () async {
      final container = buildContainer(profile: null);

      final contacts = await container.read(addressBookContactsProvider.future);

      expect(contacts, isEmpty);
      verifyNever(() => mockService.fetchByArea(any()));
    });

    test('returns empty list when profile.areaId is 0', () async {
      final container = buildContainer(profile: _profile(areaId: 0));

      final contacts = await container.read(addressBookContactsProvider.future);

      expect(contacts, isEmpty);
      verifyNever(() => mockService.fetchByArea(any()));
    });

    test('fetches contacts using profile.areaId', () async {
      when(() => mockService.fetchByArea(3)).thenAnswer(
        (_) async => const [
          AddressBookContact(id: 1, name: 'Budi', phone: '0811', areaId: 3),
        ],
      );

      final container = buildContainer(profile: _profile(areaId: 3));
      final contacts = await container.read(addressBookContactsProvider.future);

      expect(contacts, hasLength(1));
      expect(contacts.single.name, 'Budi');
      verify(() => mockService.fetchByArea(3)).called(1);
    });

    test('propagates service errors as AsyncError', () async {
      when(() => mockService.fetchByArea(any()))
          .thenThrow(Exception('HTTP 500'));

      final container = buildContainer(profile: _profile());

      await expectLater(
        container.read(addressBookContactsProvider.future),
        throwsA(isA<Exception>()),
      );
    });
  });
}
