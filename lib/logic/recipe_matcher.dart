import '../data/dummy_recipes.dart';
import '../models/recipe.dart';
import '../services/preferences_service.dart';

// A recipe plus how well it matched, so the UI can show *why*
// something was suggested (e.g. "missing 1 ingredient") without
// recalculating anything itself.
class RecipeMatch {
  final Recipe recipe;
  final List<String> missingIngredients;
  final bool hasRequiredEquipment;
  final bool withinBudget;
  final bool matchesDietaryPreferences;

  RecipeMatch({
    required this.recipe,
    required this.missingIngredients,
    required this.hasRequiredEquipment,
    required this.withinBudget,
    required this.matchesDietaryPreferences,
  });

  // A recipe only counts as a "real" match if the person actually has
  // the equipment for it, it fits their budget, and it doesn't violate
  // a stated dietary preference. Missing ingredients are fine to show
  // (that's what the shopping list / "missing" label is for) - these
  // three are hard blockers, not soft ranking signals.
  bool get isCookable =>
      hasRequiredEquipment && withinBudget && matchesDietaryPreferences;
}

// Turns the set of equipment booleans saved during onboarding into a
// plain set of equipment names, so it can be compared against
// Recipe.equipmentNeeded (which is just a List<String>).
Set<String> ownedEquipmentFrom(OnboardingData data) {
  return {
    if (data.hasRiceCooker) 'Rice cooker',
    if (data.hasStove) 'Stove',
    if (data.hasMicrowave) 'Microwave',
    if (data.hasFridge) 'Fridge',
  };
}

// Checks a single recipe against the person's stated preferences.
// Each preference is a hard yes/no - if they said "vegetarian" and
// the recipe isn't, that's a real violation, not just a low score.
bool _matchesDietaryPreferences(Recipe recipe, Set<String> preferences) {
  if (preferences.contains('vegetarian') && !recipe.isVegetarian) {
    return false;
  }
  if (preferences.contains('halal') && !recipe.isHalal) {
    return false;
  }
  if (preferences.contains('no_vegetables') && recipe.containsVegetables) {
    return false;
  }
  return true;
}

// The real matching function. Pure - no UI, no async, no side effects -
// so it's easy to reason about and, later, easy to unit test.
//
// Ranking logic, in order:
// 1. Cookable recipes (have the equipment, fit the budget, match diet)
//    always rank above non-cookable ones, regardless of ingredient
//    overlap.
// 2. Within each group, more owned ingredients (fewer missing) ranks higher.
List<RecipeMatch> getRecommendations({
  required List<String> ownedIngredients,
  required Set<String> ownedEquipment,
  required double budget,
  Set<String> dietaryPreferences = const {},
  List<Recipe>? recipePool, // defaults to dummyRecipes, overridable for tests
}) {
  final recipes = recipePool ?? dummyRecipes;

  final matches = recipes.map((recipe) {
    final missing = recipe.ingredients
        .where((i) => !ownedIngredients.contains(i))
        .toList();

    final hasEquipment =
        recipe.equipmentNeeded.every((e) => ownedEquipment.contains(e));

    // Budget of 0 means "not set / skip this filter" rather than
    // "can't afford anything" - avoids hiding every recipe for users
    // who left the onboarding budget field blank.
    final withinBudget = budget <= 0 || recipe.estimatedCost <= budget;

    final matchesDiet =
        _matchesDietaryPreferences(recipe, dietaryPreferences);

    return RecipeMatch(
      recipe: recipe,
      missingIngredients: missing,
      hasRequiredEquipment: hasEquipment,
      withinBudget: withinBudget,
      matchesDietaryPreferences: matchesDiet,
    );
  }).toList();

  matches.sort((a, b) {
    if (a.isCookable != b.isCookable) {
      return a.isCookable ? -1 : 1;
    }
    return a.missingIngredients.length.compareTo(b.missingIngredients.length);
  });

  return matches;
}