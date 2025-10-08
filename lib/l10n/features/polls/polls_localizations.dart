import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:janmat/utils/app_logger.dart';

class PollsLocalizations {
  final Locale locale;
  Map<String, String> _localizedStrings = {};

  PollsLocalizations(this.locale);

  static PollsLocalizations? of(BuildContext context) {
    return Localizations.of<PollsLocalizations>(context, PollsLocalizations);
  }

  static const LocalizationsDelegate<PollsLocalizations> delegate = _PollsLocalizationsDelegate();

  Future<bool> load() async {
    try {
      String jsonString = await rootBundle.loadString('lib/l10n/features/polls/polls_${locale.languageCode}.arb');
      Map<String, dynamic> jsonMap = json.decode(jsonString);
      _localizedStrings = jsonMap.map((key, value) => MapEntry(key, value.toString()));
      return true;
    } catch (e) {
      // Fallback to English if the language file doesn't exist
      if (locale.languageCode != 'en') {
        try {
          String jsonString = await rootBundle.loadString('lib/l10n/features/polls/polls_en.arb');
          Map<String, dynamic> jsonMap = json.decode(jsonString);
          _localizedStrings = jsonMap.map((key, value) => MapEntry(key, value.toString()));
          return true;
        } catch (e) {
          AppLogger.common('Failed to load polls localizations: $e');
          return false;
        }
      }
      AppLogger.common('Failed to load polls localizations: $e');
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
  static PollsLocalizations get current {
    final context = Get.context;
    if (context != null) {
      return of(context) ?? PollsLocalizations(const Locale('en'));
    }
    return PollsLocalizations(const Locale('en'));
  }
}

class _PollsLocalizationsDelegate extends LocalizationsDelegate<PollsLocalizations> {
  const _PollsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'mr'].contains(locale.languageCode);
  }

  @override
  Future<PollsLocalizations> load(Locale locale) async {
    PollsLocalizations localizations = PollsLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_PollsLocalizationsDelegate old) => false;
}

// Helper methods to make it easy to use
class PollsTranslations {
  static String tr(String key, {Map<String, String>? args}) {
    return PollsLocalizations.current.translate(key, args: args);
  }

  static String trArgs(String key, Map<String, String> args) {
    return PollsLocalizations.current.translate(key, args: args);
  }
}

