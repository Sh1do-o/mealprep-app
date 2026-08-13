import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mealprep_app/screens/weekly_plan_screen.dart';
import 'package:mealprep_app/services/preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('WeeklyPlanScreen loads cooked history and saves newly cooked meals', (WidgetTester tester) async {
    final prefs = PreferencesService();

    await tester.pumpWidget(
      const MaterialApp(
        home: WeeklyPlanScreen(),
      ),
    );

    await tester.pumpAndSettle();

    // Ensure button is scrolled into view before tapping
    final buttonFinder = find.text('Mark as Cooked');
    await tester.ensureVisible(buttonFinder);
    await tester.pumpAndSettle();

    expect(buttonFinder, findsOneWidget);

    // Tap Mark as Cooked
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();

    // Verify button text changes to Done
    expect(find.text('Done'), findsOneWidget);

    // Verify history was saved to PreferencesService
    final history = await prefs.loadCookedHistory();
    expect(history.length, equals(1));
  });
}
