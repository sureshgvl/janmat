import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_theme.dart';
import '../utils/app_logger.dart';

/// Available background color types for candidate profiles
enum BackgroundColorType {
  light,    // Very light saffron (default)
  cream,    // Cream
  blue,     // Light blue
  green,    // Light green
  gray,     // Light gray
}

/// Controller for managing background color selection for candidate profiles
class BackgroundColorController extends GetxController {
  static const String _backgroundColorKey = 'selected_background_color';

  // Reactive background color state
  final Rx<BackgroundColorType> currentBackgroundColorType = BackgroundColorType.light.obs;
  final Rx<Color> currentBackgroundColor = AppTheme.backgroundColorLight.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSavedBackgroundColor();
  }

  /// Load saved background color from SharedPreferences
  Future<void> _loadSavedBackgroundColor() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedBackgroundColorIndex = prefs.getInt(_backgroundColorKey);

      if (savedBackgroundColorIndex != null) {
        final backgroundColorType = BackgroundColorType.values[savedBackgroundColorIndex];
        await changeBackgroundColor(backgroundColorType, saveToPrefs: false);
        AppLogger.core('🎨 Loaded saved background color: ${backgroundColorType.name}');
      } else {
        // Default to light background color
        currentBackgroundColorType.value = BackgroundColorType.light;
        currentBackgroundColor.value = AppTheme.backgroundColorLight;
        AppLogger.core('🎨 Using default light background color');
      }
    } catch (e) {
      AppLogger.coreError('❌ Failed to load saved background color', error: e);
      // Fallback to default
      currentBackgroundColorType.value = BackgroundColorType.light;
      currentBackgroundColor.value = AppTheme.backgroundColorLight;
    }
  }

  /// Change the background color
  Future<void> changeBackgroundColor(BackgroundColorType backgroundColorType, {bool saveToPrefs = true}) async {
    try {
      currentBackgroundColorType.value = backgroundColorType;

      // Get the appropriate background color
      Color newBackgroundColor;
      switch (backgroundColorType) {
        case BackgroundColorType.light:
          newBackgroundColor = AppTheme.backgroundColorLight;
          break;
        case BackgroundColorType.cream:
          newBackgroundColor = AppTheme.backgroundColorCream;
          break;
        case BackgroundColorType.blue:
          newBackgroundColor = AppTheme.backgroundColorBlue;
          break;
        case BackgroundColorType.green:
          newBackgroundColor = AppTheme.backgroundColorGreen;
          break;
        case BackgroundColorType.gray:
          newBackgroundColor = AppTheme.backgroundColorGray;
          break;
      }

      currentBackgroundColor.value = newBackgroundColor;

      // Save to preferences if requested
      if (saveToPrefs) {
        await _saveBackgroundColorToPrefs(backgroundColorType);
      }

      AppLogger.core('🎨 Background color changed to: ${backgroundColorType.name}');
    } catch (e) {
      AppLogger.coreError('❌ Failed to change background color', error: e);
    }
  }

  /// Save background color preference to SharedPreferences
  Future<void> _saveBackgroundColorToPrefs(BackgroundColorType backgroundColorType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_backgroundColorKey, backgroundColorType.index);
      AppLogger.core('💾 Background color preference saved: ${backgroundColorType.name}');
    } catch (e) {
      AppLogger.coreError('❌ Failed to save background color preference', error: e);
    }
  }

  /// Get display name for background color type
  String getBackgroundColorDisplayName(BackgroundColorType backgroundColorType) {
    switch (backgroundColorType) {
      case BackgroundColorType.light:
        return 'Light Saffron';
      case BackgroundColorType.cream:
        return 'Cream';
      case BackgroundColorType.blue:
        return 'Light Blue';
      case BackgroundColorType.green:
        return 'Light Green';
      case BackgroundColorType.gray:
        return 'Light Gray';
    }
  }

  /// Get description for background color type
  String getBackgroundColorDescription(BackgroundColorType backgroundColorType) {
    switch (backgroundColorType) {
      case BackgroundColorType.light:
        return 'Very light saffron - Default theme';
      case BackgroundColorType.cream:
        return 'Soft cream - Warm and elegant';
      case BackgroundColorType.blue:
        return 'Light blue - Calm and professional';
      case BackgroundColorType.green:
        return 'Light green - Fresh and natural';
      case BackgroundColorType.gray:
        return 'Light gray - Modern and neutral';
    }
  }

  /// Get the actual color for background color preview
  Color getBackgroundColor(BackgroundColorType backgroundColorType) {
    switch (backgroundColorType) {
      case BackgroundColorType.light:
        return AppTheme.backgroundColorLight;
      case BackgroundColorType.cream:
        return AppTheme.backgroundColorCream;
      case BackgroundColorType.blue:
        return AppTheme.backgroundColorBlue;
      case BackgroundColorType.green:
        return AppTheme.backgroundColorGreen;
      case BackgroundColorType.gray:
        return AppTheme.backgroundColorGray;
    }
  }

  /// Get adaptive surface color for cards based on background
  /// All backgrounds are very light, so white cards work well with good contrast
  Color getAdaptiveSurfaceColor(BackgroundColorType backgroundColorType) {
    // For very light backgrounds, white surfaces provide excellent contrast
    // This ensures WCAG AA compliance (4.5:1 contrast ratio minimum)
    return Colors.white;
  }

  /// Get adaptive text color for optimal contrast
  Color getAdaptiveTextColor(BackgroundColorType backgroundColorType) {
    // All backgrounds are very light, so dark text provides excellent contrast
    return const Color(0xFF1F2937); // Dark charcoal - same as theme
  }
}
