import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightBg1,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.good,
      surface: AppColors.lightCard,
      error: AppColors.critical,
    ),
    cardTheme: CardThemeData(
      color: AppColors.lightCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.lightCardBorder),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightInput,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.lightInputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.lightInputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 52,
        fontWeight: FontWeight.w900,
        color: AppColors.lightText,
        fontFamily: 'monospace',
      ),
      headlineLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: AppColors.lightText,
      ),
      headlineMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.lightText,
      ),
      titleLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.lightText,
      ),
      titleMedium: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.lightText,
      ),
      bodyMedium: TextStyle(fontSize: 12, color: AppColors.lightSubtext),
      bodySmall: TextStyle(fontSize: 10, color: AppColors.lightMuted),
      labelSmall: TextStyle(
        fontSize: 8,
        fontWeight: FontWeight.w700,
        color: AppColors.lightMuted,
        letterSpacing: 0.1,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.lightNav,
      selectedItemColor: AppColors.good,
      unselectedItemColor: AppColors.lightSubtext,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.lightDivider,
      thickness: 0.5,
      space: 0,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Colors.white : Colors.white,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppColors.good
            : AppColors.lightInputBorder,
      ),
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryLight,
      secondary: AppColors.darkGood,
      surface: AppColors.darkCard,
      error: AppColors.darkCritical,
    ),
    cardTheme: CardThemeData(
      color: AppColors.darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.darkCardBorder),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkInput,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.darkInputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.darkInputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 52,
        fontWeight: FontWeight.w900,
        color: AppColors.darkText,
        fontFamily: 'monospace',
      ),
      headlineLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: AppColors.darkText,
      ),
      headlineMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.darkText,
      ),
      titleLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.darkText,
      ),
      titleMedium: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.darkText,
      ),
      bodyMedium: TextStyle(fontSize: 12, color: AppColors.darkSubtext),
      bodySmall: TextStyle(fontSize: 10, color: AppColors.darkMuted),
      labelSmall: TextStyle(
        fontSize: 8,
        fontWeight: FontWeight.w700,
        color: AppColors.darkMuted,
        letterSpacing: 0.1,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkNav,
      selectedItemColor: AppColors.darkGood,
      unselectedItemColor: AppColors.darkSubtext,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.darkDivider,
      thickness: 0.5,
      space: 0,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppColors.darkGood
            : AppColors.darkSubtext,
      ),
    ),
  );
}
