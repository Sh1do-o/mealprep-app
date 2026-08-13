import 'package:flutter/material.dart';
import '../services/preferences_service.dart';

const List<MapEntry<String, String>> dietaryOptions = [
  MapEntry('rice_breakfast', 'Rice for Breakfast'),
  MapEntry('no_vegetables', 'No Vegetables'),
  MapEntry('vegetarian', 'Vegetarian'),
  MapEntry('halal', 'Halal'),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _preferencesService = PreferencesService();

  bool hasRiceCooker = true;
  bool hasStove = false;
  bool hasMicrowave = false;
  bool hasFridge = true;
  bool hasElectricKettle = false;
  bool hasNone = false;

  final Set<String> selectedDietaryPreferences = {};
  double weeklyBudget = 500;
  bool isSaving = false;

  Future<void> _handleContinue() async {
    final hasAnyEquipment = hasRiceCooker || hasStove || hasMicrowave || hasFridge || hasElectricKettle || hasNone;
    if (!hasAnyEquipment) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 1 equipment option (or "None") to continue.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => isSaving = true);

    final data = OnboardingData(
      hasRiceCooker: hasRiceCooker,
      hasStove: hasStove,
      hasMicrowave: hasMicrowave,
      hasFridge: hasFridge,
      hasElectricKettle: hasElectricKettle,
      hasNone: hasNone,
      weeklyBudget: weeklyBudget,
      dietaryPreferences: selectedDietaryPreferences.toList(),
    );

    await _preferencesService.saveOnboardingData(data);

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/');
  }

  Widget _buildEquipmentCard(String title, IconData icon, bool value, ValueChanged<bool> onChanged) {
    final theme = Theme.of(context);
    final isSelected = value;

    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3) : theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: theme.colorScheme.onSurface,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              // Header Title
              Text(
                'Setup Your Kitchen',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),

              // Speech Bubble Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Hey there! Let\'s tailor DormDish to your taste and budget.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Dietary Preferences Card Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dietary Preferences',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: dietaryOptions.map((option) {
                        final key = option.key;
                        final label = option.value;
                        final isSelected = selectedDietaryPreferences.contains(key);
                        return ChoiceChip(
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
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Equipment Grid Card Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'What equipment do you have?',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 14),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.5,
                      children: [
                        _buildEquipmentCard('Rice Cooker', Icons.rice_bowl, hasRiceCooker, (v) => setState(() => hasRiceCooker = v)),
                        _buildEquipmentCard('Stove', Icons.soup_kitchen, hasStove, (v) => setState(() => hasStove = v)),
                        _buildEquipmentCard('Microwave', Icons.microwave, hasMicrowave, (v) => setState(() => hasMicrowave = v)),
                        _buildEquipmentCard('Fridge', Icons.kitchen, hasFridge, (v) => setState(() => hasFridge = v)),
                        _buildEquipmentCard('Electric Kettle', Icons.local_cafe, hasElectricKettle, (v) => setState(() => hasElectricKettle = v)),
                        _buildEquipmentCard('None', Icons.cancel_outlined, hasNone, (v) => setState(() => hasNone = v)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Weekly Food Budget Slider Card Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Weekly Food Budget',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '₱${weeklyBudget.round()}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: theme.colorScheme.primary,
                        inactiveTrackColor: theme.colorScheme.surfaceContainerHighest,
                        thumbColor: theme.colorScheme.primary,
                      ),
                      child: Slider(
                        value: weeklyBudget,
                        min: 300,
                        max: 1000,
                        divisions: 14,
                        onChanged: (val) => setState(() => weeklyBudget = val),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('₱300', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                        Text('₱1000', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Glowing Green Primary Action Button
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : _handleContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: isSaving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Ready to Cook',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 22),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}