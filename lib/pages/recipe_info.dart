import 'package:flutter/material.dart';
import '../models/consumption_log.dart';
import '../models/recipe_model.dart';
import '../services/themealdb_api_services.dart';
import '../services/spoonacular_api_service.dart';

class RecipeInfoPage extends StatefulWidget {
  final RecipeSummary recipeSummary;
  const RecipeInfoPage({super.key, required this.recipeSummary});

  @override
  State<RecipeInfoPage> createState() => _RecipeInfoPageState();
}

class _RecipeInfoPageState extends State<RecipeInfoPage> {
  RecipeInfo? _recipe;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRecipeDetails();
  }

  Future<void> _fetchRecipeDetails() async {
    try {
      RecipeInfo recipe;
      if (widget.recipeSummary.source == RecipeSource.spoonacular) {
        recipe = await SpoonacularApiService.getRecipeDetails(
          int.parse(widget.recipeSummary.id),
        );
      } else {
        recipe = await TheMealDBApiService.getRecipeDetails(
          widget.recipeSummary.id,
        );
      }
      setState(() {
        _recipe = recipe;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load recipe details.';
        _isLoading = false;
      });
    }
  }

  void _consumeRecipe() async {
    final mealType = await showDialog<MealType>(
      context: context,
      builder: (context) => const ChooseMealDialog(),
    );

    if (mealType != null && _recipe != null && mounted) {
      Navigator.pop(context, {'recipe': _recipe, 'mealType': mealType});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _recipe != null
          ? FloatingActionButton.extended(
              onPressed: _consumeRecipe,
              label: const Text('Consume Recipe'),
              icon: const Icon(Icons.restaurant),
            )
          : null,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220.0,
            pinned: true,
            title: Text(
              _isLoading ? 'Loading...' : widget.recipeSummary.title,
              overflow: TextOverflow.fade,
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                widget.recipeSummary.image,
                fit: BoxFit.cover,
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_errorMessage != null)
            SliverFillRemaining(child: Center(child: Text(_errorMessage!)))
          else if (_recipe != null)
            SliverList(delegate: SliverChildListDelegate(_buildDetailsList())),
        ],
      ),
    );
  }

  List<Widget> _buildDetailsList() {
    final recipe = _recipe!;
    final calories = recipe.nutrients['Calories'] ?? 0;
    final carbs = recipe.nutrients['Carbohydrates'] ?? 0;
    final protein = recipe.nutrients['Protein'] ?? 0;
    final fat = recipe.nutrients['Fat'] ?? 0;

    return [
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          recipe.title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      if (recipe.totalGrams > 0)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Estimated Weight: ${recipe.totalGrams.round()}g',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      if (calories > 0)
        _buildMacroSummaryCard(
          calories: calories.round(),
          carbs: carbs,
          protein: protein,
          fat: fat,
        ),
      _buildSectionHeader('Ingredients'),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: recipe.ingredients.map((i) => Text('- $i')).toList(),
        ),
      ),
      _buildSectionHeader('Instructions'),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: recipe.instructions
              .replaceAll(RegExp(r'<[^>]*>'), '')
              .split('.')
              .where((s) => s.trim().isNotEmpty)
              .map(
                (s) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text('${s.trim()}.')),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
      const SizedBox(height: 100), // Padding for FAB
    ];
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildMacroSummaryCard({
    required int calories,
    required double carbs,
    required double protein,
    required double fat,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _nutritionColumn(calories.toString(), 'Calories', Colors.orange),
              _nutritionColumn(
                carbs.toStringAsFixed(1),
                'Carbs (g)',
                Colors.blue,
              ),
              _nutritionColumn(
                protein.toStringAsFixed(1),
                'Protein (g)',
                Colors.red,
              ),
              _nutritionColumn(
                fat.toStringAsFixed(1),
                'Fat (g)',
                Colors.purple,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nutritionColumn(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }
}

class ChooseMealDialog extends StatelessWidget {
  const ChooseMealDialog({super.key});
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add to Meal'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: MealType.values.map((meal) {
          return ListTile(
            title: Text(meal.name[0].toUpperCase() + meal.name.substring(1)),
            onTap: () => Navigator.pop(context, meal),
          );
        }).toList(),
      ),
    );
  }
}
