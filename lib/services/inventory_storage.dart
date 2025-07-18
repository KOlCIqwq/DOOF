import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/food_item.dart';

class InventoryStorageService {
  static const String _inventoryKey = 'inventory_items';

  static Future<void> saveInventory(List<FoodItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = items.map((item) => item.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await prefs.setString(_inventoryKey, jsonString);
  }

  static Future<List<FoodItem>> loadInventory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_inventoryKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList.map((json) => FoodItem.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> clearInventory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_inventoryKey);
  }

  static Future<bool> hasInventoryData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_inventoryKey);
    } catch (e) {
      return false;
    }
  }
}
