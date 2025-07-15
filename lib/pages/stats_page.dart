// lib/pages/stats_page.dart

import 'package:flutter/material.dart';
import '../models/consumption_log.dart';
import '../models/food_item.dart';
import '../utils/nutrient_helper.dart';
import '../widgets/pie_chart_widget.dart';

class StatsPage extends StatelessWidget {
  final List<FoodItem> inventoryItems;
  final List<ConsumptionLog> consumptionHistory;

  const StatsPage({
    super.key,
    required this.inventoryItems,
    required this.consumptionHistory,
  });

  int _calculateTotalInventoryCalories() {
    double totalCalories = 0;
    for (final item in inventoryItems) {
      final caloriesPer100g =
          (item.nutriments['energy-kcal_100g'] as num?)?.toDouble() ?? 0.0;
      if (caloriesPer100g > 0) {
        totalCalories += (caloriesPer100g / 100) * item.inventoryGrams;
      }
    }
    return totalCalories.round();
  }

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

  @override
  Widget build(BuildContext context) {
    final todaysLogs = _getTodaysConsumption();
    final todaysNutrients = _getTodaysNutrientTotals(todaysLogs);
    final inventoryCalories = _calculateTotalInventoryCalories();
    final consumedCalories = (todaysNutrients['energy-kcal'] ?? 0.0).round();

    final nutrientList = todaysNutrients.entries
        .where((e) => e.key != 'energy-kcal' && e.value > 0)
        .toList();
    nutrientList.sort((a, b) => b.value.compareTo(a.value)); // Sort by amount

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Daily Stats',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Row(
            children: [
              Expanded(
                child: PieChartWidget(
                  title: 'Inventory',
                  value: inventoryCalories,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: PieChartWidget(
                  title: 'Consumed',
                  value: consumedCalories,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Today\'s Consumed Nutrients',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 24),
          if (nutrientList.isEmpty)
            _buildEmptyNutrientState()
          else
            ...nutrientList.map((entry) {
              final info = NutrientHelper.getInfo(entry.key);
              final value = NutrientHelper.formatValue(entry.value, entry.key);
              return ListTile(
                leading: Icon(info.icon, color: info.color),
                title: Text(
                  info.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                trailing: Text(value, style: const TextStyle(fontSize: 15)),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildEmptyNutrientState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40.0),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.no_food, color: Colors.grey, size: 60),
            SizedBox(height: 16),
            Text(
              'No items consumed today.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
