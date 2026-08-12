import 'package:flutter/material.dart';
import '../services/preferences_service.dart';
import 'home_screen.dart';

// key -> display label. Keys match what recipe_matcher.dart checks for.
const List<MapEntry<String, String>> dietaryOptions = [
  MapEntry('vegetarian', 'Vegetarian'),
  MapEntry('halal', 'Halal'),
  MapEntry('no_vegetables', 'No vegetables'),
];

// StatefulWidget because the checkboxes and text field
// need to remember and update their own values as the user taps them.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _preferencesService = PreferencesService();

  // These booleans track which equipment checkboxes are checked.
  bool hasRiceCooker = true;
  bool hasStove = false;
  bool hasMicrowave = false;
  bool hasFridge = true;

  // Which dietary preference chips are selected. Values match the
  // string keys the matcher checks for ('vegetarian', 'halal',
  // 'no_vegetables') - kept as plain strings rather than an enum
  // set since this maps directly to what gets saved/loaded as JSON.
  final Set<String> selectedDietaryPreferences = {};

  // Controller lets us both display and read back the typed budget.
  final _budgetController = TextEditingController(text: '500');
  bool isSaving = false;

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    setState(() => isSaving = true);

    // Falls back to 0 if the field is empty or not a valid number,
    // rather than crashing - budget just won't filter anything yet.
    final budget = double.tryParse(_budgetController.text) ?? 0;

    final data = OnboardingData(
      hasRiceCooker: hasRiceCooker,
      hasStove: hasStove,
      hasMicrowave: hasMicrowave,
      hasFridge: hasFridge,
      weeklyBudget: budget,
      dietaryPreferences: selectedDietaryPreferences.toList(),
    );

    await _preferencesService.saveOnboardingData(data);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('What do you have?')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Equipment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            CheckboxListTile(
              title: const Text('Rice cooker'),
              value: hasRiceCooker,
              onChanged: (val) => setState(() => hasRiceCooker = val!),
            ),
            CheckboxListTile(
              title: const Text('Stove'),
              value: hasStove,
              onChanged: (val) => setState(() => hasStove = val!),
            ),
            CheckboxListTile(
              title: const Text('Microwave'),
              value: hasMicrowave,
              onChanged: (val) => setState(() => hasMicrowave = val!),
            ),
            CheckboxListTile(
              title: const Text('Fridge'),
              value: hasFridge,
              onChanged: (val) => setState(() => hasFridge = val!),
            ),
            const SizedBox(height: 24),
            const Text(
              'Dietary preferences',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: dietaryOptions.map((option) {
                final key = option.key;
                final label = option.value;
                final isSelected = selectedDietaryPreferences.contains(key);
                return FilterChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        selectedDietaryPreferences.add(key);
                      } else {
                        selectedDietaryPreferences.remove(key);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text(
              'Weekly budget',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixText: '₱ ',
                hintText: 'e.g. 500',
                border: OutlineInputBorder(),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSaving ? null : _handleContinue,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Continue'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}