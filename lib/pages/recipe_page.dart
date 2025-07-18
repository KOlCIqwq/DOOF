import 'package:flutter/material.dart';
import '../models/consumption_log.dart';
import '../models/recipe_model.dart';
import '../services/themealdb_api_services.dart';
import '../services/spoonacular_api_service.dart';
import 'recipe_info.dart';

enum SearchState { initial, loading, success, noResults, error }

class RecipePage extends StatefulWidget {
  final Function(RecipeInfo recipe, MealType mealType) onRecipeConsumed;
  const RecipePage({super.key, required this.onRecipeConsumed});

  @override
  State<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  final TextEditingController _searchController = TextEditingController();
  List<RecipeSummary> _recipes = [];
  SearchState _searchState = SearchState.initial;
  bool _canLoadFromSpoonacular = false;
  bool _isLoadingMore = false;
  String _errorMessage = '';

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;
    setState(() {
      _searchState = SearchState.loading;
      _canLoadFromSpoonacular = false;
      _recipes = [];
    });

    try {
      // 1. Try TheMealDB first
      final mealDbResults = await TheMealDBApiService.searchRecipes(query);

      if (mealDbResults.isNotEmpty) {
        setState(() {
          _recipes = mealDbResults;
          _searchState = SearchState.success;
          _canLoadFromSpoonacular = true; // Allow loading more from Spoonacular
        });
        return;
      }

      // 2. If TheMealDB has no results, try Spoonacular
      final spoonacularResults = await SpoonacularApiService.searchRecipes(
        query,
      );

      if (spoonacularResults.isNotEmpty) {
        setState(() {
          _recipes = spoonacularResults;
          _searchState = SearchState.success;
          // No more to load after this
          _canLoadFromSpoonacular = false;
        });
      } else {
        // 3. If both APIs have no results
        setState(() {
          _searchState = SearchState.noResults;
        });
      }
    } catch (e) {
      setState(() {
        _searchState = SearchState.error;
        _errorMessage = 'Something went wrong. Please check your connection.';
      });
    }
  }

  Future<void> _loadMoreFromSpoonacular() async {
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final spoonacularResults = await SpoonacularApiService.searchRecipes(
        _searchController.text,
      );
      final existingIds = _recipes.map((r) => r.id).toSet();
      // Add only new recipes to avoid duplicates
      _recipes.addAll(
        spoonacularResults.where((r) => !existingIds.contains(r.id)),
      );

      setState(() {
        _canLoadFromSpoonacular = false; // Prevent further loading
        _isLoadingMore = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not load more results.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoadingMore = false;
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
    switch (_searchState) {
      case SearchState.loading:
        return const Center(child: CircularProgressIndicator());
      case SearchState.error:
        return _buildFriendlyMessage(
          Icons.error_outline,
          Colors.red,
          _errorMessage,
        );
      case SearchState.noResults:
        return _buildFriendlyMessage(
          Icons.search_off,
          Colors.grey,
          'No recipes found.\nTry a different search term.',
        );
      case SearchState.initial:
        return _buildFriendlyMessage(
          Icons.menu_book,
          Colors.grey,
          'Search for recipes to get started!',
        );
      case SearchState.success:
        return ListView.builder(
          itemCount: _recipes.length + (_canLoadFromSpoonacular ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _recipes.length && _canLoadFromSpoonacular) {
              return _buildLoadMoreButton();
            }
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
                      builder: (context) =>
                          RecipeInfoPage(recipeSummary: recipe),
                    ),
                  );
                  if (result != null &&
                      result['recipe'] != null &&
                      result['mealType'] != null) {
                    widget.onRecipeConsumed(
                      result['recipe'],
                      result['mealType'],
                    );
                  }
                },
              ),
            );
          },
        );
    }
  }

  Widget _buildFriendlyMessage(IconData icon, Color color, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: color),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: _isLoadingMore
          ? const Center(child: CircularProgressIndicator())
          : OutlinedButton.icon(
              onPressed: _loadMoreFromSpoonacular,
              icon: const Icon(Icons.add),
              label: const Text('Load More from Spoonacular'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
    );
  }
}
