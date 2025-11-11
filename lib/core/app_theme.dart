import 'package:flutter/material.dart';

class AppTheme {
  // Background color options for candidate profiles
  static const Color backgroundColorLight = Color(0xFFFFF8F0); // Very light saffron
  static const Color backgroundColorCream = Color(0xFFFFFBF7); // Cream
  static const Color backgroundColorBlue = Color(0xFFF0F8FF); // Light blue
  static const Color backgroundColorGreen = Color(0xFFF0FFF0); // Light green
  static const Color backgroundColorGray = Color(0xFFF8F8F8); // Light gray

  // Home screen background color - very light saffron for contrast
  static const Color homeBackgroundColor = backgroundColorLight;

  // Patriotic Theme - Default (Saffron & Green)
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: const Color(0xFFFF9933), // Deep saffron
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFFF9933), // Deep saffron
        secondary: Color(0xFF138808), // Forest green
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF1F2937), // Dark charcoal
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF9933),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFFF9933),
          side: const BorderSide(color: Color(0xFFFF9933)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFFFF9933),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFF9933),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }

  // Parliamentary Theme - Blue & White
  static ThemeData get parliamentaryTheme {
    return ThemeData(
      primaryColor: const Color(0xFF1e40af), // Blue
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF1e40af), // Blue
        secondary: Color(0xFF3b82f6), // Light blue
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF1F2937),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1e40af),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF1e40af),
          side: const BorderSide(color: Color(0xFF1e40af)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF1e40af),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1e40af),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }

  // Assembly Theme - Green & White
  static ThemeData get assemblyTheme {
    return ThemeData(
      primaryColor: const Color(0xFF16a34a), // Green
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF16a34a), // Green
        secondary: Color(0xFF22c55e), // Light green
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF1F2937),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF16a34a),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF16a34a),
          side: const BorderSide(color: Color(0xFF16a34a)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF16a34a),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF16a34a),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }

  // Local Body Theme - Orange & Brown
  static ThemeData get localBodyTheme {
    return ThemeData(
      primaryColor: const Color(0xFFea580c), // Orange
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFea580c), // Orange
        secondary: Color(0xFF92400e), // Brown
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF1F2937),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFea580c),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFea580c),
          side: const BorderSide(color: Color(0xFFea580c)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFFea580c),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFea580c),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }
}
