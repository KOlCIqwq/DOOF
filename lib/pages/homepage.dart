import 'package:flutter/material.dart';
import 'package:food/models/food_item.dart';
import 'package:food/pages/food_detail_page.dart';
import 'package:food/pages/camera_scanner_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:permission_handler/permission_handler.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final List<FoodItem> _inventoryItems = [];

  Future<void> _scanBarcodeAndAddItem() async {
    // Check camera permission
    final cameraPermission = await Permission.camera.request();
    if (!cameraPermission.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera permission is required to scan barcodes'),
          ),
        );
      }
      return;
    }

    try {
      // Navigate to camera scanner
      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (context) => const CameraScannerPage()),
      );

      if (result != null && result.isNotEmpty) {
        // Create a new food item with the scanned barcode
        final newItem = FoodItem(
          barcode: result,
          name:
              'Scanned Product', // You can fetch product info from an API using the barcode
          imageUrl:
              'https://images.unsplash.com/photo-1571771894824-c8fdc904a423?ixlib=rb-4.0.3&q=80&w=1080',
          scanDate: DateTime.now(),
          calories: 105, // These would come from a product database
          nutrients: [
            'Potassium: 422mg',
            'Vitamin C: 10.3mg',
            'Fiber: 3.1g',
            'Sugar: 14g',
          ],
        );

        setState(() {
          _inventoryItems.add(newItem);
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Barcode scanned: $result'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scanning barcode: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addTestItem() {
    // For testing without camera
    final newItem = FoodItem(
      barcode: '123456789${_inventoryItems.length}',
      name: 'Test Product ${_inventoryItems.length + 1}',
      imageUrl:
          'https://images.unsplash.com/photo-1571771894824-c8fdc904a423?ixlib=rb-4.0.3&q=80&w=1080',
      scanDate: DateTime.now(),
      calories: 105,
      nutrients: [
        'Potassium: 422mg',
        'Vitamin C: 10.3mg',
        'Fiber: 3.1g',
        'Sugar: 14g',
      ],
    );

    setState(() {
      _inventoryItems.add(newItem);
    });
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
          // Add test item button for development
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _addTestItem,
            tooltip: 'Add test item',
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _scanBarcodeAndAddItem,
            backgroundColor: Colors.black,
            tooltip: 'Scan barcode',
            heroTag: 'scan',
            child: const Icon(Icons.qr_code_scanner),
          ),
        ],
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
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _scanBarcodeAndAddItem,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan Your First Item'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FoodDetailPage(item: item),
                ),
              );
            },
            leading: Hero(
              tag: 'foodImage_${item.barcode}',
              child: CachedNetworkImage(
                imageUrl: item.imageUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                placeholder: (context, url) => const SizedBox(
                  width: 50,
                  height: 50,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2.0),
                  ),
                ),
                errorWidget: (context, url, error) =>
                    const Icon(Icons.fastfood, size: 40, color: Colors.grey),
              ),
            ),
            title: Text(
              item.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Barcode: ${item.barcode}'),
                Text('Scanned: ${item.scanDate.toLocal()}'.split(' ')[0]),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                setState(() {
                  _inventoryItems.removeAt(index);
                });
              },
            ),
          ),
        );
      },
    );
  }
}
