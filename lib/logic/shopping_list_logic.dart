import '../data/ingredient_database.dart';
import 'weekly_planner_logic.dart';

class ShoppingItem {
  final String ingredientName;
  final IngredientCategory category;
  final int countInPlan;
  final List<String> recipesUsing;
  final bool inPantry;
  bool isChecked;

  ShoppingItem({
    required this.ingredientName,
    required this.category,
    required this.countInPlan,
    required this.recipesUsing,
    required this.inPantry,
    this.isChecked = false,
  });
}

class ShoppingListGroup {
  final IngredientCategory category;
  final List<ShoppingItem> items;

  const ShoppingListGroup({
    required this.category,
    required this.items,
  });

  int get missingCount => items.where((i) => !i.inPantry).length;
  int get checkedMissingCount =>
      items.where((i) => !i.inPantry && i.isChecked).length;
}

class ShoppingListResult {
  final List<ShoppingListGroup> groups;
  final int totalItemsCount;
  final int totalMissingCount;
  final int totalCheckedCount;

  const ShoppingListResult({
    required this.groups,
    required this.totalItemsCount,
    required this.totalMissingCount,
    required this.totalCheckedCount,
  });
}

/// Helper to resolve the category for an ingredient name string.
IngredientCategory getCategoryForIngredient(String ingredientName) {
  final nameLower = ingredientName.toLowerCase();
  for (final item in categorizedIngredients) {
    if (item.name.toLowerCase() == nameLower) {
      return item.category;
    }
  }

  // Fallback heuristics if ingredient is not in the database
  if (nameLower.contains('sauce') ||
      nameLower.contains('oil') ||
      nameLower.contains('pepper') ||
      nameLower.contains('salt') ||
      nameLower.contains('mayo') ||
      nameLower.contains('vinegar')) {
    return IngredientCategory.condiments;
  }
  if (nameLower.contains('rice') ||
      nameLower.contains('noodle') ||
      nameLower.contains('bread') ||
      nameLower.contains('oat') ||
      nameLower.contains('pasta')) {
    return IngredientCategory.grains;
  }
  if (nameLower.contains('chicken') ||
      nameLower.contains('tuna') ||
      nameLower.contains('beef') ||
      nameLower.contains('egg') ||
      nameLower.contains('pork') ||
      nameLower.contains('tofu')) {
    return IngredientCategory.proteins;
  }
  if (nameLower.contains('onion') ||
      nameLower.contains('garlic') ||
      nameLower.contains('kimchi') ||
      nameLower.contains('carrot') ||
      nameLower.contains('cabbage') ||
      nameLower.contains('corn')) {
    return IngredientCategory.vegetables;
  }

  return IngredientCategory.dairyPantry;
}

/// Generates a categorized shopping list comparing planned meals vs pantry ingredients.
ShoppingListResult generateShoppingList({
  required WeeklyPlanResult plan,
  required Set<String> pantryIngredients,
  Set<String>? checkedItemNames,
}) {
  final Map<String, List<String>> ingredientToRecipes = {};
  final Map<String, int> ingredientCounts = {};

  final pantryLower = pantryIngredients.map((i) => i.toLowerCase()).toSet();
  final checkedLower = checkedItemNames?.map((i) => i.toLowerCase()).toSet() ?? {};

  for (final day in plan.days) {
    for (final ingredient in day.recipe.ingredients) {
      final key = ingredient.trim();
      ingredientCounts[key] = (ingredientCounts[key] ?? 0) + 1;
      ingredientToRecipes.putIfAbsent(key, () => []).add(day.recipe.title);
    }
  }

  final Map<IngredientCategory, List<ShoppingItem>> categoryItems = {};

  for (final category in IngredientCategory.values) {
    categoryItems[category] = [];
  }

  int totalItems = 0;
  int totalMissing = 0;
  int totalChecked = 0;

  ingredientCounts.forEach((name, count) {
    final category = getCategoryForIngredient(name);
    final isPantry = pantryLower.contains(name.toLowerCase());
    final isChecked = checkedLower.contains(name.toLowerCase());

    totalItems++;
    if (!isPantry) {
      totalMissing++;
      if (isChecked) totalChecked++;
    }

    final recipes = (ingredientToRecipes[name] ?? []).toSet().toList();

    categoryItems[category]!.add(
      ShoppingItem(
        ingredientName: name,
        category: category,
        countInPlan: count,
        recipesUsing: recipes,
        inPantry: isPantry,
        isChecked: isChecked,
      ),
    );
  });

  // Sort items within each category: missing items first, then in-pantry
  final List<ShoppingListGroup> groups = [];
  for (final category in IngredientCategory.values) {
    final items = categoryItems[category]!;
    items.sort((a, b) {
      if (a.inPantry != b.inPantry) {
        return a.inPantry ? 1 : -1;
      }
      return a.ingredientName.compareTo(b.ingredientName);
    });

    if (items.isNotEmpty) {
      groups.add(ShoppingListGroup(category: category, items: items));
    }
  }

  return ShoppingListResult(
    groups: groups,
    totalItemsCount: totalItems,
    totalMissingCount: totalMissing,
    totalCheckedCount: totalChecked,
  );
}
