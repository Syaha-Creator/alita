class ApplyDiscountsUsecase {
  const ApplyDiscountsUsecase();

  double applySequentially(double basePrice, List<double> discountPercentages) {
    double price = basePrice;
    for (final percent in discountPercentages) {
      if (percent <= 0) continue;
      price = price * (1 - (percent / 100.0));
    }
    if (price < 0) price = 0;
    return price;
  }
}
