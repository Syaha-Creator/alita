import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../history/data/services/order_letter_fetch.dart';

/// Muat payload mentah SP untuk [ApprovalDetailPage] (mis. dari tap notifikasi).
final approvalOrderWrapProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, int>(
  (ref, orderId) async {
    final wrap = await fetchOrderLetterResultWrap(orderId);
    if (wrap == null) {
      throw Exception('Tidak dapat memuat data surat pesanan.');
    }
    return wrap;
  },
);
