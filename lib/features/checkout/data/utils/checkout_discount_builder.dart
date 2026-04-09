import '../models/approver_model.dart';

/// Builds checkout discount approval chain payload entries.
class CheckoutDiscountBuilder {
  const CheckoutDiscountBuilder._();

  static List<Map<String, dynamic>> build({
    required int userId,
    required String creatorName,
    required String creatorTitle,
    required Approver? selectedSpv,
    required Approver? selectedManager,
    required int? analystId,
    required String analystName,
    required String analystTitle,
    required double discount1,
    required double discount2,
    required double discount3,
    required double discount4,
    /// Indirect sales: level-2 `approver_level` harus **ASM** (bukan SPV).
    bool useAsmSecondApprover = false,
  }) {
    final discounts = <Map<String, dynamic>>[];
    final now = DateTime.now().toIso8601String();

    // Level 1 — User/Sales (auto-approved)
    discounts.add({
      'discount': discount1.toString(),
      'approver': userId,
      'approver_name': creatorName,
      'approver_level_id': 1,
      'approver_level': 'User',
      'approver_work_tittle': creatorTitle,
      'approved': true,
      'approved_at': now,
    });

    // Level 2 — SPV (direct) atau ASM (indirect); selalu disertakan jika dipilih.
    if (selectedSpv != null) {
      discounts.add({
        'discount': discount2.toString(),
        'approver': selectedSpv.id,
        'approver_name': selectedSpv.fullName,
        'approver_level_id': 2,
        'approver_level': useAsmSecondApprover ? 'ASM' : 'SPV',
        'approver_work_tittle': selectedSpv.jobLevelName,
        'approved': null,
        'approved_at': null,
      });
    }

    // Level 3 — RSM / Manager (kondisional)
    if (discount3 > 0 && selectedManager != null) {
      discounts.add({
        'discount': discount3.toString(),
        'approver': selectedManager.id,
        'approver_name': selectedManager.fullName,
        'approver_level_id': 3,
        'approver_level': 'RSM',
        'approver_work_tittle': selectedManager.jobLevelName,
        'approved': null,
        'approved_at': null,
      });
    }

    // Level 4 — Analyst (kondisional)
    if (discount4 > 0 && analystId != null) {
      discounts.add({
        'discount': discount4.toString(),
        'approver': analystId,
        'approver_name': analystName,
        'approver_level_id': 4,
        'approver_level': 'Analyst',
        'approver_work_tittle': analystTitle,
        'approved': null,
        'approved_at': null,
      });
    }

    return discounts;
  }

  /// Voucher FOC 100%: satu baris diskon agar order letter menandai barang gratis.
  /// `discount` = 100 (persen); `approver_level_id` 90 agar tidak bentrok 1–4 & toko.
  ///
  /// Persetujuan **hanya** ke [selectedSpv] — tidak memakai sales/user sebagai approver.
  static List<Map<String, dynamic>> buildFocVoucherRow({
    required Approver selectedSpv,
  }) {
    return [
      {
        'discount': '100',
        'approver': selectedSpv.id,
        'approver_name': selectedSpv.fullName,
        'approver_level_id': 90,
        'approver_level': 'FOC',
        'approver_work_tittle': selectedSpv.jobLevelName,
        'approved': null,
        'approved_at': null,
      },
    ];
  }

  /// Diskon toko (indirect): `approver_level_id` mulai 5 agar tidak bentrok 1–4.
  static List<Map<String, dynamic>> buildStoreDiscountRows({
    required List<double> storeDiscounts,
    required String storeAlphaName,
  }) {
    const startLevel = 5;
    final now = DateTime.now().toIso8601String();
    final out = <Map<String, dynamic>>[];
    var slot = 0;
    for (final d in storeDiscounts) {
      if (d <= 0) continue;
      out.add({
        'discount': d.toString(),
        'approver': null,
        'approver_name': storeAlphaName,
        'approver_level_id': startLevel + slot,
        'approver_level': 'Diskon Toko ${slot + 1}',
        'approver_work_tittle': 'Toko',
        'approved': true,
        'approved_at': now,
      });
      slot++;
    }
    return out;
  }
}
