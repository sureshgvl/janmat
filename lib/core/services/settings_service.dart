import 'user_prefs_service.dart';

/// Service for managing app settings and preferences
/// Provides a clean interface for settings screen functionality
class SettingsService {
  final UserPrefsService _prefs = UserPrefsService();

  // ====================
  // THEME SETTINGS
  // ====================

  /// Get current theme mode
  String get themeMode => _prefs.themeMode;

  /// Set theme mode
  Future<void> setThemeMode(String mode) async {
    await _prefs.setThemeMode(mode);
  }

  /// Check if dark theme is enabled
  bool get isDarkTheme => _prefs.themeMode == 'dark';

  /// Check if system theme is enabled
  bool get isSystemTheme => _prefs.themeMode == 'system';

  // ====================
  // LANGUAGE SETTINGS
  // ====================

  /// Get current language
  String get language => _prefs.language;

  /// Set language
  Future<void> setLanguage(String languageCode) async {
    await _prefs.setLanguage(languageCode);
  }

  /// Check if English is selected
  bool get isEnglish => _prefs.language == 'en';

  /// Check if Marathi is selected
  bool get isMarathi => _prefs.language == 'mr';

  // ====================
  // NOTIFICATION SETTINGS
  // ====================

  /// Check if notifications are enabled
  bool get isNotificationsEnabled => _prefs.isNotificationsEnabled;

  /// Set notifications enabled/disabled
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs.setNotificationsEnabled(enabled);
  }

  // ====================
  // SOUND SETTINGS
  // ====================

  /// Check if sound is enabled
  bool get isSoundEnabled => _prefs.isSoundEnabled;

  /// Set sound enabled/disabled
  Future<void> setSoundEnabled(bool enabled) async {
    await _prefs.setSoundEnabled(enabled);
  }

  // ====================
  // VIBRATION SETTINGS
  // ====================

  /// Check if vibration is enabled
  bool get isVibrationEnabled => _prefs.isVibrationEnabled;

  /// Set vibration enabled/disabled
  Future<void> setVibrationEnabled(bool enabled) async {
    await _prefs.setVibrationEnabled(enabled);
  }

  // ====================
  // APP INFO
  // ====================

  /// Get app launch count
  int get appLaunchCount => _prefs.appLaunchCount;

  /// Increment app launch count
  Future<void> incrementAppLaunchCount() async {
    await _prefs.incrementAppLaunchCount();
  }

  /// Check if it's first launch
  bool get isFirstLaunch => _prefs.isFirstLaunch;

  /// Mark first launch as completed
  Future<void> completeFirstLaunch() async {
    await _prefs.completeFirstLaunch();
  }

  // ====================
  // SETTINGS SUMMARY
  // ====================

  /// Get all settings as a map
  Map<String, dynamic> getAllSettings() {
    return {
      'themeMode': themeMode,
      'language': language,
      'notificationsEnabled': isNotificationsEnabled,
      'soundEnabled': isSoundEnabled,
      'vibrationEnabled': isVibrationEnabled,
      'appLaunchCount': appLaunchCount,
      'isFirstLaunch': isFirstLaunch,
    };
  }

  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    await setThemeMode('system');
    await setLanguage('en');
    await setNotificationsEnabled(true);
    await setSoundEnabled(true);
    await setVibrationEnabled(true);
  }

  /// Export settings (for backup/sharing)
  Map<String, dynamic> exportSettings() {
    return getAllSettings();
  }

  /// Import settings (for restore)
  Future<void> importSettings(Map<String, dynamic> settings) async {
    if (settings.containsKey('themeMode')) {
      await setThemeMode(settings['themeMode']);
    }
    if (settings.containsKey('language')) {
      await setLanguage(settings['language']);
    }
    if (settings.containsKey('notificationsEnabled')) {
      await setNotificationsEnabled(settings['notificationsEnabled']);
    }
    if (settings.containsKey('soundEnabled')) {
      await setSoundEnabled(settings['soundEnabled']);
    }
    if (settings.containsKey('vibrationEnabled')) {
      await setVibrationEnabled(settings['vibrationEnabled']);
    }
  }
}