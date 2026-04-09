import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alitapricelist/core/utils/order_letter_date_utils.dart';
import 'package:alitapricelist/features/checkout/logic/checkout_form_validator.dart';
import 'package:alitapricelist/features/checkout/data/models/payment_entry.dart';

void main() {
  group('CheckoutFormValidator.isPhoneInvalid', () {
    test('empty string is invalid', () {
      expect(CheckoutFormValidator.isPhoneInvalid(''), isTrue);
    });

    test('whitespace only is invalid', () {
      expect(CheckoutFormValidator.isPhoneInvalid('   '), isTrue);
    });

    test('less than 10 digits is invalid', () {
      expect(CheckoutFormValidator.isPhoneInvalid('08123'), isTrue);
    });

    test('10 digits is valid', () {
      expect(CheckoutFormValidator.isPhoneInvalid('0812345678'), isFalse);
    });

    test('13 digits is valid', () {
      expect(CheckoutFormValidator.isPhoneInvalid('0812345678901'), isFalse);
    });

    test('15 digits is valid', () {
      expect(CheckoutFormValidator.isPhoneInvalid('081234567890123'), isFalse);
    });

    test('more than 15 digits is invalid', () {
      expect(CheckoutFormValidator.isPhoneInvalid('0812345678901234'), isTrue);
    });

    test('strips non-digit characters before counting', () {
      expect(CheckoutFormValidator.isPhoneInvalid('+62 812-345-6789'), isFalse);
    });

    test('formatted number with dashes is valid', () {
      expect(CheckoutFormValidator.isPhoneInvalid('0812-3456-7890'), isFalse);
    });
  });

  group('CheckoutFormValidator optional field helpers', () {
    test('isFilledEmailInvalid is false when empty', () {
      expect(CheckoutFormValidator.isFilledEmailInvalid(''), isFalse);
      expect(CheckoutFormValidator.isFilledEmailInvalid('  '), isFalse);
    });

    test('isFilledEmailInvalid is true when filled but bad', () {
      expect(CheckoutFormValidator.isFilledEmailInvalid('bad'), isTrue);
    });

    test('isFilledPhoneInvalid is false when empty', () {
      expect(CheckoutFormValidator.isFilledPhoneInvalid(''), isFalse);
    });

    test('isFilledPhoneInvalid is true when too short', () {
      expect(CheckoutFormValidator.isFilledPhoneInvalid('0812'), isTrue);
    });
  });

  group('CheckoutFormValidator.findFirstFormError', () {
    late GlobalKey customerKey;
    late GlobalKey deliveryKey;
    late GlobalKey approvalKey;
    late GlobalKey paymentKey;

    setUp(() {
      customerKey = GlobalKey();
      deliveryKey = GlobalKey();
      approvalKey = GlobalKey();
      paymentKey = GlobalKey();
    });

    ({GlobalKey key, String label}) validate({
      String customerName = 'John Doe',
      String customerEmail = 'john@example.com',
      String customerPhone = '081234567890',
      String customerPhone2 = '',
      String customerAddress = 'Jl. Test 123',
      bool isShippingSameAsCustomer = true,
      String shippingName = '',
      String shippingPhone = '',
      String shippingPhone2 = '',
      String shippingAddress = '',
      bool isTakeAway = true,
      DateTime? orderDate,
      DateTime? requestDate,
      bool hasSelectedSpv = true,
      bool requiresManager = false,
      bool hasSelectedManager = false,
      List<PaymentEntry>? payments,
      bool indirectStoreContactOptional = false,
      bool indirectReceiverContactOptional = false,
      String indirectAlternateReceiverEmail = '',
      bool indirectSkipPaymentValidation = false,
    }) {
      final defaultPayment = PaymentEntry()
        ..method = 'Transfer'
        ..bank = 'BCA'
        ..receiptImage = File('test.jpg');

      return CheckoutFormValidator.findFirstFormError(
        customerName: customerName,
        customerEmail: customerEmail,
        customerPhone: customerPhone,
        customerPhone2: customerPhone2,
        customerAddress: customerAddress,
        isShippingSameAsCustomer: isShippingSameAsCustomer,
        shippingName: shippingName,
        shippingPhone: shippingPhone,
        shippingPhone2: shippingPhone2,
        shippingAddress: shippingAddress,
        indirectStoreContactOptional: indirectStoreContactOptional,
        indirectReceiverContactOptional: indirectReceiverContactOptional,
        indirectAlternateReceiverEmail: indirectAlternateReceiverEmail,
        indirectSkipPaymentValidation: indirectSkipPaymentValidation,
        isTakeAway: isTakeAway,
        orderDate: orderDate ?? OrderLetterDateUtils.today(),
        requestDate: requestDate,
        hasSelectedSpv: hasSelectedSpv,
        requiresManager: requiresManager,
        hasSelectedManager: hasSelectedManager,
        payments: payments ?? [defaultPayment],
        customerSectionKey: customerKey,
        deliverySectionKey: deliveryKey,
        approvalSectionKey: approvalKey,
        paymentSectionKey: paymentKey,
      );
    }

    test('returns customer section for empty name', () {
      final result = validate(customerName: '');
      expect(result.key, customerKey);
      expect(result.label, 'Informasi Pelanggan');
    });

    test('indirect: empty name uses Informasi Toko label', () {
      final result = validate(
        customerName: '',
        indirectStoreContactOptional: true,
      );
      expect(result.key, customerKey);
      expect(result.label, 'Informasi Toko');
    });

    test('indirect: empty email and phone do not block; address still required', () {
      final result = validate(
        customerEmail: '',
        customerPhone: '',
        customerAddress: '',
        indirectStoreContactOptional: true,
      );
      expect(result.key, customerKey);
      expect(result.label, 'Alamat Toko');
    });

    test('indirect receiver: empty name and phone ok when address filled', () {
      final result = validate(
        isShippingSameAsCustomer: false,
        shippingName: '',
        shippingPhone: '',
        shippingAddress: 'Gudang A',
        indirectStoreContactOptional: true,
        indirectReceiverContactOptional: true,
      );
      expect(result.label, isNot('Informasi Penerima'));
    });

    test('indirect receiver: empty address still errors', () {
      final result = validate(
        isShippingSameAsCustomer: false,
        shippingName: '',
        shippingPhone: '081234567890',
        shippingAddress: '',
        indirectStoreContactOptional: true,
        indirectReceiverContactOptional: true,
      );
      expect(result.key, customerKey);
      expect(result.label, 'Informasi Penerima');
    });

    test('indirect: invalid HP kedua toko', () {
      final result = validate(
        customerPhone2: '12',
        customerAddress: 'Alamat toko',
        indirectStoreContactOptional: true,
      );
      expect(result.key, customerKey);
      expect(result.label, 'Informasi Toko');
    });

    test('indirect receiver: invalid HP kedua penerima', () {
      final result = validate(
        isShippingSameAsCustomer: false,
        shippingPhone: '081234567890',
        shippingPhone2: '99',
        shippingAddress: 'Gudang',
        indirectStoreContactOptional: true,
        indirectReceiverContactOptional: true,
      );
      expect(result.key, customerKey);
      expect(result.label, 'Informasi Penerima');
    });

    test('returns customer section for invalid email', () {
      final result = validate(customerEmail: 'not-an-email');
      expect(result.key, customerKey);
      expect(result.label, 'Informasi Pelanggan');
    });

    test('returns customer section for invalid phone', () {
      final result = validate(customerPhone: '123');
      expect(result.key, customerKey);
      expect(result.label, 'Informasi Pelanggan');
    });

    test('returns customer section for empty address', () {
      final result = validate(customerAddress: '');
      expect(result.key, customerKey);
      expect(result.label, 'Alamat Pelanggan');
    });

    test('returns customer section for missing shipping info', () {
      final result = validate(
        isShippingSameAsCustomer: false,
        shippingName: '',
        shippingPhone: '081234567890',
        shippingAddress: 'Jl. Ship 123',
      );
      expect(result.key, customerKey);
      expect(result.label, 'Informasi Penerima');
    });

    test('returns delivery section when requestDate is null and not takeAway', () {
      final result = validate(
        isTakeAway: false,
        requestDate: null,
      );
      expect(result.key, deliveryKey);
      expect(result.label, 'Informasi Pengiriman');
    });

    test('returns delivery section when orderDate is outside current month', () {
      final ref = DateTime.now();
      final lastMonth = DateTime(ref.year, ref.month - 1, 15);
      final result = validate(orderDate: lastMonth);
      expect(result.key, deliveryKey);
      expect(result.label, 'Informasi Pengiriman');
    });

    test('returns approval section when no SPV selected', () {
      final result = validate(hasSelectedSpv: false);
      expect(result.key, approvalKey);
      expect(result.label, 'Persetujuan');
    });

    test('returns approval section when manager required but not selected', () {
      final result = validate(
        requiresManager: true,
        hasSelectedManager: false,
      );
      expect(result.key, approvalKey);
      expect(result.label, 'Persetujuan');
    });

    test('returns payment section for incomplete payment', () {
      final incompletePayment = PaymentEntry()
        ..method = null;

      final result = validate(payments: [incompletePayment]);
      expect(result.key, paymentKey);
      expect(result.label, 'Informasi Pembayaran');
    });

    test('indirect: skips payment validation when flag set', () {
      final incompletePayment = PaymentEntry()..method = null;
      final result = validate(
        payments: [incompletePayment],
        indirectSkipPaymentValidation: true,
      );
      expect(result.key, customerKey);
      expect(result.label, 'Informasi Pelanggan');
    });

    test('returns payment section when Lainnya method has no channel', () {
      final payment = PaymentEntry()
        ..method = 'Lainnya'
        ..receiptImage = File('test.jpg');

      final result = validate(payments: [payment]);
      expect(result.key, paymentKey);
      expect(result.label, 'Informasi Pembayaran');
    });
  });
}
