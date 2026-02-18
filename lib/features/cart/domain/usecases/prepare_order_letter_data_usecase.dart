import '../../../../services/attendance_service.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/contact_work_experience_service.dart';
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
  final ContactWorkExperienceService _contactWorkExperienceService;

  PrepareOrderLetterDataUseCase({
    AttendanceService? attendanceService,
    DetermineOrderStatusUseCase? determineOrderStatusUseCase,
    ContactWorkExperienceService? contactWorkExperienceService,
  })  : _attendanceService = attendanceService ?? locator<AttendanceService>(),
        _determineOrderStatusUseCase =
            determineOrderStatusUseCase ?? DetermineOrderStatusUseCase(),
        _contactWorkExperienceService = contactWorkExperienceService ??
            locator<ContactWorkExperienceService>();

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
  /// - scCode: SC code (optional)
  /// - isTakeAway: Is take away flag
  /// - postage: Postage value (optional)
  /// - totalExtendedAmount: Total extended amount
  /// - totalHargaAwal: Total harga awal
  /// - totalDiscountPercentage: Total discount percentage
  /// - allDiscounts: All discounts list for status determination
  /// - isIndirectCheckout: Skip phone/email validation for indirect checkout
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
    bool isIndirectCheckout = false,
  }) async {
    // Validate input parameters
    Validators.validateRequired(creatorId, 'Creator ID');
    Validators.validateDateString(orderDateStr, 'Order date');
    Validators.validateDateString(requestDateStr, 'Request date');
    Validators.validateRequired(customerName, 'Customer name');

    // Skip phone/email validation for indirect checkout (store data format may differ)
    if (!isIndirectCheckout) {
      Validators.validatePhone(customerPhone);
      Validators.validateEmail(email);
    }

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

    // Get channel code from user's division
    // Division ID 25 (direct/retail) → "S1"
    // Division ID 24 (indirect) → "S0"
    // Division ID 26 → "MM"
    String? channelString;
    try {
      final token = await AuthService.getToken();
      final userId = int.tryParse(creatorId);
      if (token != null && userId != null) {
        channelString = await _contactWorkExperienceService.getUserChannelCode(
          token: token,
          userId: userId,
        );
      }
    } catch (_) {
      // Ignore errors, channel will be null
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
      channel: channelString,
      skipPhoneEmailValidation: isIndirectCheckout,
    );
  }
}
