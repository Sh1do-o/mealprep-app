import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// A single small record of "this recipe was cooked at this time".
// Kept intentionally simple - just enough for a future weekly summary
// to sum up later. Not full nutrition/cost history yet.
class CookedEntry {
  final String recipeId;
  final String recipeTitle;
  final DateTime cookedAt;

  CookedEntry({
    required this.recipeId,
    required this.recipeTitle,
    required this.cookedAt,
  });

  Map<String, dynamic> toJson() => {
        'recipeId': recipeId,
        'recipeTitle': recipeTitle,
        'cookedAt': cookedAt.toIso8601String(),
      };

  factory CookedEntry.fromJson(Map<String, dynamic> json) => CookedEntry(
        recipeId: json['recipeId'] as String,
        recipeTitle: json['recipeTitle'] as String,
        cookedAt: DateTime.parse(json['cookedAt'] as String),
      );
}

// Everything the onboarding screen collects, bundled together so it's
// one save/load call instead of five separate keys to keep in sync.
class OnboardingData {
  final bool hasRiceCooker;
  final bool hasStove;
  final bool hasMicrowave;
  final bool hasFridge;
  final bool hasElectricKettle;
  final double weeklyBudget;
  final List<String> dietaryPreferences; // e.g. ["vegetarian", "halal"]

  const OnboardingData({
    required this.hasRiceCooker,
    required this.hasStove,
    required this.hasMicrowave,
    required this.hasFridge,
    this.hasElectricKettle = false,
    required this.weeklyBudget,
    this.dietaryPreferences = const [],
  });

  Map<String, dynamic> toJson() => {
        'hasRiceCooker': hasRiceCooker,
        'hasStove': hasStove,
        'hasMicrowave': hasMicrowave,
        'hasFridge': hasFridge,
        'hasElectricKettle': hasElectricKettle,
        'weeklyBudget': weeklyBudget,
        'dietaryPreferences': dietaryPreferences,
      };

  factory OnboardingData.fromJson(Map<String, dynamic> json) =>
      OnboardingData(
        hasRiceCooker: json['hasRiceCooker'] as bool,
        hasStove: json['hasStove'] as bool,
        hasMicrowave: json['hasMicrowave'] as bool,
        hasFridge: json['hasFridge'] as bool,
        hasElectricKettle: (json['hasElectricKettle'] as bool?) ?? false,
        weeklyBudget: (json['weeklyBudget'] as num).toDouble(),
        // Falls back to empty if loading data saved before this field
        // existed, instead of crashing on old saved onboarding data.
        dietaryPreferences: (json['dietaryPreferences'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
      );
}

// All local storage for the app goes through this class.
// Keeping it in one place means screens never call
// SharedPreferences directly, so if we ever swap to a real
// backend later, only this file needs to change.
class PreferencesService {
  static const _onboardingKey = 'onboarding_data';
  static const _cookedHistoryKey = 'cooked_history';

  Future<void> saveOnboardingData(OnboardingData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_onboardingKey, jsonEncode(data.toJson()));
  }

  Future<OnboardingData?> loadOnboardingData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_onboardingKey);
    if (raw == null) return null;
    return OnboardingData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_onboardingKey);
  }

  Future<void> addCookedEntry(CookedEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await loadCookedHistory();
    history.add(entry);
    final rawList = history.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_cookedHistoryKey, rawList);
  }

  Future<List<CookedEntry>> loadCookedHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_cookedHistoryKey) ?? [];
    return rawList
        .map((raw) => CookedEntry.fromJson(jsonDecode(raw) as Map<String, dynamic>))
        .toList();
  }

  static const _weeklyPlanKey = 'weekly_plan_recipe_ids';
  static const _checkedShoppingItemsKey = 'checked_shopping_items';
  static const _favoriteRecipesKey = 'favorite_recipe_ids';

  Future<void> saveWeeklyPlanRecipeIds(List<String> recipeIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_weeklyPlanKey, recipeIds);
  }

  Future<List<String>?> loadWeeklyPlanRecipeIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_weeklyPlanKey);
  }

  Future<void> saveCheckedShoppingItems(Set<String> itemNames) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_checkedShoppingItemsKey, itemNames.toList());
  }

  Future<Set<String>> loadCheckedShoppingItems() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_checkedShoppingItemsKey) ?? [];
    return rawList.toSet();
  }

  Future<void> saveFavoriteRecipeIds(Set<String> recipeIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoriteRecipesKey, recipeIds.toList());
  }

  Future<Set<String>> loadFavoriteRecipeIds() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_favoriteRecipesKey) ?? [];
    return rawList.toSet();
  }

  Future<bool> toggleFavoriteRecipe(String recipeId) async {
    final favorites = await loadFavoriteRecipeIds();
    final isFav = favorites.contains(recipeId);
    if (isFav) {
      favorites.remove(recipeId);
    } else {
      favorites.add(recipeId);
    }
    await saveFavoriteRecipeIds(favorites);
    return !isFav;
  }

  // Mostly useful for testing / a future "reset app" button in Profile.
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_onboardingKey);
    await prefs.remove(_cookedHistoryKey);
    await prefs.remove(_weeklyPlanKey);
    await prefs.remove(_checkedShoppingItemsKey);
    await prefs.remove(_favoriteRecipesKey);
  }
}