import 'package:flutter/material.dart';
import '../data/dummy_recipes.dart';
import '../data/ingredient_database.dart';
import '../logic/recipe_matcher.dart' show ownedEquipmentFrom;
import '../logic/shopping_list_logic.dart';
import '../logic/weekly_planner_logic.dart';
import '../services/preferences_service.dart';

class ShoppingListScreen extends StatefulWidget {
  final Set<String> selectedIngredients;

  const ShoppingListScreen({
    super.key,
    this.selectedIngredients = const {},
  });

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final PreferencesService _prefs = PreferencesService();
  bool _isLoading = true;
  ShoppingListResult? _shoppingList;
  Set<String> _checkedItems = {};

  @override
  void initState() {
    super.initState();
    _loadShoppingList();
  }

  Future<void> _loadShoppingList() async {
    final onboarding = await _prefs.loadOnboardingData();
    final savedIds = await _prefs.loadWeeklyPlanRecipeIds();
    final savedChecked = await _prefs.loadCheckedShoppingItems();

    final equipment = onboarding != null ? ownedEquipmentFrom(onboarding) : <String>{};
    final budget = onboarding?.weeklyBudget ?? 500.0;
    final preferences = onboarding?.dietaryPreferences.toSet() ?? {};

    WeeklyPlanResult plan;
    if (savedIds != null && savedIds.length == 7) {
      final recipeMap = {for (var r in dummyRecipes) r.id: r};
      List<PlannedDay> plannedDays = [];
      const dayLabels = [
        'Day 1 (Mon)',
        'Day 2 (Tue)',
        'Day 3 (Wed)',
        'Day 4 (Thu)',
        'Day 5 (Fri)',
        'Day 6 (Sat)',
        'Day 7 (Sun)',
      ];
      for (int i = 0; i < 7; i++) {
        final recipe = recipeMap[savedIds[i]] ?? dummyRecipes[i % dummyRecipes.length];
        plannedDays.add(PlannedDay(dayIndex: i + 1, dayName: dayLabels[i], recipe: recipe));
      }
      plan = WeeklyPlanResult.fromDays(plannedDays, budget);
    } else {
      plan = generateWeeklyPlan(
        ownedEquipment: equipment,
        weeklyBudget: budget,
        dietaryPreferences: preferences,
      );
    }

    final shoppingResult = generateShoppingList(
      plan: plan,
      pantryIngredients: widget.selectedIngredients,
      checkedItemNames: savedChecked,
    );

    if (!mounted) return;
    setState(() {
      _checkedItems = savedChecked;
      _shoppingList = shoppingResult;
      _isLoading = false;
    });
  }

  Future<void> _toggleItem(String itemName, bool isChecked) async {
    setState(() {
      if (isChecked) {
        _checkedItems.add(itemName.toLowerCase());
      } else {
        _checkedItems.remove(itemName.toLowerCase());
      }
    });
    await _prefs.saveCheckedShoppingItems(_checkedItems);
    _loadShoppingList();
  }

  double get estimatedTotal {
    if (_shoppingList == null) return 0;
    double total = 0;
    for (final group in _shoppingList!.groups) {
      for (final item in group.items) {
        if (!item.inPantry && !item.isChecked) {
          // Estimate item cost roughly
          total += 35.0 * item.countInPlan;
        }
      }
    }
    return total;
  }

  bool get isAllDone {
    if (_shoppingList == null || _shoppingList!.totalMissingCount == 0) return true;
    return _shoppingList!.totalCheckedCount >= _shoppingList!.totalMissingCount;
  }

  IconData _iconForCategory(IngredientCategory cat) {
    switch (cat) {
      case IngredientCategory.vegetables:
        return Icons.eco_outlined;
      case IngredientCategory.proteins:
        return Icons.egg_outlined;
      case IngredientCategory.grains:
        return Icons.rice_bowl_outlined;
      case IngredientCategory.condiments:
        return Icons.kitchen_outlined;
      case IngredientCategory.dairyPantry:
        return Icons.local_grocery_store_outlined;
    }
  }

  Widget _buildCategoryHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemTile(BuildContext context, ShoppingItem item) {
    final theme = Theme.of(context);
    final isChecked = item.isChecked;

    return CheckboxListTile(
      value: isChecked,
      activeColor: theme.colorScheme.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '${item.ingredientName} (${item.countInPlan}x)',
              style: TextStyle(
                fontSize: 15,
                decoration: isChecked ? TextDecoration.lineThrough : null,
                color: isChecked ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurface,
              ),
            ),
          ),
          Text(
            '₱${(35 * item.countInPlan).round()}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isChecked ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
      onChanged: (val) {
        if (val != null) {
          _toggleItem(item.ingredientName, val);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Shopping List')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final missingGroups = _shoppingList!.groups.where((g) => g.missingCount > 0).toList();
    final pantryGroups = _shoppingList!.groups.where((g) => g.items.any((i) => i.inPantry)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.soup_kitchen, color: theme.colorScheme.primary, size: 22),
            const SizedBox(width: 8),
            const Text(
              'Shopping List',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.share, size: 16),
              label: const Text('Share'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                foregroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Shopping list copied to clipboard!')),
                );
              },
            ),
          ),
        ],
      ),
      body: isAllDone
          ? _buildEmptyState(context)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Need to Buy',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ...missingGroups.map((group) {
                    final missingItems = group.items.where((i) => !i.inPantry).toList();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCategoryHeader(context, group.category.name, _iconForCategory(group.category)),
                          ...List.generate(missingItems.length, (idx) {
                            final item = missingItems[idx];
                            return Column(
                              children: [
                                if (idx > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                                _buildItemTile(context, item),
                              ],
                            );
                          }),
                        ],
                      ),
                    );
                  }),

                  if (pantryGroups.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 20, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Text(
                          'Already Have In Pantry',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...pantryGroups.map((group) {
                      final pantryItems = group.items.where((i) => i.inPantry).toList();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: List.generate(pantryItems.length, (idx) {
                            final item = pantryItems[idx];
                            return Column(
                              children: [
                                if (idx > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                                CheckboxListTile(
                                  value: true,
                                  enabled: false,
                                  activeColor: theme.colorScheme.primary,
                                  title: Text(
                                    item.ingredientName,
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                  onChanged: null,
                                ),
                              ],
                            );
                          }),
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),

      bottomSheet: isAllDone
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              color: theme.colorScheme.surface,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estimated Total',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                          ),
                        ),
                        Text(
                          '₱${estimatedTotal.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        foregroundColor: theme.colorScheme.onSurface,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: () async {
                        final allMissingNames = _shoppingList!.groups
                            .expand((g) => g.items)
                            .where((i) => !i.inPantry)
                            .map((i) => i.ingredientName.toLowerCase())
                            .toSet();
                        setState(() {
                          _checkedItems.addAll(allMissingNames);
                        });
                        await _prefs.saveCheckedShoppingItems(_checkedItems);
                        _loadShoppingList();
                      },
                      child: const Text('Mark All Done', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.celebration_outlined, size: 50, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 24),
              const Text(
                'You\'re all set!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Your pantry is fully stocked for your weekly plan. No grocery run needed today!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant, height: 1.4),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset Shopping List'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () async {
                    setState(() {
                      _checkedItems.clear();
                    });
                    await _prefs.saveCheckedShoppingItems(_checkedItems);
                    _loadShoppingList();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
