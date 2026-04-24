import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/order_history.dart';

/// Menyimpan [OrderHistory] yang sedang dalam proses "Edit Items".
///
/// - Di-set oleh [OrderDetailPage] saat user menekan tombol "Edit Items".
/// - Dibaca oleh [CheckoutPage] untuk mendeteksi edit mode.
/// - Dibersihkan oleh [CheckoutNotifier.submitEditOrder] setelah berhasil,
///   atau oleh [OrderDetailPage] saat user membatalkan alur edit.
final editOrderContextProvider = StateProvider<OrderHistory?>((ref) => null);
