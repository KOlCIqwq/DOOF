import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/food_item.dart';
import '../services/inventory_storage.dart';
import '../widgets/delete_quantity.dart';
import 'camera_scanner_page.dart';
import 'product_detail_page.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});
  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> with WidgetsBindingObserver {
  final List<FoodItem> _inventoryItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadInventory();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Save inventory when app goes to background or is paused
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _saveInventory();
    }
  }

  Future<void> _loadInventory() async {
    try {
      final items = await InventoryStorageService.loadInventory();
      setState(() {
        _inventoryItems.clear();
        _inventoryItems.addAll(items);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading inventory: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveInventory() async {
    try {
      await InventoryStorageService.saveInventory(_inventoryItems);
    } catch (e) {
      print('Error saving inventory: $e');
    }
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
    _saveInventory();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${newItem.name} added to inventory!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _scanBarcodeAndAddItem() async {
    final cameraPermission = await Permission.camera.request();
    if (!cameraPermission.isGranted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission is required')),
      );
      return;
    }

    try {
      final newItem = await Navigator.push<FoodItem>(
        context,
        MaterialPageRoute(builder: (context) => const CameraScannerPage()),
      );
      if (newItem != null) {
        _addItemToInventory(newItem);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showDeleteDialog(int index) async {
    final item = _inventoryItems[index];

    final double? gramsToDelete = await showDialog<double>(
      context: context,
      builder: (context) => DeleteQuantity(item: item),
    );

    if (gramsToDelete != null && gramsToDelete > 0) {
      setState(() {
        final newGrams = item.inventoryGrams - gramsToDelete;
        if (newGrams > 0.1) {
          _inventoryItems[index] = item.copyWith(inventoryGrams: newGrams);
        } else {
          _inventoryItems.removeAt(index);
        }
      });
      _saveInventory();
    }
  }

  Future<void> _clearAllInventory() async {
    final bool? confirmClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Inventory'),
        content: const Text(
          'Are you sure you want to clear all items from your inventory? This action cannot be undone.',
        ),
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
      setState(() {
        _inventoryItems.clear();
      });
      await InventoryStorageService.clearInventory();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All inventory items cleared'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Inventory',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          if (_inventoryItems.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'clear') {
                  _clearAllInventory();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Clear All'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scanBarcodeAndAddItem,
        backgroundColor: Colors.black,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scan Item'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _inventoryItems.isEmpty
          ? _buildEmptyState()
          : _buildInventoryList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            'Your inventory is empty',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Tap the scan button to add your first item!',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _inventoryItems.length,
      itemBuilder: (context, index) {
        final item = _inventoryItems[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          clipBehavior: Clip.antiAlias,
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
                final idx = _inventoryItems.indexWhere(
                  (i) => i.barcode == updatedItem.barcode,
                );
                if (idx != -1) {
                  setState(() {
                    _inventoryItems[idx] = updatedItem;
                  });
                  _saveInventory();
                }
              } else if (result is FoodItem) {
                _addItemToInventory(result);
              }
            },
            leading: Hero(
              tag: '${item.barcode}-${item.packageSize}',
              child: item.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const CircularProgressIndicator(strokeWidth: 2.0),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.fastfood,
                        size: 40,
                        color: Colors.grey,
                      ),
                    )
                  : Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    ),
            ),
            title: Text(
              item.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Brand: ${item.brand}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Chip(
                  label: Text('x${item.displayQuantity.toStringAsFixed(1)}'),
                  padding: const EdgeInsets.all(4),
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  backgroundColor: Colors.grey.shade200,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _showDeleteDialog(index),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
