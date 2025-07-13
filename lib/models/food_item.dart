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

  // Convert FoodItem to JSON
  Map<String, dynamic> toJson() {
    return {
      'barcode': barcode,
      'name': name,
      'brand': brand,
      'imageUrl': imageUrl,
      'scanDate': scanDate.toIso8601String(),
      'calories': calories,
      'fat': fat,
      'carbs': carbs,
      'protein': protein,
      'nutriments': nutriments,
      'quantity': quantity,
      'isKnown': isKnown,
    };
  }

  // Create FoodItem from JSON
  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      barcode: json['barcode'] ?? '',
      name: json['name'] ?? '',
      brand: json['brand'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      scanDate: DateTime.parse(
        json['scanDate'] ?? DateTime.now().toIso8601String(),
      ),
      calories: json['calories'] ?? 0,
      fat: (json['fat'] ?? 0.0).toDouble(),
      carbs: (json['carbs'] ?? 0.0).toDouble(),
      protein: (json['protein'] ?? 0.0).toDouble(),
      nutriments: Map<String, dynamic>.from(json['nutriments'] ?? {}),
      quantity: json['quantity'] ?? 1,
      isKnown: json['isKnown'] ?? true,
    );
  }
}
