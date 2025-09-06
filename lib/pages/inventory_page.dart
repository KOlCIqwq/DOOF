import 'dart:async';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/food_item.dart';
import '../services/inventory_storage.dart';
import '../services/open_food_facts_api_service.dart';
//import '../utils/quantity_parser.dart';
import '../widgets/delete_quantity.dart';
import 'camera_scanner_page.dart';
import 'product_detail_page.dart';
import '../models/inventory_model.dart';

class InventoryPage extends StatefulWidget {
  final List<InventoryModel> inventory;
  final Function(FoodItem newItem) onAddNewItem;
  final Function(String inventoryId, double newGrams) onUpdateItem;
  final Function(String inventoryId) onDeleteItem;
  final VoidCallback onClearAll;

  const InventoryPage({
    super.key,
    required this.inventory,
    required this.onAddNewItem,
    required this.onUpdateItem,
    required this.onDeleteItem,
    required this.onClearAll,
  });

  @override
  State<InventoryPage> createState() => InventoryPageState();
}

class InventoryPageState extends State<InventoryPage>
    with SingleTickerProviderStateMixin {
  late AnimationController fabAnimationController;
  bool isFabMenuOpen = false;
  bool isSearchVisible = false;

  final TextEditingController searchController = TextEditingController();
  List<FoodItem> searchResults = [];
  bool isSearching = false;
  Timer? debounce;

  @override
  void initState() {
    super.initState();
    fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    fabAnimationController.dispose();
    searchController.dispose();
    debounce?.cancel();
    super.dispose();
  }

  // Toggle the floating action button menu open/close state
  void toggleFabMenu() {
    setState(() {
      isFabMenuOpen = !isFabMenuOpen;
      if (isFabMenuOpen) {
        fabAnimationController.forward();
      } else {
        fabAnimationController.reverse();
      }
    });
  }

  // Open the search overlay
  void openSearch() {
    if (isFabMenuOpen) {
      toggleFabMenu(); // Close FAB menu if open
    }
    setState(() {
      isSearchVisible = true;
    });
  }

  // Close the search overlay and clear results
  void closeSearch() {
    setState(() {
      isSearchVisible = false;
      searchResults = [];
      searchController.clear();
    });
  }

  // Scan a barcode using the camera
  Future<void> scanBarcode() async {
    if (isFabMenuOpen) {
      toggleFabMenu(); // Close FAB menu if open
    }
    // Request camera permission
    final cameraPermission = await Permission.camera.request();
    if (!cameraPermission.isGranted && mounted) {
      // Show snackbar if permission denied
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission is required')),
      );
      return;
    }

    if (mounted) {
      // Navigate to camera scanner page and get new item
      final newItem = await Navigator.push<FoodItem>(
        context,
        MaterialPageRoute(builder: (context) => const CameraScannerPage()),
      );
      if (newItem != null) {
        widget.onAddNewItem(newItem);
      }
    }
  }

  // Handle search query changes with debounce
  void onSearchChanged(String query) {
    if (debounce?.isActive ?? false) debounce!.cancel();
    debounce = Timer(const Duration(milliseconds: 500), () {
      performSearch(query); // Perform search after debounce
    });
  }

  // Perform product search by name
  Future<void> performSearch(String query) async {
    if (query.length < 2) {
      setState(() {
        searchResults = [];
      });
      return;
    }
    setState(() {
      isSearching = true;
    });
    // Call API to search products
    final results = await OpenFoodFactsApiService.searchProductsByName(query);
    if (mounted) {
      setState(() {
        searchResults = results;
        isSearching = false;
      });
    }
  }

  // Show dialog to delete a specific quantity of an item
  Future<void> showDeleteDialog(BuildContext context, int index) async {
    final inventoryItem = widget.inventory[index];
    final foodItem = inventoryItem.foodItem; // Get the nested food item

    final double? gramsToDelete = await showDialog<double>(
      context: context,
      builder: (context) =>
          DeleteQuantity(item: foodItem), // Pass the FoodItem to the dialog
    );

    if (gramsToDelete != null && gramsToDelete > 0) {
      final newGrams = foodItem.inventoryGrams - gramsToDelete;
      if (newGrams > 0.1) {
        // It's an UPDATE
        widget.onUpdateItem(inventoryItem.id, newGrams);
      } else {
        // It's a DELETE
        widget.onDeleteItem(inventoryItem.id);
      }
    }
  }

  // Show dialog to clear all inventory items
  Future<void> clearAllInventory(BuildContext context) async {
    // Confirm clear all action
    final bool? confirmClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Inventory'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Cancel button
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), // Clear All button
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
    if (confirmClear == true) {
      widget.onClearAll(); // Clear inventory list
      await InventoryStorageService.clearInventory(); // Clear stored inventory
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Inventory',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (widget.inventory.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () =>
                  clearAllInventory(context), // Clear all inventory
              tooltip: 'Clear All',
            ),
        ],
      ),
      body: Stack(
        children: [
          widget.inventory.isEmpty
              ? buildEmptyState() // Display empty state
              : buildInventoryList(context), // Display inventory list
          if (isSearchVisible) buildSearchOverlay(), // Display search overlay
        ],
      ),
      floatingActionButton: buildExpandingFab(), // Expanding FAB
    );
  }

  // Build the list of inventory items
  Widget buildInventoryList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
      itemCount: widget.inventory.length,
      itemBuilder: (context, index) {
        final inventoryItem = widget.inventory[index];
        final item = inventoryItem.foodItem;

        final subtitle = [
          if (item.brand.isNotEmpty && item.brand != 'N/A')
            'Brand: ${item.brand}',
        ].join();

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: ListTile(
            onTap: () async {
              // Navigate to product detail page
              final result = await Navigator.push<dynamic>(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ProductDetailPage(product: item, showAddButton: true),
                ),
              );
              if (result is Map && result['type'] == 'update') {
                // Update item in inventory
                final updatedItem = result['item'] as FoodItem;
                final idx = widget.inventory.indexWhere(
                  (i) => i.foodItem.barcode == updatedItem.barcode,
                );
                if (idx != -1) {
                  // Update the existing InventoryModel with the new FoodItem data
                  final existingInventoryModel = widget.inventory[idx];
                  widget.onUpdateItem(
                    existingInventoryModel.id,
                    updatedItem.inventoryGrams,
                  );
                }
              } else if (result is FoodItem) {
                widget.onAddNewItem(result); // Add new item to inventory
              }
            },
            leading: Hero(
              tag: '${item.barcode}-${item.packageSize}', // Hero animation tag
              child: CachedNetworkImage(
                imageUrl: item.imageUrl, // Product image URL
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const CircularProgressIndicator(strokeWidth: 2.0),
                errorWidget: (context, url, error) =>
                    const Icon(Icons.fastfood, size: 40, color: Colors.grey),
              ),
            ),
            title: Text(
              item.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(subtitle),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Chip(
                  label: Text(
                    'x${item.displayQuantity.toStringAsFixed(1)}',
                  ), // Display quantity chip
                  backgroundColor: Colors.grey.shade200,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ), // Delete icon
                  onPressed: () =>
                      showDeleteDialog(context, index), // Show delete dialog
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Build the empty state widget when inventory is empty
  Widget buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: Colors.grey,
          ), // Empty inbox icon
          SizedBox(height: 20),
          Text(
            'Your inventory is empty',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'Tap the + button to add your first item!',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Build the search overlay widget
  Widget buildSearchOverlay() {
    return Stack(
      children: [
        GestureDetector(
          onTap: closeSearch, // Close search on tap outside
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Blur background
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(30),
                  child: TextField(
                    controller: searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search for a product...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: closeSearch, // Close search button
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: onSearchChanged, // Handle search query changes
                  ),
                ),
              ),
              Expanded(
                child: isSearching
                    ? const Center(
                        child: CircularProgressIndicator(),
                      ) // Loading indicator
                    : ListView.builder(
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          final item = searchResults[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: ListTile(
                              leading: CachedNetworkImage(
                                imageUrl: item.imageUrl, // Product image
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorWidget: (c, u, e) =>
                                    const Icon(Icons.fastfood),
                              ),
                              title: Text(item.name), // Product name
                              subtitle: Text(item.brand), // Product brand
                              onTap: () async {
                                closeSearch(); // Close search on item tap
                                final result = await Navigator.push<FoodItem>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetailPage(
                                      product: item,
                                      showAddButton: true,
                                    ),
                                  ),
                                );
                                if (result != null) {
                                  widget.onAddNewItem(
                                    result,
                                  ); // Add item to inventory
                                }
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Build the expanding floating action button
  Widget buildExpandingFab() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FadeTransition(
          opacity: fabAnimationController,
          child: ScaleTransition(
            scale: fabAnimationController,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: FloatingActionButton.small(
                heroTag: 'search',
                onPressed: openSearch, // Open search
                child: const Icon(Icons.search), // Search icon
              ),
            ),
          ),
        ),
        FadeTransition(
          opacity: fabAnimationController,
          child: ScaleTransition(
            scale: fabAnimationController,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: FloatingActionButton.small(
                heroTag: 'scan',
                onPressed: scanBarcode, // Scan barcode
                child: const Icon(Icons.qr_code_scanner), // Scan icon
              ),
            ),
          ),
        ),
        FloatingActionButton(
          heroTag: 'main',
          onPressed: toggleFabMenu, // Toggle FAB menu
          child: AnimatedIcon(
            icon: AnimatedIcons.menu_close,
            progress: fabAnimationController,
          ),
        ),
      ],
    );
  }
}
