import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_theme.dart';
import '../utils/app_logger.dart';

/// Available theme types for the election app
enum AppThemeType {
  patriotic,      // Default - Saffron & Green (National)
  parliamentary,  // Blue & White (Parliamentary)
  assembly,       // Green & White (State Assembly)
  localBody,      // Orange & Brown (Local elections)
}

/// Controller for managing app theme switching
class ThemeController extends GetxController {
  static const String _themeKey = 'selected_theme';

  // Reactive theme state
  final Rx<AppThemeType> currentThemeType = AppThemeType.patriotic.obs;
  final Rx<ThemeData> currentTheme = AppTheme.lightTheme.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSavedTheme();
  }

  /// Load saved theme from SharedPreferences
  Future<void> _loadSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedThemeIndex = prefs.getInt(_themeKey);

      if (savedThemeIndex != null) {
        final themeType = AppThemeType.values[savedThemeIndex];
        await changeTheme(themeType, saveToPrefs: false);
        AppLogger.core('🎨 Loaded saved theme: ${themeType.name}');
      } else {
        // Default to patriotic theme
        currentThemeType.value = AppThemeType.patriotic;
        currentTheme.value = AppTheme.lightTheme;
        AppLogger.core('🎨 Using default patriotic theme');
      }
    } catch (e) {
      AppLogger.coreError('❌ Failed to load saved theme', error: e);
      // Fallback to default
      currentThemeType.value = AppThemeType.patriotic;
      currentTheme.value = AppTheme.lightTheme;
    }
  }

  /// Change the app theme
  Future<void> changeTheme(AppThemeType themeType, {bool saveToPrefs = true}) async {
    try {
      currentThemeType.value = themeType;

      // Get the appropriate theme data
      ThemeData newTheme;
      switch (themeType) {
        case AppThemeType.patriotic:
          newTheme = AppTheme.lightTheme;
          break;
        case AppThemeType.parliamentary:
          newTheme = AppTheme.parliamentaryTheme;
          break;
        case AppThemeType.assembly:
          newTheme = AppTheme.assemblyTheme;
          break;
        case AppThemeType.localBody:
          newTheme = AppTheme.localBodyTheme;
          break;
      }

      currentTheme.value = newTheme;

      // Apply theme using GetX
      Get.changeTheme(newTheme);

      // Save to preferences if requested
      if (saveToPrefs) {
        await _saveThemeToPrefs(themeType);
      }

      AppLogger.core('🎨 Theme changed to: ${themeType.name}');
    } catch (e) {
      AppLogger.coreError('❌ Failed to change theme', error: e);
    }
  }

  /// Save theme preference to SharedPreferences
  Future<void> _saveThemeToPrefs(AppThemeType themeType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, themeType.index);
      AppLogger.core('💾 Theme preference saved: ${themeType.name}');
    } catch (e) {
      AppLogger.coreError('❌ Failed to save theme preference', error: e);
    }
  }

  /// Get display name for theme type
  String getThemeDisplayName(AppThemeType themeType) {
    switch (themeType) {
      case AppThemeType.patriotic:
        return 'Patriotic';
      case AppThemeType.parliamentary:
        return 'Parliamentary';
      case AppThemeType.assembly:
        return 'Assembly';
      case AppThemeType.localBody:
        return 'Local Body';
    }
  }

  /// Get description for theme type
  String getThemeDescription(AppThemeType themeType) {
    switch (themeType) {
      case AppThemeType.patriotic:
        return 'Saffron & Green - National spirit';
      case AppThemeType.parliamentary:
        return 'Blue & White - Parliamentary elections';
      case AppThemeType.assembly:
        return 'Green & White - State Assembly';
      case AppThemeType.localBody:
        return 'Orange & Brown - Local governance';
    }
  }

  /// Get primary color for theme preview
  Color getThemePrimaryColor(AppThemeType themeType) {
    switch (themeType) {
      case AppThemeType.patriotic:
        return const Color(0xFFFF9933); // Saffron
      case AppThemeType.parliamentary:
        return const Color(0xFF1e40af); // Blue
      case AppThemeType.assembly:
        return const Color(0xFF16a34a); // Green
      case AppThemeType.localBody:
        return const Color(0xFFea580c); // Orange
    }
  }

  /// Get secondary color for theme preview
  Color getThemeSecondaryColor(AppThemeType themeType) {
    switch (themeType) {
      case AppThemeType.patriotic:
        return const Color(0xFF138808); // Forest Green
      case AppThemeType.parliamentary:
        return Colors.white;
      case AppThemeType.assembly:
        return Colors.white;
      case AppThemeType.localBody:
        return const Color(0xFF92400e); // Brown
    }
  }
}
