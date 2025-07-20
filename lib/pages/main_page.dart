import 'package:flutter/material.dart';
import '../models/consumption_log.dart';
import '../models/food_item.dart';
import '../models/recipe_model.dart';
import '../services/consumption_storage.dart';
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
  final List<FoodItem> _inventoryItems = [];
  List<ConsumptionLog> _consumptionHistory = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _saveAllData();
    }
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final items = await InventoryStorageService.loadInventory();
      final consumption = await ConsumptionStorageService.loadConsumptionLog();
      setState(() {
        _inventoryItems.clear();
        _inventoryItems.addAll(items);
        _consumptionHistory = consumption;
        _isLoading = false;
      });
    } catch (e) {
      _showErrorSnackbar('Error loading data: $e');
    }
  }

  Future<void> _saveAllData() async {
    await InventoryStorageService.saveInventory(_inventoryItems);
    await ConsumptionStorageService.saveConsumptionLog(_consumptionHistory);
  }

  void _addItemToInventory(FoodItem newItem) {
    setState(() {
      final int existingItemIndex = _inventoryItems.indexWhere(
        (item) => item.barcode == newItem.barcode,
      );

      if (existingItemIndex != -1) {
        final existingItem = _inventoryItems[existingItemIndex];
        _inventoryItems[existingItemIndex] = existingItem.copyWith(
          inventoryGrams: existingItem.inventoryGrams + newItem.inventoryGrams,
        );
      } else {
        _inventoryItems.insert(0, newItem);
      }
    });

    _saveAllData();
    _showSuccessSnackbar('${newItem.name} added to inventory!');
  }

  void _updateInventory(List<FoodItem> updatedItems) {
    setState(() {
      _inventoryItems.clear();
      _inventoryItems.addAll(updatedItems);
    });
    _saveAllData();
  }

  void _logConsumption(
    FoodItem item,
    double gramsToConsume,
    MealType mealType,
  ) {
    final Map<String, double> consumedNutrients = {};
    final nutrientsPer100g = item.nutriments;

    nutrientsPer100g.forEach((key, value) {
      if (key.endsWith('_100g') && value is num) {
        final nutrientName = key.replaceAll('_100g', '');
        consumedNutrients[nutrientName] = (value / 100.0) * gramsToConsume;
      }
    });

    final log = ConsumptionLog(
      barcode: item.barcode,
      productName: item.name,
      imageUrl: item.imageUrl,
      consumedGrams: gramsToConsume,
      consumedDate: DateTime.now(),
      consumedNutrients: consumedNutrients,
      mealType: mealType,
      source: null,
    );

    setState(() {
      _consumptionHistory.insert(0, log);
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
          _inventoryItems.removeAt(itemIndex);
        }
      }
    });

    _saveAllData();
    _showSuccessSnackbar('Consumption logged!');
  }

  void _logRecipeConsumption(RecipeInfo recipe, MealType mealType) {
    final Map<String, double> consumedNutrients = {};

    if (recipe.nutrients.isNotEmpty) {
      recipe.nutrients.forEach((name, amount) {
        final key = _mapSpoonacularToOFF(name);
        if (key != null) {
          if (key == 'energy-kcal') {
            consumedNutrients[key] = amount;
          } else {
            consumedNutrients[key] = amount;
          }
        }
      });
    }

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
      _pageController.jumpToPage(2);
    });

    _saveAllData();
    _showSuccessSnackbar('${recipe.title} logged as ${mealType.name}!');
  }

  String? _mapSpoonacularToOFF(String name) {
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

  Future<void> _showConsumeDialog() async {
    final consumableItems = _inventoryItems
        .where((item) => item.inventoryGrams > 0)
        .toList();
    if (consumableItems.isEmpty) {
      _showErrorSnackbar("No consumable items in inventory.");
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ConsumeDialog(
        inventoryItems: consumableItems,
        onConsume: _logConsumption,
      ),
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onBottomNavTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _showSuccessSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }

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
          ? const Center(child: CircularProgressIndicator())
          : PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              physics: const BouncingScrollPhysics(),
              children: [
                InventoryPage(
                  inventoryItems: _inventoryItems,
                  onAddItem: _addItemToInventory,
                  onUpdateInventory: _updateInventory,
                ),
                RecipePage(onRecipeConsumed: _logRecipeConsumption),
                StatsPage(
                  inventoryItems: _inventoryItems,
                  consumptionHistory: _consumptionHistory,
                ),
              ],
            ),
      floatingActionButton: _currentIndex == 2
          ? FloatingActionButton.extended(
              onPressed: _showConsumeDialog,
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
