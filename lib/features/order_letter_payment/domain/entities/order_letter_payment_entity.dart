/// Entity untuk order letter payment
/// Representasi business object untuk payment information
class OrderLetterPaymentEntity {
  final int orderLetterId;
  final String paymentMethod;
  final String paymentBank;
  final String paymentNumber;
  final double paymentAmount;
  final int creator;
  final String? note;
  final String? receiptImagePath;
  final String? paymentDate;
  final int? id;

  const OrderLetterPaymentEntity({
    required this.orderLetterId,
    required this.paymentMethod,
    required this.paymentBank,
    required this.paymentNumber,
    required this.paymentAmount,
    required this.creator,
    this.note,
    this.receiptImagePath,
    this.paymentDate,
    this.id,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderLetterPaymentEntity &&
          runtimeType == other.runtimeType &&
          orderLetterId == other.orderLetterId &&
          paymentMethod == other.paymentMethod &&
          paymentBank == other.paymentBank &&
          paymentNumber == other.paymentNumber &&
          paymentAmount == other.paymentAmount &&
          creator == other.creator &&
          note == other.note &&
          receiptImagePath == other.receiptImagePath &&
          paymentDate == other.paymentDate &&
          id == other.id;

  @override
  int get hashCode =>
      orderLetterId.hashCode ^
      paymentMethod.hashCode ^
      paymentBank.hashCode ^
      paymentNumber.hashCode ^
      paymentAmount.hashCode ^
      creator.hashCode ^
      note.hashCode ^
      receiptImagePath.hashCode ^
      paymentDate.hashCode ^
      id.hashCode;
}

