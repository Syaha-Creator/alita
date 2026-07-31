import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/logic/profile_provider.dart';
import '../data/models/address_book_contact.dart';
import '../data/services/address_book_service.dart';

final addressBookServiceProvider = Provider<AddressBookService>((ref) {
  return AddressBookService();
});

/// Contacts from the server-side `/address_books` search, filtered by the
/// logged-in sales' own work area (`UserProfile.areaId`) — replaces the old
/// on-device-only "saved contacts" list in the checkout contact picker.
///
/// Read-only, fetch-once, no user-triggered mutation → [FutureProvider] is
/// the right fit here (not a [Notifier]).
final addressBookContactsProvider =
    FutureProvider.autoDispose<List<AddressBookContact>>((ref) async {
  final profile = await ref.watch(profileProvider.future);
  final areaId = profile?.areaId ?? 0;
  if (areaId <= 0) return const [];
  return ref.watch(addressBookServiceProvider).fetchByArea(areaId);
});
