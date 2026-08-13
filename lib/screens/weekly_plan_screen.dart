import 'package:flutter/material.dart';
import '../data/dummy_recipes.dart';
import '../logic/recipe_matcher.dart' show ownedEquipmentFrom;
import '../logic/weekly_planner_logic.dart';
import '../models/recipe.dart';
import '../services/preferences_service.dart';
import 'recipe_detail_screen.dart';

import 'nutrition_tracker_screen.dart';
import 'weekly_summary_screen.dart';

class WeeklyPlanScreen extends StatefulWidget {
  final Set<String> selectedIngredients;

  const WeeklyPlanScreen({
    super.key,
    this.selectedIngredients = const {},
  });

  @override
  State<WeeklyPlanScreen> createState() => _WeeklyPlanScreenState();
}

class _WeeklyPlanScreenState extends State<WeeklyPlanScreen> {
  final PreferencesService _prefs = PreferencesService();
  int selectedDayIndex = 0; // 0 for MON (Day 1)
  final Set<String> cookedMealIds = {};
  WeeklyPlanResult? _plan;
  bool _isLoading = true;
  int _seedOffset = 0;

  Set<String> _ownedEquipment = {};
  Set<String> _dietaryPreferences = {};

  List<Map<String, String>> get days {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    const dayNames = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return List.generate(7, (i) {
      final dayDate = monday.add(Duration(days: i));
      return {
        'day': dayNames[i],
        'date': '${dayDate.day}',
      };
    });
  }

  @override
  void initState() {
    super.initState();
    selectedDayIndex = (DateTime.now().weekday - 1).clamp(0, 6);
    _loadPlan();
  }

  Future<void> _loadPlan({bool forceRegenerate = false}) async {
    final onboarding = await _prefs.loadOnboardingData();
    final savedIds = await _prefs.loadWeeklyPlanRecipeIds();
    final alwaysRice = await _prefs.loadAlwaysPairWithRice();

    final equipment = onboarding != null ? ownedEquipmentFrom(onboarding) : <String>{};
    final budget = onboarding?.weeklyBudget ?? 500.0;
    final preferences = onboarding?.dietaryPreferences.toSet() ?? {};

    _ownedEquipment = equipment;
    _dietaryPreferences = preferences;

    WeeklyPlanResult plan;

    if (!forceRegenerate && savedIds != null && savedIds.length == 7) {
      final recipeMap = {for (var r in dummyRecipes) r.id: r};
      List<PlannedDay> plannedDays = [];
      const dayLabels = [
        'Day 1 (Mon)',
        'Day 2 (Tue)',
        'Day 3 (Wed)',
        'Day 4 (Thu)',
        'Day 5 (Fri)',
        'Day 6 (Sat)',
        'Day 7 (Sun)',
      ];

      for (int i = 0; i < 7; i++) {
        final recipe = recipeMap[savedIds[i]] ?? dummyRecipes[i % dummyRecipes.length];
        final pairRice = alwaysRice && recipe.canPairWithRice;
        plannedDays.add(PlannedDay(
          dayIndex: i + 1,
          dayName: dayLabels[i],
          recipe: recipe,
          isPairedWithRice: pairRice,
        ));
      }
      plan = WeeklyPlanResult.fromDays(plannedDays, budget);
    } else {
      final seed = 42 + _seedOffset;
      plan = generateWeeklyPlan(
        ownedEquipment: equipment,
        weeklyBudget: budget,
        dietaryPreferences: preferences,
        alwaysPairWithRice: alwaysRice,
        seed: seed,
      );
      await _prefs.saveWeeklyPlanRecipeIds(plan.days.map((d) => d.recipe.id).toList());
    }

    final history = await _prefs.loadCookedHistory();
    final cookedIds = history.map((e) => e.recipeId).toSet();

    if (!mounted) return;
    setState(() {
      _plan = plan;
      cookedMealIds.clear();
      cookedMealIds.addAll(cookedIds);
      _isLoading = false;
    });
  }

  void _regeneratePlan() {
    setState(() {
      _seedOffset += 7;
      _isLoading = true;
    });
    _loadPlan(forceRegenerate: true);
  }

