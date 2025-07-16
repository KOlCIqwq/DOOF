// lib/pages/stats_page.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/consumption_log.dart';
import '../models/food_item.dart';
import '../utils/nutrient_helper.dart';
import '../utils/recommended_intake_helper.dart';
import '../widgets/macro_pie_chart.dart';
import '../widgets/nutrients_progress_bar.dart';

class StatsPage extends StatelessWidget {
  final List<FoodItem> inventoryItems;
  final List<ConsumptionLog> consumptionHistory;

  const StatsPage({
    super.key,
    required this.inventoryItems,
    required this.consumptionHistory,
  });

  List<ConsumptionLog> _getTodaysConsumption() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return consumptionHistory
        .where((log) => log.consumedDate.isAfter(startOfDay))
        .toList();
  }

  Map<String, double> _getTodaysNutrientTotals(
    List<ConsumptionLog> todaysLogs,
  ) {
    final Map<String, double> totals = {};
    for (final log in todaysLogs) {
      log.consumedNutrients.forEach((key, value) {
        totals.update(
          key,
          (existing) => existing + value,
          ifAbsent: () => value,
        );
      });
    }
    return totals;
  }

  Map<String, double> _getMacroTotals(List<FoodItem> items) {
    double totalCarbs = 0;
    double totalProtein = 0;
    double totalFat = 0;
    for (final item in items) {
      final carbsPer100g =
          (item.nutriments['carbohydrates_100g'] as num?)?.toDouble() ?? 0;
      final proteinPer100g =
          (item.nutriments['proteins_100g'] as num?)?.toDouble() ?? 0;
      final fatPer100g = (item.nutriments['fat_100g'] as num?)?.toDouble() ?? 0;

      totalCarbs += (carbsPer100g / 100) * item.inventoryGrams;
      totalProtein += (proteinPer100g / 100) * item.inventoryGrams;
      totalFat += (fatPer100g / 100) * item.inventoryGrams;
    }
    return {'carbs': totalCarbs, 'protein': totalProtein, 'fat': totalFat};
  }

  List<Map<String, dynamic>> _aggregateMealLogs(List<ConsumptionLog> logs) {
    final Map<String, Map<String, dynamic>> aggregatedMap = {};

    for (final log in logs) {
      if (aggregatedMap.containsKey(log.barcode)) {
        aggregatedMap[log.barcode]!['totalGrams'] += log.consumedGrams;
      } else {
        aggregatedMap[log.barcode] = {
          'productName': log.productName,
          'imageUrl': log.imageUrl,
          'totalGrams': log.consumedGrams,
        };
      }
    }
    return aggregatedMap.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    final todaysLogs = _getTodaysConsumption();
    final todaysNutrients = _getTodaysNutrientTotals(todaysLogs);
    final inventoryMacros = _getMacroTotals(inventoryItems);

    final consumedCarbs = todaysNutrients['carbohydrates'] ?? 0;
    final consumedProtein = todaysNutrients['proteins'] ?? 0;
    final consumedFat = todaysNutrients['fat'] ?? 0;

    final Map<MealType, List<Map<String, dynamic>>> meals = {
      MealType.breakfast: _aggregateMealLogs(
        todaysLogs.where((l) => l.mealType == MealType.breakfast).toList(),
      ),
      MealType.lunch: _aggregateMealLogs(
        todaysLogs.where((l) => l.mealType == MealType.lunch).toList(),
      ),
      MealType.dinner: _aggregateMealLogs(
        todaysLogs.where((l) => l.mealType == MealType.dinner).toList(),
      ),
      MealType.snack: _aggregateMealLogs(
        todaysLogs.where((l) => l.mealType == MealType.snack).toList(),
      ),
    };

    final primaryNutrientKeys = RecommendedIntakeHelper.dailyValues.keys
        .map((key) => NutrientHelper.getOpenFoodFactsKey(key))
        .toSet();

    final otherNutrients = todaysNutrients.entries
        .where(
          (entry) =>
              !primaryNutrientKeys.contains(entry.key) && entry.value > 0.001,
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Daily Stats',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      'Inventory',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                      height: 150,
                      child: MacroPieChart(
                        carbs: inventoryMacros['carbs'] ?? 0,
                        protein: inventoryMacros['protein'] ?? 0,
                        fat: inventoryMacros['fat'] ?? 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      'Consumed Today',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                      height: 150,
                      child: MacroPieChart(
                        carbs: consumedCarbs,
                        protein: consumedProtein,
                        fat: consumedFat,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          _buildSectionHeader("Daily Intake Goals"),
          ...RecommendedIntakeHelper.dailyValues.entries.map((entry) {
            final nutrientKey = NutrientHelper.getOpenFoodFactsKey(entry.key);
            return NutrientProgressBar(
              name: NutrientHelper.getInfo(nutrientKey).name,
              currentValue: todaysNutrients[nutrientKey] ?? 0.0,
              maxValue: entry.value,
              unit: entry.key == 'energy-kcal' ? 'kcal' : 'g',
            );
          }),
          if (otherNutrients.isNotEmpty) ...[
            _buildSectionHeader("Other Nutrients"),
            ...otherNutrients.map((entry) {
              final info = NutrientHelper.getInfo(entry.key);
              return ListTile(
                title: Text(info.name),
                trailing: Text(
                  NutrientHelper.formatValue(entry.value, entry.key),
                ),
                dense: true,
              );
            }),
          ],
          _buildSectionHeader("Today's Meals"),
          _buildMealExpansionTile('Breakfast', MealType.breakfast, meals),
          _buildMealExpansionTile('Lunch', MealType.lunch, meals),
          _buildMealExpansionTile('Dinner', MealType.dinner, meals),
          _buildMealExpansionTile('Snacks', MealType.snack, meals),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildMealExpansionTile(
    String title,
    MealType mealType,
    Map<MealType, List<Map<String, dynamic>>> meals,
  ) {
    final logs = meals[mealType]!;
    if (logs.isEmpty) {
      return const SizedBox.shrink();
    }
    return ExpansionTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      initiallyExpanded: true,
      children: logs
          .map(
            (log) => ListTile(
              leading: SizedBox(
                width: 40,
                height: 40,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: log['imageUrl'],
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.fastfood, color: Colors.grey),
                  ),
                ),
              ),
              title: Text(log['productName']),
              trailing: Text('${(log['totalGrams'] as double).round()}g'),
              dense: true,
            ),
          )
          .toList(),
    );
  }
}
