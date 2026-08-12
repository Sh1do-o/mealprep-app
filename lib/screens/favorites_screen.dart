import 'package:flutter/material.dart';
import '../data/dummy_recipes.dart';
import '../models/recipe.dart';
import '../services/preferences_service.dart';
import 'recipe_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _preferencesService = PreferencesService();

  bool _isLoading = true;
  Set<String> _favoriteIds = {};
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final favs = await _preferencesService.loadFavoriteRecipeIds();
    if (!mounted) return;
    setState(() {
      _favoriteIds = favs;
      _isLoading = false;
    });
  }

  void _removeFavorite(String recipeId) async {
    await _preferencesService.toggleFavoriteRecipe(recipeId);
    await _loadFavorites();
  }

  List<Recipe> get _favoriteRecipes {
    final Map<String, Recipe> recipeMap = {
      for (var r in dummyRecipes) r.id: r
    };

    final list = _favoriteIds
        .map((id) => recipeMap[id])
        .whereType<Recipe>()
        .toList();

    if (_searchQuery.isEmpty) return list;
    return list
        .where((r) => r.title.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final favorites = _favoriteRecipes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Favorites'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_favoriteIds.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search saved recipes...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                Expanded(
                  child: _favoriteIds.isEmpty
                      ? _buildEmptyState()
                      : favorites.isEmpty
                          ? const Center(
                              child: Text('No saved meals match your search.'),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: favorites.length,
                              itemBuilder: (context, index) {
                                final recipe = favorites[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(12),
                                    leading: CircleAvatar(
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer,
                                      child: const Icon(Icons.favorite,
                                          color: Colors.red, size: 20),
                                    ),
                                    title: Text(
                                      recipe.title,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      '${recipe.prepTime} • ₱${recipe.estimatedCost.toInt()} • ${recipe.nutrition.calories} kcal',
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.favorite,
                                          color: Colors.red),
                                      tooltip: 'Remove from Favorites',
                                      onPressed: () =>
                                          _removeFavorite(recipe.id),
                                    ),
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => RecipeDetailScreen(
                                            recipe: recipe,
                                          ),
                                        ),
                                      );
                                      _loadFavorites();
                                    },
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Favorites Saved Yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the heart icon on any recipe detail screen to save your go-to dorm meals for fast access!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
