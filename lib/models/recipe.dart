// Standard nutrition and cost constants for 1 cup of steamed white rice.
class SteamedRicePortion {
  static const double cost = 15.0;
  static const int calories = 200;
  static const double proteinGrams = 4.0;
  static const double carbsGrams = 45.0;
  static const double fatGrams = 0.5;
  static const String ingredientName = 'Steamed Rice';
  static const String quantity = '1 cup';
}

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
  final bool canPairWithRice;

  List<String> get ingredients =>
      detailedIngredients.map((e) => e.name).toList();

  List<String> get steps =>
      detailedSteps.map((s) => '${s.title}: ${s.description}').toList();

  double getCostWithRice({required bool pairWithRice}) =>
      (pairWithRice && canPairWithRice)
          ? estimatedCost + SteamedRicePortion.cost
          : estimatedCost;

  NutritionEstimate getNutritionWithRice({required bool pairWithRice}) {
    if (!pairWithRice || !canPairWithRice) return nutrition;
    return NutritionEstimate(
      calories: nutrition.calories + SteamedRicePortion.calories,
      proteinGrams: nutrition.proteinGrams + SteamedRicePortion.proteinGrams,
      carbsGrams: nutrition.carbsGrams + SteamedRicePortion.carbsGrams,
      fatGrams: nutrition.fatGrams + SteamedRicePortion.fatGrams,
    );
  }

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
    bool? canPairWithRice,
  })  : detailedIngredients = detailedIngredients ??
            (ingredients?.map((name) => IngredientSpec(name: name)).toList() ??
                const []),
        detailedSteps = detailedSteps ??
            (steps
                    ?.map((s) => RecipeStep(title: 'Step', description: s))
                    .toList() ??
                const []),
        canPairWithRice = canPairWithRice ??
            !((ingredients ??
                    detailedIngredients?.map((e) => e.name).toList() ??
                    [])
                .any((i) {
              final lower = i.toLowerCase();
              return lower.contains('rice') ||
                  lower.contains('bread') ||
                  lower.contains('toast') ||
                  lower.contains('noodle') ||
                  lower.contains('ramen') ||
                  lower.contains('macaroni') ||
                  lower.contains('pasta');
            }));
}