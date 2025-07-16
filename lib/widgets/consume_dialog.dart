// lib/widgets/consume_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/consumption_log.dart';
import '../models/food_item.dart';
import '../utils/quantity_parser.dart';

class ConsumeDialog extends StatefulWidget {
  final List<FoodItem> inventoryItems;
  final Function(FoodItem item, double grams, MealType mealType) onConsume;

  const ConsumeDialog({
    super.key,
    required this.inventoryItems,
    required this.onConsume,
  });

  @override
  State<ConsumeDialog> createState() => _ConsumeDialogState();
}

class _ConsumeDialogState extends State<ConsumeDialog> {
  FoodItem? _selectedItem;
  double _gramsPerUnit = 0;
  double _gramsPerServing = 0;
  double _totalAvailableGrams = 0;
  MealType _selectedMeal = MealType.snack;

  final _gramsController = TextEditingController();
  final _servingsController = TextEditingController();
  final _unitsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.inventoryItems.isNotEmpty) {
      _onItemChanged(widget.inventoryItems.first);
    }
  }

  @override
  void dispose() {
    _gramsController.dispose();
    _servingsController.dispose();
    _unitsController.dispose();
    super.dispose();
  }

  void _onItemChanged(FoodItem? item) {
    if (item == null) return;
    setState(() {
      _selectedItem = item;
      _gramsPerUnit = item.gramsPerUnit;

      final servingSizeString = item.nutriments['serving_size'] as String?;
      _gramsPerServing = servingSizeString != null
          ? QuantityParser.toGrams(QuantityParser.parse(servingSizeString))
          : 0;

      _totalAvailableGrams = item.inventoryGrams;

      _gramsController.text =
          (_gramsPerServing > 0
                  ? _gramsPerServing
                  : (_gramsPerUnit > 0 ? 100.0 : 0.0))
              .toStringAsFixed(0);
      _updateInputsFromGrams();
    });
  }

  void _updateInputsFromGrams() {
    final grams = double.tryParse(_gramsController.text) ?? 0.0;
    if (_gramsPerServing > 0) {
      _servingsController.text = (grams / _gramsPerServing).toStringAsFixed(1);
    }
    if (_gramsPerUnit > 0) {
      _unitsController.text = (grams / _gramsPerUnit).toStringAsFixed(1);
    }
  }

  void _updateInputsFromServings() {
    final servings = double.tryParse(_servingsController.text) ?? 0.0;
    final grams = servings * _gramsPerServing;
    _gramsController.text = grams.toStringAsFixed(0);
    if (_gramsPerUnit > 0) {
      _unitsController.text = (grams / _gramsPerUnit).toStringAsFixed(1);
    }
  }

  void _updateInputsFromUnits() {
    final units = double.tryParse(_unitsController.text) ?? 0.0;
    final grams = units * _gramsPerUnit;
    _gramsController.text = grams.toStringAsFixed(0);
    if (_gramsPerServing > 0) {
      _servingsController.text = (grams / _gramsPerServing).toStringAsFixed(1);
    }
  }

  void _handleConsume() {
    final gramsToConsume = double.tryParse(_gramsController.text) ?? 0.0;
    if (gramsToConsume <= 0 || _selectedItem == null) return;
    if (gramsToConsume > _totalAvailableGrams) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Not enough in inventory. Only ${_totalAvailableGrams.toStringAsFixed(0)}g available.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    widget.onConsume(_selectedItem!, gramsToConsume, _selectedMeal);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Consume Item',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildItemSelector(),
            if (_selectedItem != null) ...[
              const SizedBox(height: 16),
              SegmentedButton<MealType>(
                segments: const [
                  ButtonSegment(
                    value: MealType.breakfast,
                    label: Text('Breakfast'),
                  ),
                  ButtonSegment(value: MealType.lunch, label: Text('Lunch')),
                  ButtonSegment(value: MealType.dinner, label: Text('Dinner')),
                  ButtonSegment(value: MealType.snack, label: Text('Snack')),
                ],
                selected: {_selectedMeal},
                onSelectionChanged: (Set<MealType> newSelection) {
                  setState(() {
                    _selectedMeal = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 24),
              _buildInputRow('Grams', _gramsController, _updateInputsFromGrams),
              if (_gramsPerServing > 0) const SizedBox(height: 16),
              if (_gramsPerServing > 0)
                _buildInputRow(
                  'Servings',
                  _servingsController,
                  _updateInputsFromServings,
                ),
              const SizedBox(height: 16),
              _buildInputRow('Units', _unitsController, _updateInputsFromUnits),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _handleConsume,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Confirm Consumption'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItemSelector() {
    return DropdownButtonFormField<FoodItem>(
      value: _selectedItem,
      onChanged: _onItemChanged,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Select Product',
        border: OutlineInputBorder(),
      ),
      items: widget.inventoryItems.map((item) {
        return DropdownMenuItem<FoodItem>(
          value: item,
          child: Text(
            '${item.name} (x${item.displayQuantity.toStringAsFixed(1)})',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInputRow(
    String label,
    TextEditingController controller,
    VoidCallback onEdit,
  ) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      onChanged: (value) => onEdit(),
    );
  }
}
