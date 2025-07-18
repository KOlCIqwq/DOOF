import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recipe_model.dart';
import '../secrets.dart';

class SpoonacularApiService {
  static const String _baseUrl = 'api.spoonacular.com';
  static const String _apiKey = apiKey;

  static Future<List<RecipeSummary>> searchRecipes(String query) async {
    final uri = Uri.https(_baseUrl, '/recipes/complexSearch', {
      'query': query,
      'addRecipeInformation': 'true',
      'addRecipeNutrition': 'true',
      'number': '20',
    });

    final response = await http.get(uri, headers: {'x-api-key': _apiKey});

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List;
      return results.map((e) => RecipeSummary.fromSpoonacularJson(e)).toList();
    } else {
      throw Exception('Failed to load recipes from Spoonacular');
    }
  }

  static Future<RecipeInfo> getRecipeDetails(int id) async {
    final uri = Uri.https(_baseUrl, '/recipes/$id/information', {
      'includeNutrition': 'true',
    });

    final response = await http.get(uri, headers: {'x-api-key': _apiKey});

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return RecipeInfo.fromSpoonacularJson(data);
    } else {
      throw Exception('Failed to load recipe information from Spoonacular');
    }
  }
}
