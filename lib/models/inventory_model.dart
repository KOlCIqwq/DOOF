import 'food_item.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

class InventoryModel {
  final String id;
  final String userId;
  final String foodId;
  final FoodItem foodItem; // The full, nested FoodItem object

  InventoryModel({
    required this.id,
    this.userId = '',
    required this.foodId,
    required this.foodItem,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'food_id': foodId,
      'foodItem': foodItem.toJson(), // This nests the full FoodItem object
    };
  }

  factory InventoryModel.fromJson(Map<String, dynamic> json) {
    final foodData = json['foodItems'] ?? json['foodItem'];

    if (foodData == null) {
      throw Exception(
        'Inventory row with ID ${json['id']} is missing its food data.',
      );
    }

    final baseFoodItem = FoodItem.fromJson(foodData);
    final correctQuantity = (json['quantity'] as num?)?.toDouble() ?? baseFoodItem.inventoryGrams;

    return InventoryModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      foodId: json['food_id'] ?? json['item_barcode'] ?? baseFoodItem.barcode,

      foodItem: baseFoodItem.copyWith(inventoryGrams: correctQuantity),
    );
  }

  factory InventoryModel.fromNewFoodItem(
    FoodItem item, [
    String userId = '',
  ]) {
    return InventoryModel(
      id: uuid.v4(),
      userId: userId,
      foodId: item.barcode, // The barcode serves as the food_id
      foodItem: item,
    );
  }

  InventoryModel copyWith({
    String? id,
    String? userId,
    String? foodId,
    double? quantity,
    FoodItem? foodItem,
  }) {
    return InventoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      foodId: foodId ?? this.foodId,
      foodItem: foodItem ?? this.foodItem,
    );
  }
}
