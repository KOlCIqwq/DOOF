import 'package:flutter/material.dart';
import '../models/consumption_log.dart';
import '../models/food_item.dart';
import '../utils/quantity_parser.dart';

class ConsumeDialog extends StatefulWidget {
  final List<FoodItem> inventoryItems;
  // The callback signature remains the same, accepting grams.
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
  MealType _selectedMeal = MealType.snack;
  String? _errorMessage;

  String _packageUnit = 'g';
  double _valuePerPackage = 0;
  double _valuePerServing = 0;
  double _totalAvailableValue = 0;

  final _amountController = TextEditingController();
  final _packageController = TextEditingController();
  final _servingsController = TextEditingController();

  final _amountFocusNode = FocusNode();
  final _packageFocusNode = FocusNode();
  final _servingsFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.inventoryItems.isNotEmpty) {
      _onItemChanged(widget.inventoryItems.first);
    }
    _amountController.addListener(_onAmountChanged);
    _packageController.addListener(_onPackageChanged);
    _servingsController.addListener(_onServingsChanged);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _packageController.dispose();
    _servingsController.dispose();
    _amountFocusNode.dispose();
    _packageFocusNode.dispose();
    _servingsFocusNode.dispose();
    super.dispose();
  }

  void _onItemChanged(FoodItem? item) {
    if (item == null) return;

    setState(() {
      _selectedItem = item;
      _errorMessage = null;

      // Set the canonical unit and value for the package
      final (pkgValue, pkgUnit) = QuantityParser.parse(item.packageSize);
      _packageUnit = pkgUnit.isEmpty ? 'Unit' : pkgUnit;
      _valuePerPackage = pkgValue;

      // Calculate serving size IN THE CANONICAL UNIT
      final servingSizeString = item.nutriments['serving_size'] as String?;
      if (servingSizeString != null) {
        final (servingValue, servingUnit) = QuantityParser.parse(
          servingSizeString,
        );
        _valuePerServing = QuantityParser.convert(
          servingValue,
          from: servingUnit,
          to: _packageUnit,
        );
      } else {
        _valuePerServing = 0;
      }

      _totalAvailableValue = item.inventoryGrams;

      // Set an initial consumption value (one serving or one package)
      final initialValue = _valuePerServing > 0
          ? _valuePerServing
          : _valuePerPackage;
      _updateAllInputsFromAmount(initialValue);
    });
  }

  // The new central update method, driven by the native amount.
  void _updateAllInputsFromAmount(
    double amount, {
    TextEditingController? skipController,
  }) {
    if (skipController != _amountController) {
      _amountController.text = amount.toStringAsFixed(1);
    }
    if (_valuePerPackage > 0 && skipController != _packageController) {
      _packageController.text = (amount / _valuePerPackage).toStringAsFixed(2);
    }
    if (_valuePerServing > 0 && skipController != _servingsController) {
      _servingsController.text = (amount / _valuePerServing).toStringAsFixed(1);
    }
  }

  void _onAmountChanged() {
    if (!_amountFocusNode.hasFocus) return;
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    _updateAllInputsFromAmount(amount, skipController: _amountController);
  }

  void _onPackageChanged() {
    if (!_packageFocusNode.hasFocus) return;
    final packages = double.tryParse(_packageController.text) ?? 0.0;
    final amount = packages * _valuePerPackage;
    _updateAllInputsFromAmount(amount, skipController: _packageController);
  }

  void _onServingsChanged() {
    if (!_servingsFocusNode.hasFocus) return;
    final servings = double.tryParse(_servingsController.text) ?? 0.0;
    final amount = servings * _valuePerServing;
    _updateAllInputsFromAmount(amount, skipController: _servingsController);
  }

  void _handleConsume() {
    final valueToConsume = double.tryParse(_amountController.text) ?? 0.0;
    if (valueToConsume <= 0 || _selectedItem == null) return;

    if (valueToConsume > _totalAvailableValue) {
      setState(() {
        _errorMessage =
            'Not enough in inventory. Only ${_totalAvailableValue.toStringAsFixed(1)} $_packageUnit available.';
      });
      return;
    }
    widget.onConsume(_selectedItem!, valueToConsume, _selectedMeal);
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
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              ),
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
                  setState(() => _selectedMeal = newSelection.first);
                },
              ),
              const SizedBox(height: 24),
              _buildInputRow(
                label: 'Amount ($_packageUnit)',
                controller: _amountController,
                focusNode: _amountFocusNode,
              ),
              const SizedBox(height: 16),
              _buildInputRow(
                label: 'Packages',
                controller: _packageController,
                focusNode: _packageFocusNode,
              ),
              if (_valuePerServing > 0) ...[
                const SizedBox(height: 16),
                _buildInputRow(
                  label: 'Servings',
                  controller: _servingsController,
                  focusNode: _servingsFocusNode,
                ),
              ],
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
        // Display available inventory in its native unit
        final availableValue = QuantityParser.fromGrams(
          item.inventoryGrams,
          QuantityParser.parse(item.packageSize).$2,
        );
        final unit = QuantityParser.parse(item.packageSize).$2;
        return DropdownMenuItem<FoodItem>(
          value: item,
          child: Text(
            '${item.name} (${availableValue.toStringAsFixed(1)} $unit)',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInputRow({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
