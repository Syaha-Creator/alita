import 'dart:convert';

import '../../../../core/services/api_client.dart';
import '../../../checkout/data/models/checkout_models.dart';

/// GET `/store_discounts?kode_toko=…` pada API utama (Bearer query).
class IndirectStoreDiscountService {
  IndirectStoreDiscountService({ApiClient? client})
      : _api = client ?? ApiClient.instance;

  final ApiClient _api;

  /// Coba `addressNumber.0` lalu `addressNumber` agar cocok dengan backend.
  Future<List<double>> fetchDiscounts({
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

      if (discounts.isNotEmpty) return discounts;
    }

    return [];
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
