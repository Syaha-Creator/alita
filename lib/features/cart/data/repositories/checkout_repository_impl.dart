import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../../../core/error/exceptions.dart';
import '../../../../services/enhanced_checkout_service.dart';
import '../../domain/entities/cart_entity.dart';
import '../../domain/repositories/checkout_repository.dart';
import '../../../order_letter_contact/domain/usecases/upload_phone_numbers_usecase.dart';
import '../../../order_letter_payment/domain/usecases/upload_payment_methods_usecase.dart';

/// Implementation of CheckoutRepository
/// Menggunakan services dan use cases sesuai Clean Architecture
class CheckoutRepositoryImpl implements CheckoutRepository {
  final EnhancedCheckoutService _enhancedCheckoutService;
  final UploadPhoneNumbersUseCase _uploadPhoneNumbersUseCase;
  final UploadPaymentMethodsUseCase _uploadPaymentMethodsUseCase;

  CheckoutRepositoryImpl({
    required EnhancedCheckoutService enhancedCheckoutService,
    required UploadPhoneNumbersUseCase uploadPhoneNumbersUseCase,
    required UploadPaymentMethodsUseCase uploadPaymentMethodsUseCase,
  })  : _enhancedCheckoutService = enhancedCheckoutService,
        _uploadPhoneNumbersUseCase = uploadPhoneNumbersUseCase,
        _uploadPaymentMethodsUseCase = uploadPaymentMethodsUseCase;

  @override
  Future<Map<String, dynamic>> createOrderLetter({
    required List<CartEntity> cartItems,
    required String customerName,
    required String customerPhone,
    required String email,
    required String customerAddress,
    required String shipToName,
    required String addressShipTo,
    required String requestDate,
    required String note,
    String? spgCode,
    bool isTakeAway = false,
    double? postage,
  }) async {
    try {
      final result = await _enhancedCheckoutService.checkoutWithItemMapping(
        cartItems: cartItems,
        customerName: customerName,
        customerPhone: customerPhone,
        email: email,
        customerAddress: customerAddress,
        shipToName: shipToName,
        addressShipTo: addressShipTo,
        requestDate: requestDate,
        note: note,
        spgCode: spgCode,
        isTakeAway: isTakeAway,
        postage: postage,
      );

      return result;
    } catch (e) {
      // Map exceptions to proper error types
      if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        throw NetworkException(
          'Gagal terhubung ke server. Periksa koneksi Anda.',
        );
      }

      throw ServerException(
        e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  @override
  Future<void> uploadPhoneNumbers({
    required int orderLetterId,
    required String primaryPhone,
    String? secondaryPhone,
  }) async {
    try {
      await _uploadPhoneNumbersUseCase(
        orderLetterId: orderLetterId,
        primaryPhone: primaryPhone,
        secondaryPhone: secondaryPhone,
      );
    } on ServerException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw ServerException(
        'Gagal mengupload nomor telepon: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> uploadPaymentMethods({
    required int orderLetterId,
    required List<Map<String, dynamic>> paymentMethods,
    required int creator,
    String? note,
  }) async {
    try {
      await _uploadPaymentMethodsUseCase(
        orderLetterId: orderLetterId,
        paymentMethods: paymentMethods,
        creator: creator,
        note: note,
      );
    } on ServerException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw ServerException(
        'Gagal mengupload metode pembayaran: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> saveDraft({
    required Map<String, dynamic> draftData,
    required int userId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'checkout_drafts_$userId';

      // Get existing drafts
      final existingDrafts = prefs.getStringList(key) ?? [];
      final draftStrings = List<String>.from(existingDrafts);

      // Check if this is updating an existing draft
      if (draftData['savedAt'] != null) {
        final originalSavedAt = draftData['savedAt'] as String;
        final draftIndex = draftStrings.indexWhere((draftString) {
          try {
            final existingDraft =
                jsonDecode(draftString) as Map<String, dynamic>;
            return existingDraft['savedAt'] == originalSavedAt;
          } catch (e) {
            return false;
          }
        });

        if (draftIndex != -1) {
          // Replace existing draft
          draftStrings[draftIndex] = jsonEncode(draftData);
        } else {
          // If not found, add as new draft
          draftStrings.add(jsonEncode(draftData));
        }
      } else {
        // Add new draft
        draftStrings.add(jsonEncode(draftData));
      }

      await prefs.setStringList(key, draftStrings);
    } catch (e) {
      throw ServerException(
        'Gagal menyimpan draft: ${e.toString()}',
      );
    }
  }

  @override
  Future<Map<String, dynamic>?> loadDraft({required int userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'checkout_drafts_$userId';
      final draftStrings = prefs.getStringList(key) ?? [];

      if (draftStrings.isEmpty) {
        return null;
      }

      // Return the most recent draft (last in list)
      final latestDraftString = draftStrings.last;
      return jsonDecode(latestDraftString) as Map<String, dynamic>;
    } catch (e) {
      throw ServerException(
        'Gagal memuat draft: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> deleteDraft({required int userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'checkout_drafts_$userId';
      await prefs.remove(key);
    } catch (e) {
      throw ServerException(
        'Gagal menghapus draft: ${e.toString()}',
      );
    }
  }
}
