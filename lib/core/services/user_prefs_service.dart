import 'prefs_service.dart';
import '../constants/prefs_keys.dart';

/// Service for managing user preferences and app settings using SharedPreferences
/// This provides a clean interface for user flow states and settings
class UserPrefsService {
  final PrefsService _prefs = PrefsService();

  // ====================
  // USER FLOW & ONBOARDING
  // ====================

  /// Check if language has been selected
  bool get isLanguageSelected => _prefs.getBool(PrefKeys.languageSelected);

  /// Set language selection status
  Future<void> setLanguageSelected(bool selected) async {
    await _prefs.setBool(PrefKeys.languageSelected, selected);
  }

  /// Check if role has been selected
  bool get isRoleSelected => _prefs.getBool(PrefKeys.roleSelected);

  /// Set role selection status
  Future<void> setRoleSelected(bool selected) async {
    await _prefs.setBool(PrefKeys.roleSelected, selected);
  }

  /// Check if profile is completed
  bool get isProfileCompleted => _prefs.getBool(PrefKeys.profileCompleted);

  /// Set profile completion status
  Future<void> setProfileCompleted(bool completed) async {
    await _prefs.setBool(PrefKeys.profileCompleted, completed);
  }

  /// Check if onboarding is completed
  bool get isOnboardingCompleted => _prefs.getBool(PrefKeys.onboardingCompleted);

  /// Set onboarding completion status
  Future<void> setOnboardingCompleted(bool completed) async {
    await _prefs.setBool(PrefKeys.onboardingCompleted, completed);
  }

  // ====================
  // APP SETTINGS
  // ====================

  /// Get current theme mode
  String get themeMode => _prefs.getString(PrefKeys.themeMode) ?? 'system';

  /// Set theme mode
  Future<void> setThemeMode(String mode) async {
    await _prefs.setString(PrefKeys.themeMode, mode);
  }

  /// Get current language
  String get language => _prefs.getString(PrefKeys.language) ?? 'en';

  /// Set language
  Future<void> setLanguage(String languageCode) async {
    await _prefs.setString(PrefKeys.language, languageCode);
  }

  /// Check if notifications are enabled
  bool get isNotificationsEnabled => _prefs.getBool(PrefKeys.notificationsEnabled, defaultValue: true);

  /// Set notifications enabled/disabled
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs.setBool(PrefKeys.notificationsEnabled, enabled);
  }

  /// Check if sound is enabled
  bool get isSoundEnabled => _prefs.getBool(PrefKeys.soundEnabled, defaultValue: true);

  /// Set sound enabled/disabled
  Future<void> setSoundEnabled(bool enabled) async {
    await _prefs.setBool(PrefKeys.soundEnabled, enabled);
  }

  /// Check if vibration is enabled
  bool get isVibrationEnabled => _prefs.getBool(PrefKeys.vibrationEnabled, defaultValue: true);

  /// Set vibration enabled/disabled
  Future<void> setVibrationEnabled(bool enabled) async {
    await _prefs.setBool(PrefKeys.vibrationEnabled, enabled);
  }

  // ====================
  // USER DATA
  // ====================

  /// Get user ID
  String? get userId => _prefs.getString(PrefKeys.userId);

  /// Set user ID
  Future<void> setUserId(String userId) async {
    await _prefs.setString(PrefKeys.userId, userId);
  }

  /// Get user profile data
  Map<String, dynamic>? get userProfile => _prefs.getJson(PrefKeys.userProfile);

  /// Set user profile data
  Future<void> setUserProfile(Map<String, dynamic> profile) async {
    await _prefs.setJson(PrefKeys.userProfile, profile);
  }

  /// Check if user is logged in
  bool get isLoggedIn => _prefs.getBool(PrefKeys.isLoggedIn);

  /// Set login status
  Future<void> setLoggedIn(bool loggedIn) async {
    await _prefs.setBool(PrefKeys.isLoggedIn, loggedIn);
  }

  // ====================
  // UTILITY METHODS
  // ====================

  /// Get complete user flow status
  Map<String, bool> getUserFlowStatus() {
    return {
      'languageSelected': isLanguageSelected,
      'roleSelected': isRoleSelected,
      'profileCompleted': isProfileCompleted,
      'onboardingCompleted': isOnboardingCompleted,
    };
  }

  /// Get all app settings
  Map<String, dynamic> getAppSettings() {
    return {
      'themeMode': themeMode,
      'language': language,
      'notificationsEnabled': isNotificationsEnabled,
      'soundEnabled': isSoundEnabled,
      'vibrationEnabled': isVibrationEnabled,
    };
  }

  /// Reset user flow (for logout or reset)
  Future<void> resetUserFlow() async {
    await _prefs.remove(PrefKeys.roleSelected);
    await _prefs.remove(PrefKeys.profileCompleted);
    await _prefs.remove(PrefKeys.onboardingCompleted);
  }

  /// Clear all user data (complete logout)
  Future<void> clearAllUserData() async {
    await _prefs.remove(PrefKeys.userId);
    await _prefs.remove(PrefKeys.userProfile);
    await _prefs.remove(PrefKeys.authToken);
    await _prefs.setBool(PrefKeys.isLoggedIn, false);
    await resetUserFlow();
  }

  /// Check if this is first launch
  bool get isFirstLaunch => _prefs.getBool(PrefKeys.firstLaunch, defaultValue: true);

  /// Mark first launch as completed
  Future<void> completeFirstLaunch() async {
    await _prefs.setBool(PrefKeys.firstLaunch, false);
  }

  /// Get app launch count
  int get appLaunchCount => _prefs.getInt(PrefKeys.appLaunchCount);

  /// Increment app launch count
  Future<void> incrementAppLaunchCount() async {
    final currentCount = appLaunchCount;
    await _prefs.setInt(PrefKeys.appLaunchCount, currentCount + 1);
  }
}