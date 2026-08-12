import 'package:flutter/material.dart';
import '../data/ingredient_database.dart';
import '../logic/recipe_matcher.dart';
import '../services/preferences_service.dart';
import 'results_screen.dart';
import 'weekly_summary_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _preferencesService = PreferencesService();
  final TextEditingController _searchController = TextEditingController();

  // Keeps track of which ingredients the user has selected.
  final Set<String> selectedIngredients = {};

  // Currently selected category filter (null means "All").
  IngredientCategory? selectedCategory;

  // Search query text for filtering ingredients in real time.
  String searchQuery = '';

  // Loaded once when the screen opens.
  OnboardingData? onboardingData;

  @override
  void initState() {
    super.initState();
    _loadOnboardingData();
    _searchController.addListener(() {
      setState(() {
        searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOnboardingData() async {
    final data = await _preferencesService.loadOnboardingData();
    if (!mounted) return;
    setState(() => onboardingData = data);
  }

  void _goToResults() {
    final equipment = onboardingData != null
        ? ownedEquipmentFrom(onboardingData!)
        : <String>{};
    final budget = onboardingData?.weeklyBudget ?? 0;
    final preferences = onboardingData?.dietaryPreferences.toSet() ?? {};

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultsScreen(
          selectedIngredients: selectedIngredients.toList(),
          ownedEquipment: equipment,
          budget: budget,
          dietaryPreferences: preferences,
        ),
      ),
    );
  }

  void _toggleIngredient(String name) {
    setState(() {
      if (selectedIngredients.contains(name)) {
        selectedIngredients.remove(name);
      } else {
        selectedIngredients.add(name);
      }
    });
  }

  void _addCustomIngredient(String name) {
    if (name.isEmpty) return;
    setState(() {
      selectedIngredients.add(name);
      _searchController.clear();
      searchQuery = '';
    });
  }

  List<CategorizedIngredient> get _filteredIngredients {
    return categorizedIngredients.where((item) {
      final matchesCategory =
          selectedCategory == null || item.category == selectedCategory;
      final matchesSearch = searchQuery.isEmpty ||
          item.name.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredIngredients;
    final hasExactSearchMatch = searchQuery.isNotEmpty &&
        categorizedIngredients.any(
            (i) => i.name.toLowerCase() == searchQuery.toLowerCase());

    return Scaffold(
      appBar: AppBar(
        title: const Text('What do you have today?'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Weekly Summary',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const WeeklySummaryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search & Custom Input Field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search or add ingredient...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),

            // Active Selected Ingredients Bar (if any selected)
            if (selectedIngredients.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Selected (${selectedIngredients.length}):',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  TextButton(
                    onPressed: () => setState(() => selectedIngredients.clear()),
                    child: const Text('Clear all'),
                  ),
                ],
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: selectedIngredients.map((ingredient) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InputChip(
                        label: Text(ingredient),
                        selected: true,
                        onDeleted: () => _toggleIngredient(ingredient),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Category Filter Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: selectedCategory == null,
                    onSelected: (_) => setState(() => selectedCategory = null),
                  ),
                  const SizedBox(width: 6),
                  ...IngredientCategory.values.map((cat) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(cat.label),
                        selected: selectedCategory == cat,
                        onSelected: (selected) {
                          setState(() {
                            selectedCategory = selected ? cat : null;
                          });
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Ingredients Grid / List
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Option to add custom ingredient if searched item isn't an exact match
                    if (searchQuery.isNotEmpty && !hasExactSearchMatch) ...[
                      InkWell(
                        onTap: () => _addCustomIngredient(searchQuery),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.add_circle_outline, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Add "$searchQuery" as a custom ingredient',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (filteredList.isEmpty && searchQuery.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'No matching standard ingredients.\nTap above to add it as custom!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    ] else ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: filteredList.map((item) {
                          final isSelected =
                              selectedIngredients.contains(item.name);
                          return FilterChip(
                            label: Text(item.name),
                            selected: isSelected,
                            onSelected: (_) => _toggleIngredient(item.name),
                          );
                        }).toList(),
                      ),
                    ],

                    if (selectedIngredients.isEmpty) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline,
                                size: 20, color: Colors.blue),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Tap ingredients you have on hand to find what you can cook, or skip to see budget-friendly options.',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _goToResults,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    selectedIngredients.isEmpty
                        ? 'Find meals with what I have'
                        : 'Find meals (${selectedIngredients.length} ingredients)',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  selectedIngredients.clear();
                  _goToResults();
                },
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text("I have basically nothing"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}