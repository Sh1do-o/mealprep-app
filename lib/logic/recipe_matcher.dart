import '../data/dummy_recipes.dart';
import '../data/substitutions_database.dart';
import '../models/recipe.dart';
import '../services/preferences_service.dart';

// A recipe plus how well it matched, including available ingredient substitutes.
class RecipeMatch {
  final Recipe recipe;
  final List<String> missingIngredients;
  final Map<String, String> substitutionsAvailable; // missing -> substitute in pantry
  final bool hasRequiredEquipment;
  final bool withinBudget;
  final bool matchesDietaryPreferences;

  RecipeMatch({
    required this.recipe,
    required this.missingIngredients,
    this.substitutionsAvailable = const {},
    required this.hasRequiredEquipment,
    required this.withinBudget,
    required this.matchesDietaryPreferences,
  });

  bool get isCookable =>
      hasRequiredEquipment && withinBudget && matchesDietaryPreferences;

  bool get isCookableWithSubstitutes =>
      isCookable &&
      missingIngredients.isNotEmpty &&
      missingIngredients.every((m) => substitutionsAvailable.containsKey(m));

  int get unreplaceableMissingCount =>
      missingIngredients.length - substitutionsAvailable.length;
}

Set<String> ownedEquipmentFrom(OnboardingData data) {
  return {
    if (data.hasRiceCooker) 'Rice cooker',
    if (data.hasStove) 'Stove',
    if (data.hasMicrowave) 'Microwave',
    if (data.hasFridge) 'Fridge',
    if (data.hasElectricKettle) 'Electric Kettle',
  };
}

bool _matchesDietaryPreferences(Recipe recipe, Set<String> preferences) {
  final prefLower = preferences.map((p) => p.toLowerCase()).toSet();
  if (prefLower.contains('vegetarian') && !recipe.isVegetarian) {
    return false;
  }
  if (prefLower.contains('halal') && !recipe.isHalal) {
    return false;
  }
  if (prefLower.contains('no_vegetables') && recipe.containsVegetables) {
    return false;
  }
  if (prefLower.contains('no-vegetables') && recipe.containsVegetables) {
    return false;
  }
  return true;
}

List<RecipeMatch> getRecommendations({
  required List<String> ownedIngredients,
  required Set<String> ownedEquipment,
  required double budget,
  Set<String> dietaryPreferences = const {},
  List<Recipe>? recipePool,
}) {
  final recipes = recipePool ?? dummyRecipes;
  final ownedSetLower = ownedIngredients.map((i) => i.toLowerCase()).toSet();
  final ownedEquipLower = ownedEquipment.map((e) => e.toLowerCase()).toSet();

  final matches = recipes
      .where((recipe) {
        // Strict appliance filter: if user doesn't own equipment, don't suggest the recipe
        if (recipe.equipmentNeeded.isEmpty) return true;
        return recipe.equipmentNeeded.every(
          (e) => ownedEquipLower.contains(e.toLowerCase()),
        );
      })
      .map((recipe) {
        final missing = <String>[];
        final substitutions = <String, String>{};

        for (final spec in recipe.detailedIngredients) {
          final nameLower = spec.name.toLowerCase();
          final hasIngredient = ownedSetLower.contains(nameLower);

          if (!hasIngredient) {
            missing.add(spec.name);

            // 1. Check recipe-specific substitutes
            String? foundSub;
            for (final sub in spec.substitutes) {
              if (ownedSetLower.contains(sub.toLowerCase())) {
                foundSub = sub;
                break;
              }
            }

            // 2. Check global fallback database if not found in recipe spec
            if (foundSub == null) {
              final globalSub = findGlobalSubstitution(spec.name);
              if (globalSub != null) {
                for (final sub in globalSub.substitutes) {
                  if (ownedSetLower.contains(sub.toLowerCase())) {
                    foundSub = sub;
                    break;
                  }
                }
              }
            }

            if (foundSub != null) {
              substitutions[spec.name] = foundSub;
            }
          }
        }

        final hasEquipment = recipe.equipmentNeeded.every(
          (e) => ownedEquipLower.contains(e.toLowerCase()),
        );
        final withinBudget = budget <= 0 || recipe.estimatedCost <= budget;
        final matchesDiet =
            _matchesDietaryPreferences(recipe, dietaryPreferences);

        return RecipeMatch(
          recipe: recipe,
          missingIngredients: missing,
          substitutionsAvailable: substitutions,
          hasRequiredEquipment: hasEquipment,
          withinBudget: withinBudget,
          matchesDietaryPreferences: matchesDiet,
        );
      })
      .toList();

  matches.sort((a, b) {
    if (a.isCookable != b.isCookable) {
      return a.isCookable ? -1 : 1;
    }
    if (a.unreplaceableMissingCount != b.unreplaceableMissingCount) {
      return a.unreplaceableMissingCount.compareTo(b.unreplaceableMissingCount);
    }
    return a.missingIngredients.length.compareTo(b.missingIngredients.length);
  });

  return matches;
}