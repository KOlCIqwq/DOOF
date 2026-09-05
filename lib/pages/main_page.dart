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
import './profile_page.dart';
import '../models/profile_model.dart';
import '../services/profille_storage.dart';
import '../models/inventory_model.dart';
import '../utils/global_state.dart';
import '../utils/recommended_intake_helper.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  List<InventoryModel> inventoryItems = [];
  List<ConsumptionLog> consumptionHistory = [];
  List<DailyStatsSummary> dailySummaries = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  ProfileModel? profileHistory;

  @override
  void initState() {
    super.initState();
    GlobalState.addFoodToInventory = addNewItemToInventory;
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
      saveAllData();
    }
  }

  void deleteConsumptionLog(String barcode, MealType mealType) {
    setState(() {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      consumptionHistory.removeWhere(
        (log) =>
            log.barcode == barcode &&
            log.mealType == mealType &&
            log.consumedDate.isAfter(startOfDay),
      );
    });

    // Save and sync the changes
    saveAllData();
    showErrorSnackbar('Meal log deleted');
  }

  /// Load all data including inventory,consumption,summaries,personal info
  Future<void> _loadAllData() async {
    // Set loading state to true
    setState(() => _isLoading = true);
    try {
      final loadedInventory = await InventoryStorageService.loadInventory();
      final consumption = await ConsumptionStorageService.loadConsumptionLog();
      final summaries = await DailyStatsStorageService.loadDailyStats();
      final loadedProfile =
          await ProfileStorage.loadProfile() ?? ProfileModel.defaults();
      setState(() {
        inventoryItems = loadedInventory;
        consumptionHistory = consumption;
        dailySummaries = summaries;
        profileHistory = loadedProfile;
      });
      // load profile at startups
      RecommendedIntakeHelper.update(
        weight: loadedProfile.weight ?? 70.0,
        heightCm: loadedProfile.height ?? 170.0,
        age: loadedProfile.age ?? 20.0,
        gender: loadedProfile.gender,
        activityLevel: loadedProfile.activity,
        activityPhase: loadedProfile.phase,
      );

      // Process and save previous day's statistics
      await processAndSavePreviousDayStats();

      // Set loading state to false
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      // Show error snackbar on failure
      showErrorSnackbar('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  // Save all current data to storage
  Future<void> saveAllData() async {
    await InventoryStorageService.saveInventory(inventoryItems);
    await ConsumptionStorageService.saveConsumptionLog(consumptionHistory);
    await DailyStatsStorageService.saveDailyStats(dailySummaries);

    if (profileHistory != null) {
      await ProfileStorage.saveProfile(profileHistory!);
    }
  }

  // Process and save statistics for the previous day if not already summarized
  Future<void> processAndSavePreviousDayStats() async {
    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);
    final yesterday = today.subtract(const Duration(days: 1));

    // Check if yesterday's stats are already summarized
    bool isYesterdaySummarized = dailySummaries.any(
      (s) => DateUtils.isSameDay(s.date, yesterday),
    );

    if (isYesterdaySummarized) return; // Already summarized

    // Get consumption logs for yesterday
    final yesterdayLogs = consumptionHistory
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
        dailySummaries.add(summary);
      });
      // Save updated daily stats
      await DailyStatsStorageService.saveDailyStats(dailySummaries);
    }
  }

  // Add a new food item to inventory or update existing one
  void addNewItemToInventory(FoodItem newItem) {
    setState(() {
      final existingIndex = inventoryItems.indexWhere(
        (invModel) => invModel.foodItem.barcode == newItem.barcode,
      );

      if (existingIndex != -1) {
        final existingItem = inventoryItems[existingIndex];
        final updatedGrams =
            existingItem.foodItem.inventoryGrams + newItem.inventoryGrams;
        final updatedModel = existingItem.copyWith(
          foodItem: existingItem.foodItem.copyWith(
            inventoryGrams: updatedGrams,
          ),
        );
        inventoryItems[existingIndex] = updatedModel;
      } else {
        final newModel = InventoryModel.fromNewFoodItem(newItem);
        inventoryItems.insert(0, newModel);
      }
    });
    saveAllData();
  }

  // Update the entire inventory list, setting dirty
  void updateItemQuantity(String inventoryId, double newGrams) {
    setState(() {
      final index = inventoryItems.indexWhere((item) => item.id == inventoryId);
      if (index != -1) {
        final model = inventoryItems[index];
        final updatedModel = model.copyWith(
          foodItem: model.foodItem.copyWith(inventoryGrams: newGrams),
        );
        inventoryItems[index] = updatedModel;
      }
    });
    saveAllData();
  }

  void deleteItemFromInventory(String inventoryId) {
    setState(() {
      inventoryItems.removeWhere((item) => item.id == inventoryId);
    });
    saveAllData();
  }

  void clearAllInventory() {
    setState(() {
      inventoryItems.clear();
    });
    saveAllData();
  }

  // Log a food item consumption
  void logConsumption(FoodItem item, double gramsToConsume, MealType mealType) {
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
      brand: item.brand,
      packageSize: item.packageSize,
    );

    final itemIndex = inventoryItems.indexWhere(
      (i) => i.foodItem.barcode == item.barcode,
    );

    if (itemIndex != -1) {
      final inventoryItem = inventoryItems[itemIndex];
      final newGram = inventoryItem.foodItem.inventoryGrams - gramsToConsume;

      if (newGram >= 0.1) {
        // Enough quantity to consume
        updateItemQuantity(inventoryItem.id, newGram);
      } else {
        // Finish all the food
        deleteItemFromInventory(inventoryItem.id);
      }
      // Set the consumption history
      setState(() {
        consumptionHistory.insert(0, log);
      });
      showErrorSnackbar('Consumption logged!'); // Show success
    } else {
      showErrorSnackbar("Item not found in the inventory???");
    }
    saveAllData(); // Persist changes
  }

  // Log a recipe consumption
  void logRecipeConsumption(RecipeInfo recipe, MealType mealType) {
    final Map<String, double> consumedNutrients = {};
    if (recipe.nutrients.isNotEmpty) {
      // Map Spoonacular nutrients to Open Food Facts keys
      recipe.nutrients.forEach((name, amount) {
        final key = mapSpoonacularToOff(name);
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
      brand: '',
      packageSize: '100g',
    );
    setState(() {
      consumptionHistory.insert(0, log);
      // Navigate to stats page
      _pageController.jumpToPage(2);
    });
    saveAllData(); // Persist changes
    showErrorSnackbar(
      '${recipe.title} logged as ${mealType.name}!',
    ); // Show success
  }

  void handleProfileUpdate(ProfileModel updatedProfile) {
    setState(() {
      profileHistory = updatedProfile;
    });
    saveAllData();
  }

  // Map Spoonacular nutrient names to Open Food Facts keys
  String? mapSpoonacularToOff(String name) {
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
  Future<void> showConsumeDialog() async {
    // Filter for consumable items
    final consumableItems = inventoryItems
        .where((item) => item.foodItem.inventoryGrams > 0)
        .toList();
    if (consumableItems.isEmpty) {
      showErrorSnackbar("No consumable items in inventory.");
      return;
    }
    // Display bottom sheet dialog
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ConsumeDialog(
        inventoryItems: consumableItems.map((item) => item.foodItem).toList(),
        onConsume: logConsumption,
      ),
    );
  }

  // Callback for page changes in PageView
  void onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // Handle bottom navigation bar taps
  void onBottomNavTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // Show an error snackbar message
  void showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
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
              onPageChanged: onPageChanged,
              physics: const BouncingScrollPhysics(),
              children: [
                // Inventory page
                InventoryPage(
                  inventory: inventoryItems,
                  onAddNewItem: addNewItemToInventory,
                  onUpdateItem: updateItemQuantity,
                  onDeleteItem: deleteItemFromInventory,
                  onClearAll: clearAllInventory,
                ),
                // Recipe page
                RecipePage(onRecipeConsumed: logRecipeConsumption),
                // Stats page
                StatsPage(
                  inventoryItems: inventoryItems
                      .map((e) => e.foodItem)
                      .toList(),
                  consumptionHistory: consumptionHistory,
                  dailySummaries: dailySummaries,
                  onDeleteLog: deleteConsumptionLog,
                ),
                // Account page
                ProfilePage(
                  profile: profileHistory,
                  onProfileChanged: handleProfileUpdate,
                  onSyncRequested: () async {
                    await saveAllData();
                  },
                ),
              ],
            ),
      floatingActionButton:
          _currentIndex ==
              2 // Stats page
          ? FloatingActionButton.extended(
              onPressed: showConsumeDialog, // Show consume dialog
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
        onTap: onBottomNavTapped,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
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
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
