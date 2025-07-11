// lib/pages/product_detail_page.dart

import 'package:flutter/material.dart';
import '../models/food_item.dart';

class ProductDetailPage extends StatelessWidget {
  final FoodItem product;
  final bool showAddButton;

  const ProductDetailPage({
    super.key,
    required this.product,
    this.showAddButton = false, // Defaults to false
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Hero(
              tag: product.barcode, // Hero animation tag
              child: Container(
                height: 250,
                color: Colors.grey[200],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Image.network(product.imageUrl, fit: BoxFit.contain),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Brand: ${product.brand}',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  _buildNutritionInfo(),
                  const SizedBox(height: 24),
                  const Text(
                    'Additional Info',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 16),
                  ...product.nutrients.map(
                    (nutrient) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        '• $nutrient',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: showAddButton
          ? Padding(
              padding: const EdgeInsets.all(16.0).copyWith(bottom: 32, top: 0),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context, product);
                },
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Add to Inventory'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildNutritionInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _nutritionColumn(
              product.calories.toString(),
              'Calories',
              Colors.orange,
            ),
            _nutritionColumn(
              product.carbs.toStringAsFixed(1),
              'Carbs (g)',
              Colors.blue,
            ),
            _nutritionColumn(
              product.protein.toStringAsFixed(1),
              'Protein (g)',
              Colors.red,
            ),
            _nutritionColumn(
              product.fat.toStringAsFixed(1),
              'Fat (g)',
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _nutritionColumn(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }
}
