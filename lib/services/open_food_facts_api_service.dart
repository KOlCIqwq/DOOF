import 'package:openfoodfacts/openfoodfacts.dart';
import '../models/food_item.dart';
import '../utils/quantity_parser.dart';

class OpenFoodFactsApiService {
  static Future<FoodItem?> fetchFoodItem(String barcode) async {
    try {
      final ProductQueryConfiguration configuration = ProductQueryConfiguration(
        barcode,
        language: OpenFoodFactsLanguage.ENGLISH,
        fields: [ProductField.ALL],
        version: ProductQueryVersion.v3,
      );
      final ProductResultV3 result = await OpenFoodAPIClient.getProductV3(
        configuration,
      );

      if (result.status == ProductResultV3.statusSuccess &&
          result.product != null) {
        final product = result.product!;
        final nutrimentsJson = product.nutriments?.toJson() ?? {};

        final packageSize = product.quantity?.isNotEmpty == true
            ? product.quantity!
            : '100 g';
        final initialGrams = QuantityParser.toGrams(
          QuantityParser.parse(packageSize),
        );

        return FoodItem(
          barcode: barcode,
          name: product.productName ?? 'N/A',
          brand: product.brands ?? 'N/A',
          imageUrl: product.imageFrontUrl ?? '',
          insertDate: DateTime.now(),
          packageSize: packageSize,
          inventoryGrams: initialGrams > 0 ? initialGrams : 100.0,
          nutriments: nutrimentsJson,
          fat: (nutrimentsJson['fat_100g'] as num?)?.toDouble() ?? 0.0,
          carbs:
              (nutrimentsJson['carbohydrates_100g'] as num?)?.toDouble() ?? 0.0,
          protein: (nutrimentsJson['proteins_100g'] as num?)?.toDouble() ?? 0.0,
          isKnown: true,
        );
      }
    } catch (e) {
      print('Error fetching product from OFF: $e');
    }
    return null;
  }
}
