import 'package:flutter/material.dart';
import '../../../core/services/user_prefs_service.dart';

class LanguageService {
  final UserPrefsService _prefs = UserPrefsService();

  // ENABLED: Language persistence using SharedPreferences
  Future<String?> getStoredLanguage() async {
    return _prefs.language;
  }

  // ENABLED: Language persistence using SharedPreferences
  Future<void> setLanguage(String languageCode) async {
    await _prefs.setLanguage(languageCode);
    await _prefs.setLanguageSelected(true); // Mark language as selected
  }

  // Check if it's first time user
  Future<bool> isFirstTimeUser() async {
    return _prefs.isFirstLaunch;
  }

  // Mark user as not first time
  Future<void> markFirstTimeComplete() async {
    await _prefs.completeFirstLaunch();
  }

  // Check if onboarding is completed
  Future<bool> isOnboardingCompleted() async {
    return _prefs.isOnboardingCompleted;
  }

  // Mark onboarding as completed
  Future<void> markOnboardingCompleted() async {
    await _prefs.setOnboardingCompleted(true);
  }

  // Get locale from stored language
  Future<Locale?> getStoredLocale() async {
    final languageCode = await getStoredLanguage();
    if (languageCode != null) {
      return Locale(languageCode);
    }
    return null;
  }

  // DISABLED: Language persistence - no SharedPreferences caching
  Future<void> setDefaultLanguage(String languageCode) async {
    // No-op - no persistence
  }
}

