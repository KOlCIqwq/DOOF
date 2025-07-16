import 'package:flutter/material.dart';

class NutrientInfo {
  final String name;
  final IconData icon;
  final Color color;
  NutrientInfo({required this.name, required this.icon, required this.color});
}

class NutrientLists {
  final List<MapEntry<String, String>> keyNutrients;
  final List<MapEntry<String, String>> otherNutrients;
  NutrientLists({required this.keyNutrients, required this.otherNutrients});
}

class NutrientHelper {
  static final Map<String, NutrientInfo> _nutrientMap = {
    'energy-kcal': NutrientInfo(
      name: 'Calories',
      icon: Icons.local_fire_department,
      color: Colors.orange,
    ),
    'fat': NutrientInfo(name: 'Fat', icon: Icons.opacity, color: Colors.purple),
    'carbohydrates': NutrientInfo(
      name: 'Carbs',
      icon: Icons.grain,
      color: Colors.blue,
    ),
    'proteins': NutrientInfo(
      name: 'Protein',
      icon: Icons.fitness_center,
      color: Colors.red,
    ),
    'sugars': NutrientInfo(
      name: 'Sugars',
      icon: Icons.scatter_plot_outlined,
      color: Colors.pinkAccent,
    ),
    'salt': NutrientInfo(
      name: 'Salt',
      icon: Icons.blur_on,
      color: Colors.blueGrey,
    ),
    'sodium': NutrientInfo(
      name: 'Sodium',
      icon: Icons.science_outlined,
      color: Colors.grey.shade600,
    ),
    'fiber': NutrientInfo(name: 'Fiber', icon: Icons.eco, color: Colors.green),
    'trans-fat': NutrientInfo(
      name: 'Trans Fat',
      icon: Icons.warning_amber_rounded,
      color: Colors.red.shade900,
    ),
    'vitamin-c': NutrientInfo(
      name: 'Vitamin C',
      icon: Icons.health_and_safety,
      color: Colors.orangeAccent,
    ),
    'calcium': NutrientInfo(
      name: 'Calcium',
      icon: Icons.monitor_heart,
      color: Colors.lightBlue,
    ),
    'iron': NutrientInfo(name: 'Iron', icon: Icons.iron, color: Colors.brown),
  };

  static final Set<String> _macroKeys = {
    'energy-kcal',
    'fat',
    'carbohydrates',
    'proteins',
  };

  static final Set<String> _keyNutrientKeys = {
    'sugars',
    'salt',
    'sodium',
    'fiber',
    'trans-fat',
  };

  static NutrientInfo getInfo(String key) {
    final baseKey = key.split('_')[0];
    return _nutrientMap[baseKey] ??
        NutrientInfo(
          name: _formatKey(key),
          icon: Icons.help_outline,
          color: Colors.grey,
        );
  }

  static NutrientLists getNutrientLists(Map<String, String> nutrients) {
    final List<MapEntry<String, String>> key = [];
    final List<MapEntry<String, String>> other = [];

    for (var entry in nutrients.entries) {
      final baseKey = entry.key;
      if (_keyNutrientKeys.contains(baseKey)) {
        key.add(entry);
      } else if (!_macroKeys.contains(baseKey)) {
        other.add(entry);
      }
    }
    return NutrientLists(keyNutrients: key, otherNutrients: other);
  }

  static String _formatKey(String key) {
    return key
        .replaceAll('_100g', '')
        .replaceAll('-', ' ')
        .replaceAll('_', ' ')
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() + e.substring(1) : '')
        .join(' ');
  }

  static String formatValue(dynamic value, String key) {
    if (value is! num) return value.toString();
    if (value == 0 && !key.contains('energy')) return '0 g';

    double originalValue = value.toDouble();
    String unit = 'g';
    double displayValue = originalValue;

    if (key.contains('energy-kcal')) {
      return '${originalValue.round()} kcal';
    } else if (key.contains('energy-kj')) {
      return '${originalValue.round()} kJ';
    } else {
      if (originalValue >= 0.1) {
        unit = 'g';
        displayValue = originalValue;
      } else if (originalValue >= 0.0001) {
        unit = 'mg';
        displayValue = originalValue * 1000;
      } else {
        unit = 'μg';
        displayValue = originalValue * 1000000;
      }
    }

    if (displayValue < 10 && displayValue != displayValue.roundToDouble()) {
      return '${displayValue.toStringAsFixed(1)} $unit';
    }
    return '${displayValue.round()} $unit';
  }

  static String getOpenFoodFactsKey(String simpleKey) {
    switch (simpleKey) {
      case 'energy-kcal':
        return 'energy-kcal';
      case 'fat':
        return 'fat';
      case 'saturated-fat':
        return 'saturated-fat';
      case 'carbohydrates':
        return 'carbohydrates';
      case 'sugars':
        return 'sugars';
      case 'proteins':
        return 'proteins';
      case 'salt':
        return 'salt';
      default:
        return simpleKey;
    }
  }
}
