import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class SettingsLocalizations {
  final Locale locale;
  Map<String, String> _localizedStrings = {};

  SettingsLocalizations(this.locale);

  static SettingsLocalizations? of(BuildContext context) {
    return Localizations.of<SettingsLocalizations>(context, SettingsLocalizations);
  }

  static const LocalizationsDelegate<SettingsLocalizations> delegate = _SettingsLocalizationsDelegate();

  Future<bool> load() async {
    try {
      String jsonString = await rootBundle.loadString('lib/l10n/features/settings/settings_${locale.languageCode}.arb');
      Map<String, dynamic> jsonMap = json.decode(jsonString);
      _localizedStrings = jsonMap.map((key, value) => MapEntry(key, value.toString()));
      return true;
    } catch (e) {
      // Fallback to English if the language file doesn't exist
      if (locale.languageCode != 'en') {
        try {
          String jsonString = await rootBundle.loadString('lib/l10n/features/settings/settings_en.arb');
          Map<String, dynamic> jsonMap = json.decode(jsonString);
          _localizedStrings = jsonMap.map((key, value) => MapEntry(key, value.toString()));
          return true;
        } catch (e) {
          debugPrint('Failed to load settings localizations: $e');
          return false;
        }
      }
      debugPrint('Failed to load settings localizations: $e');
      return false;
    }
  }

  String translate(String key, {Map<String, String>? args}) {
    String translation = _localizedStrings[key] ?? key;

    if (args != null) {
      args.forEach((argKey, value) {
        translation = translation.replaceAll('{$argKey}', value);
      });
    }

    return translation;
  }

  // Convenience method that works like GetX .tr
  String tr(String key, {Map<String, String>? args}) {
    return translate(key, args: args);
  }

  // Get the current instance
  static SettingsLocalizations get current {
    final context = Get.context;
    if (context != null) {
      return of(context) ?? SettingsLocalizations(const Locale('en'));
    }
    return SettingsLocalizations(const Locale('en'));
  }
}

class _SettingsLocalizationsDelegate extends LocalizationsDelegate<SettingsLocalizations> {
  const _SettingsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'mr'].contains(locale.languageCode);
  }

  @override
  Future<SettingsLocalizations> load(Locale locale) async {
    SettingsLocalizations localizations = SettingsLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_SettingsLocalizationsDelegate old) => false;
}

// Helper methods to make it easy to use
class SettingsTranslations {
  static String tr(String key, {Map<String, String>? args}) {
    return SettingsLocalizations.current.translate(key, args: args);
  }

  static String trArgs(String key, Map<String, String> args) {
    return SettingsLocalizations.current.translate(key, args: args);
  }
}

