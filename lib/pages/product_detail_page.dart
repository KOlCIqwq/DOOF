import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../utils/nutrient_helper.dart';
import '../widgets/product_detail/product_detail_header.dart';
import '../widgets/product_detail/product_summary.dart';
import 'product_detail_controller.dart';

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
  late final ProductDetailController _controller;
  int _selectedQuantity = 1;

  @override
  void initState() {
    super.initState();
    _controller = ProductDetailController(
      initialProduct: widget.product,
      onStateUpdate: () => setState(() {}),
    );
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleAdjustPackageSize() async {
    await _controller.adjustPackageSize(context);
  }

  void _handleUpdateRemainingGrams() {
    _controller.updateRemainingGrams();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Remaining amount updated!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = _controller.product;
    final currentNutrients = NutrienHelper.getNutrientsForMode(
      product.nutriments,
      _controller.currentMode,
    );
    final nutrientLists = NutrientHelper.getNutrientLists(currentNutrients);

    return PopScope(
      canPop: false, // Prevents default back navigation.
      onPopInvoked: (didPop) {
        if (didPop) return;
        // When back is pressed, pop with the updated item if it exists.
        final result = _controller.finalProduct != null
            ? {'type': 'update', 'item': _controller.finalProduct}
            : null;
        Navigator.pop(context, result);
      },

      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            _buildSliverAppBar(product),
            SliverList(
              delegate: SliverChildListDelegate([
                ProductDetailHeader(
                  product: product,
                  remainingGramsController:
                      _controller.remainingGramsController,
                  onAdjustPackageSize: _handleAdjustPackageSize,
                  onUpdateRemainingGrams: _handleUpdateRemainingGrams,
                ),
                if (product.isKnown) ...[
                  _buildModeSwitcher(),
                  ProductMacroSummaryCard(
                    calories:
                        (num.tryParse(currentNutrients['energy-kcal'] ?? '0') ??
                                0)
                            .round(),
                    carbs:
                        (num.tryParse(
                                  currentNutrients['carbohydrates'] ?? '0',
                                ) ??
                                0.0)
                            .toDouble(),
                    protein:
                        (num.tryParse(currentNutrients['proteins'] ?? '0') ??
                                0.0)
                            .toDouble(),
                    fat: (num.tryParse(currentNutrients['fat'] ?? '0') ?? 0.0)
                        .toDouble(),
                  ),
                  _buildKeyNutrientsList(nutrientLists.keyNutrients),
                  if (nutrientLists.otherNutrients.isNotEmpty)
                    _buildOtherNutrientsExpansionTile(
                      nutrientLists.otherNutrients,
                    ),
                ] else
                  _buildUnknownProductView(context, product),
              ]),
            ),
          ],
        ),
        bottomNavigationBar: widget.showAddButton && product.isKnown
            ? _buildBottomAddToCartButton(context, product)
            : null,
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(FoodItem product) {
    return SliverAppBar(
      expandedHeight: 220.0,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: '${product.barcode}-${product.packageSize}',
          child: Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.all(16.0),
            child: product.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: product.imageUrl,
                    fit: BoxFit.contain,
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

  Widget _buildModeSwitcher() {
    if (_controller.availableModes.length <= 1 ||
        _controller.currentMode == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          InkWell(
            onTap: _controller.switchMode,
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
                  Text(
                    NutrienHelper.formatModeName(_controller.currentMode!),
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
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

  Widget _buildUnknownProductView(BuildContext context, FoodItem product) {
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
                  barcode: product.barcode,
                  name: 'New Item',
                  brand: 'Unknown',
                  imageUrl: '',
                  insertDate: DateTime.now(),
                  fat: 0,
                  carbs: 0,
                  protein: 0,
                  nutriments: const {},
                  packageSize: '100 g',
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

  Widget _buildBottomAddToCartButton(BuildContext context, FoodItem product) {
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
                final gramsToAdd = _selectedQuantity * product.gramsPerUnit;
                final itemToAdd = product.copyWith(
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

class NutrienHelper {
  static Map<String, String> getNutrientsForMode(
    Map<String, dynamic> nutriments,
    String? currentMode,
  ) {
    if (currentMode == null) return {};
    final Map<String, String> filteredNutrients = {};
    nutriments.forEach((key, value) {
      if (key.endsWith('_$currentMode')) {
        final baseKey = key.substring(0, key.length - currentMode.length - 1);
        if (value != null) {
          filteredNutrients[baseKey] = value.toString();
        }
      }
    });
    return filteredNutrients;
  }

  static String formatModeName(String mode) {
    return 'Per ${mode.replaceAll('_', ' ').replaceAll('100g', '100 g')}';
  }
}
