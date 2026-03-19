/// Determines whether the shipping recipient differs from the customer.
///
/// Returns `true` when either the shipping name or address is
/// non-empty, non-dash, and differs (case-insensitive) from the customer's.
bool isShippingDifferent({
  required String shipToName,
  required String shipToAddress,
  required String customerName,
  required String customerAddress,
}) {
  final shipName = shipToName.trim();
  final shipAddr = shipToAddress.trim();
  if (shipName.isEmpty && shipAddr.isEmpty) return false;

  final nameDiff = shipName.isNotEmpty &&
      shipName != '-' &&
      shipName.toLowerCase() != customerName.trim().toLowerCase();

  final addrDiff = shipAddr.isNotEmpty &&
      shipAddr != '-' &&
      shipAddr.toLowerCase() != customerAddress.trim().toLowerCase();

  return nameDiff || addrDiff;
}
