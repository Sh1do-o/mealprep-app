import 'package:flutter/material.dart';
import '../data/dummy_recipes.dart';
import '../logic/weekly_planner_logic.dart';
import '../models/recipe.dart';
import '../services/preferences_service.dart';
import 'recipe_detail_screen.dart';

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
  final _preferencesService = PreferencesService();

  bool _isLoading = true;
  OnboardingData? _onboardingData;
  WeeklyPlanResult? _plan;

  @override
  void initState() {
    super.initState();
    _loadPlanAndOnboarding();
  }

  Future<void> _loadPlanAndOnboarding() async {
    final onboarding = await _preferencesService.loadOnboardingData();
    final savedRecipeIds = await _preferencesService.loadWeeklyPlanRecipeIds();

    final equipment = onboarding != null
        ? ownedEquipmentFrom(onboarding)
        : <String>{};
    final budget = onboarding?.weeklyBudget ?? 500.0;
    final preferences = onboarding?.dietaryPreferences.toSet() ?? {};

    WeeklyPlanResult plan;

    if (savedRecipeIds != null && savedRecipeIds.length == 7) {
      // Reconstruct plan from saved recipe IDs
      final Map<String, Recipe> recipeMap = {
        for (var r in dummyRecipes) r.id: r
      };

      List<PlannedDay> days = [];
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
        final id = savedRecipeIds[i];
        final recipe = recipeMap[id] ?? dummyRecipes[i % dummyRecipes.length];
        days.add(
          PlannedDay(
            dayIndex: i + 1,
            dayName: dayLabels[i],
            recipe: recipe,
          ),
        );
      }
      plan = WeeklyPlanResult.fromDays(days, budget);
    } else {
      // Generate new plan
      plan = generateWeeklyPlan(
        ownedEquipment: equipment,
        weeklyBudget: budget,
        dietaryPreferences: preferences,
        seed: DateTime.now().millisecondsSinceEpoch,
      );
      await _savePlanRecipeIds(plan);
    }

    if (!mounted) return;
    setState(() {
      _onboardingData = onboarding;
      _plan = plan;
      _isLoading = false;
    });
  }

  Future<void> _savePlanRecipeIds(WeeklyPlanResult plan) async {
    final ids = plan.days.map((d) => d.recipe.id).toList();
    await _preferencesService.saveWeeklyPlanRecipeIds(ids);
  }

  void _regeneratePlan() async {
    final equipment = _onboardingData != null
        ? ownedEquipmentFrom(_onboardingData!)
        : <String>{};
    final budget = _onboardingData?.weeklyBudget ?? 500.0;
    final preferences = _onboardingData?.dietaryPreferences.toSet() ?? {};

    final newPlan = generateWeeklyPlan(
      ownedEquipment: equipment,
      weeklyBudget: budget,
      dietaryPreferences: preferences,
      seed: DateTime.now().millisecondsSinceEpoch,
    );

    setState(() {
      _plan = newPlan;
    });
    await _savePlanRecipeIds(newPlan);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generated a new non-repeating 7-day meal plan!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _openSwapModal(PlannedDay day) {
    if (_plan == null) return;

    final equipment = _onboardingData != null
        ? ownedEquipmentFrom(_onboardingData!)
        : <String>{};
    final preferences = _onboardingData?.dietaryPreferences.toSet() ?? {};

    final candidates = getSwapCandidates(
      currentPlan: _plan!,
      dayIndex: day.dayIndex,
      ownedEquipment: equipment,
      dietaryPreferences: preferences,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.85,
          minChildSize: 0.4,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Swap Meal for ${day.dayName}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Currently: ${day.recipe.title}',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: candidates.isEmpty
                      ? const Center(
                          child: Text(
                            'No alternative compatible recipes available.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: candidates.length,
                          itemBuilder: (context, index) {
                            final recipe = candidates[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                child: Text(
                                  '₱${recipe.estimatedCost.toInt()}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  ),
                                ),
                              ),
                              title: Text(recipe.title),
                              subtitle: Text(
                                '${recipe.prepTime} • ${recipe.nutrition.calories} kcal',
                              ),
                              trailing: const Icon(Icons.swap_horiz),
                              onTap: () async {
                                final updatedPlan = swapMealForDay(
                                  currentPlan: _plan!,
                                  dayIndex: day.dayIndex,
                                  newRecipe: recipe,
                                );
                                Navigator.pop(context);
                                setState(() {
                                  _plan = updatedPlan;
                                });
                                await _savePlanRecipeIds(updatedPlan);
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Set<String> ownedEquipmentFrom(OnboardingData data) {
    final set = <String>{};
    if (data.hasRiceCooker) set.add('Rice cooker');
    if (data.hasStove) set.add('Stove');
    if (data.hasMicrowave) set.add('Microwave');
    if (data.hasFridge) set.add('Fridge');
    return set;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Meal Plan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Regenerate Plan',
            onPressed: _regeneratePlan,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _plan == null
              ? const Center(child: Text('Could not generate plan'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryHeader(),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '7-Day Meal Schedule',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          OutlinedButton.icon(
                            onPressed: _regeneratePlan,
                            icon: const Icon(Icons.auto_awesome, size: 16),
                            label: const Text('Regenerate'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _plan!.days.length,
                        itemBuilder: (context, index) {
                          final day = _plan!.days[index];
                          return _buildDayCard(day);
                        },
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryHeader() {
    final plan = _plan!;
    final budget = plan.weeklyBudget;
    final cost = plan.totalEstimatedCost;
    final ratio = budget > 0 ? (cost / budget).clamp(0.0, 1.0) : 0.0;
    final isOverBudget = cost > budget && budget > 0;

    return Card(
      elevation: 0,
      color: isOverBudget
          ? Colors.red[50]
          : Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isOverBudget
              ? Colors.red.shade200
              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Estimated Plan Cost',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOverBudget ? Colors.red : Colors.green[700],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isOverBudget ? 'Over Budget' : 'Within Budget',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '₱${cost.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: isOverBudget
                        ? Colors.red[800]
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  ' / ₱${budget.toStringAsFixed(0)} weekly budget',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                color: isOverBudget ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Weekly Nutrition Breakdown',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMacroItem('Calories', '${plan.totalCalories} kcal'),
                _buildMacroItem('Protein', '${plan.totalProteinGrams.toInt()}g'),
                _buildMacroItem('Carbs', '${plan.totalCarbsGrams.toInt()}g'),
                _buildMacroItem('Fat', '${plan.totalFatGrams.toInt()}g'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildDayCard(PlannedDay day) {
    final recipe = day.recipe;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RecipeDetailScreen(
                recipe: recipe,
                ownedIngredients: widget.selectedIngredients.toList(),
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      day.dayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.swap_horiz_rounded, size: 20),
                    tooltip: 'Swap Meal',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _openSwapModal(day),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                recipe.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    recipe.prepTime,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.payments_outlined,
                      size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '₱${recipe.estimatedCost.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.local_fire_department_outlined,
                      size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${recipe.nutrition.calories} kcal',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final equip in recipe.equipmentNeeded)
                    Chip(
                      label: Text(equip, style: const TextStyle(fontSize: 10)),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  if (recipe.isVegetarian)
                    Chip(
                      label: const Text('Veg',
                          style: TextStyle(fontSize: 10, color: Colors.green)),
                      backgroundColor: Colors.green[50],
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
