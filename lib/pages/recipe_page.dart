import 'package:flutter/material.dart';
import '../models/consumption_log.dart';
import '../models/recipe_model.dart';
import '../services/themealdb_api_services.dart';
import '../services/spoonacular_api_service.dart';
import 'recipe_info.dart';

class RecipePage extends StatefulWidget {
  final Function(RecipeInfo recipe, MealType mealType) onRecipeConsumed;
  const RecipePage({super.key, required this.onRecipeConsumed});

  @override
  State<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  final TextEditingController _searchController = TextEditingController();
  List<RecipeSummary> _recipes = [];
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Try TheMealDB first
      List<RecipeSummary> results = await TheMealDBApiService.searchRecipes(
        query,
      );

      // 2. If TheMealDB has no results, try Spoonacular
      if (results.isEmpty) {
        results = await SpoonacularApiService.searchRecipes(query);
      }

      setState(() {
        _recipes = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load recipes. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Find a Recipe',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'e.g., "chicken pasta"',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _performSearch(_searchController.text),
                ),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: _performSearch,
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
      );
    }
    if (_recipes.isEmpty) {
      return const Center(child: Text('Search for recipes to get started!'));
    }
    return ListView.builder(
      itemCount: _recipes.length,
      itemBuilder: (context, index) {
        final recipe = _recipes[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                recipe.image,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(recipe.title),
            onTap: () async {
              final result = await Navigator.push<Map<String, dynamic>>(
                context,
                MaterialPageRoute(
                  builder: (context) => RecipeInfoPage(recipeSummary: recipe),
                ),
              );
              if (result != null &&
                  result['recipe'] != null &&
                  result['mealType'] != null) {
                widget.onRecipeConsumed(result['recipe'], result['mealType']);
              }
            },
          ),
        );
      },
    );
  }
}
