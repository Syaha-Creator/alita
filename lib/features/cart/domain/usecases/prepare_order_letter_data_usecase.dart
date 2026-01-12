import '../../../../services/attendance_service.dart';
import '../../../../config/dependency_injection.dart';
import '../../../../core/utils/validators.dart';
import '../../../order_letter/domain/entities/order_letter_data_entity.dart';
import 'determine_order_status_usecase.dart';

/// Use case untuk prepare order letter data
///
/// Prepares order letter data map dengan semua field yang diperlukan
class PrepareOrderLetterDataUseCase {
  final AttendanceService _attendanceService;
  final DetermineOrderStatusUseCase _determineOrderStatusUseCase;

  PrepareOrderLetterDataUseCase({
    AttendanceService? attendanceService,
    DetermineOrderStatusUseCase? determineOrderStatusUseCase,
  })  : _attendanceService = attendanceService ?? locator<AttendanceService>(),
        _determineOrderStatusUseCase =
            determineOrderStatusUseCase ?? DetermineOrderStatusUseCase();

  /// Prepare order letter data
  ///
  /// Parameters:
  /// - creatorId: User ID yang membuat order
  /// - orderDateStr: Order date string (YYYY-MM-DD)
  /// - requestDateStr: Request date string (YYYY-MM-DD)
  /// - customerName: Customer name
  /// - customerPhone: Customer phone
  /// - email: Customer email
  /// - customerAddress: Customer address
  /// - shipToName: Ship to name
  /// - addressShipTo: Address ship to
  /// - note: Order note
  /// - spgCode: SPG code (optional)
  /// - isTakeAway: Is take away flag
  /// - postage: Postage value (optional)
  /// - totalExtendedAmount: Total extended amount
  /// - totalHargaAwal: Total harga awal
  /// - totalDiscountPercentage: Total discount percentage
  /// - allDiscounts: All discounts list for status determination
  ///
  /// Returns OrderLetterDataEntity dengan order letter data
  Future<OrderLetterDataEntity> call({
    required String creatorId,
    required String orderDateStr,
    required String requestDateStr,
    required String customerName,
    required String customerPhone,
    required String email,
    required String customerAddress,
    required String shipToName,
    required String addressShipTo,
    required String note,
    String? spgCode,
    bool isTakeAway = false,
    double? postage,
    required double totalExtendedAmount,
    required int totalHargaAwal,
    required double totalDiscountPercentage,
    required List<double> allDiscounts,
  }) async {
    // Validate input parameters
    Validators.validateRequired(creatorId, 'Creator ID');
    Validators.validateDateString(orderDateStr, 'Order date');
    Validators.validateDateString(requestDateStr, 'Request date');
    Validators.validateRequired(customerName, 'Customer name');
    Validators.validatePhone(customerPhone);
    Validators.validateEmail(email);
    Validators.validateRequired(customerAddress, 'Customer address');
    if (!isTakeAway) {
      Validators.validateRequired(shipToName, 'Ship to name');
      Validators.validateRequired(addressShipTo, 'Address ship to');
    }
    Validators.validateNonNegative(
        totalExtendedAmount, 'Total extended amount');
    Validators.validateNonNegative(totalHargaAwal, 'Total harga awal');
    Validators.validateNonNegative(
      totalDiscountPercentage,
      'Total discount percentage',
    );
    if (postage != null) {
      Validators.validateNonNegative(postage, 'Postage');
    }

    // Determine smart status based on discount approval requirements
    final orderStatus = _determineOrderStatusUseCase(allDiscounts);

    // Get work_place_id from attendance API
    final workPlaceId = await _attendanceService.getWorkPlaceId() ?? 0;

    // Parse postage value (ensure it's a number, not null)
    final double postageValue = postage ?? 0.0;

    // Add postage to total extended amount
    double finalExtendedAmount = totalExtendedAmount;
    if (postageValue > 0) {
      finalExtendedAmount += postageValue;
    }

    // Prepare Order Letter Data
    return OrderLetterDataEntity(
      orderDate: orderDateStr,
      requestDate: requestDateStr,
      creator: creatorId,
      customerName: customerName,
      phone: customerPhone,
      email: email,
      address: customerAddress,
      shipToName: shipToName,
      addressShipTo: addressShipTo,
      extendedAmount: finalExtendedAmount,
      hargaAwal: totalHargaAwal,
      discount: totalDiscountPercentage,
      note: note,
      status: orderStatus,
      salesCode: spgCode ?? '',
      workPlaceId: workPlaceId,
      takeAway: isTakeAway,
      postage: postageValue,
    );
  }
}
