import '../../../../core/enums/order_status.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../history/data/models/order_history.dart';

/// Jumlahkan [OrderHistory.totalAmount] hanya untuk SP berstatus **Approved**
/// (header `order_letter.status`). Pending, rejected, dan unknown diabaikan.
double sumNominalFromApprovedSpOrderWrapsOnly(List<dynamic> wraps) {
  var sum = 0.0;
  for (final raw in wraps) {
    if (raw is! Map) continue;
    try {
      final oh = OrderHistory.fromApiJson(
        Map<String, dynamic>.from(raw),
      );
      if (OrderStatusX.fromRaw(oh.status) != OrderStatus.approved) continue;
      sum += oh.totalAmount;
    } catch (_) {
      continue;
    }
  }
  return sum;
}

/// Banyaknya wrap yang dihitung di [sumNominalFromApprovedSpOrderWrapsOnly].
int countApprovedSpOrderWrapsOnly(List<dynamic> wraps) {
  var n = 0;
  for (final raw in wraps) {
    if (raw is! Map) continue;
    try {
      final oh = OrderHistory.fromApiJson(
        Map<String, dynamic>.from(raw),
      );
      if (OrderStatusX.fromRaw(oh.status) != OrderStatus.approved) continue;
      n++;
    } catch (_) {
      continue;
    }
  }
  return n;
}

/// Kolom kiri mini dashboard **Profil** (atasan): sama cakupan dengan tab
/// **Selesai** + banner total ( [wraps] = `filteredHistoryApprovals` ).
(String compact, int approvedCount) approverProfileLeftColumnFromWraps({
  required List<dynamic> wraps,
  required bool isLoading,
}) {
  if (isLoading) return ('...', 0);
  final sum = sumNominalFromApprovedSpOrderWrapsOnly(wraps);
  final count = countApprovedSpOrderWrapsOnly(wraps);
  return (AppFormatters.currencyIdrCompact(sum), count);
}
