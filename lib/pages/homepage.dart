// lib/pages/homepage.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/food_item.dart';
import '../widgets/delete_quantity.dart';
import 'camera_scanner_page.dart';
import 'product_detail_page.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});
  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final List<FoodItem> _inventoryItems = [];

  void _addItemToInventory(FoodItem newItem) {
    setState(() {
      final int existingItemIndex = _inventoryItems.indexWhere(
        (item) => item.barcode == newItem.barcode,
      );

      if (existingItemIndex != -1) {
        // Item exists, create a new one with the updated quantity
        final existingItem = _inventoryItems[existingItemIndex];
        final updatedItem = existingItem.copyWith(
          quantity: existingItem.quantity + newItem.quantity,
        );
        // Replace the old item with the updated one
        _inventoryItems[existingItemIndex] = updatedItem;
      } else {
        // Item does not exist, add it to the list
        _inventoryItems.insert(0, newItem);
      }
    });

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
    if (item.quantity == 1) {
      setState(() => _inventoryItems.removeAt(index));
      return;
    }

    final int? quantityToDelete = await showDialog<int>(
      context: context,
      builder: (context) => DeleteQuantity(item: item),
    );

    if (quantityToDelete != null && quantityToDelete > 0) {
      setState(() {
        if (quantityToDelete >= item.quantity) {
          _inventoryItems.removeAt(index);
        } else {
          // Replace the item with a new one that has the reduced quantity
          final updatedItem = item.copyWith(
            quantity: item.quantity - quantityToDelete,
          );
          _inventoryItems[index] = updatedItem;
        }
      });
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scanBarcodeAndAddItem,
        backgroundColor: Colors.black,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scan Item'),
      ),
      body: _inventoryItems.isEmpty
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
              final result = await Navigator.push<FoodItem>(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ProductDetailPage(product: item, showAddButton: true),
                ),
              );
              if (result != null) {
                _addItemToInventory(result);
              }
            },
            leading: Hero(
              tag: item.barcode,
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
                if (item.quantity > 1)
                  Chip(
                    label: Text('x${item.quantity}'),
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
