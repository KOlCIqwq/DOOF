import '../utils/quantity_parser.dart';

class FoodItem {
  final String barcode;
  final String name;
  final String brand;
  final String imageUrl;
  final DateTime insertDate;
  final DateTime? expirationDate; // The expiration date of the product
  final String categories; // Product categories
  final Map<String, dynamic> nutriments; // Map of nutriment values
  final double fat;
  final double carbs;
  final double protein;
  final String packageSize;
  final double inventoryGrams;
  final bool isKnown;
  final List<dynamic>? ingredients;

  FoodItem({
    required this.barcode,
    required this.name,
    required this.brand,
    required this.imageUrl,
    required this.insertDate,
    this.expirationDate,
    required this.categories,
    required this.nutriments,
    required this.fat,
    required this.carbs,
    required this.protein,
    required this.packageSize,
    required this.inventoryGrams,
    this.isKnown = true,
    this.ingredients,
  });

  // The weight in grams of a single, standard package of this item.
  double get gramsPerUnit {
    final (value, unit) = QuantityParser.parse(packageSize);
    if (value <= 0) return 100.0;
    return QuantityParser.getVal((value, unit));
  }

  // The calculated quantity available, as a decimal (e.g., 2.5 units).
  double get displayQuantity {
    final gpu = gramsPerUnit;
    if (gpu <= 0) return 0.0;
    return inventoryGrams / gpu;
  }

  FoodItem copyWith({
    String? barcode,
    String? name,
    String? brand,
    String? imageUrl,
    DateTime? insertDate,
    DateTime? expirationDate,
    String? categories,
    Map<String, dynamic>? nutriments,
    double? fat,
    double? carbs,
    double? protein,
    String? packageSize,
    double? inventoryGrams,
    bool? isKnown,
    List<dynamic>? ingredients,
  }) {
    return FoodItem(
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      imageUrl: imageUrl ?? this.imageUrl,
      insertDate: insertDate ?? this.insertDate,
      expirationDate: expirationDate ?? this.expirationDate,
      categories: categories ?? this.categories,
      nutriments: nutriments ?? this.nutriments,
      fat: fat ?? this.fat,
      carbs: carbs ?? this.carbs,
      protein: protein ?? this.protein,
      packageSize: packageSize ?? this.packageSize,
      inventoryGrams: inventoryGrams ?? this.inventoryGrams,
      isKnown: isKnown ?? this.isKnown,
      ingredients: ingredients ?? this.ingredients,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'barcode': barcode,
      'name': name,
      'brand': brand,
      'image_url': imageUrl,
      'insert_date': insertDate.toIso8601String(),
      'expiration_date': expirationDate?.toIso8601String(),
      'categories': categories,
      'nutriments': nutriments,
      'fat': fat,
      'carbs': carbs,
      'protein': protein,
      'package_size': packageSize,
      'inventory_grams': inventoryGrams,
      'is_known': isKnown,
      'ingredients': ingredients,
    };
  }

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      barcode: json['barcode'] as String,

      name: json['name'] ?? 'Unknown Product',
      brand: json['brand'] ?? '',
      imageUrl: json['image_url'] ?? '',

      insertDate: json['insert_date'] != null
          ? DateTime.parse(json['insert_date'])
          : DateTime.now(),
      expirationDate: json['expiration_date'] != null
          ? DateTime.parse(json['expiration_date'])
          : null,

      categories: json['categories'] ?? '',
      packageSize: json['package_size'] ?? '',

      // Handle the nested JSON 'nutriments' object
      nutriments: json['nutriments'] != null
          ? Map<String, dynamic>.from(json['nutriments'])
          : const {}, // Default to an empty map
      fat: (json['fat'] as num? ?? 0.0).toDouble(),
      carbs: (json['carbs'] as num? ?? 0.0).toDouble(),
      protein: (json['protein'] as num? ?? 0.0).toDouble(),
      inventoryGrams: (json['inventory_grams'] as num? ?? 0.0).toDouble(),

      isKnown: json['is_known'] ?? false,
      ingredients: json['ingredients'] != null
          ? List<dynamic>.from(json['ingredients'])
          : null,
    );
  }
}
