/// Resolves order-letter `channel` from user divisions + address_number.
///
/// Rules (same as header payload):
/// - **SO** — division id 24 (indirect) AND user has address_number
/// - **S1** — division id 25 (direct) OR id 24 without address_number
/// - **MM** — division id 26 when neither SO nor S1 applies
/// - empty — no known division
class CheckoutChannelResolver {
  CheckoutChannelResolver._();

  static const int divisionIndirect = 24;
  static const int divisionDirect = 25;
  static const int divisionMm = 26;

  static const String channelSo = 'SO';
  static const String channelS1 = 'S1';
  static const String channelMm = 'MM';

  static String resolve({
    required List<Map<String, dynamic>> divisions,
    String? userAddressNumber,
  }) {
    final hasMM = divisions.any((d) => d['id'] == divisionMm);
    final hasS1Division = divisions.any((d) => d['id'] == divisionDirect);
    final hasIndirectDivision =
        divisions.any((d) => d['id'] == divisionIndirect);
    final trimmedAddr = userAddressNumber?.trim() ?? '';
    final userHasAddressNumber =
        trimmedAddr.isNotEmpty && trimmedAddr.toLowerCase() != 'null';

    if (hasIndirectDivision && userHasAddressNumber) {
      return channelSo;
    }
    if (hasS1Division || hasIndirectDivision) {
      return channelS1;
    }
    if (hasMM) {
      return channelMm;
    }
    return '';
  }

  /// Checkout payment section (manual form and/or Paper opt-in).
  ///
  /// Visible for **MM** and **Direct** (S1 / empty). Hidden for **SO**.
  static bool showsCheckoutPaymentSection(String channel) =>
      channel == channelMm || canOptInPaperIdPayment(channel);

  /// MM always uses the legacy receipt form (no Paper toggle).
  static bool usesManualCheckoutPayment(String channel) =>
      channel == channelMm;

  /// Direct (S1) / empty channel may opt into Paper.id instead of manual form.
  ///
  /// Callers must still exclude indirect (`SO` / `isIndirectSale`) separately.
  static bool canOptInPaperIdPayment(String channel) =>
      channel != channelMm && channel != channelSo;

  /// Alias of [canOptInPaperIdPayment] — kept for existing call sites.
  static bool usesPaperIdPayment(String channel) =>
      canOptInPaperIdPayment(channel);

  /// Builds `payment_number` for Paper.id: `INV/{no_sp}`.
  static String paperPaymentNumber(String noSp) => 'INV/${noSp.trim()}';
}
