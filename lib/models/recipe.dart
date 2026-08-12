// Rough nutrition estimate for one serving of a recipe.
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

// Represents a specific ingredient, its quantity display, and student-friendly substitutes.
class IngredientSpec {
  final String name;
  final String? quantity; // e.g. "1 packet", "1 can (drained)"
  final double? priceEstimate; // in PHP
  final List<String> substitutes;
  final String? substitutionNote;

  const IngredientSpec({
    required this.name,
    this.quantity,
    this.priceEstimate,
    this.substitutes = const [],
    this.substitutionNote,
  });

  String get fullDisplay => quantity != null ? '$quantity $name' : name;
}

enum Difficulty { easy, medium, hard }
enum MealType { breakfast, lunch, dinner }

class RecipeStep {
  final String title;
  final String description;

  const RecipeStep({
    required this.title,
    required this.description,
  });
}

// Represents a single recipe with full visual and nutritional spec.
class Recipe {
  final String id;
  final String title;
  final String imageUrl;
  final String prepTime; // e.g. "10 min"
  final double estimatedCost; // in PHP
  final List<String> equipmentNeeded; // e.g. ["Rice cooker"]
  final List<IngredientSpec> detailedIngredients;
  final List<RecipeStep> detailedSteps;
  final NutritionEstimate nutrition;
  final Difficulty difficulty;
  final MealType mealType;

  final bool isVegetarian;
  final bool isHalal;
  final bool containsVegetables;

  List<String> get ingredients =>
      detailedIngredients.map((e) => e.name).toList();

  List<String> get steps =>
      detailedSteps.map((s) => '${s.title}: ${s.description}').toList();

  Recipe({
    required this.id,
    required this.title,
    this.imageUrl = '',
    required this.prepTime,
    required this.estimatedCost,
    required this.equipmentNeeded,
    List<IngredientSpec>? detailedIngredients,
    List<String>? ingredients,
    List<RecipeStep>? detailedSteps,
    List<String>? steps,
    this.nutrition = const NutritionEstimate(),
    this.difficulty = Difficulty.easy,
    this.mealType = MealType.lunch,
    this.isVegetarian = false,
    this.isHalal = true,
    this.containsVegetables = false,
  })  : detailedIngredients = detailedIngredients ??
            (ingredients?.map((name) => IngredientSpec(name: name)).toList() ??
                const []),
        detailedSteps = detailedSteps ??
            (steps
                    ?.map((s) => RecipeStep(title: 'Step', description: s))
                    .toList() ??
                const []);
}