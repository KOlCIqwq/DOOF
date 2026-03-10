import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../utils/quantity_parser.dart';

class CustomProductPage extends StatefulWidget {
  final FoodItem? initialItem; // Pass an item if editing, null if creating new

  const CustomProductPage({super.key, this.initialItem});

  @override
  State<CustomProductPage> createState() => _CustomProductPageState();
}

class _CustomProductPageState extends State<CustomProductPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _packageSizeController;
  late TextEditingController _caloriesController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;

  final Map<String, TextEditingController> _extraNutrientControllers = {};
  final Map<String, String> _supportedExtraNutrients = {
    'sugars': 'Sugars (g)',
    'saturated-fat': 'Sat. Fat (g)',
    'fiber': 'Fiber (g)',
    'sodium': 'Sodium (g)',
    'calcium': 'Calcium (mg)',
    'iron': 'Iron (mg)',
  };

  bool _isPerPackage = false;

  double get _parsedPackageGrams {
    final parsed = QuantityParser.parse(_packageSizeController.text);
    final grams = QuantityParser.toGrams(parsed);
    return grams > 0
        ? grams
        : 100.0; // Fallback to 100g to avoid divide-by-zero
  }

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;

    // Initialize controllers with existing data or defaults
    _nameController = TextEditingController(text: item?.name ?? '');
    _brandController = TextEditingController(text: item?.brand ?? '');
    _packageSizeController = TextEditingController(
      text: item?.packageSize ?? '100 g',
    );

    // Extract macros from nutriments or direct fields
    final cals = item?.nutriments['energy-kcal_100g']?.toString() ?? '0';
    _caloriesController = TextEditingController(text: cals == '0' ? '' : cals);
    _proteinController = TextEditingController(
      text: (item?.protein ?? 0) > 0 ? item!.protein.toString() : '',
    );
    _carbsController = TextEditingController(
      text: (item?.carbs ?? 0) > 0 ? item!.carbs.toString() : '',
    );
    _fatController = TextEditingController(
      text: (item?.fat ?? 0) > 0 ? item!.fat.toString() : '',
    );
    _supportedExtraNutrients.forEach((key, label) {
      final value = item?.nutriments['${key}_100g']?.toString();
      _extraNutrientControllers[key] = TextEditingController(
        text: (value != null && value != '0' && value != '0.0') ? value : '',
      );
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _packageSizeController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    for (var controller in _extraNutrientControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _saveItem() {
    if (_formKey.currentState!.validate()) {
      final multiplierTo100g = _isPerPackage
          ? (100.0 / _parsedPackageGrams)
          : 1.0;

      final protein =
          (double.tryParse(_proteinController.text) ?? 0.0) * multiplierTo100g;
      final carbs =
          (double.tryParse(_carbsController.text) ?? 0.0) * multiplierTo100g;
      final fat =
          (double.tryParse(_fatController.text) ?? 0.0) * multiplierTo100g;
      final calories =
          (double.tryParse(_caloriesController.text) ?? 0.0) * multiplierTo100g;

      final Map<String, dynamic> customNutriments = Map<String, dynamic>.from(
        widget.initialItem?.nutriments ?? {},
      );
      customNutriments['energy-kcal_100g'] = calories;
      customNutriments['proteins_100g'] = protein;
      customNutriments['carbohydrates_100g'] = carbs;
      customNutriments['fat_100g'] = fat;

      _extraNutrientControllers.forEach((nutrientKey, controller) {
        final val = double.tryParse(controller.text);
        if (val != null) {
          customNutriments['${nutrientKey}_100g'] = val * multiplierTo100g;
        } else {
          customNutriments.remove('${nutrientKey}_100g');
        }
      });
      // Create or update the FoodItem
      final newItem = FoodItem(
        barcode:
            widget.initialItem?.barcode ??
            'custom_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        brand: _brandController.text.trim().isEmpty
            ? 'Custom'
            : _brandController.text.trim(),
        imageUrl: widget.initialItem?.imageUrl ?? '',
        insertDate: widget.initialItem?.insertDate ?? DateTime.now(),
        expirationDate: widget.initialItem?.expirationDate,
        categories: widget.initialItem?.categories ?? 'Custom',
        nutriments: customNutriments, // Pass the dynamically built map
        fat: fat,
        carbs: carbs,
        protein: protein,
        packageSize: _packageSizeController.text.trim(),
        inventoryGrams: _parsedPackageGrams,
        isKnown: true,
      );

      // Return the item to the previous screen
      Navigator.pop(context, newItem);
    }
  }

  void _toggleInputMode(bool toPerPackage) {
    if (_isPerPackage == toPerPackage) return;

    // Calculate the conversion multiplier
    final multiplier = toPerPackage
        ? (_parsedPackageGrams / 100.0)
        : (100.0 / _parsedPackageGrams);

    void convertController(TextEditingController ctrl) {
      final val = double.tryParse(ctrl.text);
      if (val != null) {
        ctrl.text = (val * multiplier)
            .toStringAsFixed(1)
            .replaceAll(RegExp(r'\.0$'), '');
      }
    }

    convertController(_caloriesController);
    convertController(_proteinController);
    convertController(_carbsController);
    convertController(_fatController);
    for (var ctrl in _extraNutrientControllers.values) {
      convertController(ctrl);
    }
    setState(() {
      _isPerPackage = toPerPackage;
    });
  }

  List<Widget> _buildExtraNutrientFields() {
    List<Widget> rows = [];
    final keys = _supportedExtraNutrients.keys.toList();

    for (int i = 0; i < keys.length; i += 2) {
      final key1 = keys[i];
      final key2 = (i + 1 < keys.length) ? keys[i + 1] : null;

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _extraNutrientControllers[key1],
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: _supportedExtraNutrients[key1],
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: key2 != null
                    ? TextFormField(
                        controller: _extraNutrientControllers[key2],
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: _supportedExtraNutrients[key2],
                          border: const OutlineInputBorder(),
                        ),
                      )
                    : const SizedBox.shrink(), // Empty space if there's an odd number of fields
              ),
            ],
          ),
        ),
      );
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialItem != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Custom Food' : 'Create Custom Food'),
        actions: [
          /* IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveItem,
            tooltip: 'Save',
          ), */
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const Text(
              'Basic Info',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Product Name',
                border: OutlineInputBorder(),
              ),
              validator: (val) =>
                  val == null || val.isEmpty ? 'Please enter a name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _brandController,
              decoration: const InputDecoration(
                labelText: 'Brand (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _packageSizeController,
              decoration: const InputDecoration(
                labelText: 'Package Size (e.g., 100 g, 1 L)',
                border: OutlineInputBorder(),
              ),
              validator: (val) =>
                  val == null || val.isEmpty ? 'Required' : null,
            ),

            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Primary Macros',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Segmented toggle button
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Per 100g')),
                    ButtonSegment(value: true, label: Text('Per Pkg')),
                  ],
                  selected: {_isPerPackage},
                  onSelectionChanged: (Set<bool> newSelection) {
                    _toggleInputMode(newSelection.first);
                  },
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Text(
              _isPerPackage
                  ? 'Values for $_parsedPackageGrams g'
                  : 'Values for 100 g',
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _caloriesController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Calories (kcal)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _proteinController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Protein (g)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _carbsController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Carbs (g)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _fatController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Fat (g)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              _isPerPackage
                  ? 'Other Nutrients (per Package)'
                  : 'Other Nutrients (per 100g)',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._buildExtraNutrientFields(),

            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _saveItem,
              child: const Text(
                'Save Food Item',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
