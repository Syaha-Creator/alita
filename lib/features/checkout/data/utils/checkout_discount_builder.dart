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

    /// True untuk alur indirect:
    ///   Level 1 User  = 0 (creator saja, tidak ada self-approved discount).
    ///   Level 2 ASM   = 0 (acknowledgment).
    ///   Level 3 RSM   = semua diskon non-zero via discount_extra (d1, d2, d3).
    bool isIndirectOrder = false,

    /// True jika ada item yang bonusnya diubah dari bundle default.
    /// RSM approval tetap dibutuhkan meski semua diskon = 0.
    bool isBonusCustomized = false,

    /// Nominal (Rp) per discount level — diisi per komponen oleh checkout_order_service.
    /// Dipakai untuk:
    /// - `discount_price` di setiap baris yang punya persentase non-zero.
    /// - `discount_extra_price` di baris Manager (L3 indirect) & Analyst (L4).
    double? discount1NominalLine,
    double? discount2NominalLine,
    double? discount3NominalLine,
    double? discount4NominalLine,
  }) {
    final discounts = <Map<String, dynamic>>[];
    final now = DateTime.now().toIso8601String();

    if (isIndirectOrder) {
      // ── INDIRECT ──────────────────────────────────────────────
      // Level 1 — User: creator saja, tidak self-approve diskon apapun.
      discounts.add({
        'discount': '0',
        'approver': userId,
        'approver_name': creatorName,
        'approver_level_id': 1,
        'approver_level': 'User',
        'approver_work_tittle': creatorTitle,
        'approved': true,
        'approved_at': now,
      });

      // Level 2 — ASM: acknowledgment, selalu 0%.
      if (selectedSpv != null) {
        discounts.add({
          'discount': '0',
          'approver': selectedSpv.id,
          'approver_name': selectedSpv.fullName,
          'approver_level_id': 2,
          'approver_level': 'ASM',
          'approver_work_tittle': selectedSpv.jobLevelName,
          'approved': null,
          'approved_at': null,
        });
      }

      // Level 3 — RSM/GM (Manager): satu baris per diskon non-zero,
      // masing-masing pakai discount_extra + discount_extra_price (pola sama dengan Analyst).
      // Jika bonus diubah tapi tidak ada diskon, tetap buat satu baris RSM dengan discount=0.
      if (selectedManager != null) {
        Map<String, dynamic> managerRow(double pct, double? nominal) => {
              'discount': pct.toString(),
              'approver': selectedManager.id,
              'approver_name': selectedManager.fullName,
              'approver_level_id': 3,
              'approver_level': 'RSM',
              'approver_work_tittle': selectedManager.jobLevelName,
              'approved': null,
              'approved_at': null,
              if (nominal != null && nominal > 0) 'discount_price': nominal,
              'discount_extra': pct.toString(),
              if (nominal != null && nominal > 0)
                'discount_extra_price': nominal,
            };

        final hasAnyDiscount =
            discount1 > 0 || discount2 > 0 || discount3 > 0;

        if (discount1 > 0) {
          discounts.add(managerRow(discount1, discount1NominalLine));
        }
        if (discount2 > 0) {
          discounts.add(managerRow(discount2, discount2NominalLine));
        }
        if (discount3 > 0) {
          discounts.add(managerRow(discount3, discount3NominalLine));
        }
        // Bonus customized tanpa diskon → RSM approval dengan discount=0.
        if (!hasAnyDiscount && isBonusCustomized) {
          discounts.add(managerRow(0, null));
        }
      }
    } else {
      // ── DIRECT ────────────────────────────────────────────────
      // Level 1 — User/Sales (auto-approved, discount1 self-approved)
      discounts.add({
        'discount': discount1.toString(),
        'approver': userId,
        'approver_name': creatorName,
        'approver_level_id': 1,
        'approver_level': 'User',
        'approver_work_tittle': creatorTitle,
        'approved': true,
        'approved_at': now,
        if (discount1 > 0 &&
            discount1NominalLine != null &&
            discount1NominalLine > 0)
          'discount_price': discount1NominalLine,
      });

      // Level 2 — SPV: diskon aktual.
      if (selectedSpv != null) {
        discounts.add({
          'discount': discount2.toString(),
          'approver': selectedSpv.id,
          'approver_name': selectedSpv.fullName,
          'approver_level_id': 2,
          'approver_level': 'SPV',
          'approver_work_tittle': selectedSpv.jobLevelName,
          'approved': null,
          'approved_at': null,
          if (discount2 > 0 &&
              discount2NominalLine != null &&
              discount2NominalLine > 0)
            'discount_price': discount2NominalLine,
        });
      }

      // Level 3 — RSM / Manager (kondisional)
      // Muncul saat discount3 > 0, atau bonus diubah dari bundle default.
      if (selectedManager != null && (discount3 > 0 || isBonusCustomized)) {
        discounts.add({
          'discount': discount3.toString(),
          'approver': selectedManager.id,
          'approver_name': selectedManager.fullName,
          'approver_level_id': 3,
          'approver_level': 'RSM',
          'approver_work_tittle': selectedManager.jobLevelName,
          'approved': null,
          'approved_at': null,
          if (discount3 > 0 &&
              discount3NominalLine != null &&
              discount3NominalLine > 0)
            'discount_price': discount3NominalLine,
        });
      }
    }

    // Level 4 — Analyst (kondisional, berlaku direct & indirect)
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
        if (discount4NominalLine != null && discount4NominalLine > 0)
          'discount_price': discount4NominalLine,
        'discount_extra': discount4.toString(),
        if (discount4NominalLine != null && discount4NominalLine > 0)
          'discount_extra_price': discount4NominalLine,
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
  ///
  /// Tambahan kolom:
  /// - `standard_discount` (persentase, sama dengan `discount`) — menandai bahwa
  ///   baris ini adalah diskon toko yang "standar" dari master toko (bukan
  ///   diskon sales/program).
  /// - `standard_discount_price` (nominal Rp per-komponen) — jika disediakan
  ///   lewat [storeDiscountNominals] (paralel dengan [storeDiscounts]).
  static List<Map<String, dynamic>> buildStoreDiscountRows({
    required List<double> storeDiscounts,
    required String storeAlphaName,
    List<double>? storeDiscountNominals,
  }) {
    const startLevel = 5;
    final now = DateTime.now().toIso8601String();
    final out = <Map<String, dynamic>>[];
    var slot = 0;
    for (var i = 0; i < storeDiscounts.length; i++) {
      final d = storeDiscounts[i];
      if (d <= 0) continue;
      final nominal =
          (storeDiscountNominals != null && i < storeDiscountNominals.length)
              ? storeDiscountNominals[i]
              : 0.0;
      out.add({
        'discount': d.toString(),
        'approver': null,
        'approver_name': storeAlphaName,
        'approver_level_id': startLevel + slot,
        'approver_level': 'Diskon Toko ${slot + 1}',
        'approver_work_tittle': 'Toko',
        'approved': true,
        'approved_at': now,
        if (nominal > 0) 'discount_price': nominal,
        'standard_discount': d.toString(),
        if (nominal > 0) 'standart_discount_price': nominal,
      });
      slot++;
    }
    return out;
  }
}
