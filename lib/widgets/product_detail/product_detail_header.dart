import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/food_item.dart';
import '../../utils/quantity_parser.dart';

// Displays the main product information and editable fields.
class ProductDetailHeader extends StatelessWidget {
  final FoodItem product;
  final TextEditingController remainingGramsController;
  final VoidCallback onUpdateRemainingGrams;
  final VoidCallback openEditForm;

  const ProductDetailHeader({
    super.key,
    required this.product,
    required this.remainingGramsController,
    required this.onUpdateRemainingGrams,
    required this.openEditForm,
  });

  @override
  Widget build(BuildContext context) {
    final (_, unit) = QuantityParser.parse(product.packageSize);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                // Use Flexible so long text wraps instead of overflowing
                child: Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Edit Details',
                onPressed: openEditForm,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          const SizedBox(height: 4),
          if (product.brand.isNotEmpty && product.brand != 'N/A')
            Text(
              'Brand: ${product.brand}',
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
          const SizedBox(height: 8),
          if (product.categories.isNotEmpty) ...[
            Text(
              'Category: ${product.categories}',
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 8),
          ],
          if (product.expirationDate != null) ...[
            Text(
              'Expires On: ${DateFormat.yMd().format(product.expirationDate!)}',
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
                product.packageSize,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
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
                  controller: remainingGramsController,
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
                onPressed: onUpdateRemainingGrams,
                icon: const Icon(
                  Icons.check_circle_outline,
                  size: 20,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
