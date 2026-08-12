import 'package:flutter/material.dart';
import '../data/substitutions_database.dart';
import '../models/recipe.dart';
import '../services/preferences_service.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;
  final List<String> ownedIngredients;

  const RecipeDetailScreen({
    super.key,
    required this.recipe,
    this.ownedIngredients = const [],
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final _preferencesService = PreferencesService();
  bool isSaved = false;
  bool isCooked = false;
  bool isSavingCookedEntry = false;

  late final Map<String, bool> checkedIngredients;

  @override
  void initState() {
    super.initState();
    _checkIsFavorite();
    checkedIngredients = {
      for (final ingredient in widget.recipe.ingredients)
        ingredient: widget.ownedIngredients.contains(ingredient),
    };
  }

  Future<void> _checkIsFavorite() async {
    final favorites = await _preferencesService.loadFavoriteRecipeIds();
    if (!mounted) return;
    setState(() {
      isSaved = favorites.contains(widget.recipe.id);
    });
  }

  Future<void> _toggleFavorite() async {
    final newIsSaved =
        await _preferencesService.toggleFavoriteRecipe(widget.recipe.id);
    if (!mounted) return;
    setState(() {
      isSaved = newIsSaved;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newIsSaved
              ? 'Saved "${widget.recipe.title}" to Favorites'
              : 'Removed from Favorites',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _difficultyLabel(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return 'Easy';
      case Difficulty.medium:
        return 'Medium';
      case Difficulty.hard:
        return 'Hard';
    }
  }

  Color _difficultyColor(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return Colors.green;
      case Difficulty.medium:
        return Colors.orange;
      case Difficulty.hard:
        return Colors.red;
    }
  }

  Future<void> _handleMarkAsCooked() async {
    if (isCooked) {
      setState(() => isCooked = false);
      return;
    }

    setState(() {
      isCooked = true;
      isSavingCookedEntry = true;
    });

    await _preferencesService.addCookedEntry(
      CookedEntry(
        recipeId: widget.recipe.id,
        recipeTitle: widget.recipe.title,
        cookedAt: DateTime.now(),
      ),
    );

    if (!mounted) return;
    setState(() => isSavingCookedEntry = false);
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final ownedLower = widget.ownedIngredients.map((i) => i.toLowerCase()).toSet();

    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.title),
        actions: [
          IconButton(
            icon: Icon(
              isSaved ? Icons.favorite : Icons.favorite_border,
              color: isSaved ? Colors.red : null,
            ),
            tooltip: isSaved ? 'Remove from Favorites' : 'Save to Favorites',
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${recipe.prepTime} • ₱${recipe.estimatedCost.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Chip(
                  label: Text(
                    _difficultyLabel(recipe.difficulty),
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: _difficultyColor(recipe.difficulty),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Ingredients',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            ...recipe.detailedIngredients.map((spec) {
              final isOwned = ownedLower.contains(spec.name.toLowerCase());

              // Check if user owns any valid substitute for missing ingredient
              String? matchingSub;
              if (!isOwned) {
                for (final sub in spec.substitutes) {
                  if (ownedLower.contains(sub.toLowerCase())) {
                    matchingSub = sub;
                    break;
                  }
                }
                if (matchingSub == null) {
                  final globalSub = findGlobalSubstitution(spec.name);
                  if (globalSub != null) {
                    for (final sub in globalSub.substitutes) {
                      if (ownedLower.contains(sub.toLowerCase())) {
                        matchingSub = sub;
                        break;
                      }
                    }
                  }
                }
              }

              return CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                title: Text(spec.name),
                subtitle: isOwned
                    ? null
                    : matchingSub != null
                        ? Text(
                            'Substituted with $matchingSub in your pantry',
                            style: const TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          )
                        : const Text(
                            'Missing',
                            style:
                                TextStyle(color: Colors.orange, fontSize: 12),
                          ),
                value: checkedIngredients[spec.name] ?? false,
                onChanged: (val) {
                  setState(() => checkedIngredients[spec.name] = val!);
                },
              );
            }),

            const SizedBox(height: 12),
            _buildSubstitutionsSection(recipe, ownedLower),

            const SizedBox(height: 12),
            if (recipe.nutrition.calories > 0) ...[
              const Text(
                'Nutrition (per serving)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMacroColumn(
                        label: 'Calories',
                        value: '${recipe.nutrition.calories}',
                        unit: 'kcal',
                      ),
                      _buildMacroColumn(
                        label: 'Protein',
                        value: '${recipe.nutrition.proteinGrams.toStringAsFixed(0)}',
                        unit: 'g',
                      ),
                      _buildMacroColumn(
                        label: 'Carbs',
                        value: '${recipe.nutrition.carbsGrams.toStringAsFixed(0)}',
                        unit: 'g',
                      ),
                      _buildMacroColumn(
                        label: 'Fat',
                        value: '${recipe.nutrition.fatGrams.toStringAsFixed(0)}',
                        unit: 'g',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            const Text(
              'Equipment needed',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: recipe.equipmentNeeded
                  .map((e) => Chip(label: Text(e)))
                  .toList(),
            ),

            const SizedBox(height: 16),
            const Text(
              'Steps',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...recipe.steps.asMap().entries.map((entry) {
              final stepIndex = entry.key + 1;
              final stepText = entry.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      child: Text(
                        '$stepIndex',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        stepText,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCooked ? Colors.green[700] : null,
                  foregroundColor: isCooked ? Colors.white : null,
                ),
                onPressed: isSavingCookedEntry ? null : _handleMarkAsCooked,
                icon: isSavingCookedEntry
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        isCooked ? Icons.check_circle : Icons.soup_kitchen,
                      ),
                label: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    isCooked ? 'Cooked today!' : 'Mark as cooked',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubstitutionsSection(Recipe recipe, Set<String> ownedLower) {
    final subTips = <Map<String, String>>[];

    for (final spec in recipe.detailedIngredients) {
      final isOwned = ownedLower.contains(spec.name.toLowerCase());
      if (!isOwned) {
        final global = findGlobalSubstitution(spec.name);
        final subs = spec.substitutes.isNotEmpty
            ? spec.substitutes
            : (global?.substitutes ?? []);
        final note = spec.substitutionNote ?? (global?.tip ?? '');

        if (subs.isNotEmpty) {
          subTips.add({
            'ingredient': spec.name,
            'substitutes': subs.join(', '),
            'note': note,
          });
        }
      }
    }

    if (subTips.isEmpty) return const SizedBox();

    return Card(
      color: Colors.amber[50],
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.amber.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.amber[900]),
                const SizedBox(width: 8),
                Text(
                  'Smart Ingredient Substitutions',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[900],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...subTips.map((tip) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '• Missing ${tip['ingredient']}? Try: ${tip['substitutes']}.${tip['note']!.isNotEmpty ? ' (${tip['note']})' : ''}',
                  style: const TextStyle(fontSize: 12),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroColumn({
    required String label,
    required String value,
    required String unit,
  }) {
    return Column(
      children: [
        Text(
          '$value $unit',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }
}