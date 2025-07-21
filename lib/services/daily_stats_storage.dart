import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_stats_summary.dart';

class DailyStatsStorageService {
  static const String _statsKey = 'daily_stats_history';

  static Future<void> saveDailyStats(List<DailyStatsSummary> stats) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = stats.map((s) => s.toJson()).toList();
    await prefs.setString(_statsKey, jsonEncode(jsonList));
  }

  static Future<List<DailyStatsSummary>> loadDailyStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_statsKey);
      if (jsonString == null) return [];

      final jsonList = jsonDecode(jsonString) as List;
      final sevenDaysAgo = DateTime.now().subtract(
        const Duration(days: 8),
      ); // Keep 7 full days
      return jsonList
          .map((json) => DailyStatsSummary.fromJson(json))
          .where((stat) => stat.date.isAfter(sevenDaysAgo))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
