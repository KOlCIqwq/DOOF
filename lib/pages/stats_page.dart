import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  // Get today's consumption logs from the history.
  List<ConsumptionLog> getTodaysConsumption() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return consumptionHistory
        .where((log) => log.consumedDate.isAfter(startOfDay))
        .toList();
  }

  // Sum all nutrients from a list of consumption logs.
  Map<String, double> getTodaysNutrientTotals(List<ConsumptionLog> todaysLogs) {
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

  // Calculate total macronutrients (carbs, protein, fat) from inventory items.
  Map<String, double> getMacroTotals(List<FoodItem> items) {
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

  // Groups consumed items by barcode to sum their weights.
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
          'categories': log.categories,
          'expirationDate': log.expirationDate,
        };
      }
    }
    return aggregatedMap.values.toList();
  }

  // Handles tap events on consumed items to show their details.
  Future<void> navigateToDetail(
    BuildContext context,
    Map<String, dynamic> log,
  ) async {
    final String? barcode = log['barcode'];
    if (barcode == null) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try {
      if (log['source'] != null) {
        final recipeId = barcode.replaceAll('recipe_', '');
        final source = log['source'] as RecipeSource;
        final summary = RecipeSummary(
          id: recipeId,
          title: log['productName'],
          image: log['imageUrl'],
          source: source,
        );
        Navigator.pop(context);
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeInfoPage(recipeSummary: summary),
          ),
        );
      } else {
        final item = await OpenFoodFactsApiService.fetchFoodItem(barcode);
        Navigator.pop(context);
        if (item != null && context.mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ProductDetailPage(product: item, showAddButton: false),
            ),
          );
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not find details for this item.'),
            ),
          );
        }
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error loading details.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final todaysLogs = getTodaysConsumption();
    final todaysNutrients = getTodaysNutrientTotals(todaysLogs);
    final inventoryMacros = getMacroTotals(inventoryItems);
    final consumedCarbs = todaysNutrients['carbohydrates'] ?? 0;
    final consumedProtein = todaysNutrients['proteins'] ?? 0;
    final consumedFat = todaysNutrients['fat'] ?? 0;
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
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
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
          buildSectionHeader("Daily Intake Goals"),
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
            buildSectionHeader("Other Nutrients"),
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
          buildSectionHeader("Today's Meals"),
          buildMealExpansionTile(
            context,
            'Breakfast',
            MealType.breakfast,
            meals,
          ),
          buildMealExpansionTile(context, 'Lunch', MealType.lunch, meals),
          buildMealExpansionTile(context, 'Dinner', MealType.dinner, meals),
          buildMealExpansionTile(context, 'Snacks', MealType.snack, meals),
        ],
      ),
    );
  }

  // A reusable widget for section headers.
  Widget buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  // A reusable widget for the expandable meal sections.
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
        final List<String> subtitles = [];
        if (log['categories'] != null &&
            (log['categories'] as String).isNotEmpty) {
          subtitles.add(log['categories']);
        }
        if (log['expirationDate'] != null) {
          final date = log['expirationDate'] as DateTime;
          subtitles.add('Expires: ${DateFormat.yMd().format(date)}');
        }

        return ListTile(
          onTap: () => navigateToDetail(context, log),
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
          subtitle: subtitles.isNotEmpty ? Text(subtitles.join(' | ')) : null,
          trailing: Text('${(log['totalGrams'] as double).round()}g'),
          dense: true,
        );
      }).toList(),
    );
  }
}
