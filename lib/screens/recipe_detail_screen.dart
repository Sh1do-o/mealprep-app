import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/preferences_service.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;
  final bool? initialPairWithRice;

  const RecipeDetailScreen({
    super.key,
    required this.recipe,
    this.initialPairWithRice,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final PreferencesService _prefs = PreferencesService();
  bool isFavorite = false;
  bool isCooked = false;
  late bool pairWithRice;
  final Set<int> checkedIngredients = {};

  @override
  void initState() {
    super.initState();
    pairWithRice = widget.initialPairWithRice ?? widget.recipe.canPairWithRice;
    _initSettings();
  }

  Future<void> _initSettings() async {
    final favorites = await _prefs.loadFavoriteRecipeIds();
    final alwaysRice = await _prefs.loadAlwaysPairWithRice();
    if (!mounted) return;
    setState(() {
      isFavorite = favorites.contains(widget.recipe.id);
      if (widget.initialPairWithRice == null && widget.recipe.canPairWithRice) {
        pairWithRice = alwaysRice;
      }
    });
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
    final effectiveCost = recipe.getCostWithRice(pairWithRice: pairWithRice);
    final effectiveNutrition = recipe.getNutritionWithRice(pairWithRice: pairWithRice);

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
                  // Filipino Rice Preference Pairing Toggle Card
                  if (recipe.canPairWithRice) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: pairWithRice
                            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                            : theme.colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: pairWithRice
                              ? theme.colorScheme.primary.withValues(alpha: 0.5)
                              : theme.colorScheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text('🍚', style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pair with Steamed Rice (+₱15)',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  'Adds 1 cup white rice (+200 kcal, +45g carbs, +4g protein)',
                                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: pairWithRice,
                            onChanged: (val) => setState(() => pairWithRice = val),
                          ),
                        ],
                      ),
                    ),
                  ],

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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Ingredients',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Est. ₱${effectiveCost.round()}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
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
                        }),
                        if (pairWithRice) ...[
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              '1 cup Steamed Rice (₱15)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                decoration: checkedIngredients.contains(999) ? TextDecoration.lineThrough : null,
                                color: checkedIngredients.contains(999) ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.primary,
                              ),
                            ),
                            value: checkedIngredients.contains(999),
                            activeColor: theme.colorScheme.primary,
                            onChanged: (val) {
                              setState(() {
                                if (val!) {
                                  checkedIngredients.add(999);
                                } else {
                                  checkedIngredients.remove(999);
                                }
                              });
                            },
                          ),
                        ],
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            if (pairWithRice)
                              Text(
                                '(Includes Rice)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                          ],
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
                                      '${effectiveNutrition.calories}',
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
                                      '${effectiveNutrition.proteinGrams.round()}g',
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
                                      '${effectiveNutrition.carbsGrams.round()}g',
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
                                      '${effectiveNutrition.fatGrams.round()}g',
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
                  const SizedBox(height: 16),

                  // Smart Substitutions Card Section
                  if (recipe.detailedIngredients.any((i) => i.substitutes.isNotEmpty)) ...[
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
                          Row(
                            children: [
                              Icon(Icons.lightbulb_outline, color: theme.colorScheme.secondary, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Student Smart Substitutions',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...recipe.detailedIngredients
                              .where((item) => item.substitutes.isNotEmpty)
                              .map((item) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface, height: 1.3),
                                  children: [
                                    TextSpan(
                                      text: 'Instead of ${item.name}: ',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    TextSpan(
                                      text: item.substitutes.join(', '),
                                      style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Instructions / Steps Section
                  const Text(
                    'Step-by-Step Instructions',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(recipe.detailedSteps.length, (index) {
                    final step = recipe.detailedSteps[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: theme.colorScheme.primary,
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  step.title,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
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
                    pairedWithRice: pairWithRice,
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