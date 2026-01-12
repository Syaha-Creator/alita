import '../../domain/entities/product_entity.dart';

/// Helper class untuk menghitung price dan discount secara otomatis
///
/// Logic ini dipindahkan dari ProductBloc untuk meningkatkan maintainability
/// dan testability.
class ProductPriceCalculator {
  /// Menghitung split discount untuk mencapai target price
  ///
  /// [product] - Product yang akan dihitung discount-nya
  /// [targetPrice] - Harga target yang ingin dicapai
  ///
  /// Returns Map dengan keys:
  /// - 'discounts': List of discount percentages untuk setiap level
  /// - 'nominals': List of nominal discount untuk setiap level
  static Map<String, List<double>> calculateSplitDiscounts(
    ProductEntity product,
    double targetPrice,
  ) {
    double originalPrice = product.endUserPrice;

    // Ensure target price is not below bottom price analyst
    if (targetPrice < product.bottomPriceAnalyst) {
      targetPrice = product.bottomPriceAnalyst;
    }

    List<double> maxDiscs = [
      product.disc1,
      product.disc2,
      product.disc3,
      product.disc4,
      product.disc5,
    ];
    List<double> splitDiscs = [];
    List<double> splitNominals = [];
    double currentPrice = originalPrice;

    // Calculate discounts sequentially to ensure final price matches target
    for (int i = 0; i < maxDiscs.length; i++) {
      if (currentPrice <= targetPrice + 0.01) {
        // Already reached or exceeded target price
        splitDiscs.add(0);
        splitNominals.add(0);
        continue;
      }

      double maxAllowed = maxDiscs[i] * 100;
      if (maxAllowed <= 0) {
        splitDiscs.add(0);
        splitNominals.add(0);
        continue;
      }

      // Calculate how much discount is needed to reach target price
      // Formula: currentPrice * (1 - discount/100) = targetPrice
      // Solving for discount: discount = (1 - targetPrice/currentPrice) * 100
      double neededDiscount = (1 - (targetPrice / currentPrice)) * 100;

      // Use the minimum of needed discount and max allowed
      double useDisc =
          neededDiscount > maxAllowed ? maxAllowed : neededDiscount;
      if (useDisc < 0) useDisc = 0;

      splitDiscs.add(useDisc);
      double nominal = currentPrice * (useDisc / 100);
      splitNominals.add(nominal);

      // Update current price after applying this discount
      currentPrice = currentPrice * (1 - useDisc / 100);
    }

    // Verify final price matches target (with small tolerance for rounding)
    double verifyPrice = originalPrice;
    for (int i = 0; i < splitDiscs.length; i++) {
      if (splitDiscs[i] > 0) {
        verifyPrice = verifyPrice * (1 - splitDiscs[i] / 100);
      }
    }

    // If there's a significant difference, adjust the last non-zero discount
    if ((verifyPrice - targetPrice).abs() > 0.01 &&
        splitDiscs.any((d) => d > 0)) {
      // Find last non-zero discount index
      int lastIndex = -1;
      for (int i = splitDiscs.length - 1; i >= 0; i--) {
        if (splitDiscs[i] > 0) {
          lastIndex = i;
          break;
        }
      }

      if (lastIndex >= 0) {
        // Recalculate from beginning to lastIndex-1
        double priceBeforeLast = originalPrice;
        for (int i = 0; i < lastIndex; i++) {
          if (splitDiscs[i] > 0) {
            priceBeforeLast = priceBeforeLast * (1 - splitDiscs[i] / 100);
          }
        }

        // Calculate exact discount needed for last level
        if (priceBeforeLast > targetPrice + 0.01) {
          double exactDiscount = (1 - (targetPrice / priceBeforeLast)) * 100;
          double maxAllowed = maxDiscs[lastIndex] * 100;
          splitDiscs[lastIndex] = exactDiscount > maxAllowed
              ? maxAllowed
              : (exactDiscount < 0 ? 0 : exactDiscount);
          splitNominals[lastIndex] =
              priceBeforeLast * (splitDiscs[lastIndex] / 100);
        }
      }
    }

    return {
      'discounts': splitDiscs,
      'nominals': splitNominals,
    };
  }

  /// Menghitung final price setelah discount diterapkan
  ///
  /// [originalPrice] - Harga asli
  /// [discountPercentages] - List discount percentages
  ///
  /// Returns final price setelah semua discount diterapkan
  static double calculateFinalPrice(
    double originalPrice,
    List<double> discountPercentages,
  ) {
    double finalPrice = originalPrice;
    for (var discount in discountPercentages) {
      finalPrice -= finalPrice * (discount / 100);
    }
    return finalPrice.clamp(0, originalPrice);
  }
}
