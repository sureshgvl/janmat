import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/snackbar_utils.dart';
import '../services/language_service.dart';

class LanguageController extends GetxController {
  final LanguageService _languageService = LanguageService();

  // Reactive locale that MaterialApp binds to
  final Rx<Locale> currentLocale = const Locale('en').obs;

  @override
  void onInit() {
    super.onInit();
    _initializeLanguage();
  }

  Future<void> _initializeLanguage() async {
    try {
      final storedLanguage = await _languageService.getStoredLanguage();
      if (storedLanguage != null && storedLanguage != currentLocale.value.languageCode) {
        currentLocale.value = Locale(storedLanguage);
      }
    } catch (e) {
      // Keep default English on error
    }
  }

  Future<bool> changeLanguage(String languageCode) async {
    try {
      print('🔄 LANGUAGE CHANGE START: $languageCode');
      print('📍 Current locale before: ${currentLocale.value}');

      // Save preference first
      await _languageService.setLanguage(languageCode);

      // Update reactive locale - MaterialApp will rebuild automatically through Obx
      currentLocale.value = Locale(languageCode);

      print('✅ New locale set: ${currentLocale.value}');
      print('⚡ MaterialApp rebuilds instantly (no app restart needed)');

      // Show brief success message
      SnackbarUtils.showSuccess(languageCode == 'en' ? 'Switched to English' : 'मराठीमध्ये बदलले');

      return true;
    } catch (e) {
      print('❌ Language change failed: $e');
      SnackbarUtils.showError(languageCode == 'en' ? 'Failed to change language' : 'भाषा बदलण्यात अयशस्वी');
      return false;
    }
  }

  // Get current language code for UI state management
  String get currentLanguageCode => currentLocale.value.languageCode;
}
