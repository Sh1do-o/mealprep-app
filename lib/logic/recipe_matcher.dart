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

bool _isIngredientMatch(String specName, Set<String> ownedSetLower) {
  final specLower = specName.toLowerCase();
  for (final owned in ownedSetLower) {
    if (specLower == owned) return true;
    if (specLower.contains(owned) || owned.contains(specLower)) return true;
    if (specLower.endsWith('s') && specLower.substring(0, specLower.length - 1) == owned) return true;
    if (owned.endsWith('s') && owned.substring(0, owned.length - 1) == specLower) return true;
    if (specLower.endsWith('es') && specLower.substring(0, specLower.length - 2) == owned) return true;
    if (owned.endsWith('es') && owned.substring(0, owned.length - 2) == specLower) return true;
  }
  return false;
}

bool _hasRequiredEquipment(List<String> equipmentNeeded, Set<String> ownedEquipLower) {
  if (equipmentNeeded.isEmpty) return true;
  for (final equip in equipmentNeeded) {
    final equipLower = equip.toLowerCase();
    if (ownedEquipLower.contains(equipLower)) continue;
    if ({'skillet', 'pan', 'frying pan', 'pot'}.contains(equipLower) && ownedEquipLower.contains('stove')) continue;
    if ({'kettle'}.contains(equipLower) && ownedEquipLower.contains('electric kettle')) continue;
    if ({'mug', 'heat-safe bowl'}.contains(equipLower) && ownedEquipLower.contains('microwave')) continue;
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
      .where((recipe) => _hasRequiredEquipment(recipe.equipmentNeeded, ownedEquipLower))
      .map((recipe) {
        final missing = <String>[];
        final substitutions = <String, String>{};

        for (final spec in recipe.detailedIngredients) {
          final hasIngredient = _isIngredientMatch(spec.name, ownedSetLower);

          if (!hasIngredient) {
            missing.add(spec.name);

            // 1. Check recipe-specific substitutes
            String? foundSub;
            for (final sub in spec.substitutes) {
              if (_isIngredientMatch(sub, ownedSetLower)) {
                foundSub = sub;
                break;
              }
            }

            // 2. Check global fallback database if not found in recipe spec
            if (foundSub == null) {
              final globalSub = findGlobalSubstitution(spec.name);
              if (globalSub != null) {
                for (final sub in globalSub.substitutes) {
                  if (_isIngredientMatch(sub, ownedSetLower)) {
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

        final hasEquipment = _hasRequiredEquipment(recipe.equipmentNeeded, ownedEquipLower);
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

  // If user selected ingredients, exclude recipes with 0 matching ingredients and 0 substitutes
  if (ownedIngredients.isNotEmpty) {
    matches.removeWhere((match) =>
        match.missingIngredients.length == match.recipe.detailedIngredients.length &&
        match.substitutionsAvailable.isEmpty);
  }

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