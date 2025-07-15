// lib/models/food_item.dart

import '../utils/quantity_parser.dart';

class FoodItem {
  final String barcode;
  final String name;
  final String brand;
  final String imageUrl;
  final DateTime insertDate;
  final DateTime? expireDate;
  final Map<String, dynamic> nutriments;
  final double fat;
  final double carbs;
  final double protein;
  final String packageSize;
  final double inventoryGrams;
  final bool isKnown;

  FoodItem({
    required this.barcode,
    required this.name,
    required this.brand,
    required this.imageUrl,
    required this.insertDate,
    this.expireDate,
    required this.nutriments,
    required this.fat,
    required this.carbs,
    required this.protein,
    required this.packageSize,
    required this.inventoryGrams,
    this.isKnown = true,
  });

  double get gramsPerUnit {
    final (value, unit) = QuantityParser.parse(packageSize);
    if (value <= 0) return 100.0;
    return QuantityParser.toGrams((value, unit));
  }

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
    DateTime? expireDate,
    Map<String, dynamic>? nutriments,
    double? fat,
    double? carbs,
    double? protein,
    String? packageSize,
    double? inventoryGrams,
    bool? isKnown,
  }) {
    return FoodItem(
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      imageUrl: imageUrl ?? this.imageUrl,
      insertDate: insertDate ?? this.insertDate,
      expireDate: expireDate ?? this.expireDate,
      nutriments: nutriments ?? this.nutriments,
      fat: fat ?? this.fat,
      carbs: carbs ?? this.carbs,
      protein: protein ?? this.protein,
      packageSize: packageSize ?? this.packageSize,
      inventoryGrams: inventoryGrams ?? this.inventoryGrams,
      isKnown: isKnown ?? this.isKnown,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'barcode': barcode,
      'name': name,
      'brand': brand,
      'imageUrl': imageUrl,
      'insertDate': insertDate.toIso8601String(),
      'expireDate': expireDate?.toIso8601String(),
      'nutriments': nutriments,
      'fat': fat,
      'carbs': carbs,
      'protein': protein,
      'packageSize': packageSize,
      'inventoryGrams': inventoryGrams,
      'isKnown': isKnown,
    };
  }

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    double grams = (json['inventoryGrams'] as num?)?.toDouble() ?? 0.0;
    if (grams == 0.0 && json.containsKey('quantity')) {
      final oldQty = (json['quantity'] as num?)?.toInt() ?? 1;
      final pkgSize = json['packageSize'] as String? ?? '100 g';
      final gramsPerUnit = QuantityParser.toGrams(
        QuantityParser.parse(pkgSize),
      );
      grams = oldQty * (gramsPerUnit > 0 ? gramsPerUnit : 100.0);
    }

    return FoodItem(
      barcode: json['barcode'] ?? '',
      name: json['name'] ?? '',
      brand: json['brand'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      insertDate: DateTime.parse(
        json['insertDate'] ?? DateTime.now().toIso8601String(),
      ),
      expireDate: json['expireDate'] != null
          ? DateTime.parse(json['expireDate'])
          : null,
      nutriments: Map<String, dynamic>.from(json['nutriments'] ?? {}),
      fat: (json['fat'] as num?)?.toDouble() ?? 0.0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0.0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0.0,
      packageSize: json['packageSize'] ?? '100 g',
      inventoryGrams: grams,
      isKnown: json['isKnown'] ?? true,
    );
  }
}
