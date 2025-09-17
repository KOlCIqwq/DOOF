enum UnitType { weight, volume, unknown }

class QuantityParser {
  static (double, String) parse(String? quantityString) {
    if (quantityString == null || quantityString.isEmpty) {
      return (0.0, '');
    }

    final sanitized = quantityString.trim().toLowerCase();
    final regExp = RegExp(r'^(\d+(?:[.,]\d+)?)\s*([a-zA-Z]+)?$');
    final match = regExp.firstMatch(sanitized);

    if (match != null) {
      var numberStr = match.group(1)!;
      final unit = match.group(2) ?? 'g';
      numberStr = numberStr.replaceAll(',', '.');
      final value = double.tryParse(numberStr) ?? 0.0;
      return (value, unit);
    }

    return (1.0, '');
  }

  static double convert(
    double value, {
    required String from,
    required String to,
  }) {
    if (from == to) {
      return value;
    }
    // First, convert the input value to a base unit (grams).
    final grams = toGrams((value, from));
    // Then, convert from grams to the target unit.
    return fromGrams(grams, to);
  }

  static double toGrams((double, String) parsedQuantity) {
    final (value, unitRaw) = parsedQuantity;
    final unit = unitRaw.toLowerCase();

    switch (unit) {
      case 'g':
        return value;
      case 'kg':
        return value * 1000;
      case 'ml':
        return value;
      case 'l':
        return value * 1000;
      case 'oz':
        return value * 28.35;
      case 'lb':
        return value * 453.6;
      default:
        return value;
    }
  }

  static double fromGrams(double grams, String toUnit) {
    final unit = toUnit.toLowerCase();
    switch (unit) {
      case 'g':
        return grams;
      case 'kg':
        return grams / 1000;
      case 'ml':
        return grams;
      case 'l':
        return grams / 1000;
      case 'oz':
        return grams / 28.35;
      case 'lb':
        return grams / 453.6;
      default:
        return grams;
    }
  }

  static UnitType getUnitType(String unit) {
    final u = unit.toLowerCase();
    if (['g', 'kg', 'oz', 'lb'].contains(u)) {
      return UnitType.weight;
    } else if (['ml', 'l'].contains(u)) {
      return UnitType.volume;
    } else {
      return UnitType.unknown;
    }
  }

  static double getVal((double, String) parsedQuantity) {
    final (value, _) = parsedQuantity;
    return value;
  }
}
