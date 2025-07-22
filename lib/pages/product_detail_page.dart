import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/food_item.dart';
import '../utils/nutrient_helper.dart';
import '../utils/quantity_parser.dart';
import '../widgets/adjust_package_size_dialog.dart';

class ProductDetailPage extends StatefulWidget {
  final FoodItem product;
  final bool showAddButton;

  const ProductDetailPage({
    super.key,
    required this.product,
    this.showAddButton = false,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _selectedQuantity = 1;
  List<String> _availableModes = [];
  String? _currentMode;
  late TextEditingController _remainingGramsController;

  @override
  void initState() {
    super.initState();
    _initializeModes();
    _remainingGramsController = TextEditingController(
      text: widget.product.inventoryGrams.round().toString(),
    );
  }

  @override
  void dispose() {
    _remainingGramsController.dispose();
    super.dispose();
  }

  void _initializeModes() {
    if (widget.product.nutriments.isEmpty) return;
    final modes = <String>{};
    for (var key in widget.product.nutriments.keys) {
      final parts = key.split('_');
      if (parts.length > 1) {
        modes.add(parts.sublist(1).join('_'));
      }
    }
    if (modes.isEmpty) return;
    _availableModes = modes.toList();
    _availableModes.sort((a, b) {
      if (a.contains('100g')) return -1;
      if (b.contains('100g')) return 1;
      return a.compareTo(b);
    });
    setState(() {
      _currentMode = _availableModes.first;
    });
  }

  Future<void> _adjustPackageSize() async {
    final newSize = await showDialog<String>(
      context: context,
      builder: (_) =>
          AdjustPackageSizeDialog(initialValue: widget.product.packageSize),
    );
    if (newSize != null && newSize.isNotEmpty && mounted) {
      final newGramsPerUnit = QuantityParser.toGrams(
        QuantityParser.parse(newSize),
      );
      final updatedItem = widget.product.copyWith(
        packageSize: newSize,
        inventoryGrams: newGramsPerUnit,
      );
      Navigator.pop(context, {'type': 'update', 'item': updatedItem});
    }
  }

  void _updateRemainingGrams() {
    final newGrams = double.tryParse(_remainingGramsController.text);
    if (newGrams != null && newGrams != widget.product.inventoryGrams) {
      final updatedItem = widget.product.copyWith(inventoryGrams: newGrams);
      Navigator.pop(context, {'type': 'update', 'item': updatedItem});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Remaining amount updated!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Map<String, String> _getNutrientsForCurrentMode() {
    if (_currentMode == null) return {};
    final Map<String, String> filteredNutrients = {};
    widget.product.nutriments.forEach((key, value) {
      if (key.endsWith('$_currentMode')) {
        final baseKey = key.substring(0, key.length - _currentMode!.length - 1);
        if (value != null) {
          filteredNutrients[baseKey] = value.toString();
        }
      }
    });
    return filteredNutrients;
  }

  void _switchMode() {
    if (_availableModes.length <= 1) return;
    final currentIndex = _availableModes.indexOf(_currentMode!);
    final nextIndex = (currentIndex + 1) % _availableModes.length;
    setState(() {
      _currentMode = _availableModes[nextIndex];
    });
  }

  String _formatModeName(String mode) {
    final cleanMode = mode.replaceAll('_', ' ').replaceAll('100g', '100 g');
    return 'Per $cleanMode';
  }

  @override
  Widget build(BuildContext context) {
    final currentNutrients = _getNutrientsForCurrentMode();
    final nutrientLists = NutrientHelper.getNutrientLists(currentNutrients);
    final calories = num.tryParse(currentNutrients['energy-kcal'] ?? '0') ?? 0;
    final carbs = num.tryParse(currentNutrients['carbohydrates'] ?? '0') ?? 0.0;
    final protein = num.tryParse(currentNutrients['proteins'] ?? '0') ?? 0.0;
    final fat = num.tryParse(currentNutrients['fat'] ?? '0') ?? 0.0;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverList(
            delegate: SliverChildListDelegate([
              _buildHeader(),
              if (widget.product.isKnown) ...[
                _buildModeSwitcher(),
                _buildMacroSummaryCard(
                  calories: calories.round(),
                  carbs: carbs.toDouble(),
                  protein: protein.toDouble(),
                  fat: fat.toDouble(),
                ),
                _buildKeyNutrientsList(nutrientLists.keyNutrients),
                if (nutrientLists.otherNutrients.isNotEmpty)
                  _buildOtherNutrientsExpansionTile(
                    nutrientLists.otherNutrients,
                  ),
              ] else ...[
                _buildUnknownProductView(context),
              ],
            ]),
          ),
        ],
      ),
      bottomNavigationBar: widget.showAddButton && widget.product.isKnown
          ? _buildBottomAddToCartButton(context)
          : null,
    );
  }

  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 220.0,
      pinned: true,
      elevation: 1,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: '${widget.product.barcode}-${widget.product.packageSize}',
          child: Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.all(16.0),
            child: widget.product.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: widget.product.imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2.0),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.fastfood,
                      size: 80,
                      color: Colors.grey,
                    ),
                  )
                : const Icon(
                    Icons.image_not_supported,
                    size: 80,
                    color: Colors.grey,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final (_, unit) = QuantityParser.parse(widget.product.packageSize);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.product.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          if (widget.product.brand.isNotEmpty && widget.product.brand != 'N/A')
            Text(
              'Brand: ${widget.product.brand}',
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
          const SizedBox(height: 8),
          if (widget.product.categories.isNotEmpty) ...[
            Text(
              'Category: ${widget.product.categories}',
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 8),
          ],
          if (widget.product.expirationDate != null) ...[
            Text(
              'Expires On: ${DateFormat.yMd().format(widget.product.expirationDate!)}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.redAccent,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              const Text(
                'Package Size: ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                widget.product.packageSize,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              IconButton(
                onPressed: _adjustPackageSize,
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: Colors.grey,
                ),
                tooltip: 'Adjust Package Size',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          Row(
            children: [
              const Text(
                'Remaining: ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _remainingGramsController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: InputDecoration(
                    suffixText: unit.isNotEmpty ? ' $unit' : ' g',
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                onPressed: _updateRemainingGrams,
                icon: const Icon(
                  Icons.check_circle_outline,
                  size: 20,
                  color: Colors.green,
                ),
                tooltip: 'Update Remaining Amount',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeSwitcher() {
    if (_availableModes.length <= 1 || _currentMode == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          InkWell(
            onTap: _switchMode,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.swap_horiz, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: const Offset(0.0, 0.5),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutCubic,
                                ),
                              ),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      _formatModeName(_currentMode!),
                      key: ValueKey<String>(_currentMode!),
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroSummaryCard({
    required int calories,
    required double carbs,
    required double protein,
    required double fat,
  }) {
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

  Widget _buildKeyNutrientsList(List<MapEntry<String, String>> nutrients) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (nutrients.isNotEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                'Key Nutrition Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ...nutrients.map((entry) {
            final info = NutrientHelper.getInfo(entry.key);
            final value = NutrientHelper.formatValue(
              num.tryParse(entry.value),
              entry.key,
            );
            return ListTile(
              leading: Icon(info.icon, color: info.color),
              title: Text(
                info.name,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              trailing: Text(value, style: const TextStyle(fontSize: 15)),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildOtherNutrientsExpansionTile(
    List<MapEntry<String, String>> nutrients,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ExpansionTile(
        title: const Text(
          'Other Nutrients',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        children: nutrients.map((entry) {
          final info = NutrientHelper.getInfo(entry.key);
          final value = NutrientHelper.formatValue(
            num.tryParse(entry.value),
            entry.key,
          );
          return ListTile(
            leading: const SizedBox(width: 40),
            title: Text(info.name),
            trailing: Text(
              value,
              style: const TextStyle(color: Colors.black54),
            ),
            dense: true,
          );
        }).toList(),
      ),
    );
  }

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

  Widget _buildUnknownProductView(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.help_outline, size: 60, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'Product Not Found',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'This barcode is not in our database. You can add it manually.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                final manualItem = FoodItem(
                  barcode: widget.product.barcode,
                  name: 'New Item',
                  brand: 'Unknown',
                  imageUrl: '',
                  insertDate: DateTime.now(),
                  fat: 0,
                  carbs: 0,
                  protein: 0,
                  nutriments: const {},
                  packageSize: '',
                  inventoryGrams: 100.0,
                  categories: '',
                  expirationDate: null,
                );
                Navigator.pop(context, manualItem);
              },
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Add Manually'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: _selectedQuantity > 1
                ? () => setState(() => _selectedQuantity--)
                : null,
            icon: const Icon(Icons.remove),
            style: IconButton.styleFrom(
              foregroundColor: _selectedQuantity > 1
                  ? Colors.green
                  : Colors.grey,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              '$_selectedQuantity',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _selectedQuantity++),
            icon: const Icon(Icons.add),
            style: IconButton.styleFrom(foregroundColor: Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAddToCartButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0).copyWith(bottom: 32, top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildQuantitySelector(),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                final gramsToAdd =
                    _selectedQuantity * widget.product.gramsPerUnit;
                final itemToAdd = widget.product.copyWith(
                  inventoryGrams: gramsToAdd,
                  insertDate: DateTime.now(),
                );
                Navigator.pop(context, itemToAdd);
              },
              icon: const Icon(Icons.add_shopping_cart),
              label: Text(
                _selectedQuantity == 1
                    ? 'Add to Inventory'
                    : 'Add $_selectedQuantity to Inventory',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
