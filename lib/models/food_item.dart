class FoodItem {
  final String barcode;
  final String name;
  final String brand;
  final String imageUrl;
  final DateTime scanDate;
  final int calories;
  final List<String> nutrients;
  final double fat;
  final double carbs;
  final double protein;

  FoodItem({
    required this.barcode,
    required this.name,
    required this.brand,
    required this.imageUrl,
    required this.scanDate,
    required this.calories,
    required this.nutrients,
    this.fat = 0.0,
    this.carbs = 0.0,
    this.protein = 0.0,
  });
}
