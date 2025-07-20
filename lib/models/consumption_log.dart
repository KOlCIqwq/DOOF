import '../models/recipe_model.dart';

enum MealType { breakfast, lunch, dinner, snack }

class ConsumptionLog {
  final String barcode;
  final String productName;
  final String imageUrl;
  final double consumedGrams;
  final DateTime consumedDate;
  final Map<String, double> consumedNutrients;
  final MealType mealType;
  final RecipeSource? source; //To know if it's a recipe and from where

  ConsumptionLog({
    required this.barcode,
    required this.productName,
    required this.imageUrl,
    required this.consumedGrams,
    required this.consumedDate,
    required this.consumedNutrients,
    required this.mealType,
    this.source,
  });

  Map<String, dynamic> toJson() {
    return {
      'barcode': barcode,
      'productName': productName,
      'imageUrl': imageUrl,
      'consumedGrams': consumedGrams,
      'consumedDate': consumedDate.toIso8601String(),
      'consumedNutrients': consumedNutrients,
      'mealType': mealType.name,
      'source': source?.name,
    };
  }

  factory ConsumptionLog.fromJson(Map<String, dynamic> json) {
    return ConsumptionLog(
      barcode: json['barcode'] ?? '',
      productName: json['productName'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      consumedGrams: (json['consumedGrams'] as num?)?.toDouble() ?? 0.0,
      consumedDate: DateTime.parse(
        json['consumedDate'] ?? DateTime.now().toIso8601String(),
      ),
      consumedNutrients: Map<String, double>.from(
        json['consumedNutrients'] ?? {},
      ),
      mealType: MealType.values.byName(json['mealType'] ?? 'snack'),
      source: json['source'] != null
          ? RecipeSource.values.byName(json['source'])
          : null,
    );
  }
}
