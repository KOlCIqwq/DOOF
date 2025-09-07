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
import '../services/user_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../services/profille_storage.dart';
import '../models/inventory_model.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  List<InventoryModel> inventoryItems = [];
  List<InventoryModel> inventoryItemsToDelete = [];
  List<InventoryModel> inventoryItemsToCreate = [];
  List<InventoryModel> inventoryItemsToUpdate = [];
  List<ConsumptionLog> consumptionHistory = [];
  List<DailyStatsSummary> dailySummaries = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  ProfileModel? profileHistory;
  bool isDataDirty = false;

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
      syncAllDataToSupabase();
    }
  }

  /// Load all data including inventory,consumption,summaries,personal info
  Future<void> _loadAllData() async {
    // Set loading state to true
    setState(() => _isLoading = true);
    final user = Supabase.instance.client.auth.currentUser;
    try {
      List<InventoryModel> loadedInventory = [];
      if (user != null) {
        // This query is still correct: it gets the inventory row and the food item
        final inventoryData = await UserService().getInventoryFromUserId(
          userId: user.id,
        );
        if (inventoryData.isNotEmpty) {
          // Directly map the response to our new state model
          loadedInventory = inventoryData
              .map((data) => InventoryModel.fromJson(data))
              .toList();
        }
      }
      final consumption = await ConsumptionStorageService.loadConsumptionLog();
      final summaries = await DailyStatsStorageService.loadDailyStats();
      ProfileModel loadedProfile;
      if (user != null) {
        final profileMap = await UserService().getProfile(user.id);
        if (profileMap != null) {
          loadedProfile = ProfileModel.fromMap(profileMap);
        } else {
          loadedProfile = ProfileModel.defaults();
        }
      } else {
        loadedProfile = ProfileModel.defaults();
      }
      setState(() {
        inventoryItems = loadedInventory;
        consumptionHistory = consumption;
        dailySummaries = summaries;
        profileHistory = loadedProfile;
      });

      // Process and save previous day's statistics
      await _processAndSavePreviousDayStats();

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
  Future<void> _saveAllData() async {
    await InventoryStorageService.saveInventory(inventoryItems);
    await ConsumptionStorageService.saveConsumptionLog(consumptionHistory);
    await DailyStatsStorageService.saveDailyStats(dailySummaries);

    if (profileHistory != null) {
      await ProfileStorage.saveProfile(profileHistory!);
    }
  }

  Future<void> syncAllDataToSupabase() async {
    // Only run if there are pending changes.
    if (!isDataDirty) {
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return;
    }
    try {
      // Sync Profile Data
      if (profileHistory != null) {
        await UserService().updateProfile(
          userId: user.id,
          weight: profileHistory!.weight,
          height: profileHistory!.height,
          age: profileHistory!.age?.toInt(),
          gender: profileHistory!.gender.index,
          activity: profileHistory!.activity.index,
          phase: profileHistory!.phase.index,
        );

        final allFoodItems = {
          ...inventoryItemsToCreate.map((m) => m.foodItem),
          ...inventoryItemsToUpdate.map((m) => m.foodItem),
          ...inventoryItemsToDelete.map((m) => m.foodItem),
        }.toList();

        // Ensure all parent 'foodItems' exist.
        if (allFoodItems.isNotEmpty) {
          await UserService().upsertFoodItems(allFoodItems);
        }

        // DELETES.
        final itemIdsToDelete = inventoryItemsToDelete
            .map((m) => m.id)
            .toList();
        if (itemIdsToDelete.isNotEmpty) {
          await UserService().deleteInventoryItems(itemIds: itemIdsToDelete);
        }

        //CREATES.
        if (inventoryItemsToCreate.isNotEmpty) {
          await UserService().upsertInventory(items: inventoryItemsToCreate);
        }

        // quantity UPDATES.
        if (inventoryItemsToUpdate.isNotEmpty) {
          await Future.wait(
            inventoryItemsToUpdate.map((item) {
              return UserService().updateQuantity(
                userItemId: item
                    .id, // We need to update the UserService method for this
                quantity: item.foodItem.inventoryGrams.round(),
              );
            }),
          );
        }
        showErrorSnackbar("Synced");
        resetSyncState();
      }

      setState(() {
        isDataDirty = false;
        inventoryItemsToDelete.clear();
      });
    } catch (e) {
      showErrorSnackbar("Can't sync:$e");
    }
  }

  // Process and save statistics for the previous day if not already summarized
  Future<void> _processAndSavePreviousDayStats() async {
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

  void setDirty() {
    if (!isDataDirty) setState(() => isDataDirty = true);
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
        // Add it to the update list (if not already there)
        inventoryItemsToUpdate.removeWhere(
          (item) => item.id == updatedModel.id,
        );
        inventoryItemsToUpdate.add(updatedModel);
      } else {
        // This is a brand new inventory item.
        final newModel = InventoryModel.fromNewFoodItem(
          newItem,
          userId: Supabase.instance.client.auth.currentUser!.id,
        );
        inventoryItems.insert(0, newModel);
        // Add it to the CREATE list.
        inventoryItemsToCreate.add(newModel);
      }
      setState(() {
        setDirty();
      });
    });
  }

  // Update the entire inventory list
  void _updateItemQuantity(String inventoryId, double newGrams) {
    setState(() {
      final index = inventoryItems.indexWhere((item) => item.id == inventoryId);
      if (index != -1) {
        final model = inventoryItems[index];
        final updatedModel = model.copyWith(
          foodItem: model.foodItem.copyWith(inventoryGrams: newGrams),
        );
        inventoryItems[index] = updatedModel;

        // If this was a newly created item, just update it in the create list.
        final createIndex = inventoryItemsToCreate.indexWhere(
          (item) => item.id == inventoryId,
        );
        if (createIndex != -1) {
          inventoryItemsToCreate[createIndex] = updatedModel;
        } else {
          // Otherwise, add it to the update list.
          inventoryItemsToUpdate.removeWhere(
            (item) => item.id == updatedModel.id,
          );
          inventoryItemsToUpdate.add(updatedModel);
        }
      }
    });
    setState(() {
      setDirty();
    });
  }

  void deleteItemFromInventory(String inventoryId) {
    setState(() {
      final index = inventoryItems.indexWhere((item) => item.id == inventoryId);
      if (index != -1) {
        final itemToDelete = inventoryItems[index];

        // If this item was just created locally and never synced,
        // we can just remove it from the create list and we're done.
        final createIndex = inventoryItemsToCreate.indexWhere(
          (item) => item.id == inventoryId,
        );
        if (createIndex != -1) {
          inventoryItemsToCreate.removeAt(createIndex);
        } else {
          // Otherwise, it's an item that exists on the server and needs to be deleted.
          inventoryItemsToDelete.add(itemToDelete);
          // Also remove it from any pending updates.
          inventoryItemsToUpdate.removeWhere((item) => item.id == inventoryId);
        }

        inventoryItems.removeAt(index);
      }
    });
    setState(() {
      setDirty();
    });
  }

  void _clearAllInventory() {
    setState(() {
      // Add all current inventory IDs to the delete list
      inventoryItemsToDelete.addAll(inventoryItems);
      // Clear the live list
      inventoryItems.clear();
      setDirty();
    });
  }

  void resetSyncState() {
    setState(() {
      inventoryItemsToCreate.clear();
      inventoryItemsToUpdate.clear();
      inventoryItemsToDelete.clear();
    });
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
      consumptionHistory.insert(0, log);
      // Update inventory item quantity
      final itemIndex = inventoryItems.indexWhere(
        (i) => i.foodItem.barcode == item.barcode,
      );
      if (itemIndex != -1) {
        final currentItem = inventoryItems[itemIndex];
        final newGrams = currentItem.foodItem.inventoryGrams - gramsToConsume;
        if (newGrams > 0.1) {
          // Create updated foodItem with new quantity, use to create updated inventoryItem
          inventoryItems[itemIndex] = currentItem.copyWith(
            foodItem: currentItem.foodItem.copyWith(inventoryGrams: newGrams),
          );
        } else {
          // Remove item if grams are too low
          deleteItemFromInventory(currentItem.id);
        }
      }
    });
    _saveAllData(); // Persist changes
    showErrorSnackbar('Consumption logged!'); // Show success
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
      consumptionHistory.insert(0, log);
      // Navigate to stats page
      _pageController.jumpToPage(2);
    });
    _saveAllData(); // Persist changes
    showErrorSnackbar(
      '${recipe.title} logged as ${mealType.name}!',
    ); // Show success
  }

  void _handleProfileUpdate(ProfileModel updatedProfile) {
    setState(() {
      profileHistory = updatedProfile;
      isDataDirty = true; // Mark data as dirty
    });
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
        onConsume: _logConsumption,
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
              onPageChanged: onPageChanged,
              physics: const BouncingScrollPhysics(),
              children: [
                // Inventory page
                InventoryPage(
                  inventory: inventoryItems,
                  onAddNewItem: addNewItemToInventory,
                  onUpdateItem: _updateItemQuantity,
                  onDeleteItem: deleteItemFromInventory,
                  onClearAll: _clearAllInventory,
                ),
                // Recipe page
                RecipePage(onRecipeConsumed: _logRecipeConsumption),
                // Stats page
                StatsPage(
                  inventoryItems: inventoryItems
                      .map((e) => e.foodItem)
                      .toList(),
                  consumptionHistory: consumptionHistory,
                  dailySummaries: dailySummaries,
                ),
                // Account page
                ProfilePage(
                  profile: profileHistory,
                  onProfileChanged: _handleProfileUpdate,
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
