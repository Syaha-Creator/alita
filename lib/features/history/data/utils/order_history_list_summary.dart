import '../../../../core/enums/order_status.dart';
import '../models/order_history.dart';

/// Agregat nominal & jumlah SP per **status**, untuk daftar yang sama dengan
/// kartu di Riwayat Pesanan (satu respons API).
class OrderHistoryStatusTotals {
  const OrderHistoryStatusTotals({
    required this.approvedCount,
    required this.pendingCount,
    required this.rejectedCount,
    required this.unknownCount,
    required this.approvedTotal,
    required this.pendingTotal,
    required this.rejectedTotal,
    required this.unknownTotal,
  });

  final int approvedCount;
  final int pendingCount;
  final int rejectedCount;
  final int unknownCount;

  final double approvedTotal;
  final double pendingTotal;
  final double rejectedTotal;
  final double unknownTotal;

  int get totalOrders =>
      approvedCount + pendingCount + rejectedCount + unknownCount;

  double get grandTotal =>
      approvedTotal + pendingTotal + rejectedTotal + unknownTotal;

  factory OrderHistoryStatusTotals.fromOrders(List<OrderHistory> orders) {
    var ac = 0, pc = 0, rc = 0, uc = 0;
    var at = 0.0, pt = 0.0, rt = 0.0, ut = 0.0;
    for (final o in orders) {
      final t = o.totalAmount;
      switch (OrderStatusX.fromRaw(o.status)) {
        case OrderStatus.approved:
          ac++;
          at += t;
        case OrderStatus.pending:
          pc++;
          pt += t;
        case OrderStatus.rejected:
          rc++;
          rt += t;
        case OrderStatus.unknown:
          uc++;
          ut += t;
      }
    }
    return OrderHistoryStatusTotals(
      approvedCount: ac,
      pendingCount: pc,
      rejectedCount: rc,
      unknownCount: uc,
      approvedTotal: at,
      pendingTotal: pt,
      rejectedTotal: rt,
      unknownTotal: ut,
    );
  }
}
