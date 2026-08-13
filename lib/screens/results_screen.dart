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
    if (selectedIngredients.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Meal Recommendations',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: _buildNoIngredientsState(context),
      );
    }

    final theme = Theme.of(context);
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
          style: const TextStyle(fontWeight: FontWeight.bold),
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
                final isPerfectMatch = match.missingIngredients.isEmpty;
                final hasSubs = match.substitutionsAvailable.isNotEmpty;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isPerfectMatch
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withValues(alpha: 0.3),
                      width: isPerfectMatch ? 1.5 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RecipeDetailScreen(
                            recipe: recipe,
                          ),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Recipe Image Banner with Match Badge
                        Stack(
                          children: [
                            Image.network(
                              recipe.imageUrl,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 150,
                                color: theme.colorScheme.surfaceContainerHighest,
                                child: const Icon(Icons.restaurant, size: 40),
                              ),
                            ),
                            Positioned(
                              top: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isPerfectMatch
                                      ? theme.colorScheme.secondary
                                      : Colors.black87,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isPerfectMatch
                                          ? Icons.star
                                          : Icons.warning_amber_rounded,
                                      size: 14,
                                      color: Colors.black,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isPerfectMatch
                                          ? '⭐ Perfect Match'
                                          : '⚠️ Missing: ${match.missingIngredients.join(', ')}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (hasSubs)
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '💡 ${match.substitutionsAvailable.length} Swap Available',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),

                        // Details
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recipe.title,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),

                              // Time, Equipment, Price Tag
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme
                                          .surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.access_time, size: 14),
                                        const SizedBox(width: 4),
                                        Text(recipe.prepTime,
                                            style:
                                                const TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme
                                          .surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.microwave, size: 14),
                                        const SizedBox(width: 4),
                                        Text(recipe.equipmentNeeded.isNotEmpty ? recipe.equipmentNeeded.join(', ') : 'No equipment',
                                            style:
                                                const TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '₱${recipe.estimatedCost.round()}',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // You have / Missing text
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: isPerfectMatch
                                          ? 'You have: '
                                          : 'Missing: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: isPerfectMatch
                                            ? theme.colorScheme.onSurface
                                            : theme.colorScheme.secondary,
                                      ),
                                    ),
                                    TextSpan(
                                      text: isPerfectMatch
                                          ? recipe.ingredients.join(', ')
                                          : match.missingIngredients.join(', '),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: theme
                                            .colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            const Text(
              'No matching recipes found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'We couldn\'t find any meals that match your current equipment, budget, and dietary preferences.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
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

  Widget _buildNoIngredientsState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.kitchen_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            const Text(
              'No ingredients selected',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap a few ingredients first so we know what to suggest.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.arrow_back),
              label: const Text('Select Ingredients'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}