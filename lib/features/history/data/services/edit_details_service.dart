import '../../../../core/services/api_client.dart';
import '../../../../core/services/api_session_expired.dart';
import '../../../../core/utils/log.dart';
import '../models/order_history.dart';

/// Mengelola penghapusan & pembaruan data detail surat pesanan saat "Edit Items".
///
/// Urutan wajib (ada foreign key):
///   1. DELETE /order_letter_discounts/{id}   — satu per satu, semua discount
///   2. DELETE /order_letter_details/{id}     — satu per satu, setelah discount bersih
///   3. PATCH  /order_letters/{id}            — perbarui extended_amount + harga_awal + discount%
class EditDetailsService {
  EditDetailsService({ApiClient? client}) : _api = client ?? ApiClient.instance;

  final ApiClient _api;
  static const _timeout = Duration(seconds: 20);

  // ── Step 1: Hapus semua discount rows ──────────────────────────

  Future<void> _deleteOneDiscount(int discountId, String token) async {
    final res = await _api.delete(
      '/order_letter_discounts/$discountId',
      token: token,
      timeout: _timeout,
    );
    _assertOk(res.statusCode, 'DELETE discount $discountId', res.body);
  }

  Future<void> deleteAllDiscounts(OrderHistory order, String token) async {
    final ids = <int>[];
    for (final detail in order.details) {
      for (final disc in detail.discounts) {
        if (disc.id > 0) ids.add(disc.id);
      }
    }
    Log.info(
      'EditDetails: menghapus ${ids.length} discount rows',
      tag: 'EditDetailsService',
    );
    for (final id in ids) {
      await _deleteOneDiscount(id, token);
    }
    Log.info('EditDetails: semua discount terhapus', tag: 'EditDetailsService');
  }

  // ── Step 2: Hapus semua detail rows ────────────────────────────

  Future<void> _deleteOneDetail(int detailId, String token) async {
    final res = await _api.delete(
      '/order_letter_details/$detailId',
      token: token,
      timeout: _timeout,
    );
    _assertOk(res.statusCode, 'DELETE detail $detailId', res.body);
  }

  Future<void> deleteAllDetails(OrderHistory order, String token) async {
    final ids = order.details.map((d) => d.id).where((id) => id > 0).toList();
    Log.info(
      'EditDetails: menghapus ${ids.length} detail rows',
      tag: 'EditDetailsService',
    );
    for (final id in ids) {
      await _deleteOneDetail(id, token);
    }
    Log.info('EditDetails: semua detail terhapus', tag: 'EditDetailsService');
  }

  // ── Step 0 (combined): hapus discount dulu, lalu detail ────────

  Future<void> deleteAll(OrderHistory order, String token) async {
    await deleteAllDiscounts(order, token);
    await deleteAllDetails(order, token);
  }

  // ── Step 3: Patch totals + reset status di order_letters ───────

  Future<void> patchOrderTotals({
    required int orderId,
    required double extendedAmount,
    required double hargaAwal,
    required String token,
  }) async {
    final discount = hargaAwal > 0
        ? ((hargaAwal - extendedAmount) / hargaAwal) * 100
        : 0.0;

    final res = await _api.put(
      '/order_letters/$orderId',
      token: token,
      body: {
        'extended_amount': extendedAmount,
        'harga_awal': hargaAwal,
        'discount': discount,
        // Reset status ke Pending agar approval baru bisa diproses.
        'status': 'Pending',
      },
      timeout: _timeout,
    );
    _assertOk(res.statusCode, 'PATCH totals order $orderId', res.body);
    Log.info(
      'EditDetails: totals order $orderId updated '
      '(extended=$extendedAmount hargaAwal=$hargaAwal '
      'disc=${discount.toStringAsFixed(2)}% status→Pending)',
      tag: 'EditDetailsService',
    );
  }

  // ── Helper ─────────────────────────────────────────────────────

  void _assertOk(int statusCode, String label, String body) {
    if (statusCode == 401 || statusCode == 403) {
      throw ApiSessionExpiredException('$label status=$statusCode');
    }
    if (statusCode != 200 && statusCode != 201 && statusCode != 204) {
      final preview = body.length > 200 ? '${body.substring(0, 200)}…' : body;
      throw Exception('Gagal $label (status $statusCode).\nResponse: $preview');
    }
  }
}
