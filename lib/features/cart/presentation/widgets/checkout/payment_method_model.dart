/// Model untuk menyimpan data metode pembayaran
class PaymentMethod {
  final String methodType; // BRI, BCA, Cash, etc
  final String methodName; // Display name
  final double amount;
  final String? reference;
  final String receiptImagePath; // Changed from optional to required
  final String? paymentDate; // Payment date
  final String? note; // User note

  PaymentMethod({
    required this.methodType,
    required this.methodName,
    required this.amount,
    this.reference,
    required this.receiptImagePath, // Now required
    this.paymentDate,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'methodType': methodType,
      'methodName': methodName,
      'amount': amount,
      'reference': reference,
      'receiptImagePath': receiptImagePath,
      'paymentDate': paymentDate,
      'note': note,
    };
  }

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      methodType: json['methodType'] as String,
      methodName: json['methodName'] as String,
      amount: (json['amount'] as num).toDouble(),
      reference: json['reference'] as String?,
      receiptImagePath: json['receiptImagePath'] as String,
      paymentDate: json['paymentDate'] as String?,
      note: json['note'] as String?,
    );
  }
}

