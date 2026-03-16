/// One split detail segment for bonus fulfillment.
class TakeAwaySplit {
  final int qty;
  final bool isTakeAway;
  final String note;

  const TakeAwaySplit({
    required this.qty,
    required this.isTakeAway,
    required this.note,
  });
}

/// Splits bonus quantity into take-away and delivery segments.
class TakeAwaySplitter {
  const TakeAwaySplitter._();

  static List<TakeAwaySplit> split({
    required int totalQty,
    required int takeAwayQty,
  }) {
    final total = totalQty < 0 ? 0 : totalQty;
    final takeAway = takeAwayQty.clamp(0, total);
    final delivery = total - takeAway;

    if (total == 0) return const [];
    if (takeAway == total) {
      return [
        TakeAwaySplit(qty: total, isTakeAway: true, note: 'Bawa Langsung'),
      ];
    }
    if (takeAway == 0) {
      return [
        TakeAwaySplit(qty: total, isTakeAway: false, note: 'Dikirim'),
      ];
    }
    return [
      TakeAwaySplit(qty: takeAway, isTakeAway: true, note: 'Bawa Langsung'),
      TakeAwaySplit(qty: delivery, isTakeAway: false, note: 'Dikirim'),
    ];
  }
}
