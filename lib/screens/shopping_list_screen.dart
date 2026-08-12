import 'package:flutter/material.dart';
import '../data/dummy_recipes.dart';
import '../logic/shopping_list_logic.dart';
import '../logic/weekly_planner_logic.dart';
import '../models/recipe.dart';
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
  final _preferencesService = PreferencesService();

  bool _isLoading = true;
  WeeklyPlanResult? _plan;
  Set<String> _checkedItemNames = {};
  ShoppingListResult? _shoppingList;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final onboarding = await _preferencesService.loadOnboardingData();
    final savedRecipeIds = await _preferencesService.loadWeeklyPlanRecipeIds();
    final savedCheckedItems = await _preferencesService.loadCheckedShoppingItems();

    final equipment = onboarding != null
        ? ownedEquipmentFrom(onboarding)
        : <String>{};
    final budget = onboarding?.weeklyBudget ?? 500.0;
    final preferences = onboarding?.dietaryPreferences.toSet() ?? {};

    WeeklyPlanResult plan;

    if (savedRecipeIds != null && savedRecipeIds.length == 7) {
      final Map<String, Recipe> recipeMap = {
        for (var r in dummyRecipes) r.id: r
      };

      List<PlannedDay> days = [];
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
        final id = savedRecipeIds[i];
        final recipe = recipeMap[id] ?? dummyRecipes[i % dummyRecipes.length];
        days.add(
          PlannedDay(
            dayIndex: i + 1,
            dayName: dayLabels[i],
            recipe: recipe,
          ),
        );
      }
      plan = WeeklyPlanResult.fromDays(days, budget);
    } else {
      plan = generateWeeklyPlan(
        ownedEquipment: equipment,
        weeklyBudget: budget,
        dietaryPreferences: preferences,
      );
    }

    final result = generateShoppingList(
      plan: plan,
      pantryIngredients: widget.selectedIngredients,
      checkedItemNames: savedCheckedItems,
    );

    if (!mounted) return;
    setState(() {
      _plan = plan;
      _checkedItemNames = savedCheckedItems;
      _shoppingList = result;
      _isLoading = false;
    });
  }

  Set<String> ownedEquipmentFrom(OnboardingData data) {
    final set = <String>{};
    if (data.hasRiceCooker) set.add('Rice cooker');
    if (data.hasStove) set.add('Stove');
    if (data.hasMicrowave) set.add('Microwave');
    if (data.hasFridge) set.add('Fridge');
    return set;
  }

  void _toggleCheck(ShoppingItem item) async {
    final newChecked = Set<String>.from(_checkedItemNames);
    if (newChecked.contains(item.ingredientName.toLowerCase())) {
      newChecked.remove(item.ingredientName.toLowerCase());
    } else {
      newChecked.add(item.ingredientName.toLowerCase());
    }

    await _preferencesService.saveCheckedShoppingItems(newChecked);

    if (!mounted) return;
    setState(() {
      _checkedItemNames = newChecked;
      if (_plan != null) {
        _shoppingList = generateShoppingList(
          plan: _plan!,
          pantryIngredients: widget.selectedIngredients,
          checkedItemNames: newChecked,
        );
      }
    });
  }

  void _clearChecked() async {
    await _preferencesService.saveCheckedShoppingItems({});
    if (!mounted) return;
    setState(() {
      _checkedItemNames = {};
      if (_plan != null) {
        _shoppingList = generateShoppingList(
          plan: _plan!,
          pantryIngredients: widget.selectedIngredients,
          checkedItemNames: {},
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto Shopping List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services_outlined),
            tooltip: 'Clear Checked Items',
            onPressed: _clearChecked,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _shoppingList == null || _shoppingList!.groups.isEmpty
              ? const Center(child: Text('No planned recipes found.'))
              : Column(
                  children: [
                    _buildHeaderBanner(),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _shoppingList!.groups.length,
                        itemBuilder: (context, index) {
                          final group = _shoppingList!.groups[index];
                          return _buildGroupSection(group);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildHeaderBanner() {
    final missing = _shoppingList!.totalMissingCount;
    final checked = _shoppingList!.totalCheckedCount;
    final ratio = missing > 0 ? (checked / missing).clamp(0.0, 1.0) : 1.0;

    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Grocery Progress',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '$checked / $missing items bought',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: checked == missing && missing > 0
                      ? Colors.green[700]
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupSection(ShoppingListGroup group) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              children: [
                Text(
                  group.category.label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${group.items.length} items',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Column(
              children: group.items.map((item) {
                return Column(
                  children: [
                    ListTile(
                      dense: true,
                      leading: Checkbox(
                        value: item.inPantry || item.isChecked,
                        onChanged: item.inPantry
                            ? null
                            : (_) => _toggleCheck(item),
                      ),
                      title: Text(
                        item.ingredientName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          decoration: item.inPantry || item.isChecked
                              ? TextDecoration.lineThrough
                              : null,
                          color: item.inPantry || item.isChecked
                              ? Colors.grey
                              : null,
                        ),
                      ),
                      subtitle: Text(
                        'Used in: ${item.recipesUsing.join(", ")}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      trailing: item.inPantry
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'In Pantry',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                            )
                          : item.countInPlan > 1
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${item.countInPlan}x meals',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : null,
                      onTap: item.inPantry ? null : () => _toggleCheck(item),
                    ),
                    if (item != group.items.last)
                      const Divider(height: 1, indent: 48),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
