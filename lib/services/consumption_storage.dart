// lib/services/consumption_storage.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/consumption_log.dart';

class ConsumptionStorageService {
  static const String _logKey = 'consumption_log';

  static Future<void> saveConsumptionLog(List<ConsumptionLog> logs) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = logs.map((log) => log.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await prefs.setString(_logKey, jsonString);
  }

  static Future<List<ConsumptionLog>> loadConsumptionLog() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_logKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      // Filter out logs older than 7 days to keep storage clean
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      return jsonList
          .map((json) => ConsumptionLog.fromJson(json))
          .where((log) => log.consumedDate.isAfter(sevenDaysAgo))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
