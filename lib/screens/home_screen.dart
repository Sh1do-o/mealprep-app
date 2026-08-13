import 'package:flutter/material.dart';
import '../data/ingredient_database.dart';
import '../logic/recipe_matcher.dart';
import '../services/preferences_service.dart';
import '../theme/app_theme.dart';
import 'recipe_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PreferencesService _prefs = PreferencesService();
  final Set<String> selectedPantryIngredients = {};
  String activeTimeFilter = '30+ min';
  String searchQuery = '';
  IngredientCategory? selectedCategoryFilter;

  Set<String> _ownedEquipment = {};
  double _weeklyBudget = 500;
  Set<String> _dietaryPreferences = {};
  bool _alwaysPairWithRice = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final onboarding = await _prefs.loadOnboardingData();
    final pairRice = await _prefs.loadAlwaysPairWithRice();
    if (!mounted) return;
    setState(() {
      _alwaysPairWithRice = pairRice;
      if (onboarding != null) {
        _ownedEquipment = ownedEquipmentFrom(onboarding);
        _weeklyBudget = onboarding.weeklyBudget;
        _dietaryPreferences = onboarding.dietaryPreferences.toSet();
      } else {
        _ownedEquipment = {'Stove', 'Microwave', 'Rice cooker', 'Fridge'};
      }
      _isLoading = false;
    });
  }

  void _togglePantryIngredient(String item) {
    setState(() {
      if (selectedPantryIngredients.contains(item)) {
        selectedPantryIngredients.remove(item);
      } else {
        selectedPantryIngredients.add(item);
      }
    });
  }

  List<RecipeMatch> _getFilteredMatches() {
    final matches = getRecommendations(
      ownedIngredients: selectedPantryIngredients.toList(),
      ownedEquipment: _ownedEquipment,
      budget: _weeklyBudget,
      dietaryPreferences: _dietaryPreferences,
      alwaysPairWithRice: _alwaysPairWithRice,
    );

    return matches.where((m) {
      if (activeTimeFilter == '30+ min') return true;
      final prepMin = int.tryParse(m.recipe.prepTime.replaceAll(RegExp(r'[^0-9]'), '')) ?? 15;
      if (activeTimeFilter == '5 min') return prepMin <= 5;
      if (activeTimeFilter == '15 min') return prepMin <= 15;
      return true;
    }).toList();
  }

  List<CategorizedIngredient> _getFilteredIngredients() {
    return categorizedIngredients.where((item) {
      final matchesSearch = item.name.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesCategory = selectedCategoryFilter == null || item.category == selectedCategoryFilter;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(AppConfig.appName)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final filteredMatches = _getFilteredMatches();
    final availableIngredients = _getFilteredIngredients();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.soup_kitchen, color: theme.colorScheme.primary, size: 24),
            const SizedBox(width: 8),
            Text(
              AppConfig.appName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Clear Pantry Selection',
            onPressed: () {
              setState(() {
                selectedPantryIngredients.clear();
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              selectedPantryIngredients.isEmpty
                  ? 'What Can I Cook Right Now?'
                  : 'What\'s in your pantry?',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              selectedPantryIngredients.isEmpty
                  ? 'Search and tap ingredients you currently have on hand.'
                  : 'Selected ${selectedPantryIngredients.length} ingredient(s) in pantry.',
              style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),

            // Search Bar for full ingredient database (Q2: Option A)
            TextField(
              decoration: InputDecoration(
                hintText: 'Search ingredients (e.g. Eggs, Soy Sauce, Rice)...',
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) {
                setState(() => searchQuery = val);
              },
            ),
            const SizedBox(height: 12),

            // Category Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All Categories'),
                    selected: selectedCategoryFilter == null,
                    onSelected: (_) => setState(() => selectedCategoryFilter = null),
                  ),
                  const SizedBox(width: 8),
                  ...IngredientCategory.values.map((cat) {
                    final isSelected = selectedCategoryFilter == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat.name.toUpperCase()),
                        selected: isSelected,
                        onSelected: (_) => setState(() => selectedCategoryFilter = isSelected ? null : cat),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Ingredient Selector Chips (dynamic from database + search) - Wrapped for multiple lines
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableIngredients.map((item) {
                final isSelected = selectedPantryIngredients.contains(item.name);
                return FilterChip(
                  avatar: isSelected
                      ? Icon(Icons.check, size: 16, color: theme.colorScheme.onPrimaryContainer)
                      : Icon(Icons.water_drop_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                  label: Text(item.name),
                  selected: isSelected,
                  selectedColor: theme.colorScheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (_) => _togglePantryIngredient(item.name),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Time to Cook Filter Bar
            if (selectedPantryIngredients.isNotEmpty) ...[
              const Text(
                'Time to Cook',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: ['5 min', '15 min', '30+ min'].map((time) {
                    final isSelected = activeTimeFilter == time;
                    return Expanded(
                      child: InkWell(
                        onTap: () => setState(() => activeTimeFilter = time),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? theme.colorScheme.surfaceContainerHighest : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected ? Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.5)) : null,
                          ),
                          child: Text(
                            time,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Filipino Rice Preference Toggle Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _alwaysPairWithRice
                      ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                      : theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _alwaysPairWithRice
                        ? theme.colorScheme.primary.withValues(alpha: 0.5)
                        : theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Text('🍚', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Always Pair Ulam with Rice',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            'Auto-adds 1 cup rice (+₱15 • 200 kcal) to viands',
                            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _alwaysPairWithRice,
                      onChanged: (val) async {
                        setState(() => _alwaysPairWithRice = val);
                        await _prefs.saveAlwaysPairWithRice(val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Suggestions Header with real match count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Suggestions',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${filteredMatches.length} Found',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Recipe Suggestions List Cards with real RecipeMatch calculations
              filteredMatches.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No recipes match your current time filter.',
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredMatches.length,
                      itemBuilder: (context, index) {
                        final match = filteredMatches[index];
                        final recipe = match.recipe;
                        final isPerfectMatch = match.missingIngredients.isEmpty;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isPerfectMatch
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline.withValues(alpha: 0.3),
                              width: isPerfectMatch ? 1.5 : 1,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RecipeDetailScreen(
                                    recipe: recipe,
                                    initialPairWithRice: match.isPairedWithRice,
                                  ),
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Stack(
                                  children: [
                                    Image.network(
                                      recipe.imageUrl,
                                      height: 160,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        height: 160,
                                        color: theme.colorScheme.surfaceContainerHighest,
                                        child: const Icon(Icons.restaurant, size: 40),
                                      ),
                                    ),
                                    Positioned(
                                      top: 12,
                                      left: 12,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: isPerfectMatch ? theme.colorScheme.secondary : Colors.black87,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isPerfectMatch ? Icons.star : Icons.warning_amber_rounded,
                                              size: 14,
                                              color: Colors.black,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              isPerfectMatch ? '⭐ Perfect Match' : '⚠️ Missing ${match.missingIngredients.length}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (match.isPairedWithRice)
                                      Positioned(
                                        top: 12,
                                        right: 12,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primaryContainer,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Text('🍚', style: TextStyle(fontSize: 12)),
                                              const SizedBox(width: 4),
                                              Text(
                                                '+ Rice',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: theme.colorScheme.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        recipe.title,
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.surfaceContainerHighest,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.access_time, size: 14),
                                                const SizedBox(width: 4),
                                                Text(recipe.prepTime, style: const TextStyle(fontSize: 12)),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.surfaceContainerHighest,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.microwave, size: 14),
                                                const SizedBox(width: 4),
                                                Text(
                                                  recipe.equipmentNeeded.isNotEmpty ? recipe.equipmentNeeded.join(', ') : 'No equipment',
                                                  style: const TextStyle(fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            '₱${match.effectiveCost.round()}',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w800,
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(
                                              text: isPerfectMatch ? 'You have: ' : 'Missing: ',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: isPerfectMatch ? theme.colorScheme.onSurface : theme.colorScheme.secondary,
                                              ),
                                            ),
                                            TextSpan(
                                              text: isPerfectMatch
                                                  ? recipe.ingredients.join(', ')
                                                  : match.missingIngredients.join(', '),
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: theme.colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ] else ...[
              // Empty State
              const SizedBox(height: 40),
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainer,
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                          ),
                          child: Icon(
                            Icons.kitchen,
                            size: 64,
                            color: theme.colorScheme.primary.withValues(alpha: 0.5),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.colorScheme.primary),
                          ),
                          child: Icon(Icons.search, size: 24, color: theme.colorScheme.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Your pantry is feeling a bit lonely.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Search or tap ingredients above to see what delicious meals you can cook with your equipment!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant, height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Icon(
                      Icons.arrow_upward_rounded,
                      size: 32,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}