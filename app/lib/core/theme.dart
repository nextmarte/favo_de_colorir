import 'package:flutter/material.dart';

class FavoColors {
  FavoColors._();

  // Primary palette — warm, artisanal tones
  static const Color honey = Color(0xFFD4A03C);
  static const Color honeyLight = Color(0xFFF5E6C0);
  static const Color honeyDark = Color(0xFFB8872E);

  static const Color terracotta = Color(0xFFC75B39);
  static const Color terracottaLight = Color(0xFFE8A08B);
  static const Color terracottaDark = Color(0xFF9A3F25);

  static const Color cream = Color(0xFFFFF8F0);
  static const Color warmWhite = Color(0xFFFFFDF9);
  static const Color warmGray = Color(0xFF6B5E53);
  static const Color darkBrown = Color(0xFF3D2E22);

  // Semantic colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF42A5F5);
}

class FavoTheme {
  FavoTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: FavoColors.honey,
      primary: FavoColors.honey,
      secondary: FavoColors.terracotta,
      surface: FavoColors.cream,
      error: FavoColors.error,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: FavoColors.cream,

      // Typography
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: FavoColors.darkBrown,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: FavoColors.darkBrown,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: FavoColors.darkBrown,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: FavoColors.warmGray,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: FavoColors.warmGray,
        ),
      ),

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: FavoColors.cream,
        foregroundColor: FavoColors.darkBrown,
        elevation: 0,
        centerTitle: true,
      ),

      // Cards — rounded, organic feel
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: FavoColors.warmWhite,
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: FavoColors.honey,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: FavoColors.honey,
          side: const BorderSide(color: FavoColors.honey),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      // Input fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FavoColors.warmWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: FavoColors.honeyLight.withAlpha(128)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: FavoColors.honey, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: FavoColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // Bottom navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: FavoColors.warmWhite,
        selectedItemColor: FavoColors.honey,
        unselectedItemColor: FavoColors.warmGray,
      ),

      // Floating action button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: FavoColors.terracotta,
        foregroundColor: Colors.white,
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: FavoColors.honeyLight,
        selectedColor: FavoColors.honey,
        labelStyle: const TextStyle(color: FavoColors.darkBrown),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
