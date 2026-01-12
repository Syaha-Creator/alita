import '../../../../core/error/exceptions.dart';
import '../entities/cart_entity.dart';
import '../repositories/checkout_repository.dart';

/// Use case untuk checkout dengan proper error handling
class CheckoutUseCase {
  final CheckoutRepository repository;

  CheckoutUseCase({required this.repository});

  /// Execute checkout dengan validasi dan error handling
  Future<CheckoutResult> call(CheckoutParams params) async {
    try {
      // Validasi input
      _validateParams(params);

      // Create order letter
      final orderLetterResult = await repository.createOrderLetter(
        cartItems: params.cartItems,
        customerName: params.customerName,
        customerPhone: params.customerPhone,
        email: params.email,
        customerAddress: params.customerAddress,
        shipToName: params.shipToName,
        addressShipTo: params.addressShipTo,
        requestDate: params.requestDate,
        note: params.note,
        spgCode: params.spgCode,
        isTakeAway: params.isTakeAway,
        postage: params.postage,
      );

      if (orderLetterResult['success'] != true) {
        return CheckoutResult.failure(
          orderLetterResult['message'] ?? 'Gagal membuat surat pesanan',
        );
      }

      final orderLetterId = orderLetterResult['orderLetterId'] as int?;
      final noSp = orderLetterResult['noSp'] as String?;

      if (orderLetterId == null || noSp == null) {
        return CheckoutResult.failure(
          'Order letter berhasil dibuat tapi data tidak lengkap',
        );
      }

      // Upload phone numbers (non-blocking)
      if (params.primaryPhone.isNotEmpty) {
        try {
          await repository.uploadPhoneNumbers(
            orderLetterId: orderLetterId,
            primaryPhone: params.primaryPhone,
            secondaryPhone: params.secondaryPhone,
          );
        } catch (e) {
          // Log error but don't fail checkout
          // Phone upload is optional
        }
      }

      // Upload payment methods (non-blocking)
      if (params.paymentMethods.isNotEmpty) {
        try {
          await repository.uploadPaymentMethods(
            orderLetterId: orderLetterId,
            paymentMethods: params.paymentMethods,
            creator: params.creatorId,
            note: 'Payment from checkout',
          );
        } catch (e) {
          // Log error but don't fail checkout
          // Payment upload failure will be shown as warning
          return CheckoutResult.successWithWarning(
            orderLetterId: orderLetterId,
            noSp: noSp,
            warning: 'Pembayaran gagal diupload: ${e.toString()}',
          );
        }
      }

      return CheckoutResult.success(
        orderLetterId: orderLetterId,
        noSp: noSp,
      );
    } on NetworkException catch (e) {
      return CheckoutResult.failure(
        'Gagal terhubung ke server. Periksa koneksi Anda: ${e.message}',
      );
    } on ServerException catch (e) {
      return CheckoutResult.failure(e.message);
    } on ValidationException catch (e) {
      return CheckoutResult.failure(e.message);
    } catch (e) {
      return CheckoutResult.failure(
        'Terjadi kesalahan yang tidak diketahui: ${e.toString()}',
      );
    }
  }

  void _validateParams(CheckoutParams params) {
    if (params.cartItems.isEmpty) {
      throw ValidationException('Cart tidak boleh kosong');
    }

    if (params.customerName.trim().isEmpty) {
      throw ValidationException('Nama customer wajib diisi');
    }

    if (params.email.trim().isEmpty) {
      throw ValidationException('Email wajib diisi');
    }

    if (params.customerAddress.trim().isEmpty) {
      throw ValidationException('Alamat customer wajib diisi');
    }

    if (!params.isTakeAway) {
      if (params.shipToName.trim().isEmpty) {
        throw ValidationException('Nama penerima wajib diisi');
      }

      if (params.addressShipTo.trim().isEmpty) {
        throw ValidationException('Alamat pengiriman wajib diisi');
      }

      if (params.requestDate.trim().isEmpty) {
        throw ValidationException('Tanggal pengiriman wajib diisi');
      }
    }
  }
}

/// Parameters untuk checkout
class CheckoutParams {
  final List<CartEntity> cartItems;
  final String customerName;
  final String customerPhone;
  final String email;
  final String customerAddress;
  final String shipToName;
  final String addressShipTo;
  final String requestDate;
  final String note;
  final String? spgCode;
  final bool isTakeAway;
  final double? postage;
  final String primaryPhone;
  final String? secondaryPhone;
  final List<Map<String, dynamic>> paymentMethods;
  final int creatorId;

  CheckoutParams({
    required this.cartItems,
    required this.customerName,
    required this.customerPhone,
    required this.email,
    required this.customerAddress,
    required this.shipToName,
    required this.addressShipTo,
    required this.requestDate,
    required this.note,
    this.spgCode,
    this.isTakeAway = false,
    this.postage,
    required this.primaryPhone,
    this.secondaryPhone,
    required this.paymentMethods,
    required this.creatorId,
  });
}

/// Result dari checkout operation
class CheckoutResult {
  final bool isSuccess;
  final int? orderLetterId;
  final String? noSp;
  final String? errorMessage;
  final String? warning;

  CheckoutResult._({
    required this.isSuccess,
    this.orderLetterId,
    this.noSp,
    this.errorMessage,
    this.warning,
  });

  factory CheckoutResult.success({
    required int orderLetterId,
    required String noSp,
  }) {
    return CheckoutResult._(
      isSuccess: true,
      orderLetterId: orderLetterId,
      noSp: noSp,
    );
  }

  factory CheckoutResult.successWithWarning({
    required int orderLetterId,
    required String noSp,
    required String warning,
  }) {
    return CheckoutResult._(
      isSuccess: true,
      orderLetterId: orderLetterId,
      noSp: noSp,
      warning: warning,
    );
  }

  factory CheckoutResult.failure(String message) {
    return CheckoutResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }
}

/// Exception untuk validasi
class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);
}
