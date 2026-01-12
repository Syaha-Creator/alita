/// Utility class untuk extract data dari berbagai format API response
/// 
/// Handles berbagai format response yang mungkin dikembalikan oleh API:
/// - Direct access: data['id']
/// - Location object: data['location']['id']
/// - Nested result: data['result']['id']
/// - Array result: data['result'][0]['id']
class ResponseExtractor {
  /// Extract value dari response dengan berbagai format
  /// 
  /// Tries multiple paths:
  /// 1. Direct access: data[key]
  /// 2. Location object: data['location'][key]
  /// 3. Nested result: data['result'][key]
  /// 4. Array result: data['result'][0][key]
  /// 
  /// Returns first non-null value found, or null if not found
  static T? extractValue<T>(dynamic data, String key) {
    if (data == null) return null;

    // Try direct access
    if (data is Map<String, dynamic>) {
      final directValue = data[key];
      if (directValue != null && directValue is T) {
        return directValue;
      }

      // Try location object
      if (data['location'] is Map<String, dynamic>) {
        final location = data['location'] as Map<String, dynamic>;
        final locationValue = location[key];
        if (locationValue != null && locationValue is T) {
          return locationValue;
        }
      }

      // Try nested result
      if (data['result'] is Map<String, dynamic>) {
        final result = data['result'] as Map<String, dynamic>;
        final resultValue = result[key];
        if (resultValue != null && resultValue is T) {
          return resultValue;
        }
      }

      // Try array result
      if (data['result'] is List && (data['result'] as List).isNotEmpty) {
        final firstResult = (data['result'] as List).first;
        if (firstResult is Map<String, dynamic>) {
          final arrayValue = firstResult[key];
          if (arrayValue != null && arrayValue is T) {
            return arrayValue;
          }
        }
      }
    }

    return null;
  }

  /// Extract multiple values dari response
  /// 
  /// Returns Map dengan keys yang diminta, values bisa null jika tidak ditemukan
  static Map<String, dynamic> extractValues(
    dynamic data,
    List<String> keys,
  ) {
    final result = <String, dynamic>{};
    for (final key in keys) {
      result[key] = extractValue(data, key);
    }
    return result;
  }

  /// Extract list dari response dengan berbagai format
  /// 
  /// Handles:
  /// - Direct list: data (is List)
  /// - Nested list: data['result'] (is List)
  /// - Nested data: data['data'] (is List)
  /// 
  /// Returns empty list if not found
  static List<T> extractList<T>(dynamic data) {
    if (data == null) return [];

    // Direct list
    if (data is List) {
      return data.whereType<T>().toList();
    }

    // Nested in Map
    if (data is Map<String, dynamic>) {
      // Try 'result' key
      if (data['result'] is List) {
        return (data['result'] as List).whereType<T>().toList();
      }

      // Try 'data' key
      if (data['data'] is List) {
        return (data['data'] as List).whereType<T>().toList();
      }

      // Try 'result' as Map with 'order_letter' key
      if (data['result'] is Map<String, dynamic>) {
        final result = data['result'] as Map<String, dynamic>;
        if (result.containsKey('order_letter')) {
          // Return as list with single item
          return [result as T];
        } else {
          // Direct order letter object, wrap in List
          return [result as T];
        }
      }
    }

    return [];
  }

  /// Extract order letter ID dan no_sp dari response
  /// 
  /// Convenience method untuk extract ID dan no_sp dengan berbagai alternatif keys
  static Map<String, dynamic> extractOrderLetterId(dynamic responseData) {
    final id = extractValue<int>(responseData, 'id') ??
        extractValue<int>(responseData, 'order_letter_id');
    final noSp = extractValue<String>(responseData, 'no_sp') ??
        extractValue<String>(responseData, 'no_sp_number');

    return {
      'orderLetterId': id,
      'noSp': noSp,
    };
  }
}

