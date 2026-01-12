/// Entity untuk order letter contact
/// Representasi business object untuk contact information
class OrderLetterContactEntity {
  final int orderLetterId;
  final String phoneNumber;
  final int? id;

  const OrderLetterContactEntity({
    required this.orderLetterId,
    required this.phoneNumber,
    this.id,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderLetterContactEntity &&
          runtimeType == other.runtimeType &&
          orderLetterId == other.orderLetterId &&
          phoneNumber == other.phoneNumber &&
          id == other.id;

  @override
  int get hashCode =>
      orderLetterId.hashCode ^ phoneNumber.hashCode ^ id.hashCode;
}
