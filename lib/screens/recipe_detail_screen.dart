import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/preferences_service.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;
  // Ingredients the user already said they have (from the Home screen).
  // Optional and defaults to empty, so this screen still works fine
  // if it's ever opened without that context (e.g. from Favorites later).
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

  // Tracks which ingredients have been checked off while cooking.
  // Keyed by ingredient text since we don't have per-ingredient IDs yet.
  late final Map<String, bool> checkedIngredients;

  @override
  void initState() {
    super.initState();
    // Pre-check anything the user already said they have on the Home
    // screen - saves them re-ticking ingredients they already confirmed.
    checkedIngredients = {
      for (final ingredient in widget.recipe.ingredients)
        ingredient: widget.ownedIngredients.contains(ingredient),
    };
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
    // Only ever write an entry when going from not-cooked to cooked.
    // Unmarking doesn't delete the history entry - the fact that they
    // cooked it earlier today already happened and is worth keeping,
    // this button is about the user's current view, not an undo.
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

    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.title),
        actions: [
          IconButton(
            icon: Icon(isSaved ? Icons.favorite : Icons.favorite_border),
            onPressed: () => setState(() => isSaved = !isSaved),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // Prep time, cost, and difficulty badge together.
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
            // Checkboxes so users can tick things off while gathering
            // ingredients or cooking - purely local UI state for now,
            // doesn't persist or affect matching logic.
            ...recipe.ingredients.map((ingredient) {
              final isOwned = widget.ownedIngredients.contains(ingredient);
              return CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                title: Text(ingredient),
                subtitle: isOwned
                    ? null
                    : const Text(
                        'Missing',
                        style: TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                value: checkedIngredients[ingredient],
                onChanged: (val) {
                  setState(() => checkedIngredients[ingredient] = val!);
                },
              );
            }),
            const SizedBox(height: 12),
            if (recipe.nutrition.calories > 0) ...[
              const Text(
                'Macros per serving',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _MacroRow(label: 'Calories', value: '${recipe.nutrition.calories} kcal'),
                    _MacroRow(label: 'Protein', value: '${recipe.nutrition.proteinGrams.toStringAsFixed(0)}g'),
                    _MacroRow(label: 'Carbs', value: '${recipe.nutrition.carbsGrams.toStringAsFixed(0)}g'),
                    _MacroRow(label: 'Fat', value: '${recipe.nutrition.fatGrams.toStringAsFixed(0)}g'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            const Text(
              'Cooking steps',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (recipe.steps.isEmpty)
              const Text(
                'No detailed steps provided for this recipe.',
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              )
            else
              ...recipe.steps.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('${entry.key + 1}. ${entry.value}'),
                    ),
                  ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSavingCookedEntry ? null : _handleMarkAsCooked,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: isSavingCookedEntry
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isCooked ? 'Marked as cooked ✓' : 'Mark as cooked'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Small helper row for the macros box, keeps the build method readable.
class _MacroRow extends StatelessWidget {
  final String label;
  final String value;

  const _MacroRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}