import 'dart:async';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/food_item.dart';
import '../services/inventory_storage.dart';
import '../services/open_food_facts_api_service.dart';
import '../utils/quantity_parser.dart';
import '../widgets/delete_quantity.dart';
import 'camera_scanner_page.dart';
import 'product_detail_page.dart';

class InventoryPage extends StatefulWidget {
  final List<FoodItem> inventoryItems;
  final Function(FoodItem) onAddItem;
  final Function(List<FoodItem>) onUpdateInventory;

  const InventoryPage({
    super.key,
    required this.inventoryItems,
    required this.onAddItem,
    required this.onUpdateInventory,
  });

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _fabAnimationController;
  bool _isFabMenuOpen = false;
  bool _isSearchVisible = false;

  final TextEditingController _searchController = TextEditingController();
  List<FoodItem> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _toggleFabMenu() {
    setState(() {
      _isFabMenuOpen = !_isFabMenuOpen;
      if (_isFabMenuOpen) {
        _fabAnimationController.forward();
      } else {
        _fabAnimationController.reverse();
      }
    });
  }

  void _openSearch() {
    if (_isFabMenuOpen) {
      _toggleFabMenu();
    }
    setState(() {
      _isSearchVisible = true;
    });
  }

  void _closeSearch() {
    setState(() {
      _isSearchVisible = false;
      _searchResults = [];
      _searchController.clear();
    });
  }

  Future<void> _scanBarcode() async {
    if (_isFabMenuOpen) {
      _toggleFabMenu();
    }
    final cameraPermission = await Permission.camera.request();
    if (!cameraPermission.isGranted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission is required')),
      );
      return;
    }

    if (mounted) {
      final newItem = await Navigator.push<FoodItem>(
        context,
        MaterialPageRoute(builder: (context) => const CameraScannerPage()),
      );
      if (newItem != null) {
        widget.onAddItem(newItem);
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
      });
      return;
    }
    setState(() {
      _isSearching = true;
    });
    final results = await OpenFoodFactsApiService.searchProductsByName(query);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  Future<void> _showDeleteDialog(BuildContext context, int index) async {
    final item = widget.inventoryItems[index];
    final double? gramsToDelete = await showDialog<double>(
      context: context,
      builder: (context) => DeleteQuantity(item: item),
    );
    if (gramsToDelete != null && gramsToDelete > 0) {
      final newGrams = item.inventoryGrams - gramsToDelete;
      List<FoodItem> updatedList = List.from(widget.inventoryItems);
      if (newGrams > 0.1) {
        updatedList[index] = item.copyWith(inventoryGrams: newGrams);
      } else {
        updatedList.removeAt(index);
      }
      widget.onUpdateInventory(updatedList);
    }
  }

  Future<void> _clearAllInventory(BuildContext context) async {
    final bool? confirmClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Inventory'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
    if (confirmClear == true) {
      widget.onUpdateInventory([]);
      await InventoryStorageService.clearInventory();
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
          if (widget.inventoryItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _clearAllInventory(context),
              tooltip: 'Clear All',
            ),
        ],
      ),
      body: Stack(
        children: [
          widget.inventoryItems.isEmpty
              ? _buildEmptyState()
              : _buildInventoryList(context),
          if (_isSearchVisible) _buildSearchOverlay(),
        ],
      ),
      floatingActionButton: _buildExpandingFab(),
    );
  }

  Widget _buildInventoryList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
      itemCount: widget.inventoryItems.length,
      itemBuilder: (context, index) {
        final item = widget.inventoryItems[index];
        final (_, sizeUnit) = QuantityParser.parse(item.packageSize);
        final displayUnit = sizeUnit.isNotEmpty ? sizeUnit : 'g';

        final subtitle = [
          if (item.brand.isNotEmpty && item.brand != 'N/A')
            'Brand: ${item.brand}',
          '${item.inventoryGrams.round()} $displayUnit remaining',
        ].join(' | ');

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: ListTile(
            onTap: () async {
              final result = await Navigator.push<dynamic>(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ProductDetailPage(product: item, showAddButton: true),
                ),
              );
              if (result is Map && result['type'] == 'update') {
                final updatedItem = result['item'] as FoodItem;
                final idx = widget.inventoryItems.indexWhere(
                  (i) => i.barcode == updatedItem.barcode,
                );
                if (idx != -1) {
                  List<FoodItem> updatedList = List.from(widget.inventoryItems);
                  updatedList[idx] = updatedItem;
                  widget.onUpdateInventory(updatedList);
                }
              } else if (result is FoodItem) {
                widget.onAddItem(result);
              }
            },
            leading: Hero(
              tag: '${item.barcode}-${item.packageSize}',
              child: CachedNetworkImage(
                imageUrl: item.imageUrl,
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
                  label: Text('x${item.displayQuantity.toStringAsFixed(1)}'),
                  backgroundColor: Colors.grey.shade200,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _showDeleteDialog(context, index),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey),
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

  Widget _buildSearchOverlay() {
    return Stack(
      children: [
        GestureDetector(
          onTap: _closeSearch,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
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
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search for a product...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _closeSearch,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
              ),
              Expanded(
                child: _isSearching
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final item = _searchResults[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: ListTile(
                              leading: CachedNetworkImage(
                                imageUrl: item.imageUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorWidget: (c, u, e) =>
                                    const Icon(Icons.fastfood),
                              ),
                              title: Text(item.name),
                              subtitle: Text(item.brand),
                              onTap: () async {
                                _closeSearch();
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
                                  widget.onAddItem(result);
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

  Widget _buildExpandingFab() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FadeTransition(
          opacity: _fabAnimationController,
          child: ScaleTransition(
            scale: _fabAnimationController,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: FloatingActionButton.small(
                heroTag: 'search',
                onPressed: _openSearch,
                child: const Icon(Icons.search),
              ),
            ),
          ),
        ),
        FadeTransition(
          opacity: _fabAnimationController,
          child: ScaleTransition(
            scale: _fabAnimationController,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: FloatingActionButton.small(
                heroTag: 'scan',
                onPressed: _scanBarcode,
                child: const Icon(Icons.qr_code_scanner),
              ),
            ),
          ),
        ),
        FloatingActionButton(
          heroTag: 'main',
          onPressed: _toggleFabMenu,
          child: AnimatedIcon(
            icon: AnimatedIcons.menu_close,
            progress: _fabAnimationController,
          ),
        ),
      ],
    );
  }
}
