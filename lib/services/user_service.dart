import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/food_item.dart';
import '../models/inventory_model.dart';

class UserService {
  final SupabaseClient supabase = Supabase.instance.client;

  /// Create Profile with parameters, required userId
  Future<void> createProfile({
    required String userId,
    double? weight,
    double? height,
    int? age,
    int? gender,
    int? activity,
    int? phase,
  }) async {
    await supabase.from('profiles').insert({
      'id': userId,
      'weight': weight,
      'height': height,
      'age': age,
      'gender': gender,
      'activity': activity,
      'phase': phase,
    });
  }

  /// Get all info of profile using userId
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    final response = await supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return response;
  }

  /// Update the current Profile
  Future<void> updateProfile({
    required String userId,
    double? weight,
    double? height,
    int? age,
    int? gender,
    int? activity,
    int? phase,
  }) async {
    await supabase
        .from('profiles')
        .update({
          if (weight != null) 'weight': weight,
          if (height != null) 'height': height,
          if (age != null) 'age': age,
          if (gender != null) 'gender': gender,
          if (activity != null) 'activity': activity,
          if (phase != null) 'phase': phase,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }

  /// Create new food item
  Future<void> createItem({
    required String barcode,
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
  }) async {
    await supabase.from('foodItems').insert({
      'barcode': barcode,
      'name': name,
      'brand': brand,
      'image_url': imageUrl,
      'insert_date': insertDate?.toIso8601String(),
      'expiration_date': expirationDate?.toIso8601String(),
      'categories': categories,
      'nutriments': nutriments, // jsonb in Supabase
      'fat': fat,
      'carbs': carbs,
      'protein': protein,
      'package_size': packageSize,
      'inventory_grams': inventoryGrams,
      'is_known': isKnown,
    });
  }

  Future<void> upsertFoodItem(FoodItem item) async {
    await supabase.from('foodItems').upsert({
      'barcode': item.barcode,
      'name': item.name,
      'brand': item.brand,
      'image_url': item.imageUrl,
      'categories': item.categories,
      'nutriments': item.nutriments, // Supabase handles the jsonb conversion
      'fat': item.fat,
      'carbs': item.carbs,
      'protein': item.protein,
      'package_size': item.packageSize,
      'is_known': true, // We now know about this item
    });
  }

  Future<Map<String, dynamic>?> getItem({required String itemId}) async {
    final response = await supabase
        .from('foodItems')
        .select()
        .eq('id', itemId)
        .maybeSingle();
    return response;
  }

  /// Create new inventory row
  Future<void> createInventory({
    required String inventoryId,
    required String userId,
    required String foodId,
    int? quantity,
  }) async {
    await supabase.from('userItems').insert({
      'id': inventoryId,
      'user_id': userId,
      'item_barcode': foodId,
      'quantity': quantity ?? 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get inventory for a user, joining with the foodItems table
  Future<List<Map<String, dynamic>>> getInventoryFromUserId({
    required String userId,
  }) async {
    final response = await supabase
        .from('userItems')
        // Select all columns from userItems AND all columns from the related foodItems
        .select('*, foodItems (*)')
        .eq('user_id', userId);

    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Delete item from inventory
  Future<void> deleteInventoryItem({required String userItemId}) async {
    await supabase.from('userItems').delete().eq('id', userItemId);
  }

  /// Update only the quantity for a food item in a user’s inventory
  Future<void> updateQuantity({
    required String userId,
    required String foodId,
    required int quantity,
  }) async {
    await supabase
        .from('userItems')
        .update({
          'quantity': quantity,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', userId)
        .eq('item_barcode', foodId);
  }

  /// Deletes a list of inventory items by their unique row IDs.
  Future<void> deleteInventoryItems({required List<String> itemIds}) async {
    if (itemIds.isEmpty) return; // Don't run a delete query for an empty list
    await supabase.from('userItems').delete().inFilter('id', itemIds);
  }

  /// Creates or updates a list of inventory rows ('userItems').
  Future<void> upsertInventory({required List<InventoryModel> items}) async {
    if (items.isEmpty) return; // Don't run an upsert for an empty list

    final List<Map<String, dynamic>> upsertData = items.map((item) {
      return {
        'id': item.id,
        'user_id': item.userId,
        'item_barcode': item.foodId,
        'quantity': item
            .foodItem
            .inventoryGrams, // Get the quantity from the nested FoodItem
      };
    }).toList();

    await supabase.from('userItems').upsert(upsertData);
  }
}
