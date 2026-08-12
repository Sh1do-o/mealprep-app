import 'package:flutter/material.dart';
import '../logic/recipe_matcher.dart';
import 'recipe_detail_screen.dart';

class ResultsScreen extends StatelessWidget {
  final List<String> selectedIngredients;
  final Set<String> ownedEquipment;
  final double budget;
  final Set<String> dietaryPreferences;

  const ResultsScreen({
    super.key,
    required this.selectedIngredients,
    required this.ownedEquipment,
    required this.budget,
    this.dietaryPreferences = const {},
  });

  @override
  Widget build(BuildContext context) {
    final matches = getRecommendations(
      ownedIngredients: selectedIngredients,
      ownedEquipment: ownedEquipment,
      budget: budget,
      dietaryPreferences: dietaryPreferences,
    );

    final cookableCount = matches.where((m) => m.isCookable).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          cookableCount > 0
              ? '$cookableCount Cookable Meal${cookableCount > 1 ? 's' : ''}'
              : 'Meal Recommendations',
        ),
      ),
      body: matches.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final match = matches[index];
                final recipe = match.recipe;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  // Recipes you can't actually cook right now (missing
                  // equipment or over budget) are visually dimmed rather
                  // than hidden - still useful to know they exist.
                  color: match.isCookable
                      ? null
                      : Theme.of(context)
                          .colorScheme
                          .surface
                          .withValues(alpha: 0.5),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    title: Text(
                      recipe.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: match.isCookable ? null : Colors.grey[700],
                      ),
                    ),
                    subtitle: Text(_subtitleFor(match)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RecipeDetailScreen(
                            recipe: recipe,
                            ownedIngredients: selectedIngredients,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No matching recipes found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'We couldn\'t find any meals that match your current equipment, budget, and dietary preferences.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.arrow_back),
              label: const Text('Adjust selected ingredients'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  String _subtitleFor(RecipeMatch match) {
    final recipe = match.recipe;
    final base =
        '${recipe.prepTime} • ₱${recipe.estimatedCost.toStringAsFixed(0)} • '
        '${match.missingIngredients.isEmpty ? "All ingredients ready!" : "${match.missingIngredients.length} ingredient(s) missing"}';

    if (!match.hasRequiredEquipment) {
      return '$base • Needs: ${recipe.equipmentNeeded.join(", ")}';
    }
    if (!match.withinBudget) {
      return '$base • Over budget';
    }
    if (!match.matchesDietaryPreferences) {
      return '$base • Doesn\'t match your dietary preferences';
    }
    return base;
  }
}