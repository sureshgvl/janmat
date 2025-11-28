import 'prefs_service.dart';
import '../constants/prefs_keys.dart';

/// Example usage of PrefsService
/// This file demonstrates how to use the SharedPreferences service
class PrefsUsageExample {
  final PrefsService _prefs = PrefsService();

  /// Save login status
  Future<void> saveLoginStatus(bool isLoggedIn) async {
    await _prefs.setBool(PrefKeys.isLoggedIn, isLoggedIn);
  }

  /// Get login status
  bool getLoginStatus() {
    return _prefs.getBool(PrefKeys.isLoggedIn);
  }

  /// Save user profile data
  Future<void> saveUserProfile(Map<String, dynamic> userData) async {
    await _prefs.setJson(PrefKeys.userProfile, userData);
  }

  /// Get user profile data
  Map<String, dynamic>? getUserProfile() {
    return _prefs.getJson(PrefKeys.userProfile);
  }

  /// Save theme preference
  Future<void> saveThemeMode(String themeMode) async {
    await _prefs.setString(PrefKeys.themeMode, themeMode);
  }

  /// Get theme preference
  String getThemeMode() {
    return _prefs.getString(PrefKeys.themeMode) ?? 'system';
  }

  /// Save language preference
  Future<void> saveLanguage(String languageCode) async {
    await _prefs.setString(PrefKeys.language, languageCode);
  }

  /// Get language preference
  String getLanguage() {
    return _prefs.getString(PrefKeys.language) ?? 'en';
  }

  /// Save notification settings
  Future<void> saveNotificationSettings(bool enabled) async {
    await _prefs.setBool(PrefKeys.notificationsEnabled, enabled);
  }

  /// Get notification settings
  bool getNotificationSettings() {
    return _prefs.getBool(PrefKeys.notificationsEnabled, defaultValue: true);
  }

  /// Save app launch count
  Future<void> incrementAppLaunchCount() async {
    final currentCount = _prefs.getInt(PrefKeys.appLaunchCount);
    await _prefs.setInt(PrefKeys.appLaunchCount, currentCount + 1);
  }

  /// Get app launch count
  int getAppLaunchCount() {
    return _prefs.getInt(PrefKeys.appLaunchCount);
  }

  /// Clear all user data (logout)
  Future<void> clearUserData() async {
    await _prefs.remove(PrefKeys.userId);
    await _prefs.remove(PrefKeys.userProfile);
    await _prefs.remove(PrefKeys.authToken);
    await _prefs.setBool(PrefKeys.isLoggedIn, false);
  }

  /// Check if key exists
  bool hasKey(String key) {
    return _prefs.contains(key);
  }

  /// Clear all preferences (for testing/debugging)
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}