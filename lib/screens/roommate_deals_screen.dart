import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/dummy_recipes.dart';
import '../logic/recipe_matcher.dart' show ownedEquipmentFrom;
import '../logic/weekly_planner_logic.dart';
import '../models/recipe.dart';
import '../services/preferences_service.dart';

import 'nutrition_tracker_screen.dart';

class RoommateDealsScreen extends StatefulWidget {
  const RoommateDealsScreen({super.key});

  @override
  State<RoommateDealsScreen> createState() => _RoommateDealsScreenState();
}

class _RoommateDealsScreenState extends State<RoommateDealsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _preferencesService = PreferencesService();

  int _roommateCount = 2;
  WeeklyPlanResult? _plan;
  bool _isLoading = true;

  final Map<int, String> _assignments = {
    1: 'Me',
    2: 'Roommate A',
    3: 'Me',
    4: 'Roommate A',
    5: 'Me',
    6: 'Roommate A',
    7: 'Me',
  };

  bool _isUnlocked = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPlan();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPlan() async {
    final onboarding = await _preferencesService.loadOnboardingData();
    final savedRecipeIds = await _preferencesService.loadWeeklyPlanRecipeIds();

    final equipment = onboarding != null
        ? ownedEquipmentFrom(onboarding)
        : <String>{};
    final budget = onboarding?.weeklyBudget ?? 500.0;
    final preferences = onboarding?.dietaryPreferences.toSet() ?? {};

    WeeklyPlanResult plan;

    if (savedRecipeIds != null && savedRecipeIds.length == 7) {
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
      plan = generateWeeklyPlan(
        ownedEquipment: equipment,
        weeklyBudget: budget,
        dietaryPreferences: preferences,
      );
    }

    if (!mounted) return;
    setState(() {
      _plan = plan;
      _isLoading = false;
    });
  }


  void _shareScheduleToClipboard() {
    if (_plan == null) return;

    final buffer = StringBuffer();
    buffer.writeln('🏠 Dorm Meal Prep — Weekly Roommate Schedule');
    buffer.writeln('===========================================');
    for (final day in _plan!.days) {
      final assignee = _assignments[day.dayIndex] ?? 'Me';
      buffer.writeln(
          '${day.dayName}: ${day.recipe.title} (₱${day.recipe.estimatedCost.toInt()}) ➔ Cook: $assignee');
    }

    buffer.writeln('\n💰 Grocery Split Summary:');
    final perPerson = _plan!.totalEstimatedCost / _roommateCount;
    buffer.writeln(
        'Total Weekly Plan Cost: ₱${_plan!.totalEstimatedCost.toStringAsFixed(0)}');
    buffer.writeln('Split across $_roommateCount roommates: ₱${perPerson.toStringAsFixed(0)} / person');

    Clipboard.setData(ClipboardData(text: buffer.toString()));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied roommate schedule & grocery split to clipboard!'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.people_alt, color: theme.colorScheme.primary, size: 22),
            const SizedBox(width: 8),
            const Text(
              'Roommates & Profile',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.people_outline), text: 'Rotation'),
            Tab(icon: Icon(Icons.local_offer_outlined), text: 'Perks'),
            Tab(icon: Icon(Icons.bar_chart_outlined), text: 'Tracker'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRoommateTab(),
                _buildDealsTab(),
                _buildTrackerTab(),
              ],
            ),
    );
  }

  Widget _buildRoommateTab() {
    final theme = Theme.of(context);
    final totalCost = _plan?.totalEstimatedCost ?? 0;
    final splitCost = totalCost / _roommateCount;

    final List<String> availableRoommates = [
      'Me',
      'Roommate A',
      if (_roommateCount >= 3) 'Roommate B',
      if (_roommateCount >= 4) 'Roommate C',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Roommate Grocery Splitter',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    DropdownButton<int>(
                      value: _roommateCount,
                      underline: const SizedBox(),
                      items: [2, 3, 4].map((count) {
                        return DropdownMenuItem(
                          value: count,
                          child: Text('$count People'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _roommateCount = val);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '₱${splitCost.toStringAsFixed(0)} / person',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  'Total Weekly Grocery Total: ₱${totalCost.toStringAsFixed(0)}',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _shareScheduleToClipboard,
                    icon: const Icon(Icons.share_outlined, size: 18),
                    label: const Text('Share Schedule to Group Chat'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Cooking Duty Assignments',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (_plan != null)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _plan!.days.length,
              itemBuilder: (context, index) {
                final day = _plan!.days[index];
                final currentAssignee = _assignments[day.dayIndex] ?? 'Me';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                  ),
                  child: ListTile(
                    dense: true,
                    title: Text(
                      '${day.dayName}: ${day.recipe.title}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text('Prep: ${day.recipe.prepTime}'),
                    trailing: DropdownButton<String>(
                      value: availableRoommates.contains(currentAssignee)
                          ? currentAssignee
                          : 'Me',
                      underline: const SizedBox(),
                      items: availableRoommates.map((name) {
                        return DropdownMenuItem(
                          value: name,
                          child: Text(name, style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _assignments[day.dayIndex] = val;
                          });
                        }
                      },
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDealsTab() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.stars, color: theme.colorScheme.secondary, size: 28),
                    const SizedBox(width: 8),
                    const Text(
                      'Student GCash Micro-Unlock',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete 3 meals this week to unlock exclusive student discounts at partner mini-marts.',
                  style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isUnlocked ? theme.colorScheme.primary : theme.colorScheme.secondary,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () {
                      setState(() => _isUnlocked = !_isUnlocked);
                    },
                    icon: Icon(_isUnlocked ? Icons.check_circle : Icons.lock_open),
                    label: Text(
                      _isUnlocked
                          ? 'Perk Unlocked: DORM-STUDENT-2026'
                          : 'Unlock GCash Micro-Perk (Demo)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Partner Student Discounts',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildDealCard(
            context,
            icon: Icons.egg_outlined,
            title: '10% Off Egg 12-Packs',
            vendor: 'Campus Mini-Mart',
            details: 'Flash student ID at checkout.',
          ),
          _buildDealCard(
            context,
            icon: Icons.account_balance_wallet_outlined,
            title: '₱50 GCash Cashback',
            vendor: 'GCash Micro-Pay',
            details: 'Valid for groceries over ₱300.',
          ),
          _buildDealCard(
            context,
            icon: Icons.rice_bowl_outlined,
            title: '15% Off Spices & Rice Liners',
            vendor: 'Dorm Essentials Hub',
            details: 'Discounts applied on student bundle packs.',
          ),
        ],
      ),
    );
  }

  Widget _buildDealCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String vendor,
    required String details,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vendor, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            Text(details, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackerTab() {
    return const NutritionTrackerScreen();
  }
}
