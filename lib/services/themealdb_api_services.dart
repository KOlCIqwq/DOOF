import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recipe_model.dart';

class TheMealDBApiService {
  static const String _baseUrl = 'www.themealdb.com';

  static Future<List<RecipeSummary>> searchRecipes(String query) async {
    final uri = Uri.https(_baseUrl, '/api/json/v1/1/search.php', {'s': query});
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['meals'] == null) {
        return [];
      }
      final results = data['meals'] as List;
      return results.map((e) => RecipeSummary.fromTheMealDBJson(e)).toList();
    } else {
      throw Exception('Failed to load recipes from TheMealDB');
    }
  }

  static Future<RecipeInfo> getRecipeDetails(String id) async {
    final uri = Uri.https(_baseUrl, '/api/json/v1/1/lookup.php', {'i': id});
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['meals'] != null && (data['meals'] as List).isNotEmpty) {
        return RecipeInfo.fromTheMealDBJson(data['meals'][0]);
      }
    }
    throw Exception('Failed to load recipe details from TheMealDB');
  }
}
