// lib/models/food_item.dart

class FoodItem {
  final String barcode;
  final String name;
  final String brand;
  final String imageUrl;
  final DateTime scanDate;
  final int calories;
  final double fat;
  final double carbs;
  final double protein;
  final Map<String, dynamic> nutriments;
  final int quantity;
  final bool isKnown;

  FoodItem({
    required this.barcode,
    required this.name,
    required this.brand,
    required this.imageUrl,
    required this.scanDate,
    required this.calories,
    required this.fat,
    required this.carbs,
    required this.protein,
    required this.nutriments,
    this.quantity = 1,
    this.isKnown = true,
  });

  FoodItem copyWith({
    String? barcode,
    String? name,
    String? brand,
    String? imageUrl,
    DateTime? scanDate,
    int? calories,
    double? fat,
    double? carbs,
    double? protein,
    Map<String, dynamic>? nutriments,
    int? quantity,
    bool? isKnown,
  }) {
    return FoodItem(
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      imageUrl: imageUrl ?? this.imageUrl,
      scanDate: scanDate ?? this.scanDate,
      calories: calories ?? this.calories,
      fat: fat ?? this.fat,
      carbs: carbs ?? this.carbs,
      protein: protein ?? this.protein,
      nutriments: nutriments ?? this.nutriments,
      quantity: quantity ?? this.quantity,
      isKnown: isKnown ?? this.isKnown,
    );
  }
}
