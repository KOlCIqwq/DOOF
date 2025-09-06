import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/inventory_model.dart';

class InventoryStorageService {
  static const String inventoryKey = 'inventory_items';

  /// Saves a list of InventoryModel objects to local storage.
  static Future<void> saveInventory(List<InventoryModel> items) async {
    final prefs = await SharedPreferences.getInstance();
    // Use the toJson method from InventoryModel for serialization
    final jsonList = items.map((item) => item.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await prefs.setString(inventoryKey, jsonString);
  }

  /// Loads a list of InventoryModel objects from local storage.
  static Future<List<InventoryModel>> loadInventory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(inventoryKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      // Use the fromJson factory from InventoryModel for deserialization
      return jsonList.map((json) => InventoryModel.fromJson(json)).toList();
    } catch (e) {
      // If parsing fails (e.g., old data format), return an empty list
      // to prevent the app from crashing.
      return [];
    }
  }

  /// Clears all inventory data from local storage.
  static Future<void> clearInventory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(inventoryKey);
  }

  /// Checks if there is any inventory data saved locally.
  static Future<bool> hasInventoryData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(inventoryKey);
    } catch (e) {
      return false;
    }
  }
}
