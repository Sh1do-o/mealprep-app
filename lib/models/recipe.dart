// Rough nutrition estimate for one serving of a recipe.
// Values are placeholders for now (real sourcing comes later,
// e.g. from a public nutrition database per ingredient).
// Kept as a *separate* class so it's easy to leave empty/zero
// on recipes you haven't researched yet, without breaking anything.
class NutritionEstimate {
  final int calories;
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;

  const NutritionEstimate({
    this.calories = 0,
    this.proteinGrams = 0,
    this.carbsGrams = 0,
    this.fatGrams = 0,
  });
}

// Simple difficulty label shown as a badge on the recipe detail screen.
enum Difficulty { easy, medium, hard }

// This class represents a single recipe.
// Think of it as a blueprint: every recipe in our app will have
// these exact pieces of information.
class Recipe {
  final String id;
  final String title;
  final String prepTime; // e.g. "15 mins"
  final double estimatedCost; // in PHP
  final List<String> equipmentNeeded; // e.g. ["Rice cooker"]
  final List<String> ingredients; // e.g. ["Rice", "Egg", "Soy sauce"]
  final List<String> steps;
  final NutritionEstimate nutrition; // defaults to all-zero if not provided
  final Difficulty difficulty;

  // Dietary flags, kept as simple booleans rather than a generic tag
  // list - there are only a few restrictions that actually change
  // whether a recipe is a valid suggestion, so explicit fields are
  // easier to get right than a loosely-typed string tag system.
  final bool isVegetarian;
  final bool isHalal;
  final bool containsVegetables;

  const Recipe({
    required this.id,
    required this.title,
    required this.prepTime,
    required this.estimatedCost,
    required this.equipmentNeeded,
    required this.ingredients,
    required this.steps,
    this.nutrition = const NutritionEstimate(),
    this.difficulty = Difficulty.easy,
    this.isVegetarian = false,
    // Defaults to true since none of our recipes contain pork/alcohol
    // yet - flip explicitly to false per-recipe once that changes.
    this.isHalal = true,
    this.containsVegetables = false,
  });
}