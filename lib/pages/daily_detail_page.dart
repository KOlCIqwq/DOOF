import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/daily_stats_summary.dart';
import '../utils/nutrient_helper.dart';
import '../utils/recommended_intake_helper.dart';
import '../widgets/macro_pie_chart.dart';
import '../widgets/nutrients_progress_bar.dart';

class DailyDetailPage extends StatelessWidget {
  final DailyStatsSummary summary;
  const DailyDetailPage({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final nutrients = summary.nutrientTotals;
    final carbs = nutrients['carbohydrates'] ?? 0;
    final protein = nutrients['proteins'] ?? 0;
    final fat = nutrients['fat'] ?? 0;

    // Keys for primary nutrients
    final primaryNutrientKeys = RecommendedIntakeHelper.dailyValues.keys
        .map((key) => NutrientHelper.getOpenFoodFactsKey(key))
        .toSet();

    // Other nutrients with values greater than zero
    final otherNutrients = nutrients.entries
        .where(
          (entry) =>
              !primaryNutrientKeys.contains(entry.key) && entry.value > 0.001,
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('EEEE, MMM d').format(summary.date)), // Date in AppBar
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Macro pie chart
          SizedBox(
            height: 180,
            child: MacroPieChart(carbs: carbs, protein: protein, fat: fat),
          ),
          // Daily Intake section header
          buildSectionHeader("Daily Intake"),
          // Nutrient progress bars
          ...RecommendedIntakeHelper.dailyValues.entries.map((entry) {
            final nutrientKey = NutrientHelper.getOpenFoodFactsKey(entry.key);
            return NutrientProgressBar(
              name: NutrientHelper.getInfo(nutrientKey).name,
              currentValue: nutrients[nutrientKey] ?? 0.0,
              maxValue: entry.value,
              unit: entry.key == 'energy-kcal' ? 'kcal' : 'g',
            );
          }),
          if (otherNutrients.isNotEmpty) ...[
            // Other Nutrients section header
            buildSectionHeader("Other Nutrients"),
            // List other nutrients
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
        ],
      ),
    );
  }

  // Build section header widget
  Widget buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }
}
