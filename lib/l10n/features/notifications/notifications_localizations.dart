import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:janmat/utils/app_logger.dart';

class NotificationsLocalizations {
  final Locale locale;
  Map<String, String> _localizedStrings = {};

  NotificationsLocalizations(this.locale);

  static NotificationsLocalizations? of(BuildContext context) {
    return Localizations.of<NotificationsLocalizations>(context, NotificationsLocalizations);
  }

  static const LocalizationsDelegate<NotificationsLocalizations> delegate = _NotificationsLocalizationsDelegate();

  Future<bool> load() async {
    AppLogger.common('🔍 Loading notifications localizations for ${locale.languageCode}');
    try {
      String jsonString = await rootBundle.loadString('lib/l10n/features/notifications/notifications_${locale.languageCode}.arb');
      Map<String, dynamic> jsonMap = json.decode(jsonString);
      _localizedStrings = jsonMap.map((key, value) => MapEntry(key, value.toString()));
      AppLogger.common('✅ Loaded ${jsonMap.length} notification translations for ${locale.languageCode}');
      return true;
    } catch (e) {
      AppLogger.common('⚠️ Failed to load notifications localizations for ${locale.languageCode}: $e');
      // Fallback to English if the language file doesn't exist
      if (locale.languageCode != 'en') {
        try {
          String jsonString = await rootBundle.loadString('lib/l10n/features/notifications/notifications_en.arb');
          Map<String, dynamic> jsonMap = json.decode(jsonString);
          _localizedStrings = jsonMap.map((key, value) => MapEntry(key, value.toString()));
          AppLogger.common('✅ Loaded fallback English translations (${jsonMap.length} entries)');
          return true;
        } catch (e) {
          AppLogger.error('Failed to load notifications localizations: $e');
          return false;
        }
      }
      AppLogger.error('Failed to load notifications localizations: $e');
      return false;
    }
  }

  String translate(String key, {Map<String, String>? args}) {
    String translation = _localizedStrings[key] ?? key;

    if (translation == key) {
      AppLogger.common('⚠️ No translation found for key: "$key" in ${_localizedStrings.length} entries');
    }

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
  static NotificationsLocalizations get current {
    final context = Get.context;
    if (context != null) {
      return of(context) ?? NotificationsLocalizations(const Locale('en'));
    }
    return NotificationsLocalizations(const Locale('en'));
  }
}

class _NotificationsLocalizationsDelegate extends LocalizationsDelegate<NotificationsLocalizations> {
  const _NotificationsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'mr'].contains(locale.languageCode);
  }

  @override
  Future<NotificationsLocalizations> load(Locale locale) async {
    NotificationsLocalizations localizations = NotificationsLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_NotificationsLocalizationsDelegate old) => false;
}

// Helper methods to make it easy to use
class NotificationsTranslations {
  static String tr(String key, {Map<String, String>? args}) {
    return NotificationsLocalizations.current.translate(key, args: args);
  }

  static String trArgs(String key, Map<String, String> args) {
    return NotificationsLocalizations.current.translate(key, args: args);
  }
}