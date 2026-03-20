import 'dart:io';

import 'package:flutter/material.dart';

/// Mutable per-payment state container used by the checkout multi-payment UI.
///
/// Each entry owns its own controllers and receipt image. Call [dispose]
/// when removing an entry to avoid leaks.
class PaymentEntry {
  PaymentEntry();

  final amountCtrl = TextEditingController();
  String? method;
  String? bank;
  final otherChannelCtrl = TextEditingController();
  final refCtrl = TextEditingController();
  DateTime date = DateTime.now();
  final noteCtrl = TextEditingController();
  File? receiptImage;

  double get parsedAmount {
    final raw = amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(raw) ?? 0;
  }

  void dispose() {
    amountCtrl.dispose();
    otherChannelCtrl.dispose();
    refCtrl.dispose();
    noteCtrl.dispose();
  }
}
