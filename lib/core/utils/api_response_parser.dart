import 'response_extractor.dart';

/// Utility class untuk parse API response ke berbagai format
/// 
/// Simplifies parsing logic untuk berbagai format response API
class ApiResponseParser {
  /// Parse order letters list dari response
  /// 
  /// Handles berbagai format:
  /// - Direct list: data (is List)
  /// - Nested list: data['result'] (is List)
  /// - Single object: data['result'] (is Map) - wrap in List
  /// - Nested order_letter: data['result']['order_letter'] - wrap in List
  /// 
  /// Returns empty list if not found
  static List<Map<String, dynamic>> parseOrderLettersList(dynamic data) {
    return ResponseExtractor.extractList<Map<String, dynamic>>(data);
  }

  /// Parse order letter details list dari response
  /// 
  /// Handles berbagai format response
  static List<Map<String, dynamic>> parseOrderLetterDetailsList(
    dynamic data,
  ) {
    return ResponseExtractor.extractList<Map<String, dynamic>>(data);
  }

  /// Parse order letter discounts list dari response
  /// 
  /// Handles berbagai format response
  static List<Map<String, dynamic>> parseOrderLetterDiscountsList(
    dynamic data,
  ) {
    return ResponseExtractor.extractList<Map<String, dynamic>>(data);
  }

  /// Parse order letter approves list dari response
  /// 
  /// Handles berbagai format response
  static List<Map<String, dynamic>> parseOrderLetterApprovesList(
    dynamic data,
  ) {
    return ResponseExtractor.extractList<Map<String, dynamic>>(data);
  }
}

