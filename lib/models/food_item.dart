class FoodItem {
  final String barcode;
  final String name;
  final String imageUrl; // For displaying a picture of the item
  final DateTime scanDate;

  FoodItem({
    required this.barcode,
    required this.name,
    required this.imageUrl,
    required this.scanDate,
  });
}
