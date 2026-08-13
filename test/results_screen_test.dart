import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mealprep_app/screens/results_screen.dart';

void main() {
  testWidgets('ResultsScreen displays no ingredients state when selectedIngredients is empty', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ResultsScreen(
          selectedIngredients: [],
          ownedEquipment: {'Stove'},
          budget: 200,
        ),
      ),
    );

    expect(find.text('No ingredients selected'), findsOneWidget);
    expect(find.text('Tap a few ingredients first so we know what to suggest.'), findsOneWidget);
    expect(find.text('Select Ingredients'), findsOneWidget);
  });
}
