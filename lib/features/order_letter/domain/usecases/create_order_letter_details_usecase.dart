import '../../../../core/utils/error_logger.dart';
import '../../../../services/order_letter_service.dart';

/// Use case untuk create order letter details dalam batch
///
/// Encapsulates logic untuk create multiple order letter details
class CreateOrderLetterDetailsUseCase {
  final OrderLetterService _orderLetterService;

  CreateOrderLetterDetailsUseCase(this._orderLetterService);

  /// Create order letter details dalam batch
  ///
  /// Parameters:
  /// - [orderLetterId] - ID dari order letter
  /// - [noSp] - Nomor SP dari order letter
  /// - [detailsData] - List of detail data maps
  ///
  /// Returns List dengan hasil dari setiap detail creation
  Future<List<Map<String, dynamic>>> call({
    required int orderLetterId,
    required String? noSp,
    required List<Map<String, dynamic>> detailsData,
  }) async {
    final List<Map<String, dynamic>> detailResults = [];

    for (final detail in detailsData) {
      try {
        final detailWithId = Map<String, dynamic>.from(detail);
        detailWithId['order_letter_id'] = orderLetterId;
        if (noSp != null) {
          detailWithId['no_sp'] = noSp;
        }

        final detailResult =
            await _orderLetterService.createOrderLetterDetail(detailWithId);
        detailResults.add(detailResult);
      } catch (e, stackTrace) {
        await ErrorLogger.logError(
          e,
          stackTrace: stackTrace,
          context: 'Failed to create order letter detail',
          extra: {
            'orderLetterId': orderLetterId,
            'detailIndex': detailResults.length,
          },
          fatal: false,
        );
        detailResults.add({
          'success': false,
          'message': 'Error creating detail: $e',
        });
      }
    }

    return detailResults;
  }
}
