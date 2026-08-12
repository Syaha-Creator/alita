import '../../../core/enums/order_status.dart';

/// Parse [approver_level_id] yang bisa int / String / null.
/// [fallback] default 99 agar level unknown diperlakukan konservatif.
int parseApproverLevel(dynamic value, [int fallback = 99]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

/// Ambil ID approver dari baris discount — API kadang kirim `approver_id`,
/// kadang hanya `approver` (int/string/map).
String discountApproverId(Map<String, dynamic> disc) {
  final raw = disc['approver_id'] ?? disc['approver'];
  if (raw is Map) {
    return (raw['id'] ?? '').toString().trim();
  }
  return raw?.toString().trim() ?? '';
}

bool _isDiscountSatisfied(
  Map<String, dynamic> disc, {
  Set<int> treatedAsApprovedIds = const {},
}) {
  if (OrderStatusX.fromDynamic(disc['approved']) == OrderStatus.approved) {
    return true;
  }
  final id = (disc['order_letter_discount_id'] as num?)?.toInt() ?? 0;
  return id > 0 && treatedAsApprovedIds.contains(id);
}

/// True jika semua baris dengan level &lt; [myLevel] sudah Approved
/// (lintas seluruh detail SP — bukan hanya satu komponen).
///
/// Dipakai inbox Menunggu supaya RSM tidak lolos saat SPV masih Pending
/// meski urutan array API = 1,3,4,2.
///
/// Level khusus ≥ 80 (Program Bulanan / FOC): hanya menunggu User (level 1),
/// **tidak** menunggu RSM/Analyst — supaya SPV bisa approve FOC bersama L2.
bool areLowerApprovalLevelsSatisfied({
  required Iterable<Map<String, dynamic>> allDiscounts,
  required int myLevel,
  Set<int> treatedAsApprovedIds = const {},
}) {
  if (myLevel <= 0) return true;
  // FOC/Program: prior eksklusif sampai level 2 → hanya cek level 1.
  final priorExclusiveUpper = myLevel >= 80 ? 2 : myLevel;
  for (final disc in allDiscounts) {
    final level = resolveApproverLevel(disc);
    if (level <= 0 || level >= priorExclusiveUpper) continue;
    if (!_isDiscountSatisfied(disc, treatedAsApprovedIds: treatedAsApprovedIds)) {
      return false;
    }
  }
  return true;
}

/// ID baris `order_letter_discounts` — API kadang pakai
/// `order_letter_discount_id`, kadang `id`.
int discountRowId(Map<String, dynamic> disc) {
  final raw = disc['order_letter_discount_id'] ?? disc['id'];
  if (raw is num) return raw.toInt();
  return int.tryParse(raw?.toString() ?? '') ?? 0;
}

int _levelFromLabel(String raw) {
  final label = raw.trim().toLowerCase();
  if (label.isEmpty) return 0;

  // Cocokkan token level eksplisit dulu (urutan penting).
  if (label == 'foc' || label.startsWith('foc ')) return 90;
  if (label.contains('program bulanan') || label == 'program') return 80;
  if (label == 'analyst' ||
      label == 'analis' ||
      label.startsWith('analyst') ||
      label.startsWith('analis')) {
    return 4;
  }
  if (label == 'rsm' ||
      label == 'gm' ||
      label == 'manager' ||
      label.startsWith('rsm ') ||
      label.startsWith('gm ')) {
    return 3;
  }
  if (label == 'spv' ||
      label == 'asm' ||
      label == 'supervisor' ||
      label.startsWith('spv ') ||
      label.startsWith('asm ') ||
      label.startsWith('supervisor') ||
      label.startsWith('area sales')) {
    return 2;
  }
  if (label == 'user' || label == 'sales' || label.startsWith('user ')) {
    return 1;
  }

  // Fallback contains — hindari "area sales manager" → RSM.
  if (label.contains('foc')) return 90;
  if (label.contains('analyst') || label.contains('analis')) return 4;
  if (label.contains('asm') ||
      label.contains('spv') ||
      label.contains('supervisor')) {
    return 2;
  }
  if (label.contains('rsm') ||
      (label.contains('manager') && !label.contains('area sales'))) {
    return 3;
  }
  if (label.contains('user')) return 1;
  return 0;
}

/// Resolve level approval dari baris discount.
///
/// Urutan:
/// 1. `approver_level_id` numerik > 0
/// 2. Label `approver_level` (User / SPV / ASM / RSM)
/// 3. `approver_work_tittle` sebagai fallback
/// 4. 0 jika tidak dikenali
///
/// Dipakai agar RSM tidak “lolos” ke Menunggu saat baris SPV masih Pending
/// tetapi API mengirim level_id kosong (hanya label).
int resolveApproverLevel(Map<String, dynamic> disc) {
  final raw = disc['approver_level_id'];
  if (raw != null) {
    final parsed =
        raw is num ? raw.toInt() : int.tryParse(raw.toString().trim());
    if (parsed != null && parsed > 0) return parsed;
  }

  final fromLevel = _levelFromLabel(disc['approver_level']?.toString() ?? '');
  if (fromLevel > 0) return fromLevel;

  return _levelFromLabel(disc['approver_work_tittle']?.toString() ?? '');
}

/// Cek apakah semua approval dengan level lebih rendah dari [myIndex]
/// sudah Approved (atau ada di [treatedAsApprovedIds] untuk cascade batch).
///
/// Jika level pada [myIndex] ≤ 0 / tidak dikenali, fallback ke index-based
/// (backward compat dengan payload lama tanpa level).
bool arePriorApprovalsSatisfied({
  required List<Map<String, dynamic>> discounts,
  required int myIndex,
  Set<int> treatedAsApprovedIds = const {},
}) {
  if (myIndex < 0 || myIndex >= discounts.length) return false;

  final myLevel = resolveApproverLevel(discounts[myIndex]);

  // Level tidak dikenali → index-based (urutan array API).
  if (myLevel <= 0) {
    for (var i = 0; i < myIndex; i++) {
      if (!_isDiscountSatisfied(
        discounts[i],
        treatedAsApprovedIds: treatedAsApprovedIds,
      )) {
        return false;
      }
    }
    return true;
  }

  // Level-based dalam satu detail + index fallback untuk baris tanpa level.
  for (var i = 0; i < discounts.length; i++) {
    if (i == myIndex) continue;
    final otherLevel = resolveApproverLevel(discounts[i]);
    final isPriorByLevel = otherLevel > 0 && otherLevel < myLevel;
    final isPriorByIndexFallback = otherLevel <= 0 && i < myIndex;
    if (isPriorByLevel || isPriorByIndexFallback) {
      if (!_isDiscountSatisfied(
        discounts[i],
        treatedAsApprovedIds: treatedAsApprovedIds,
      )) {
        return false;
      }
    }
  }
  return true;
}
