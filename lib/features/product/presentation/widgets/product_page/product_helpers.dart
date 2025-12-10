// Helper functions for product page

/// Checks if the given brand is a "national" brand that uses National area
/// National brands: Spring Air, Therapedic, Sleep Spa
///
/// These brands don't require area-specific pricing and always use "Nasional" area
bool isNationalBrand(String? brand) {
  if (brand == null || brand.isEmpty) return false;

  final lowerBrand = brand.toLowerCase();

  return brand == "Spring Air" ||
      brand == "Therapedic" ||
      lowerBrand.contains('spring air') ||
      lowerBrand.contains('sleep spa');
}

/// Gets the appropriate area to use based on brand
/// Returns "Nasional" for national brands, otherwise returns the selected area
String getEffectiveArea(String? selectedArea, String? selectedBrand) {
  if (isNationalBrand(selectedBrand)) {
    return "Nasional";
  }
  return selectedArea ?? "Nasional";
}

/// Returns the badge text for the area section
/// "Nasional" for national brands, "Default" for others
String getAreaBadgeText(String? selectedBrand) {
  return isNationalBrand(selectedBrand) ? "Nasional" : "Default";
}
