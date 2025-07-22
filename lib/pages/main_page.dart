import 'package:flutter/material.dart';
import '../models/consumption_log.dart';
import '../models/daily_stats_summary.dart';
import '../models/food_item.dart';
import '../models/recipe_model.dart';
import '../services/consumption_storage.dart';
import '../services/daily_stats_storage.dart';
import '../services/inventory_storage.dart';
import '../widgets/consume_dialog.dart';
import 'inventory_page.dart';
import 'recipe_page.dart';
import 'stats_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  List<FoodItem> _inventoryItems = [];
  List<ConsumptionLog> _consumptionHistory = [];
  List<DailyStatsSummary> _dailySummaries = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Load all initial data
    _loadAllData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Save data when app is paused or detached
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _saveAllData();
    }
  }

  // Load inventory, consumption history, and daily summaries
  Future<void> _loadAllData() async {
    // Set loading state to true
    setState(() => _isLoading = true);
    try {
      // Load data from storage services
      final inventory = await InventoryStorageService.loadInventory();
      final consumption = await ConsumptionStorageService.loadConsumptionLog();
      final summaries = await DailyStatsStorageService.loadDailyStats();

      setState(() {
        _inventoryItems = inventory;
        _consumptionHistory = consumption;
        _dailySummaries = summaries;
      });

      // Process and save previous day's statistics
      await _processAndSavePreviousDayStats();

      // Set loading state to false
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      // Show error snackbar on failure
      _showErrorSnackbar('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  // Save all current data to storage
  Future<void> _saveAllData() async {
    await InventoryStorageService.saveInventory(_inventoryItems);
    await ConsumptionStorageService.saveConsumptionLog(_consumptionHistory);
    await DailyStatsStorageService.saveDailyStats(_dailySummaries);
  }

  // Process and save statistics for the previous day if not already summarized
  Future<void> _processAndSavePreviousDayStats() async {
    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);
    final yesterday = today.subtract(const Duration(days: 1));

    // Check if yesterday's stats are already summarized
    bool isYesterdaySummarized = _dailySummaries.any(
      (s) => DateUtils.isSameDay(s.date, yesterday),
    );

    if (isYesterdaySummarized) return; // Already summarized

    // Get consumption logs for yesterday
    final yesterdayLogs = _consumptionHistory
        .where((log) => DateUtils.isSameDay(log.consumedDate, yesterday))
        .toList();

    if (yesterdayLogs.isNotEmpty) {
      final Map<String, double> totals = {};
      for (final log in yesterdayLogs) {
        log.consumedNutrients.forEach((key, value) {
          totals.update(
            key,
            (existing) => existing + value,
            ifAbsent: () => value,
          );
        });
      }

      // Create daily stats summary
      final summary = DailyStatsSummary(
        date: yesterday,
        nutrientTotals: totals,
      );
      setState(() {
        _dailySummaries.add(summary);
      });
      // Save updated daily stats
      await DailyStatsStorageService.saveDailyStats(_dailySummaries);
    }
  }

  // Add a new food item to inventory or update existing one
  void _addItemToInventory(FoodItem newItem) {
    setState(() {
      // Find if item already exists
      final int existingItemIndex = _inventoryItems.indexWhere(
        (item) => item.barcode == newItem.barcode,
      );

      if (existingItemIndex != -1) {
        // Update existing item's grams
        final existingItem = _inventoryItems[existingItemIndex];
        _inventoryItems[existingItemIndex] = existingItem.copyWith(
          inventoryGrams: existingItem.inventoryGrams + newItem.inventoryGrams,
        );
      } else {
        // Add new item to the beginning of the list
        _inventoryItems.insert(0, newItem);
      }
    });
    _saveAllData(); // Persist changes
    _showSuccessSnackbar('${newItem.name} added to inventory!'); // Show success
  }

  // Update the entire inventory list
  void _updateInventory(List<FoodItem> updatedItems) {
    setState(() {
      _inventoryItems = updatedItems;
    });
    _saveAllData(); // Persist changes
  }

  // Log a food item consumption
  void _logConsumption(
    FoodItem item,
    double gramsToConsume,
    MealType mealType,
  ) {
    final Map<String, double> consumedNutrients = {};
    final nutrientsPer100g = item.nutriments;
    // Calculate consumed nutrients based on grams
    nutrientsPer100g.forEach((key, value) {
      if (key.endsWith('_100g') && value is num) {
        final nutrientName = key.replaceAll('_100g', '');
        consumedNutrients[nutrientName] = (value / 100.0) * gramsToConsume;
      }
    });
    // Create new consumption log
    final log = ConsumptionLog(
      barcode: item.barcode,
      productName: item.name,
      imageUrl: item.imageUrl,
      consumedGrams: gramsToConsume,
      consumedDate: DateTime.now(),
      consumedNutrients: consumedNutrients,
      mealType: mealType,
      source: null,
      categories: item.categories,
      expirationDate: item.expirationDate,
    );
    setState(() {
      _consumptionHistory.insert(0, log);
      // Update inventory item quantity
      final itemIndex = _inventoryItems.indexWhere(
        (i) => i.barcode == item.barcode,
      );
      if (itemIndex != -1) {
        final currentItem = _inventoryItems[itemIndex];
        final newGrams = currentItem.inventoryGrams - gramsToConsume;
        if (newGrams > 0.1) {
          _inventoryItems[itemIndex] = currentItem.copyWith(
            inventoryGrams: newGrams,
          );
        } else {
          // Remove item if grams are too low
          _inventoryItems.removeAt(itemIndex);
        }
      }
    });
    _saveAllData(); // Persist changes
    _showSuccessSnackbar('Consumption logged!'); // Show success
  }

  // Log a recipe consumption
  void _logRecipeConsumption(RecipeInfo recipe, MealType mealType) {
    final Map<String, double> consumedNutrients = {};
    if (recipe.nutrients.isNotEmpty) {
      // Map Spoonacular nutrients to Open Food Facts keys
      recipe.nutrients.forEach((name, amount) {
        final key = _mapSpoonacularToOff(name);
        if (key != null) {
          consumedNutrients[key] = amount;
        }
      });
    }
    // Create new consumption log for recipe
    final log = ConsumptionLog(
      barcode: 'recipe_${recipe.id}',
      productName: recipe.title,
      imageUrl: recipe.image,
      consumedGrams: recipe.totalGrams,
      consumedDate: DateTime.now(),
      consumedNutrients: consumedNutrients,
      mealType: mealType,
      source: recipe.source,
    );
    setState(() {
      _consumptionHistory.insert(0, log);
      // Navigate to stats page
      _pageController.jumpToPage(2);
    });
    _saveAllData(); // Persist changes
    _showSuccessSnackbar(
      '${recipe.title} logged as ${mealType.name}!',
    ); // Show success
  }

  // Map Spoonacular nutrient names to Open Food Facts keys
  String? _mapSpoonacularToOff(String name) {
    final map = {
      'Calories': 'energy-kcal',
      'Fat': 'fat',
      'Saturated Fat': 'saturated-fat',
      'Carbohydrates': 'carbohydrates',
      'Net Carbohydrates': 'carbohydrates',
      'Sugar': 'sugars',
      'Protein': 'proteins',
      'Sodium': 'sodium',
      'Fiber': 'fiber',
      'Vitamin C': 'vitamin-c',
      'Vitamin A': 'vitamin-a',
      'Iron': 'iron',
      'Calcium': 'calcium',
    };
    return map[name];
  }

  // Show consume item dialog
  Future<void> _showConsumeDialog() async {
    // Filter for consumable items
    final consumableItems = _inventoryItems
        .where((item) => item.inventoryGrams > 0)
        .toList();
    if (consumableItems.isEmpty) {
      _showErrorSnackbar("No consumable items in inventory.");
      return;
    }
    // Display bottom sheet dialog
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ConsumeDialog(
        inventoryItems: consumableItems,
        onConsume: _logConsumption,
      ),
    );
  }

  // Callback for page changes in PageView
  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // Handle bottom navigation bar taps
  void _onBottomNavTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // Show a success snackbar message
  void _showSuccessSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }

  // Show an error snackbar message
  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            ) // Loading indicator
          : PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              physics: const BouncingScrollPhysics(),
              children: [
                // Inventory page
                InventoryPage(
                  inventoryItems: _inventoryItems,
                  onAddItem: _addItemToInventory,
                  onUpdateInventory: _updateInventory,
                ),
                // Recipe page
                RecipePage(onRecipeConsumed: _logRecipeConsumption),
                // Stats page
                StatsPage(
                  inventoryItems: _inventoryItems,
                  consumptionHistory: _consumptionHistory,
                  dailySummaries: _dailySummaries,
                ),
              ],
            ),
      floatingActionButton: _currentIndex == 2
          ? FloatingActionButton.extended(
              onPressed: _showConsumeDialog, // Show consume dialog
              label: const Text(
                'Consume Item',
                style: TextStyle(color: Colors.white),
              ),
              icon: const Icon(Icons.restaurant_menu, color: Colors.white),
              backgroundColor: Colors.black,
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTapped,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: 'Recipes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart_outline),
            activeIcon: Icon(Icons.pie_chart),
            label: 'Stats',
          ),
        ],
      ),
    );
  }
}
