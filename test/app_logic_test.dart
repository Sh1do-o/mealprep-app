import 'package:flutter_test/flutter_test.dart';
import 'package:mealprep_app/data/dummy_recipes.dart';
import 'package:mealprep_app/logic/recipe_matcher.dart';
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

  group('Pantry Matcher: Zero Matching Ingredient Filtering', () {
    test('getRecommendations excludes recipes when NEITHER bread NOR egg are chosen, but includes them if either is present', () {
      // 1. When only Rice is selected (NEITHER bread NOR egg chosen)
      final riceMatches = getRecommendations(
        ownedIngredients: ['Rice'],
        ownedEquipment: {'Stove', 'Microwave', 'Rice cooker'},
        budget: 500,
      );
      final riceEggAndToast = riceMatches.any((m) => m.recipe.title.contains('Egg & Toast'));
      expect(riceEggAndToast, isFalse);

      // 2. When Eggs is selected
      final eggMatches = getRecommendations(
        ownedIngredients: ['Eggs'],
        ownedEquipment: {'Stove', 'Microwave', 'Rice cooker'},
        budget: 500,
      );
      final eggEggAndToast = eggMatches.any((m) => m.recipe.title.contains('Egg & Toast'));
      expect(eggEggAndToast, isTrue);

      // 3. When Sliced Bread is selected
      final breadMatches = getRecommendations(
        ownedIngredients: ['Sliced Bread'],
        ownedEquipment: {'Stove', 'Microwave', 'Rice cooker'},
        budget: 500,
      );
      final breadEggAndToast = breadMatches.any((m) => m.recipe.title.contains('Egg & Toast'));
      expect(breadEggAndToast, isTrue);
    });
  });

  group('User 15-Ingredient Equipment Scenario', () {
    test('Verifies recipe match count for user 15 ingredients under different equipment profiles', () {
      final userIngredients = [
        'Egg',
        'Canned tuna',
        'Canned corned beef',
        'Chicken',
        'Rice',
        'Instant noodles',
        'Bread',
        'Onion',
        'Garlic',
        'Kimchi',
        'Soy sauce',
        'Cooking oil',
        'Vinegar',
        'Black pepper',
        'Milk',
      ];

      // Scenario 1: Only Rice Cooker owned (matches exact 4 recipes user reported: Avocado Toast, Hainanese, Mac & Cheese, Kimchi Fried Rice)
      final riceCookerOnly = getRecommendations(
        ownedIngredients: userIngredients,
        ownedEquipment: {'Rice cooker', 'Fridge'},
        budget: 500,
      );
      expect(riceCookerOnly.length, equals(4));

      // Scenario 2: Full equipment owned (Stove, Microwave, Rice Cooker, Kettle)
      final fullEquipment = getRecommendations(
        ownedIngredients: userIngredients,
        ownedEquipment: {'Stove', 'Microwave', 'Rice cooker', 'Electric Kettle', 'Fridge'},
        budget: 500,
      );
      expect(fullEquipment.length, greaterThanOrEqualTo(12));
    });
  });
}
