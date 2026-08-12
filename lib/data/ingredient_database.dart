enum IngredientCategory {
  proteins('Proteins'),
  grains('Grains & Carbs'),
  vegetables('Vegetables & Produce'),
  condiments('Condiments & Flavors'),
  dairyPantry('Dairy & Pantry');

  final String label;
  const IngredientCategory(this.label);
}

class CategorizedIngredient {
  final String name;
  final IngredientCategory category;

  const CategorizedIngredient({
    required this.name,
    required this.category,
  });
}

// Master list of ingredients categorized for quick lookup, filtering, and search.
const List<CategorizedIngredient> categorizedIngredients = [
  // Proteins
  CategorizedIngredient(name: 'Egg', category: IngredientCategory.proteins),
  CategorizedIngredient(name: 'Canned tuna', category: IngredientCategory.proteins),
  CategorizedIngredient(name: 'Canned corned beef', category: IngredientCategory.proteins),
  CategorizedIngredient(name: 'Chicken', category: IngredientCategory.proteins),
  CategorizedIngredient(name: 'Tofu', category: IngredientCategory.proteins),
  CategorizedIngredient(name: 'Canned sardines', category: IngredientCategory.proteins),
  CategorizedIngredient(name: 'Luncheon meat', category: IngredientCategory.proteins),
  CategorizedIngredient(name: 'Canned pork and beans', category: IngredientCategory.proteins),

  // Grains & Carbs
  CategorizedIngredient(name: 'Rice', category: IngredientCategory.grains),
  CategorizedIngredient(name: 'Instant noodles', category: IngredientCategory.grains),
  CategorizedIngredient(name: 'Bread', category: IngredientCategory.grains),
  CategorizedIngredient(name: 'Pasta', category: IngredientCategory.grains),
  CategorizedIngredient(name: 'Oats', category: IngredientCategory.grains),

  // Vegetables & Produce
  CategorizedIngredient(name: 'Onion', category: IngredientCategory.vegetables),
  CategorizedIngredient(name: 'Green onion', category: IngredientCategory.vegetables),
  CategorizedIngredient(name: 'Garlic', category: IngredientCategory.vegetables),
  CategorizedIngredient(name: 'Kimchi', category: IngredientCategory.vegetables),
  CategorizedIngredient(name: 'Banana', category: IngredientCategory.vegetables),
  CategorizedIngredient(name: 'Cabbage', category: IngredientCategory.vegetables),
  CategorizedIngredient(name: 'Carrot', category: IngredientCategory.vegetables),
  CategorizedIngredient(name: 'Ginger', category: IngredientCategory.vegetables),
  CategorizedIngredient(name: 'Canned sweet corn', category: IngredientCategory.vegetables),
  CategorizedIngredient(name: 'Canned mushrooms', category: IngredientCategory.vegetables),

  // Condiments & Flavors
  CategorizedIngredient(name: 'Soy sauce', category: IngredientCategory.condiments),
  CategorizedIngredient(name: 'Mayo', category: IngredientCategory.condiments),
  CategorizedIngredient(name: 'Cooking oil', category: IngredientCategory.condiments),
  CategorizedIngredient(name: 'Sesame oil', category: IngredientCategory.condiments),
  CategorizedIngredient(name: 'Vinegar', category: IngredientCategory.condiments),
  CategorizedIngredient(name: 'Black pepper', category: IngredientCategory.condiments),
  CategorizedIngredient(name: 'Tomato sauce', category: IngredientCategory.condiments),
  CategorizedIngredient(name: 'Honey', category: IngredientCategory.condiments),
  CategorizedIngredient(name: 'Chili garlic oil', category: IngredientCategory.condiments),
  CategorizedIngredient(name: 'Peanut butter', category: IngredientCategory.condiments),

  // Dairy & Pantry
  CategorizedIngredient(name: 'Cheese', category: IngredientCategory.dairyPantry),
  CategorizedIngredient(name: 'Milk', category: IngredientCategory.dairyPantry),
  CategorizedIngredient(name: 'All-purpose cream', category: IngredientCategory.dairyPantry),
];
