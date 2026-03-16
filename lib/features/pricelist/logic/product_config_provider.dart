import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────────────────────────────────────
//  Available sizes (master data)
// ─────────────────────────────────────────────────────────

const List<String> availableSizes = [
  '100x200',
  '120x200',
  '160x200',
  '180x200',
  '200x200',
];

// ─────────────────────────────────────────────────────────
//  Config state
// ─────────────────────────────────────────────────────────

class ProductConfig {
  final String selectedSize;
  final bool isFullSet;
  final bool useSorong;

  const ProductConfig({
    this.selectedSize = '160x200',
    this.isFullSet = false,
    this.useSorong = false,
  });

  ProductConfig copyWith({
    String? selectedSize,
    bool? isFullSet,
    bool? useSorong,
  }) {
    return ProductConfig(
      selectedSize: selectedSize ?? this.selectedSize,
      isFullSet: isFullSet ?? this.isFullSet,
      useSorong: useSorong ?? this.useSorong,
    );
  }

  /// Price surcharge for size (simulated)
  double get sizeSurcharge {
    return switch (selectedSize) {
      '100x200' => 0,
      '120x200' => 300000,
      '160x200' => 800000,
      '180x200' => 1200000,
      '200x200' => 1600000,
      _ => 0,
    };
  }

  /// Price surcharge for full set (divan + headboard)
  double get fullSetSurcharge => isFullSet ? 2500000 : 0;

  /// Price surcharge for sorong (pull-out bed)
  double get sorongSurcharge => useSorong ? 1800000 : 0;

  /// Total surcharge on top of base price
  double get totalSurcharge => sizeSurcharge + fullSetSurcharge + sorongSurcharge;

  /// Compute final price from a base price
  double computePrice(double basePrice) => basePrice + totalSurcharge;

  /// Human-readable config summary for cart / checkout
  String get summary {
    final parts = <String>[selectedSize];
    if (isFullSet) parts.add('Full Set');
    if (useSorong) parts.add('+ Sorong');
    return parts.join(' · ');
  }
}

// ─────────────────────────────────────────────────────────
//  Notifier
// ─────────────────────────────────────────────────────────

class ProductConfigNotifier extends StateNotifier<ProductConfig> {
  ProductConfigNotifier() : super(const ProductConfig());

  void selectSize(String size) {
    state = state.copyWith(selectedSize: size);
  }

  void setFullSet(bool value) {
    state = state.copyWith(isFullSet: value);
  }

  void toggleSorong(bool value) {
    state = state.copyWith(useSorong: value);
  }

  void reset() {
    state = const ProductConfig();
  }
}

// ─────────────────────────────────────────────────────────
//  Provider
// ─────────────────────────────────────────────────────────

final productConfigProvider =
    StateNotifierProvider.autoDispose<ProductConfigNotifier, ProductConfig>(
  (ref) => ProductConfigNotifier(),
);
