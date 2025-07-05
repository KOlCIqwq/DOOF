import 'package:flutter/material.dart';
import 'package:food/models/food_item.dart';
import 'package:food/pages/food_detail_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final List<FoodItem> _inventoryItems = [];

  void _scanBarcodeAndAddItem() {
    // We update this to include the new calorie and nutrient info
    final newItem = FoodItem(
      barcode: '123456789${_inventoryItems.length}',
      name: 'Organic Banana ${_inventoryItems.length + 1}',
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _scanBarcodeAndAddItem,
        backgroundColor: Colors.black,
        tooltip: 'Scan a new item',
        child: const Icon(Icons.qr_code_scanner),
      ),
      body: _inventoryItems.isEmpty
          ? _buildEmptyState()
          : _buildInventoryList(),
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

  Widget _buildInventoryList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _inventoryItems.length,
      itemBuilder: (context, index) {
        final item = _inventoryItems[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          clipBehavior: Clip.antiAlias, // Helps with rounded corners on images
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
                // Show a spinner while the image is loading
                placeholder: (context, url) => SizedBox(
                  width: 50,
                  height: 50,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2.0),
                  ),
                ),
                // Show an error icon if the image fails to load
                errorWidget: (context, url, error) =>
                    const Icon(Icons.fastfood, size: 40, color: Colors.grey),
              ),
            ),
            title: Text(
              item.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Scanned: ${item.scanDate.toLocal()}'.split(' ')[0]),
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
