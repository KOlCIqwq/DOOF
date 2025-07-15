// lib/utils/quantity_parser.dart

class QuantityParser {
  static (double, String) parse(String? quantityString) {
    if (quantityString == null || quantityString.isEmpty) {
      return (0.0, '');
    }

    final sanitized = quantityString.trim().toLowerCase();
    final regExp = RegExp(r'^(\d*\.?\d+)\s*([a-zA-Z]+)$');
    final match = regExp.firstMatch(sanitized);

    if (match != null) {
      final value = double.tryParse(match.group(1)!) ?? 0.0;
      final unit = match.group(2)!;
      return (value, unit);
    }

    final numOnlyRegExp = RegExp(r'^(\d*\.?\d+)$');
    final numOnlyMatch = numOnlyRegExp.firstMatch(sanitized);
    if (numOnlyMatch != null) {
      final value = double.tryParse(numOnlyMatch.group(1)!) ?? 0.0;
      return (value, 'g');
    }

    return (0.0, '');
  }

  static double toGrams((double, String) parsedQuantity) {
    final (value, unit) = parsedQuantity;
    switch (unit) {
      case 'g':
      case 'ml':
        return value;
      case 'kg':
      case 'l':
        return value * 1000;
      default:
        return 0.0;
    }
  }
}
