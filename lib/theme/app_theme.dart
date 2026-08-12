import 'package:flutter/material.dart';

class AppConfig {
  static String appName = 'DormDish';
  static String appSubtitle = 'What Can I Cook Right Now';
}

class AppColors {
  // Dark Theme Palette ("Forest Charcoal")
  static const darkBackground = Color(0xFF0B1326);
  static const darkSurfaceLow = Color(0xFF131B2E);
  static const darkSurfaceContainer = Color(0xFF1B2338);
  static const darkSurfaceHigh = Color(0xFF262E43);
  static const darkSurfaceHighest = Color(0xFF31394E);

  static const darkPrimary = Color(0xFF4EDEA3);
  static const darkOnPrimary = Color(0xFF003824);
  static const darkPrimaryContainer = Color(0xFF005236);
  static const darkOnPrimaryContainer = Color(0xFF6FFBBE);

  static const darkSecondary = Color(0xFFFFB690);
  static const darkOnSecondary = Color(0xFF5C2400);
  static const darkSecondaryContainer = Color(0xFF5C2400);
  static const darkOnSecondaryContainer = Color(0xFFFFDBCA);

  static const darkTertiary = Color(0xFFFDE047);
  static const darkOnTertiary = Color(0xFF402D00);

  static const darkOnSurface = Color(0xFFE1E2EB);
  static const darkOnSurfaceVariant = Color(0xFFC3C6CF);
  static const darkOutline = Color(0xFF43474F);

  // Light Theme Palette ("Fresh Culinary")
  static const lightBackground = Color(0xFFF8FAFC);
  static const lightSurfaceLow = Color(0xFFF1F5F9);
  static const lightSurfaceContainer = Color(0xFFFFFFFF);
  static const lightSurfaceHigh = Color(0xFFE2E8F0);
  static const lightSurfaceHighest = Color(0xFFCBD5E1);

  static const lightPrimary = Color(0xFF059669);
  static const lightOnPrimary = Color(0xFFFFFFFF);
  static const lightPrimaryContainer = Color(0xFFD1FAE5);
  static const lightOnPrimaryContainer = Color(0xFF065F46);

  static const lightSecondary = Color(0xFFEA580C);
  static const lightOnSecondary = Color(0xFFFFFFFF);

  static const lightOnSurface = Color(0xFF0F172A);
  static const lightOnSurfaceVariant = Color(0xFF475569);
  static const lightOutline = Color(0xFF94A3B8);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        surface: AppColors.darkBackground,
        surfaceContainerLow: AppColors.darkSurfaceLow,
        surfaceContainer: AppColors.darkSurfaceContainer,
        surfaceContainerHigh: AppColors.darkSurfaceHigh,
        surfaceContainerHighest: AppColors.darkSurfaceHighest,
        onSurface: AppColors.darkOnSurface,
        onSurfaceVariant: AppColors.darkOnSurfaceVariant,
        primary: AppColors.darkPrimary,
        onPrimary: AppColors.darkOnPrimary,
        primaryContainer: AppColors.darkPrimaryContainer,
        onPrimaryContainer: AppColors.darkOnPrimaryContainer,
        secondary: AppColors.darkSecondary,
        onSecondary: AppColors.darkOnSecondary,
        secondaryContainer: AppColors.darkSecondaryContainer,
        onSecondaryContainer: AppColors.darkOnSecondaryContainer,
        tertiary: AppColors.darkTertiary,
        onTertiary: AppColors.darkOnTertiary,
        outline: AppColors.darkOutline,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkOnSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.darkOnSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurfaceContainer,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkOutline, width: 0.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurfaceHighest,
        selectedColor: AppColors.darkPrimaryContainer,
        secondarySelectedColor: AppColors.darkPrimaryContainer,
        labelStyle: const TextStyle(color: AppColors.darkOnSurface, fontSize: 13),
        secondaryLabelStyle: const TextStyle(color: AppColors.darkOnPrimaryContainer, fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9999),
          side: BorderSide.none,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurfaceLow,
        indicatorColor: AppColors.darkPrimaryContainer,
        elevation: 8,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.darkPrimary,
            );
          }
          return const TextStyle(
            fontSize: 12,
            color: AppColors.darkOnSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.darkOnPrimaryContainer);
          }
          return const IconThemeData(color: AppColors.darkOnSurfaceVariant);
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: AppColors.darkOnPrimary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceHighest,
        hintStyle: const TextStyle(color: AppColors.darkOnSurfaceVariant),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.darkOutline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.darkOutline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.darkPrimary, width: 2),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        brightness: Brightness.light,
        surface: AppColors.lightBackground,
        surfaceContainerLow: AppColors.lightSurfaceLow,
        surfaceContainer: AppColors.lightSurfaceContainer,
        surfaceContainerHigh: AppColors.lightSurfaceHigh,
        surfaceContainerHighest: AppColors.lightSurfaceHighest,
        onSurface: AppColors.lightOnSurface,
        onSurfaceVariant: AppColors.lightOnSurfaceVariant,
        primary: AppColors.lightPrimary,
        onPrimary: AppColors.lightOnPrimary,
        primaryContainer: AppColors.lightPrimaryContainer,
        onPrimaryContainer: AppColors.lightOnPrimaryContainer,
        secondary: AppColors.lightSecondary,
        onSecondary: AppColors.lightOnSecondary,
        outline: AppColors.lightOutline,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightOnSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.lightOnSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurfaceContainer,
        elevation: 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.lightSurfaceHigh),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightSurfaceHigh,
        selectedColor: AppColors.lightPrimaryContainer,
        labelStyle: const TextStyle(color: AppColors.lightOnSurface, fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9999),
          side: BorderSide.none,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.lightSurfaceContainer,
        indicatorColor: AppColors.lightPrimaryContainer,
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightPrimary,
          foregroundColor: AppColors.lightOnPrimary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
