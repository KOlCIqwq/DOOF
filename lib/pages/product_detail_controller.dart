import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../utils/quantity_parser.dart';
import '../widgets/adjust_package_size_dialog.dart';

// Handles the state and logic for the ProductDetailPage.
class ProductDetailController {
  final FoodItem initialProduct;
  final VoidCallback
  onStateUpdate; // Callback to trigger a UI rebuild (setState).

  late FoodItem product;
  FoodItem? _updatedProduct; // Stores the latest version for the parent page.
  late TextEditingController remainingGramsController;
  List<String> availableModes = [];
  String? currentMode;

  ProductDetailController({
    required this.initialProduct,
    required this.onStateUpdate,
  });

  // Method to get the final updated product when the page is closed.
  FoodItem? get finalProduct => _updatedProduct;

  // Sets up initial values when the controller is created.
  void initialize() {
    product = initialProduct;
    _initializeRemainingGramsController();
    _initializeModes();
  }

  // Populates the list of available nutrient modes (e.g., "per 100g", "per serving").
  void _initializeModes() {
    if (product.nutriments.isEmpty) return;
    final modes = <String>{};
    for (var key in product.nutriments.keys) {
      final parts = key.split('_');
      if (parts.length > 1) {
        modes.add(parts.sublist(1).join('_'));
      }
    }
    if (modes.isEmpty) return;
    availableModes = modes.toList()
      ..sort((a, b) {
        if (a.contains('100g')) return -1;
        if (b.contains('100g')) return 1;
        return a.compareTo(b);
      });
    currentMode = availableModes.first;
  }

  // Initializes the text controller with the correct display value based on the unit.
  void _initializeRemainingGramsController() {
    final (_, unit) = QuantityParser.parse(product.packageSize);
    double displayValue = product.inventoryGrams;

    if (unit == 'kg' || unit == 'L') {
      displayValue /= 1000;
    }

    remainingGramsController = TextEditingController(
      text: displayValue.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), ''),
    );
  }

  // Shows a dialog to change the package size and returns the updated item.
  Future<void> adjustPackageSize(BuildContext context) async {
    final newSize = await showDialog<String>(
      context: context,
      builder: (_) =>
          AdjustPackageSizeDialog(initialValue: product.packageSize),
    );

    if (newSize != null && newSize.isNotEmpty) {
      final newGramsPerUnit = QuantityParser.toGrams(
        QuantityParser.parse(newSize),
      );
      product = product.copyWith(
        packageSize: newSize,
        inventoryGrams: newGramsPerUnit,
      );
      _updatedProduct = product;
      _initializeRemainingGramsController(); // Recalculate display value.
      onStateUpdate(); // Rebuild the UI.
    }
  }

  // Parses user input for remaining amount and updates the state.
  void updateRemainingGrams() {
    final newAmount = double.tryParse(remainingGramsController.text);
    if (newAmount != null) {
      final (_, unit) = QuantityParser.parse(product.packageSize);
      final newSizeStringWithUnit =
          '$newAmount ${unit.isNotEmpty ? unit : 'g'}';
      final newGrams = QuantityParser.toGrams(
        QuantityParser.parse(newSizeStringWithUnit),
      );

      if ((newGrams - product.inventoryGrams).abs() > 0.1) {
        product = product.copyWith(inventoryGrams: newGrams);
        _updatedProduct = product;
        onStateUpdate(); // Rebuild the UI.
      }
    }
  }

  // Cycles to the next available nutrient display mode.
  void switchMode() {
    if (availableModes.length <= 1) return;
    final currentIndex = availableModes.indexOf(currentMode!);
    final nextIndex = (currentIndex + 1) % availableModes.length;
    currentMode = availableModes[nextIndex];
    onStateUpdate(); // Notify UI to rebuild.
  }

  // Cleans up resources like text controllers.
  void dispose() {
    remainingGramsController.dispose();
  }
}
