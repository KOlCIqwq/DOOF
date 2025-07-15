// lib/widgets/delete_quantity.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/food_item.dart';
import '../utils/quantity_parser.dart';

enum DeletionMode { byUnit, byGram }

class DeleteQuantity extends StatefulWidget {
  final FoodItem item;
  const DeleteQuantity({super.key, required this.item});

  @override
  State<DeleteQuantity> createState() => _DeleteQuantityDialogState();
}

class _DeleteQuantityDialogState extends State<DeleteQuantity> {
  DeletionMode _mode = DeletionMode.byUnit;
  double _sliderValue = 1.0;
  late TextEditingController _textController;
  String _unit = 'units';

  double get maxUnits => widget.item.displayQuantity;
  double get maxGrams => widget.item.inventoryGrams;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: '1');
    final (_, parsedUnit) = QuantityParser.parse(widget.item.packageSize);
    _unit = parsedUnit.isNotEmpty ? parsedUnit : 'units';
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onModeChanged(Set<DeletionMode> newMode) {
    setState(() {
      _mode = newMode.first;
      _sliderValue = 1.0;
      _textController.text = '1';
    });
  }

  void _onSliderChanged(double value) {
    final String newText;
    if (_mode == DeletionMode.byUnit) {
      value = (value * 10).round() / 10;
      newText = value.toStringAsFixed(1);
    } else {
      value = value.roundToDouble();
      newText = value.round().toString();
    }
    setState(() {
      _sliderValue = value;
      _textController.text = newText;
    });
  }

  void _onTextChanged(String value) {
    double numericValue = double.tryParse(value) ?? 1.0;
    final double max = _mode == DeletionMode.byUnit ? maxUnits : maxGrams;

    if (numericValue > max) numericValue = max;
    if (numericValue < 0) numericValue = 0;

    setState(() {
      _sliderValue = numericValue;
    });
  }

  void _onDelete() {
    double gramsToDelete = 0;
    if (_mode == DeletionMode.byUnit) {
      gramsToDelete = _sliderValue * widget.item.gramsPerUnit;
    } else {
      gramsToDelete = _sliderValue;
    }
    Navigator.pop(context, gramsToDelete);
  }

  @override
  Widget build(BuildContext context) {
    final double maxSliderValue = _mode == DeletionMode.byUnit
        ? maxUnits
        : maxGrams;
    final String currentUnit = _mode == DeletionMode.byUnit ? _unit : 'g';

    return AlertDialog(
      title: Text('Delete ${widget.item.name}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<DeletionMode>(
              segments: [
                ButtonSegment(
                  value: DeletionMode.byUnit,
                  label: Text('By $_unit'),
                ),
                const ButtonSegment(
                  value: DeletionMode.byGram,
                  label: Text('By Grams'),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: _onModeChanged,
            ),
            const SizedBox(height: 24),
            Text(
              'Select amount to delete (Max: ${maxSliderValue.toStringAsFixed(1)} $currentUnit)',
            ),
            Slider(
              value: _sliderValue.clamp(0, maxSliderValue),
              min: 0,
              max: maxSliderValue,
              divisions: (maxSliderValue * 10).round().clamp(1, 200),
              label: _sliderValue.toStringAsFixed(1),
              onChanged: _onSliderChanged,
            ),
            SizedBox(
              width: 120,
              child: TextField(
                controller: _textController,
                textAlign: TextAlign.center,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                ],
                onChanged: _onTextChanged,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  suffixText: ' $currentUnit',
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _onDelete,
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