  void _showSwapDialog(int dayIndex) {
    if (_plan == null) return;
    final candidates = getSwapCandidates(
      currentPlan: _plan!,
      dayIndex: dayIndex + 1,
      ownedEquipment: _ownedEquipment,
      dietaryPreferences: _dietaryPreferences,
    );

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Swap Meal for ${days[dayIndex]['day']}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (candidates.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text('No alternative compatible recipes available.'),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: candidates.length,
                    itemBuilder: (context, idx) {
                      final recipe = candidates[idx];
                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            recipe.imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.restaurant),
                          ),
                        ),
                        title: Text(recipe.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text('${recipe.prepTime} • ₱${recipe.estimatedCost.round()}'),
                        trailing: ElevatedButton(
                          onPressed: () async {
                            final updatedPlan = swapMealForDay(
                              currentPlan: _plan!,
                              dayIndex: dayIndex + 1,
                              newRecipe: recipe,
                            );
                            await _prefs.saveWeeklyPlanRecipeIds(
                              updatedPlan.days.map((d) => d.recipe.id).toList(),
                            );
                            setState(() {
                              _plan = updatedPlan;
                            });
                            if (!mounted) return;
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Swapped meal to ${recipe.title}!')),
                            );
                          },
                          child: const Text('Swap'),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading || _plan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Weekly Plan')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final plan = _plan!;
    final currentPlannedDay = plan.days[selectedDayIndex.clamp(0, plan.days.length - 1)];
    final currentRecipe = currentPlannedDay.recipe;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.soup_kitchen, color: theme.colorScheme.primary, size: 22),
            const SizedBox(width: 8),
            const Text(
              'Weekly Plan',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Weekly Summary',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WeeklySummaryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.local_fire_department_outlined),
            tooltip: 'Nutrition Tracker',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NutritionTrackerScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Health Coach Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.eco_outlined, color: theme.colorScheme.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'You\'ve been eating healthy recently! Keep up the great work. 🥣',
                      style: TextStyle(fontSize: 13, height: 1.3, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Weekly Budget Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weekly Budget',
                          style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '₱${plan.totalEstimatedCost.round()}',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              ' / ₱${plan.weeklyBudget.round()} budget',
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: (plan.totalEstimatedCost / (plan.weeklyBudget > 0 ? plan.weeklyBudget : 1.0)).clamp(0.0, 1.0),
                          strokeWidth: 4,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            plan.totalEstimatedCost <= plan.weeklyBudget ? theme.colorScheme.primary : theme.colorScheme.error,
                          ),
                        ),
                        Icon(Icons.change_history, size: 16, color: theme.colorScheme.primary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Calories & Macro Summary Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMacroStat(context, 'CALORIES', '${plan.totalCalories}'),
                  Container(height: 24, width: 1, color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                  _buildMacroStat(context, 'PROTEIN', '${plan.totalProteinGrams.round()}g'),
                  Container(height: 24, width: 1, color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                  _buildMacroStat(context, 'CARBS', '${plan.totalCarbsGrams.round()}g'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 7-Day Date Selector Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(days.length, (index) {
                  final dayData = days[index];
                  final isSelected = selectedDayIndex == index;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => setState(() => selectedDayIndex = index),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 54,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? theme.colorScheme.surfaceContainerHighest : theme.colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline.withValues(alpha: 0.3),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  dayData['day']!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                if (isSelected) ...[
                                  const SizedBox(width: 2),
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dayData['date']!,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),

            // Daily Meal Card for the selected day
            _buildPlannedMealCard(
              context,
              mealTime: '${days[selectedDayIndex]['day']} Planned Meal',
              recipe: currentRecipe,
              isCooked: cookedMealIds.contains(currentRecipe.id),
              isPairedWithRice: currentPlannedDay.isPairedWithRice,
              onSwap: () => _showSwapDialog(selectedDayIndex),
              onToggleCooked: () async {
                final recipeId = currentRecipe.id;
                final isCurrentlyCooked = cookedMealIds.contains(recipeId);

                if (!isCurrentlyCooked) {
                  setState(() {
                    cookedMealIds.add(recipeId);
                  });
                  await _prefs.addCookedEntry(
                    CookedEntry(
                      recipeId: currentRecipe.id,
                      recipeTitle: currentRecipe.title,
                      cookedAt: DateTime.now(),
                      pairedWithRice: currentPlannedDay.isPairedWithRice,
                    ),
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Marked as cooked! Saved to history & nutrition tracker.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else {
                  setState(() {
                    cookedMealIds.remove(recipeId);
                  });
                  await _prefs.removeCookedEntryForRecipe(recipeId);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Unmarked cooked recipe.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _regeneratePlan();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Weekly plan regenerated matching your budget!')),
          );
        },
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        icon: const Icon(Icons.autorenew),
        label: const Text('Regenerate Plan', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildMacroStat(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildPlannedMealCard(
    BuildContext context, {
    required String mealTime,
    required Recipe recipe,
    String? missingIngredient,
    required bool isCooked,
    bool isPairedWithRice = false,
    VoidCallback? onSwap,
    required VoidCallback onToggleCooked,
  }) {
    final theme = Theme.of(context);
    final effectiveCost = recipe.getCostWithRice(pairWithRice: isPairedWithRice);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RecipeDetailScreen(
                recipe: recipe,
                initialPairWithRice: isPairedWithRice,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Meal Image Banner with Time Tag
            Stack(
              children: [
                Image.network(
                  recipe.imageUrl,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 140,
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
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      mealTime,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (isPairedWithRice)
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

            // Card Body
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          recipe.title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        '₱${effectiveCost.round()}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  if (missingIngredient != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '⚠️ Missing: $missingIngredient',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),

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
                      const Spacer(),
                      if (onSwap != null) ...[
                        OutlinedButton.icon(
                          icon: const Icon(Icons.swap_horiz, size: 16),
                          label: const Text('Swap'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.onSurface,
                            side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: onSwap,
                        ),
                        const SizedBox(width: 8),
                      ],
                      OutlinedButton.icon(
                        icon: Icon(
                          isCooked ? Icons.check_box : Icons.check_box_outline_blank,
                          size: 16,
                        ),
                        label: Text(isCooked ? 'Done' : 'Mark as Cooked'),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isCooked ? theme.colorScheme.primaryContainer : Colors.transparent,
                          foregroundColor: isCooked ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                          side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: onToggleCooked,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
