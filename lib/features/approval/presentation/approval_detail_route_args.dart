/// Typed `extra` untuk navigasi ke `/approval_detail`.
///
/// Membungkus payload API wrap (`order_letter` + details + …) agar router
/// tidak memaksa cast `Map` mentah.
class ApprovalDetailRouteArgs {
  const ApprovalDetailRouteArgs({required this.orderData});

  final Map<String, dynamic> orderData;
}
