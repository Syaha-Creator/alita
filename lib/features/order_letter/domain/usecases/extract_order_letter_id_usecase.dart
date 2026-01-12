import '../../../../core/utils/response_extractor.dart';
import '../../../../services/order_letter_service.dart';

/// Use case untuk extract order letter ID dan no_sp dari response
/// 
/// Uses ResponseExtractor utility untuk handle berbagai format response
/// Fallback: fetch latest order letter jika ID tidak ditemukan
class ExtractOrderLetterIdUseCase {
  final OrderLetterService _orderLetterService;

  ExtractOrderLetterIdUseCase(this._orderLetterService);

  /// Extract order letter ID dan no_sp dari response
  /// 
  /// Returns Map dengan keys:
  /// - 'orderLetterId': int?
  /// - 'noSp': String?
  /// 
  /// Jika ID tidak ditemukan, akan fetch latest order letter sebagai fallback
  Future<Map<String, dynamic>> call({
    required dynamic responseData,
    String? creator,
  }) async {
    // Use ResponseExtractor untuk extract ID dan no_sp
    final extracted = ResponseExtractor.extractOrderLetterId(responseData);
    int? orderLetterId = extracted['orderLetterId'] as int?;
    String? noSp = extracted['noSp'] as String?;

    // If we still don't have the ID, fetch the latest order letter
    if (orderLetterId == null && creator != null) {
      final latestOrderLetters =
          await _orderLetterService.getOrderLetters(creator: creator);
      if (latestOrderLetters.isNotEmpty) {
        // Sort by created_at to get the most recent one
        latestOrderLetters.sort((a, b) {
          final aCreatedAt = a['created_at'] ?? '';
          final bCreatedAt = b['created_at'] ?? '';
          return bCreatedAt
              .compareTo(aCreatedAt); // Descending order (newest first)
        });

        final latestOrder = latestOrderLetters.first;
        orderLetterId = latestOrder['id'] ?? latestOrder['order_letter_id'];
        noSp = latestOrder['no_sp'] ?? latestOrder['no_sp_number'];
      }
    }

    return {
      'orderLetterId': orderLetterId,
      'noSp': noSp,
    };
  }
}

