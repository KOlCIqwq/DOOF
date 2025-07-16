// lib/widgets/macro_pie_chart.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class MacroPieChart extends StatefulWidget {
  final double carbs;
  final double protein;
  final double fat;

  const MacroPieChart({
    super.key,
    required this.carbs,
    required this.protein,
    required this.fat,
  });

  @override
  State<MacroPieChart> createState() => _MacroPieChartState();
}

class _MacroPieChartState extends State<MacroPieChart> {
  int? _touchedIndex;
  Map<String, dynamic>? _centerData;

  @override
  Widget build(BuildContext context) {
    final carbCalories = widget.carbs * 4;
    final proteinCalories = widget.protein * 4;
    final fatCalories = widget.fat * 9;
    final totalCalories = carbCalories + proteinCalories + fatCalories;

    final nutrients = [
      {
        'value': carbCalories,
        'grams': widget.carbs,
        'color': Colors.orange,
        'name': 'Carbs',
      },
      {
        'value': proteinCalories,
        'grams': widget.protein,
        'color': Colors.red.shade400,
        'name': 'Protein',
      },
      {
        'value': fatCalories,
        'grams': widget.fat,
        'color': Colors.blue.shade400,
        'name': 'Fat',
      },
    ];

    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            pieTouchData: PieTouchData(
              touchCallback: (event, pieTouchResponse) {
                setState(() {
                  if (!event.isInterestedForInteractions ||
                      pieTouchResponse == null ||
                      pieTouchResponse.touchedSection == null) {
                    _touchedIndex = -1;
                    _centerData = null;
                    return;
                  }
                  _touchedIndex =
                      pieTouchResponse.touchedSection!.touchedSectionIndex;
                  _centerData = nutrients[_touchedIndex!];
                });
              },
            ),
            borderData: FlBorderData(show: false),
            sectionsSpace: 2,
            centerSpaceRadius: 45,
            sections: _buildSections(totalCalories, nutrients),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _centerData == null
              ? Text(
                  '${totalCalories.round()}\nkcal',
                  key: const ValueKey('total'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : Text(
                  '${_centerData!['name']}\n${(_centerData!['grams'] as double).round()}g',
                  key: ValueKey(_centerData!['name']),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _centerData!['color'] as Color,
                  ),
                ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildSections(
    double totalCalories,
    List<Map<String, dynamic>> nutrients,
  ) {
    if (totalCalories < 1) {
      return [
        PieChartSectionData(
          color: Colors.grey.shade300,
          value: 1,
          title: '',
          radius: 25,
        ),
      ];
    }

    return List.generate(3, (i) {
      final isTouched = i == _touchedIndex;
      final nutrient = nutrients[i];
      final radius = isTouched ? 35.0 : 25.0;
      final percentage = (nutrient['value'] as double) / totalCalories * 100;

      return PieChartSectionData(
        color: nutrient['color'] as Color,
        value: nutrient['value'] as double,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }
}
