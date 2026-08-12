import '../data/dummy_recipes.dart';
import '../models/recipe.dart';
import '../services/preferences_service.dart';

class CookedRecipeDetail {
  final CookedEntry entry;
  final Recipe? recipe;

  CookedRecipeDetail({
    required this.entry,
    required this.recipe,
  });
}

class WeeklySummaryData {
  final int totalMealsCooked;
  final double totalEstimatedCost;
  final double avgCostPerMeal;
  final int totalCalories;
  final double totalProteinGrams;
  final double totalCarbsGrams;
  final double totalFatGrams;
  final List<CookedRecipeDetail> cookedDetails;

  const WeeklySummaryData({
    required this.totalMealsCooked,
    required this.totalEstimatedCost,
    required this.avgCostPerMeal,
    required this.totalCalories,
    required this.totalProteinGrams,
    required this.totalCarbsGrams,
    required this.totalFatGrams,
    required this.cookedDetails,
  });
}

// Aggregates cooked entries into descriptive summary metrics.
WeeklySummaryData calculateWeeklySummary(List<CookedEntry> history,
    {List<Recipe>? recipePool}) {
  final recipes = recipePool ?? dummyRecipes;
  final recipeMap = {for (final r in recipes) r.id: r};

  final totalMeals = history.length;
  double totalCost = 0;
  int calories = 0;
  double protein = 0;
  double carbs = 0;
  double fat = 0;
  final List<CookedRecipeDetail> details = [];

  // Show newest cooked meals first in history log
  for (final entry in history.reversed) {
    final recipe = recipeMap[entry.recipeId];
    details.add(CookedRecipeDetail(entry: entry, recipe: recipe));

    if (recipe != null) {
      totalCost += recipe.estimatedCost;
      calories += recipe.nutrition.calories;
      protein += recipe.nutrition.proteinGrams;
      carbs += recipe.nutrition.carbsGrams;
      fat += recipe.nutrition.fatGrams;
    }
  }

  final avgCost = totalMeals > 0 ? totalCost / totalMeals : 0.0;

  return WeeklySummaryData(
    totalMealsCooked: totalMeals,
    totalEstimatedCost: totalCost,
    avgCostPerMeal: avgCost,
    totalCalories: calories,
    totalProteinGrams: protein,
    totalCarbsGrams: carbs,
    totalFatGrams: fat,
    cookedDetails: details,
  );
}
