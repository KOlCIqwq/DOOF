import '../utils/unit_converter.dart';

enum RecipeSource { spoonacular, theMealDB }

class RecipeSummary {
  final String id;
  final String title;
  final String image;
  final RecipeSource source;

  RecipeSummary({
    required this.id,
    required this.title,
    required this.image,
    required this.source,
  });

  factory RecipeSummary.fromSpoonacularJson(Map<String, dynamic> json) {
    return RecipeSummary(
      id: (json['id'] as int).toString(),
      title: json['title'] as String,
      image: json['image'] as String,
      source: RecipeSource.spoonacular,
    );
  }

  factory RecipeSummary.fromTheMealDBJson(Map<String, dynamic> json) {
    return RecipeSummary(
      id: json['idMeal'] as String,
      title: json['strMeal'] as String,
      image: json['strMealThumb'] as String,
      source: RecipeSource.theMealDB,
    );
  }
}

class RecipeInfo extends RecipeSummary {
  final int servings;
  final int readyInMinutes;
  final List<String> ingredients;
  final String instructions;
  final Map<String, double> nutrients;
  final double totalGrams;

  RecipeInfo({
    required super.id,
    required super.title,
    required super.image,
    required super.source,
    required this.servings,
    required this.readyInMinutes,
    required this.ingredients,
    required this.instructions,
    required this.nutrients,
    required this.totalGrams,
  });

  factory RecipeInfo.fromSpoonacularJson(Map<String, dynamic> json) {
    final ingredientsList = (json['extendedIngredients'] as List? ?? [])
        .map((i) => i['original'] as String)
        .toList();

    double calculatedGrams = 0;
    for (final ingredient in ingredientsList) {
      calculatedGrams += UnitConverter.parse(ingredient);
    }

    final Map<String, double> nutrientsMap = {};
    if (json['nutrition'] != null && json['nutrition']['nutrients'] != null) {
      for (final n in json['nutrition']['nutrients']) {
        nutrientsMap[n['name']] = (n['amount'] as num).toDouble();
      }
    }

    return RecipeInfo(
      id: (json['id'] as int).toString(),
      title: json['title'],
      image: json['image'],
      source: RecipeSource.spoonacular,
      servings: json['servings'] ?? 1,
      readyInMinutes: json['readyInMinutes'] ?? 0,
      ingredients: ingredientsList,
      instructions: json['instructions'] ?? 'No instructions provided.',
      nutrients: nutrientsMap,
      totalGrams: calculatedGrams > 0
          ? calculatedGrams
          : 350.0, // Default weight
    );
  }

  factory RecipeInfo.fromTheMealDBJson(Map<String, dynamic> json) {
    final List<String> ingredientsList = [];
    double calculatedGrams = 0;
    for (int i = 1; i <= 20; i++) {
      final ingredient = json['strIngredient$i'];
      final measure = json['strMeasure$i'];
      if (ingredient != null && ingredient.isNotEmpty) {
        final ingredientString = '$measure $ingredient';
        ingredientsList.add(ingredientString);
        calculatedGrams += UnitConverter.parse(ingredientString);
      }
    }

    return RecipeInfo(
      id: json['idMeal'],
      title: json['strMeal'],
      image: json['strMealThumb'],
      source: RecipeSource.theMealDB,
      servings: 1, // TheMealDB does not provide serving info
      readyInMinutes: 0,
      ingredients: ingredientsList,
      instructions: json['strInstructions'] ?? 'No instructions provided.',
      nutrients: {}, // TheMealDB does not provide nutrition data
      totalGrams: calculatedGrams > 0 ? calculatedGrams : 350.0,
    );
  }
}
