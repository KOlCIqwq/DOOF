// lib/pages/stats_page.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/consumption_log.dart';
import '../models/daily_stats_summary.dart';
import '../models/food_item.dart';
import '../models/recipe_model.dart';
import '../services/open_food_facts_api_service.dart';
import '../utils/nutrient_helper.dart';
import '../utils/recommended_intake_helper.dart';
import '../widgets/macro_pie_chart.dart';
import '../widgets/nutrients_progress_bar.dart';
import 'history_page.dart';
import 'product_detail_page.dart';
import 'recipe_info.dart';

class StatsPage extends StatelessWidget {
  final List<FoodItem> inventoryItems;
  final List<ConsumptionLog> consumptionHistory;
  final List<DailyStatsSummary> dailySummaries;

  const StatsPage({
    super.key,
    required this.inventoryItems,
    required this.consumptionHistory,
    required this.dailySummaries,
  });

  // Get today's consumption logs
  List<ConsumptionLog> getTodaysConsumption() {
    // Current date and time
    final now = DateTime.now();
    // Start of the current day
    final startOfDay = DateTime(now.year, now.month, now.day);
    // Filter consumption history for today's logs
    return consumptionHistory
        .where((log) => log.consumedDate.isAfter(startOfDay))
        .toList();
  }

  // Calculate today's nutrient totals
  Map<String, double> getTodaysNutrientTotals(List<ConsumptionLog> todaysLogs) {
    // Initialize totals map
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

  // Calculate macro totals for inventory
  Map<String, double> getMacroTotals(List<FoodItem> items) {
    double totalCarbs = 0;
    double totalProtein = 0;
    double totalFat = 0;
    for (final item in items) {
      // Carbohydrates per 100g
      final carbsPer100g =
          (item.nutriments['carbohydrates_100g'] as num?)?.toDouble() ?? 0;
      // Protein per 100g
      final proteinPer100g =
          (item.nutriments['proteins_100g'] as num?)?.toDouble() ?? 0;
      // Fat per 100g
      final fatPer100g = (item.nutriments['fat_100g'] as num?)?.toDouble() ?? 0;
      totalCarbs += (carbsPer100g / 100) * item.inventoryGrams;
      totalProtein += (proteinPer100g / 100) * item.inventoryGrams;
      totalFat += (fatPer100g / 100) * item.inventoryGrams;
    }
    return {'carbs': totalCarbs, 'protein': totalProtein, 'fat': totalFat};
  }

  // Aggregate meal logs by barcode
  List<Map<String, dynamic>> aggregateMealLogs(List<ConsumptionLog> logs) {
    final Map<String, Map<String, dynamic>> aggregatedMap = {};
    for (final log in logs) {
      if (aggregatedMap.containsKey(log.barcode)) {
        aggregatedMap[log.barcode]!['totalGrams'] += log.consumedGrams;
      } else {
        aggregatedMap[log.barcode] = {
          'barcode': log.barcode,
          'productName': log.productName,
          'imageUrl': log.imageUrl,
          'totalGrams': log.consumedGrams,
          'source': log.source,
        };
      }
    }
    return aggregatedMap.values.toList();
  }

  // Navigate to product or recipe detail page
  Future<void> navigateToDetail(
    BuildContext context,
    Map<String, dynamic> log,
  ) async {
    final String? barcode = log['barcode'];
    if (barcode == null) return;
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try {
      if (log['source'] != null) {
        // Handle recipe navigation
        final recipeId = barcode.replaceAll('recipe_', '');
        final source = log['source'] as RecipeSource;
        final summary = RecipeSummary(
          id: recipeId,
          title: log['productName'],
          image: log['imageUrl'],
          source: source,
        );
        Navigator.pop(context); // Close loading indicator
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeInfoPage(recipeSummary: summary),
          ),
        );
      } else {
        // Fetch food item details
        final item = await OpenFoodFactsApiService.fetchFoodItem(barcode);
        Navigator.pop(context); // Close loading indicator
        if (item != null && context.mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ProductDetailPage(product: item, showAddButton: false),
            ),
          );
        } else if (context.mounted) {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not find details for this item.'),
            ),
          );
        }
      }
    } catch (e) {
      Navigator.pop(context); // Close loading indicator on error
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error loading details.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get today's consumption logs
    final todaysLogs = getTodaysConsumption();
    // Calculate today's nutrient totals
    final todaysNutrients = getTodaysNutrientTotals(todaysLogs);
    // Calculate inventory macro totals
    final inventoryMacros = getMacroTotals(inventoryItems);
    // Consumed macronutrients
    final consumedCarbs = todaysNutrients['carbohydrates'] ?? 0;
    final consumedProtein = todaysNutrients['proteins'] ?? 0;
    final consumedFat = todaysNutrients['fat'] ?? 0;
    // Group meals by type
    final Map<MealType, List<Map<String, dynamic>>> meals = {
      MealType.breakfast: aggregateMealLogs(
        todaysLogs.where((l) => l.mealType == MealType.breakfast).toList(),
      ),
      MealType.lunch: aggregateMealLogs(
        todaysLogs.where((l) => l.mealType == MealType.lunch).toList(),
      ),
      MealType.dinner: aggregateMealLogs(
        todaysLogs.where((l) => l.mealType == MealType.dinner).toList(),
      ),
      MealType.snack: aggregateMealLogs(
        todaysLogs.where((l) => l.mealType == MealType.snack).toList(),
      ),
    };
    // Primary nutrient keys for display
    final primaryNutrientKeys = RecommendedIntakeHelper.dailyValues.keys
        .map((key) => NutrientHelper.getOpenFoodFactsKey(key))
        .toSet();
    // Other nutrients with values greater than zero
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
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // Navigate to history page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      HistoryPage(dailySummaries: dailySummaries),
                ),
              );
            },
            tooltip: 'View History',
          ),
        ],
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
                    // Inventory title
                    const Text(
                      'Inventory',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Inventory macro pie chart
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
                    // Consumed today title
                    const Text(
                      'Consumed Today',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Consumed today macro pie chart
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
          // Intake goals section
          buildSectionHeader("Daily Intake Goals"),
          // Nutrient progress bars
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
            // Other nutrients section header
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
          // Meals section header
          buildSectionHeader("Today's Meals"),
          // Breakfast expansion tile
          buildMealExpansionTile(
            context,
            'Breakfast',
            MealType.breakfast,
            meals,
          ),
          // Lunch expansion tile
          buildMealExpansionTile(context, 'Lunch', MealType.lunch, meals),
          // Dinner expansion tile
          buildMealExpansionTile(context, 'Dinner', MealType.dinner, meals),
          // Snacks expansion tile
          buildMealExpansionTile(context, 'Snacks', MealType.snack, meals),
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

  // Build meal expansion tile widget
  Widget buildMealExpansionTile(
    BuildContext context,
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
      children: logs.map((log) {
        return ListTile(
          onTap: () => navigateToDetail(context, log), // Product/recipe detail
          leading: SizedBox(
            width: 40,
            height: 40,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: log['imageUrl'], // Product image
                fit: BoxFit.cover,
                errorWidget: (context, url, error) =>
                    const Icon(Icons.fastfood, color: Colors.grey),
              ),
            ),
          ),
          title: Text(log['productName']), // Product name
          trailing: Text('${(log['totalGrams'] as double).round()}g'), // Grams
          dense: true,
        );
      }).toList(),
    );
  }
}
