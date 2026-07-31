/// Represents a single contact returned by the `/address_books` API (Ransack
/// endpoint, filtered server-side by `q[area_id_eq]`).
///
/// Source is an external ERP-style address book — field names on the wire
/// (`ABALPH`, `ABALKY`) are that system's own column names, not ours. Only
/// name + phone are available; there is no address/region data, so picking a
/// contact can only prefill name & phone — the rest must still be filled
/// manually.
class AddressBookContact {
  final int id;
  final String name;
  final String phone;
  final int areaId;

  const AddressBookContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.areaId,
  });

  factory AddressBookContact.fromJson(Map<String, dynamic> json) {
    return AddressBookContact(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['ABALPH'] as String?)?.trim() ?? '',
      phone: (json['ABALKY'] as String?)?.trim() ?? '',
      areaId: (json['area_id'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AddressBookContact && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
