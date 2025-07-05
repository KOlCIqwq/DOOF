// lib/models/food_item.dart

class FoodItem {
  final String barcode;
  final String name;
  final String imageUrl;
  final DateTime scanDate;
  final int calories;
  final List<String> nutrients;

  FoodItem({
    required this.barcode,
    required this.name,
    required this.imageUrl,
    required this.scanDate,
    required this.calories, // Add to constructor
    required this.nutrients, // Add to constructor
  });
}
