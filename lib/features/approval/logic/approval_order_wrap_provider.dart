import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_session_expired.dart';
import '../../auth/logic/auth_provider.dart';
import '../../history/data/services/order_letter_fetch.dart';

/// Muat payload mentah SP untuk [ApprovalDetailPage] (mis. dari tap notifikasi).
final approvalOrderWrapProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, int>(
  (ref, orderId) async {
    try {
      final wrap = await fetchOrderLetterResultWrap(orderId);
      if (wrap == null) {
        throw Exception('Tidak dapat memuat data surat pesanan.');
      }
      return wrap;
    } on ApiSessionExpiredException {
      await ref.read(authProvider.notifier).logout();
      rethrow;
    }
  },
);
