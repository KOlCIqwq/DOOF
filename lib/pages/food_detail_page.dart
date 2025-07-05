import 'package:flutter/material.dart';
import 'package:food/models/food_item.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FoodDetailPage extends StatelessWidget {
  final FoodItem item;

  const FoodDetailPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'foodImage_${item.barcode}',
              child: CachedNetworkImage(
                imageUrl: item.imageUrl,
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(
                  width: double.infinity,
                  height: 300,
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.broken_image,
                    size: 100,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- CALORIES ---
                  Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department_outlined,
                        color: Colors.orange,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${item.calories} Calories',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- NUTRIENTS ---
                  Text(
                    'Nutrients',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...item.nutrients.map(
                    (nutrient) => Padding(
                      padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                      child: Text(
                        '• $nutrient',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                  //.toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
