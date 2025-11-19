import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AppTheme {
  // Background color options for candidate profiles
  static const Color backgroundColorLight = Color(0xFFFFF8F0); // Very light saffron
  static const Color backgroundColorCream = Color(0xFFFFFBF7); // Cream
  static const Color backgroundColorBlue = Color(0xFFF0F8FF); // Light blue
  static const Color backgroundColorGreen = Color(0xFFF0FFF0); // Light green
  static const Color backgroundColorGray = Color(0xFFF8F8F8); // Light gray

  // Home screen background color - very light saffron for contrast
  static const Color homeBackgroundColor = backgroundColorLight;

  // Platform-aware text theme for better web font rendering
  static TextTheme _getTextTheme() {
    // Base font sizes for mobile (Android/iOS)
    const double headlineLarge = 32;
    const double headlineMedium = 28;
    const double headlineSmall = 24;
    const double titleLarge = 22;
    const double titleMedium = 16;
    const double titleSmall = 14;
    const double bodyLarge = 16;
    const double bodyMedium = 14;
    const double bodySmall = 12;
    const double labelLarge = 14;
    const double labelMedium = 12;
    const double labelSmall = 11;

    // Scale up for web to match visual perception with mobile
    final bool isWebPlatform = kIsWeb;
    final double webScale = isWebPlatform ? 1.2 : 1.0; // 20% larger on web

    return TextTheme(
      // Headlines (Large text, used for screen titles)
      headlineLarge: TextStyle(
        fontSize: headlineLarge * webScale,
        fontWeight: FontWeight.w400,
        letterSpacing: -1.5,
        color: const Color(0xFF1F2937),
      ),
      headlineMedium: TextStyle(
        fontSize: headlineMedium * webScale,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.5,
        color: const Color(0xFF1F2937),
      ),
      headlineSmall: TextStyle(
        fontSize: headlineSmall * webScale,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.0,
        color: const Color(0xFF1F2937),
      ),

      // Titles (Medium text, used for card titles, section headers)
      titleLarge: TextStyle(
        fontSize: titleLarge * webScale,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.0,
        color: const Color(0xFF1F2937),
      ),
      titleMedium: TextStyle(
        fontSize: titleMedium * webScale,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        color: const Color(0xFF1F2937),
      ),
      titleSmall: TextStyle(
        fontSize: titleSmall * webScale,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: const Color(0xFF374151),
      ),

      // Body text (Regular content text)
      bodyLarge: TextStyle(
        fontSize: bodyLarge * webScale,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        height: 1.5,
        color: const Color(0xFF1F2937),
      ),
      bodyMedium: TextStyle(
        fontSize: bodyMedium * webScale,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.5,
        color: const Color(0xFF374151),
      ),
      bodySmall: TextStyle(
        fontSize: bodySmall * webScale,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.25,
        color: const Color(0xFF6B7280),
      ),

      // Labels (Interactive elements like buttons)
      labelLarge: TextStyle(
        fontSize: labelLarge * webScale,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.25,
        color: const Color(0xFF1F2937),
      ),
      labelMedium: TextStyle(
        fontSize: labelMedium * webScale,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.25,
        color: const Color(0xFF1F2937),
      ),
      labelSmall: TextStyle(
        fontSize: labelSmall * webScale,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.25,
        color: const Color(0xFF6B7280),
      ),

      // Legacy support for backwards compatibility
      displayLarge: TextStyle(
        fontSize: (32 * webScale),
        fontWeight: FontWeight.w400,
        letterSpacing: -1.5,
        color: const Color(0xFF1F2937),
      ),
      displayMedium: TextStyle(
        fontSize: (28 * webScale),
        fontWeight: FontWeight.w400,
        letterSpacing: -0.5,
        color: const Color(0xFF1F2937),
      ),
    );
  }

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
      textTheme: _getTextTheme(), // ✅ Web-aware font sizing
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
      textTheme: _getTextTheme(), // ✅ Web-aware font sizing
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
      textTheme: _getTextTheme(), // ✅ Web-aware font sizing
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
      textTheme: _getTextTheme(), // ✅ Web-aware font sizing
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
