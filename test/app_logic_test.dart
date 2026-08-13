import 'package:flutter_test/flutter_test.dart';
import 'package:mealprep_app/data/dummy_recipes.dart';
import 'package:mealprep_app/logic/weekly_planner_logic.dart';
import 'package:mealprep_app/logic/weekly_summary_logic.dart';
import 'package:mealprep_app/services/preferences_service.dart';

void main() {
  group('Bug Fix 1: Dietary Preference Key Mismatch', () {
    test('isRecipeCompatible handles both no-vegetables and no_vegetables', () {
      final veggieRecipe = dummyRecipes.firstWhere((r) => r.containsVegetables);

      // Check no_vegetables (underscore) saved by onboarding_screen.dart
      final compatibleUnderscore = isRecipeCompatible(
        recipe: veggieRecipe,
        ownedEquipment: {'stovetop', 'rice cooker', 'microwave'},
        dietaryPreferences: {'no_vegetables'},
      );
      expect(compatibleUnderscore, isFalse);

      // Check no-vegetables (hyphen)
      final compatibleHyphen = isRecipeCompatible(
        recipe: veggieRecipe,
        ownedEquipment: {'stovetop', 'rice cooker', 'microwave'},
        dietaryPreferences: {'no-vegetables'},
      );
      expect(compatibleHyphen, isFalse);
    });
  });

  group('Bug Fix 2: Weekly Plan Budget Enforcement', () {
    test('generateWeeklyPlan respects weeklyBudget constraint', () {
      const budget = 350.0;
      final result = generateWeeklyPlan(
        allRecipes: dummyRecipes,
        ownedEquipment: {'stovetop', 'rice cooker', 'microwave'},
        weeklyBudget: budget,
        dietaryPreferences: {},
        seed: 123,
      );

      // Total estimated cost should stay within weeklyBudget
      expect(result.totalEstimatedCost, lessThanOrEqualTo(budget));
      expect(result.days.length, equals(7));
    });
  });

  group('Bug Fix 3: Weekly Summary 7-Day Window', () {
    test('calculateWeeklySummary filters out entries older than 7 days', () {
      final now = DateTime(2026, 8, 13, 12, 0);

      final history = [
        CookedEntry(
          recipeId: dummyRecipes[0].id,
          recipeTitle: dummyRecipes[0].title,
          cookedAt: now.subtract(const Duration(days: 10)), // older than 7 days
        ),
        CookedEntry(
          recipeId: dummyRecipes[1].id,
          recipeTitle: dummyRecipes[1].title,
          cookedAt: now.subtract(const Duration(days: 2)), // within 7 days
        ),
        CookedEntry(
          recipeId: dummyRecipes[2].id,
          recipeTitle: dummyRecipes[2].title,
          cookedAt: now.subtract(const Duration(days: 5)), // within 7 days
        ),
      ];

      final summary = calculateWeeklySummary(
        history,
        recipePool: dummyRecipes,
        now: now,
      );

      expect(summary.totalMealsCooked, equals(2));
      expect(summary.cookedDetails.length, equals(2));
    });
  });
}
