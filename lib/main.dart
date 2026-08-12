import 'package:flutter/material.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/preferences_service.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MealPrepApp());
}

class MealPrepApp extends StatelessWidget {
  const MealPrepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Default to Culinary Dark Mode
      home: const _StartupRouter(),
    );
  }
}

class _StartupRouter extends StatelessWidget {
  const _StartupRouter();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: PreferencesService().hasCompletedOnboarding(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data!
            ? const MainNavigationScreen()
            : const OnboardingScreen();
      },
    );
  }
}