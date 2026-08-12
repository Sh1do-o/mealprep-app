import 'dart:math';
import '../models/recipe.dart';
import '../data/dummy_recipes.dart';

class PlannedDay {
  final int dayIndex; // 1 to 7
  final String dayName;
  final Recipe recipe;

  const PlannedDay({
    required this.dayIndex,
    required this.dayName,
    required this.recipe,
  });

  PlannedDay copyWith({Recipe? recipe}) {
    return PlannedDay(
      dayIndex: dayIndex,
      dayName: dayName,
      recipe: recipe ?? this.recipe,
    );
  }
}

class WeeklyPlanResult {
  final List<PlannedDay> days;
  final double totalEstimatedCost;
  final double weeklyBudget;
  final int totalCalories;
  final double totalProteinGrams;
  final double totalCarbsGrams;
  final double totalFatGrams;

  const WeeklyPlanResult({
    required this.days,
    required this.totalEstimatedCost,
    required this.weeklyBudget,
    required this.totalCalories,
    required this.totalProteinGrams,
    required this.totalCarbsGrams,
    required this.totalFatGrams,
  });

  factory WeeklyPlanResult.fromDays(List<PlannedDay> days, double budget) {
    double cost = 0;
    int cals = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;

    for (final day in days) {
      cost += day.recipe.estimatedCost;
      cals += day.recipe.nutrition.calories;
      protein += day.recipe.nutrition.proteinGrams;
      carbs += day.recipe.nutrition.carbsGrams;
      fat += day.recipe.nutrition.fatGrams;
    }

    return WeeklyPlanResult(
      days: days,
      totalEstimatedCost: cost,
      weeklyBudget: budget,
      totalCalories: cals,
      totalProteinGrams: protein,
      totalCarbsGrams: carbs,
      totalFatGrams: fat,
    );
  }
}

const List<String> _dayLabels = [
  'Day 1 (Mon)',
  'Day 2 (Tue)',
  'Day 3 (Wed)',
  'Day 4 (Thu)',
  'Day 5 (Fri)',
  'Day 6 (Sat)',
  'Day 7 (Sun)',
];

/// Filter helper for compatible recipes
bool isRecipeCompatible({
  required Recipe recipe,
  required Set<String> ownedEquipment,
  required Set<String> dietaryPreferences,
}) {
  // Check equipment
  for (final equip in recipe.equipmentNeeded) {
    final hasEquip = ownedEquipment.any(
      (e) => e.toLowerCase() == equip.toLowerCase(),
    );
    if (!hasEquip) return false;
  }

  // Check dietary preferences
  final prefLower = dietaryPreferences.map((p) => p.toLowerCase()).toSet();
  if (prefLower.contains('vegetarian') && !recipe.isVegetarian) {
    return false;
  }
  if (prefLower.contains('halal') && !recipe.isHalal) {
    return false;
  }
  if (prefLower.contains('no-vegetables') && recipe.containsVegetables) {
    return false;
  }

  return true;
}

/// Generates a 7-day meal plan respecting dietary, equipment, and budget preferences.
WeeklyPlanResult generateWeeklyPlan({
  List<Recipe>? allRecipes,
  required Set<String> ownedEquipment,
  required double weeklyBudget,
  required Set<String> dietaryPreferences,
  int seed = 42,
}) {
  final pool = allRecipes ?? dummyRecipes;

  // Filter recipes compatible with equipment and dietary restrictions
  final validRecipes = pool
      .where(
        (r) => isRecipeCompatible(
          recipe: r,
          ownedEquipment: ownedEquipment,
          dietaryPreferences: dietaryPreferences,
        ),
      )
      .toList();

  final recipePool = validRecipes.isNotEmpty ? validRecipes : pool;
  final random = Random(seed);
  final shuffledPool = List<Recipe>.from(recipePool)..shuffle(random);

  List<PlannedDay> days = [];
  Set<String> chosenIds = {};

  for (int i = 0; i < 7; i++) {
    // Try to pick an unchosen recipe
    Recipe? selected;
    for (final r in shuffledPool) {
      if (!chosenIds.contains(r.id)) {
        selected = r;
        break;
      }
    }
    // Fallback to random choice if pool has fewer than 7 unique recipes
    selected ??= shuffledPool[i % shuffledPool.length];
    chosenIds.add(selected.id);

    days.add(
      PlannedDay(
        dayIndex: i + 1,
        dayName: _dayLabels[i],
        recipe: selected,
      ),
    );
  }

  return WeeklyPlanResult.fromDays(days, weeklyBudget);
}

/// Returns candidate recipes that can swap in for a specific day.
List<Recipe> getSwapCandidates({
  required WeeklyPlanResult currentPlan,
  required int dayIndex,
  List<Recipe>? allRecipes,
  required Set<String> ownedEquipment,
  required Set<String> dietaryPreferences,
}) {
  final pool = allRecipes ?? dummyRecipes;
  final currentRecipeId = currentPlan.days[dayIndex - 1].recipe.id;

  return pool.where((r) {
    if (r.id == currentRecipeId) return false;
    return isRecipeCompatible(
      recipe: r,
      ownedEquipment: ownedEquipment,
      dietaryPreferences: dietaryPreferences,
    );
  }).toList();
}

/// Swaps the recipe for a specific day in the plan.
WeeklyPlanResult swapMealForDay({
  required WeeklyPlanResult currentPlan,
  required int dayIndex,
  required Recipe newRecipe,
}) {
  final updatedDays = List<PlannedDay>.from(currentPlan.days);
  final targetIndex = dayIndex - 1;

  updatedDays[targetIndex] = updatedDays[targetIndex].copyWith(
    recipe: newRecipe,
  );

  return WeeklyPlanResult.fromDays(updatedDays, currentPlan.weeklyBudget);
}
