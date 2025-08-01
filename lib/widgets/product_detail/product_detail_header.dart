import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/food_item.dart';
import '../../utils/quantity_parser.dart';

// Displays the main product information and editable fields.
class ProductDetailHeader extends StatelessWidget {
  final FoodItem product;
  final TextEditingController remainingGramsController;
  final VoidCallback onAdjustPackageSize;
  final VoidCallback onUpdateRemainingGrams;

  const ProductDetailHeader({
    super.key,
    required this.product,
    required this.remainingGramsController,
    required this.onAdjustPackageSize,
    required this.onUpdateRemainingGrams,
  });

  @override
  Widget build(BuildContext context) {
    final (_, unit) = QuantityParser.parse(product.packageSize);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
              IconButton(
                onPressed: onAdjustPackageSize,
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: Colors.grey,
                ),
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
