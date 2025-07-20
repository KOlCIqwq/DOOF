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

  static Future<List<FoodItem>> searchProductsByName(String query) async {
    final ProductSearchQueryConfiguration configuration =
        ProductSearchQueryConfiguration(
          parametersList: [
            SearchTerms(terms: [query]),
            PageSize(size: 20),
          ],
          fields: [ProductField.ALL],
          language: OpenFoodFactsLanguage.ENGLISH,
          version: ProductQueryVersion.v3,
        );

    final SearchResult result = await OpenFoodAPIClient.searchProducts(
      null,
      configuration,
    );

    if (result.products != null) {
      return result.products!
          .where(
            (product) =>
                product.productName != null && product.productName!.isNotEmpty,
          )
          .map((product) {
            final nutrimentsJson = product.nutriments?.toJson() ?? {};
            final packageSize = product.quantity?.isNotEmpty == true
                ? product.quantity!
                : '100 g';
            final initialGrams = QuantityParser.toGrams(
              QuantityParser.parse(packageSize),
            );

            return FoodItem(
              barcode: product.barcode ?? 'no-barcode-${product.productName!}',
              name: product.productName!,
              brand: product.brands ?? 'N/A',
              imageUrl: product.imageFrontUrl ?? '',
              insertDate: DateTime.now(),
              packageSize: packageSize,
              inventoryGrams: initialGrams > 0 ? initialGrams : 100.0,
              nutriments: nutrimentsJson,
              fat: (nutrimentsJson['fat_100g'] as num?)?.toDouble() ?? 0.0,
              carbs:
                  (nutrimentsJson['carbohydrates_100g'] as num?)?.toDouble() ??
                  0.0,
              protein:
                  (nutrimentsJson['proteins_100g'] as num?)?.toDouble() ?? 0.0,
              isKnown: true,
            );
          })
          .toList();
    }

    return [];
  }
}
