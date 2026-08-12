import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/preferences_service.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({
    super.key,
    required this.recipe,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final PreferencesService _prefs = PreferencesService();
  bool isFavorite = false;
  bool isCooked = false;
  final Set<int> checkedIngredients = {};

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    final favorites = await _prefs.loadFavoriteRecipeIds();
    if (!mounted) return;
    setState(() => isFavorite = favorites.contains(widget.recipe.id));
  }

  Future<void> _toggleFavorite() async {
    final newIsFav = await _prefs.toggleFavoriteRecipe(widget.recipe.id);
    if (!mounted) return;
    setState(() => isFavorite = newIsFav);
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero Image Header SliverAppBar
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.redAccent : Colors.white,
                ),
                onPressed: _toggleFavorite,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    recipe.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.restaurant, size: 60),
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black45,
                          Colors.transparent,
                          Colors.black87,
                        ],
                        stops: [0.0, 0.4, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.title,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 14, color: Colors.white70),
                            const SizedBox(width: 4),
                            Text(recipe.prepTime, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            const SizedBox(width: 12),
                            const Icon(Icons.microwave, size: 14, color: Colors.white70),
                            const SizedBox(width: 4),
                            Text(recipe.equipmentNeeded.isNotEmpty ? recipe.equipmentNeeded.join(', ') : 'No equipment', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                recipe.difficulty.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content Body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ingredients Section Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ingredients',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const Divider(height: 20),
                        ...List.generate(recipe.detailedIngredients.length, (index) {
                          final item = recipe.detailedIngredients[index];
                          final isChecked = checkedIngredients.contains(index);

                          return CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              item.fullDisplay,
                              style: TextStyle(
                                fontSize: 14,
                                decoration: isChecked ? TextDecoration.lineThrough : null,
                                color: isChecked ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurface,
                              ),
                            ),
                            value: isChecked,
                            activeColor: theme.colorScheme.primary,
                            onChanged: (val) {
                              setState(() {
                                if (val!) {
                                  checkedIngredients.add(index);
                                } else {
                                  checkedIngredients.remove(index);
                                }
                              });
                            },
                          );
                        })
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // MACROS PER SERVING Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MACROS PER SERVING',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Macros grid (Calories, Protein, Carbs, Fat)
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Calories', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${recipe.nutrition.calories}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Protein', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${recipe.nutrition.proteinGrams.round()}g',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: theme.colorScheme.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Carbs', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${recipe.nutrition.carbsGrams.round()}g',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Fat', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${recipe.nutrition.fatGrams.round()}g',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Cooking Steps Section Header
                  const Text(
                    'Cooking Steps',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Numbered Step Cards
                  ...List.generate(recipe.detailedSteps.length, (index) {
                    final step = recipe.detailedSteps[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              shape: BoxShape.circle,
                              border: Border.all(color: theme.colorScheme.primary),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  step.title,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  step.description,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: theme.colorScheme.onSurfaceVariant,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: Icon(isCooked ? Icons.check_circle : Icons.check_circle_outline),
            label: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                isCooked ? 'Cooked & Tracked!' : 'Mark as Cooked',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isCooked ? theme.colorScheme.surfaceContainerHighest : theme.colorScheme.primary,
              foregroundColor: isCooked ? theme.colorScheme.primary : theme.colorScheme.onPrimary,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            onPressed: () async {
              setState(() => isCooked = !isCooked);
              if (isCooked) {
                await _prefs.addCookedEntry(
                  CookedEntry(
                    recipeId: recipe.id,
                    recipeTitle: recipe.title,
                    cookedAt: DateTime.now(),
                  ),
                );
              }
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isCooked ? 'Marked as cooked! Calories & macros tracked.' : 'Unmarked cooked recipe.'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}