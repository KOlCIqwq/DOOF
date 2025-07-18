class UnitConverter {
  static final Map<String, double> _conversionsToGrams = {
    // Weight
    'oz': 28.35,
    'ounce': 28.35,
    'ounces': 28.35,
    'lb': 453.59,
    'pound': 453.59,
    'pounds': 453.59,
    'g': 1.0,
    'gram': 1.0,
    'grams': 1.0,
    'kg': 1000.0,
    'kilogram': 1000.0,
    'kilograms': 1000.0,
    // Volume (Approximations for common ingredients like water/flour)
    'tsp': 5.0,
    'teaspoon': 5.0,
    'teaspoons': 5.0,
    'tbsp': 15.0,
    'tablespoon': 15.0,
    'tablespoons': 15.0,
    'cup': 240.0,
    'cups': 240.0,
    'ml': 1.0,
    'milliliter': 1.0,
    'milliliters': 1.0,
    'l': 1000.0,
    'liter': 1000.0,
    'liters': 1000.0,
    'clove': 5.0, // Approx. weight of a garlic clove
    'cloves': 5.0,
    'pinch': 0.3,
    'dash': 0.6,
    // Each (approximations)
    '': 120, // Default for items with no unit, e.g., "1 apple"
  };

  static double parse(String ingredientString) {
    ingredientString = ingredientString.toLowerCase();
    final RegExp regex = RegExp(r'(\d*\.?\d+)\s*([a-zA-Z]*)');
    final match = regex.firstMatch(ingredientString);

    if (match != null) {
      final double quantity = double.tryParse(match.group(1) ?? '0') ?? 0;
      final String unit = match.group(2)?.trim() ?? '';

      double conversionFactor =
          _conversionsToGrams[unit] ?? 120.0; // Default if unit is unknown
      return quantity * conversionFactor;
    }

    return 120.0; // Default weight if parsing fails
  }
}
