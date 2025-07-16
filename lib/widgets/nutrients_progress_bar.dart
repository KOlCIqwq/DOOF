// lib/widgets/nutrient_progress_bar.dart

import 'package:flutter/material.dart';

class NutrientProgressBar extends StatelessWidget {
  final String name;
  final double currentValue;
  final double maxValue;
  final String unit;

  const NutrientProgressBar({
    super.key,
    required this.name,
    required this.currentValue,
    required this.maxValue,
    this.unit = 'g',
  });

  @override
  Widget build(BuildContext context) {
    final double progress = (maxValue > 0)
        ? (currentValue / maxValue).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                '${currentValue.toStringAsFixed(1)} / ${maxValue.toStringAsFixed(0)} $unit',
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(
              progress > 1.0 ? Colors.red : Colors.green,
            ),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}
