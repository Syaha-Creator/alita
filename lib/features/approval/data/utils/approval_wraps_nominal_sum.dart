import '../../../../core/enums/order_status.dart';
import '../../../../core/utils/app_formatters.dart';

/// Extracts the `order_letter` map from a raw approval wrap and returns it
/// only when its status is **Approved** — otherwise `null`.
///
/// Reads only the two fields the banner/profile summary need (`status`,
/// `extended_amount`) instead of running the full [OrderHistory.fromApiJson]
/// tree (details + payments + discounts) just to throw away everything but
/// a total — that used to re-parse every wrap on every rebuild/search.
Map<String, dynamic>? _approvedOrderLetterOrNull(dynamic raw) {
  if (raw is! Map) return null;
  final map = Map<String, dynamic>.from(raw);
  final letterRaw = map['order_letter'];
  final letter =
      letterRaw is Map ? Map<String, dynamic>.from(letterRaw) : map;
  final status = letter['status']?.toString() ?? OrderStatus.pending.apiValue;
  if (OrderStatusX.fromRaw(status) != OrderStatus.approved) return null;
  return letter;
}

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}

/// Jumlahkan `extended_amount` hanya untuk SP berstatus **Approved** (header
/// `order_letter.status`). Pending, rejected, dan unknown diabaikan.
double sumNominalFromApprovedSpOrderWrapsOnly(List<dynamic> wraps) {
  var sum = 0.0;
  for (final raw in wraps) {
    final letter = _approvedOrderLetterOrNull(raw);
    if (letter == null) continue;
    sum += _parseDouble(letter['extended_amount']);
  }
  return sum;
}

/// Banyaknya wrap yang dihitung di [sumNominalFromApprovedSpOrderWrapsOnly].
int countApprovedSpOrderWrapsOnly(List<dynamic> wraps) {
  var n = 0;
  for (final raw in wraps) {
    if (_approvedOrderLetterOrNull(raw) != null) n++;
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
