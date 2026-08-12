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

// Represents a specific ingredient and its student-friendly substitutes.
class IngredientSpec {
  final String name;
  final List<String> substitutes;
  final String? substitutionNote;

  const IngredientSpec({
    required this.name,
    this.substitutes = const [],
    this.substitutionNote,
  });
}

// Simple difficulty label shown as a badge on the recipe detail screen.
enum Difficulty { easy, medium, hard }

// This class represents a single recipe.
class Recipe {
  final String id;
  final String title;
  final String prepTime; // e.g. "15 mins"
  final double estimatedCost; // in PHP
  final List<String> equipmentNeeded; // e.g. ["Rice cooker"]
  final List<IngredientSpec> detailedIngredients;
  final List<String> steps;
  final NutritionEstimate nutrition; // defaults to all-zero if not provided
  final Difficulty difficulty;

  final bool isVegetarian;
  final bool isHalal;
  final bool containsVegetables;

  // Convenient getter for simple string list of ingredient names.
  List<String> get ingredients =>
      detailedIngredients.map((e) => e.name).toList();

  Recipe({
    required this.id,
    required this.title,
    required this.prepTime,
    required this.estimatedCost,
    required this.equipmentNeeded,
    List<IngredientSpec>? detailedIngredients,
    List<String>? ingredients,
    required this.steps,
    this.nutrition = const NutritionEstimate(),
    this.difficulty = Difficulty.easy,
    this.isVegetarian = false,
    this.isHalal = true,
    this.containsVegetables = false,
  }) : detailedIngredients = detailedIngredients ??
            (ingredients?.map((name) => IngredientSpec(name: name)).toList() ??
                const []);
}