import '../../../../services/order_letter_service.dart';
import '../entities/order_letter_data_entity.dart';
import '../entities/order_letter_detail_data_entity.dart';
import '../entities/order_letter_discount_data_entity.dart';
import '../entities/create_order_letter_result_entity.dart';

/// Use case untuk create order letter dengan details dan discounts
///
/// Wrapper untuk OrderLetterService.createOrderLetterWithDetails
///
/// **Note:** Logic discount creation masih kompleks dan menggunakan private methods
/// di OrderLetterService. Untuk simplifikasi lebih lanjut, perlu extract logic
/// discount creation ke use cases terpisah setelah private methods diubah menjadi public.
class CreateOrderLetterWithDetailsUseCase {
  final OrderLetterService orderLetterService;

  CreateOrderLetterWithDetailsUseCase(this.orderLetterService);

  /// Create order letter with details and discounts
  ///
  /// Returns CreateOrderLetterResultEntity dengan hasil operation
  Future<CreateOrderLetterResultEntity> call({
    required OrderLetterDataEntity orderLetterData,
    required List<OrderLetterDetailDataEntity> detailsData,
    required dynamic
        discountsData, // Can be List<double> or List<OrderLetterDiscountDataEntity>
    List<int?>? leaderIds,
    int? selectedSpvId,
    String? selectedSpvName,
    int? selectedRsmId,
    String? selectedRsmName,
  }) async {
    // Convert entities to maps untuk backward compatibility dengan OrderLetterService
    final orderLetterDataMap = orderLetterData.toMap();
    final detailsDataMap = detailsData.map((e) => e.toMap()).toList();

    // Convert discounts data
    dynamic discountsDataMap;
    if (discountsData is List<OrderLetterDiscountDataEntity>) {
      discountsDataMap = discountsData.map((e) => e.toMap()).toList();
    } else {
      discountsDataMap = discountsData; // Keep as is if List<double>
    }

    final result = await orderLetterService.createOrderLetterWithDetails(
      orderLetterData: orderLetterDataMap,
      detailsData: detailsDataMap,
      discountsData: discountsDataMap,
      leaderIds: leaderIds,
      selectedSpvId: selectedSpvId,
      selectedSpvName: selectedSpvName,
      selectedRsmId: selectedRsmId,
      selectedRsmName: selectedRsmName,
    );

    // Convert result map to entity
    return CreateOrderLetterResultEntity.fromMap(result);
  }
}
