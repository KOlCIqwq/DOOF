import 'package:flutter/material.dart';

// A card summarizing the four main nutritional values.
class ProductMacroSummaryCard extends StatelessWidget {
  final int calories;
  final double carbs;
  final double protein;
  final double fat;

  const ProductMacroSummaryCard({
    super.key,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fat,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _nutritionColumn(calories.toString(), 'Calories', Colors.orange),
              _nutritionColumn(
                carbs.toStringAsFixed(1),
                'Carbs (g)',
                Colors.blue,
              ),
              _nutritionColumn(
                protein.toStringAsFixed(1),
                'Protein (g)',
                Colors.red,
              ),
              _nutritionColumn(
                fat.toStringAsFixed(1),
                'Fat (g)',
                Colors.purple,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for displaying a single nutrition value and label.
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
