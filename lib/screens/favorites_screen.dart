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
    final theme = Theme.of(context);
    final favorites = _favoriteRecipes;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.favorite, color: Colors.redAccent, size: 22),
            const SizedBox(width: 8),
            const Text(
              'Saved Favorites',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
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
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                    ),
                  ),
                Expanded(
                  child: _favoriteIds.isEmpty
                      ? _buildEmptyState(context)
                      : favorites.isEmpty
                          ? const Center(
                              child: Text('No saved meals match your search.'),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: favorites.length,
                              itemBuilder: (context, index) {
                                final recipe = favorites[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainer,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: InkWell(
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
                                    child: Row(
                                      children: [
                                        Image.network(
                                          recipe.imageUrl,
                                          width: 100,
                                          height: 90,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            width: 100,
                                            height: 90,
                                            color: theme.colorScheme.surfaceContainerHighest,
                                            child: const Icon(Icons.restaurant),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                recipe.title,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold, fontSize: 16),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${recipe.prepTime} • ₱${recipe.estimatedCost.toInt()} • ${recipe.nutrition.calories} kcal',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: theme.colorScheme.onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.favorite, color: Colors.redAccent),
                                          tooltip: 'Remove from Favorites',
                                          onPressed: () => _removeFavorite(recipe.id),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Favorites Saved Yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the heart icon on any recipe detail screen to save your go-to dorm meals for fast access!',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
