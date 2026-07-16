import '../../../core/enums/order_status.dart';

/// Parse [approver_level_id] yang bisa int / String / null.
/// [fallback] default 99 agar level unknown diperlakukan konservatif.
int parseApproverLevel(dynamic value, [int fallback = 99]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

/// Cek apakah semua approval dengan level lebih rendah dari [myIndex]
/// sudah Approved (atau ada di [treatedAsApprovedIds] untuk cascade batch).
///
/// Jika `approver_level_id` pada [myIndex] ≤ 0 / tidak ada, fallback ke
/// index-based (backward compat dengan payload lama tanpa level).
bool arePriorApprovalsSatisfied({
  required List<Map<String, dynamic>> discounts,
  required int myIndex,
  Set<int> treatedAsApprovedIds = const {},
}) {
  if (myIndex < 0 || myIndex >= discounts.length) return false;

  final myLevelRaw = discounts[myIndex]['approver_level_id'];
  final myLevel = myLevelRaw == null
      ? 0
      : (myLevelRaw is num
          ? myLevelRaw.toInt()
          : int.tryParse(myLevelRaw.toString()) ?? 0);

  bool isSatisfied(Map<String, dynamic> disc) {
    if (OrderStatusX.fromDynamic(disc['approved']) == OrderStatus.approved) {
      return true;
    }
    final id = (disc['order_letter_discount_id'] as num?)?.toInt() ?? 0;
    return id > 0 && treatedAsApprovedIds.contains(id);
  }

  // Level tidak tersedia → index-based (urutan array API).
  if (myLevel <= 0) {
    for (var i = 0; i < myIndex; i++) {
      if (!isSatisfied(discounts[i])) return false;
    }
    return true;
  }

  // Level-based: semua baris dengan level lebih rendah harus satisfied.
  for (var i = 0; i < discounts.length; i++) {
    if (i == myIndex) continue;
    final otherRaw = discounts[i]['approver_level_id'];
    final otherLevel = otherRaw == null
        ? 0
        : (otherRaw is num
            ? otherRaw.toInt()
            : int.tryParse(otherRaw.toString()) ?? 0);
    if (otherLevel > 0 && otherLevel < myLevel) {
      if (!isSatisfied(discounts[i])) return false;
    }
  }
  return true;
}
