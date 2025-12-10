import 'package:flutter/material.dart';

/// Helper class untuk metode pembayaran
class PaymentHelpers {
  /// Mendapatkan icon berdasarkan tipe pembayaran
  static IconData getPaymentIcon(String methodType) {
    // Transfer Bank
    if (methodType == 'bri' ||
        methodType == 'bca' ||
        methodType == 'mandiri' ||
        methodType == 'bni' ||
        methodType == 'btn' ||
        methodType == 'other_bank') {
      return Icons.account_balance;
    }
    // Credit Card
    else if (methodType.endsWith('_credit') || methodType == 'other_credit') {
      return Icons.credit_card;
    }
    // PayLater
    else if (methodType == 'akulaku' ||
        methodType == 'kredivo' ||
        methodType == 'indodana' ||
        methodType == 'other_paylater') {
      return Icons.schedule;
    }
    // Digital Payment (QRIS, E-wallet, etc.)
    else if (methodType == 'qris' ||
        methodType == 'gopay' ||
        methodType == 'ovo' ||
        methodType == 'dana' ||
        methodType == 'shopeepay' ||
        methodType == 'linkaja' ||
        methodType == 'other_digital') {
      return Icons.qr_code;
    }
    // Default
    return Icons.payment;
  }

  /// Mendapatkan nama pembayaran berdasarkan tipe
  static String getPaymentName(String methodType) {
    switch (methodType) {
      // Transfer Bank
      case 'bri':
        return 'BRI';
      case 'bca':
        return 'BCA';
      case 'mandiri':
        return 'Bank Mandiri';
      case 'bni':
        return 'BNI';
      case 'btn':
        return 'BTN';
      case 'other_bank':
        return 'Bank Lainnya';

      // Credit Card
      case 'bri_credit':
        return 'Kartu Kredit BRI';
      case 'bca_credit':
        return 'Kartu Kredit BCA';
      case 'mandiri_credit':
        return 'Kartu Kredit Mandiri';
      case 'bni_credit':
        return 'Kartu Kredit BNI';
      case 'other_credit':
        return 'Kartu Kredit Lainnya';

      // PayLater
      case 'akulaku':
        return 'Akulaku';
      case 'kredivo':
        return 'Kredivo';
      case 'indodana':
        return 'Indodana';
      case 'other_paylater':
        return 'PayLater Lainnya';

      // Digital Payment
      case 'qris':
        return 'QRIS';
      case 'gopay':
        return 'GoPay';
      case 'ovo':
        return 'OVO';
      case 'dana':
        return 'DANA';
      case 'shopeepay':
        return 'ShopeePay';
      case 'linkaja':
        return 'LinkAja';
      case 'other_digital':
        return 'Digital Lainnya';

      default:
        return 'Lainnya';
    }
  }

  /// Mendapatkan daftar metode pembayaran berdasarkan kategori
  static List<Map<String, String>> getPaymentMethodsByCategory(String category) {
    switch (category) {
      case 'transfer':
        return [
          {'value': 'bri', 'label': 'BRI'},
          {'value': 'bca', 'label': 'BCA'},
          {'value': 'mandiri', 'label': 'Bank Mandiri'},
          {'value': 'bni', 'label': 'BNI'},
          {'value': 'btn', 'label': 'BTN'},
          {'value': 'other_bank', 'label': 'Bank Lainnya'},
        ];
      case 'credit':
        return [
          {'value': 'bri_credit', 'label': 'Kartu Kredit BRI'},
          {'value': 'bca_credit', 'label': 'Kartu Kredit BCA'},
          {'value': 'mandiri_credit', 'label': 'Kartu Kredit Mandiri'},
          {'value': 'bni_credit', 'label': 'Kartu Kredit BNI'},
          {'value': 'other_credit', 'label': 'Kartu Kredit Lainnya'},
        ];
      case 'paylater':
        return [
          {'value': 'akulaku', 'label': 'Akulaku'},
          {'value': 'kredivo', 'label': 'Kredivo'},
          {'value': 'indodana', 'label': 'Indodana'},
          {'value': 'other_paylater', 'label': 'PayLater Lainnya'},
        ];
      case 'other':
        return [
          {'value': 'qris', 'label': 'QRIS'},
          {'value': 'gopay', 'label': 'GoPay'},
          {'value': 'ovo', 'label': 'OVO'},
          {'value': 'dana', 'label': 'DANA'},
          {'value': 'shopeepay', 'label': 'ShopeePay'},
          {'value': 'linkaja', 'label': 'LinkAja'},
          {'value': 'other_digital', 'label': 'Digital Lainnya'},
        ];
      default:
        return [];
    }
  }
}

