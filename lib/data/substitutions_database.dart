class DefaultSubstitution {
  final String ingredientName;
  final List<String> substitutes;
  final String tip;

  const DefaultSubstitution({
    required this.ingredientName,
    required this.substitutes,
    required this.tip,
  });
}

/// Global fallback database for common student food substitutions.
const List<DefaultSubstitution> globalSubstitutions = [
  DefaultSubstitution(
    ingredientName: 'Soy sauce',
    substitutes: ['Fish sauce', 'Salt', 'Chili garlic oil'],
    tip: 'Fish sauce or salt provides a quick salty umami substitute.',
  ),
  DefaultSubstitution(
    ingredientName: 'Green onion',
    substitutes: ['Onion', 'Garlic'],
    tip: 'Finely chopped onion works as a great fresh aromatic garnish.',
  ),
  DefaultSubstitution(
    ingredientName: 'Cooking oil',
    substitutes: ['Sesame oil', 'Mayo'],
    tip: 'A small dab of mayo or sesame oil works well for light pan-cooking.',
  ),
  DefaultSubstitution(
    ingredientName: 'Canned tuna',
    substitutes: ['Canned sardines', 'Egg', 'Canned corned beef', 'Tofu'],
    tip: 'Sardines or scrambled eggs offer quick protein alternatives.',
  ),
  DefaultSubstitution(
    ingredientName: 'Kimchi',
    substitutes: ['Cabbage', 'Vinegar'],
    tip: 'Sauteed cabbage with a splash of vinegar gives a sharp fresh tang.',
  ),
  DefaultSubstitution(
    ingredientName: 'Mayo',
    substitutes: ['All-purpose cream', 'Cheese'],
    tip: 'Cream or melted cheese provides creamy rich texture.',
  ),
  DefaultSubstitution(
    ingredientName: 'Honey',
    substitutes: ['Sugar', 'Condensed milk'],
    tip: 'A pinch of sugar or condensed milk adds quick sweetness.',
  ),
];

DefaultSubstitution? findGlobalSubstitution(String ingredientName) {
  final nameLower = ingredientName.toLowerCase();
  for (final sub in globalSubstitutions) {
    if (sub.ingredientName.toLowerCase() == nameLower) {
      return sub;
    }
  }
  return null;
}
