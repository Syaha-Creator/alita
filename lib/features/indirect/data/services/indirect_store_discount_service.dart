import 'dart:convert';

import '../../../../core/services/api_client.dart';
import '../../../checkout/data/models/checkout_models.dart';

/// GET `/store_discounts?kode_toko=…` pada API utama (Bearer query).
class IndirectStoreDiscountService {
  IndirectStoreDiscountService({ApiClient? client})
      : _api = client ?? ApiClient.instance;

  final ApiClient _api;

  /// Coba `addressNumber.0` lalu `addressNumber` agar cocok dengan backend.
  ///
  /// Mengembalikan tuple `discounts` (persentase tiap level) dan `discountCode`
  /// (`disc_name` dari API, dipakai sebagai `code_standart` di order_letter_discounts).
  Future<({List<double> discounts, String discountCode})> fetchDiscounts({
    required String token,
    required int addressNumber,
  }) async {
    final candidates = <String>['$addressNumber.0', '$addressNumber'];

    for (final kodeToko in candidates) {
      final response = await _api.get(
        CheckoutEndpoints.storeDiscounts,
        token: token,
        queryParams: {'kode_toko': kodeToko},
      );

      if (response.statusCode != 200) continue;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) continue;

      final result = decoded['result'];
      if (result is! List || result.isEmpty) continue;

      final first = result.first;
      if (first is! Map<String, dynamic>) continue;

      final discounts = <double>[];
      for (var i = 1; i <= 8; i++) {
        final key = 'disc_$i';
        final val = _toDouble(first[key]);
        if (val != null && val > 0) discounts.add(val);
      }

      final discountCode = (first['disc_name'] as String? ?? '').trim();

      // Return jika ada persentase diskon ATAU disc_name — keduanya berguna.
      if (discounts.isNotEmpty || discountCode.isNotEmpty) {
        return (discounts: discounts, discountCode: discountCode);
      }
    }

    return (discounts: const <double>[], discountCode: '');
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
