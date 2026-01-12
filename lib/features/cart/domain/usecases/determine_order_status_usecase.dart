/// Use case untuk determine order status berdasarkan discount approval requirements
class DetermineOrderStatusUseCase {
  String call(List<double> discounts) {
    // Filter out zero discounts (no approval needed)
    final significantDiscounts = discounts.where((d) => d > 0.0).toList();

    if (significantDiscounts.isEmpty) {
      return 'Pending';
    }

    if (significantDiscounts.every((d) => d <= 5.0)) {
      return 'Pending';
    }

    return 'Pending';
  }
}

