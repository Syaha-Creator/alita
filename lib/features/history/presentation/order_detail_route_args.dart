import '../data/models/order_history.dart';

/// Argumen opsional untuk navigasi ke `/order_detail`.
///
/// Jika hanya mengirim [OrderHistory] sebagai `extra`, void SP dari konteks
/// persetujuan tidak ditampilkan (mis. dari Riwayat Pesanan).
class OrderDetailRouteArgs {
  const OrderDetailRouteArgs({
    required this.order,
    this.allowVoidFromApprovalContext = false,
  });

  final OrderHistory order;

  /// `true` hanya saat user membuka detail dari tab selesai **Persetujuan diskon**
  /// (bukan dari riwayat pesanan umum).
  final bool allowVoidFromApprovalContext;
}
