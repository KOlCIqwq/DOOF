import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/food_item.dart';
import '../services/inventory_storage.dart';
import '../widgets/delete_quantity.dart';
import 'product_detail_page.dart';
import '../utils/quantity_parser.dart';

class InventoryPage extends StatelessWidget {
  final List<FoodItem> inventoryItems;
  final Function(FoodItem) onAddItem;
  final Function(List<FoodItem>) onUpdateInventory;
  final VoidCallback onScan;

  const InventoryPage({
    super.key,
    required this.inventoryItems,
    required this.onAddItem,
    required this.onUpdateInventory,
    required this.onScan,
  });

  Future<void> _showDeleteDialog(BuildContext context, int index) async {
    final item = inventoryItems[index];

    final double? gramsToDelete = await showDialog<double>(
      context: context,
      builder: (context) => DeleteQuantity(item: item),
    );

    if (gramsToDelete != null && gramsToDelete > 0) {
      final newGrams = item.inventoryGrams - gramsToDelete;
      List<FoodItem> updatedList = List.from(inventoryItems);

      if (newGrams > 0.1) {
        updatedList[index] = item.copyWith(inventoryGrams: newGrams);
      } else {
        updatedList.removeAt(index);
      }
      onUpdateInventory(updatedList);
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
      inventoryItems.clear();
      onUpdateInventory(inventoryItems);
      InventoryStorageService.clearInventory();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All inventory items cleared'),
          backgroundColor: Colors.orange,
        ),
      );
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
          if (inventoryItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _clearAllInventory(context),
              tooltip: 'Clear All',
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onScan,
        backgroundColor: Colors.black,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scan Item'),
      ),
      body: inventoryItems.isEmpty
          ? _buildEmptyState()
          : _buildInventoryList(context),
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
            'Tap the scan button to add your first item!',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: inventoryItems.length,
      itemBuilder: (context, index) {
        final item = inventoryItems[index];
        final (sizeValue, sizeUnit) = QuantityParser.parse(item.packageSize);
        final displayUnit = sizeUnit.isNotEmpty ? sizeUnit : 'g';

        final subtitle = [
          if (item.brand.isNotEmpty) 'Brand: ${item.brand}',
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
                final idx = inventoryItems.indexWhere(
                  (i) => i.barcode == updatedItem.barcode,
                );
                if (idx != -1) {
                  List<FoodItem> updatedList = List.from(inventoryItems);
                  updatedList[idx] = updatedItem;
                  onUpdateInventory(updatedList);
                }
              } else if (result is FoodItem) {
                onAddItem(result);
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
}
