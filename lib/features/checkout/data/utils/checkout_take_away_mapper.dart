/// Maps checkout take-away booleans to API payload value.
class CheckoutTakeAwayMapper {
  const CheckoutTakeAwayMapper._();

  static String? toPayload({
    required bool globalTakeAway,
    bool itemTakeAway = false,
  }) {
    return (globalTakeAway || itemTakeAway) ? 'TAKE AWAY' : null;
  }
}
