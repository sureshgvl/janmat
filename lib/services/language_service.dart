import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class LanguageService {
  static const String _languageKey = 'selected_language';
  static const String _firstTimeKey = 'is_first_time';

  // Get stored language preference
  Future<String?> getStoredLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey);
  }

  // Set language preference
  Future<void> setLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
  }

  // Check if it's first time user
  Future<bool> isFirstTimeUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_firstTimeKey) ?? true;
  }

  // Mark user as not first time
  Future<void> markFirstTimeComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstTimeKey, false);
  }

  // Get locale from stored language
  Future<Locale?> getStoredLocale() async {
    final languageCode = await getStoredLanguage();
    if (languageCode != null) {
      return Locale(languageCode);
    }
    return null;
  }

  // Set default language for first time users
  Future<void> setDefaultLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    final existingLanguage = prefs.getString(_languageKey);
    if (existingLanguage == null) {
      await prefs.setString(_languageKey, languageCode);
    }
  }
}

