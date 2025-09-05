import 'food_item.dart';

class InventoryItem {
  final String id; // inventory row id
  final String userId;
  final String foodId;
  final int quantity; // number of units, or you can keep grams if preferred
  final DateTime? expirationDate;
  final FoodItem? food; // optional: load full food details via join

  InventoryItem({
    required this.id,
    required this.userId,
    required this.foodId,
    required this.quantity,
    this.expirationDate,
    this.food,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'food_id': foodId,
      'quantity': quantity,
      'expiration_date': expirationDate?.toIso8601String(),
    };
  }

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'],
      userId: json['user_id'],
      foodId: json['food_id'],
      quantity: json['quantity'] ?? 0,
      expirationDate: json['expiration_date'] != null
          ? DateTime.parse(json['expiration_date'])
          : null,
      food: json['food'] != null
          ? FoodItem.fromJson(json['food'])
          : null, // if joined
    );
  }
}
