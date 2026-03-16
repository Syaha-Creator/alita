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

    // Level 2 — Supervisor (selalu disertakan, menunggu approval)
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
}
