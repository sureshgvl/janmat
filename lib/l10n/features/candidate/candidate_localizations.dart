import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class CandidateLocalizations {
  final Locale locale;
  Map<String, String> _localizedStrings = {};

  CandidateLocalizations(this.locale);

  static CandidateLocalizations? of(BuildContext context) {
    return Localizations.of<CandidateLocalizations>(context, CandidateLocalizations);
  }

  static const LocalizationsDelegate<CandidateLocalizations> delegate = _CandidateLocalizationsDelegate();

  Future<bool> load() async {
    try {
      String jsonString = await rootBundle.loadString('lib/l10n/features/candidate/candidate_${locale.languageCode}.arb');
      Map<String, dynamic> jsonMap = json.decode(jsonString);
      _localizedStrings = jsonMap.map((key, value) => MapEntry(key, value.toString()));
      return true;
    } catch (e) {
      // Fallback to English if the language file doesn't exist
      if (locale.languageCode != 'en') {
        try {
          String jsonString = await rootBundle.loadString('lib/l10n/features/candidate/candidate_en.arb');
          Map<String, dynamic> jsonMap = json.decode(jsonString);
          _localizedStrings = jsonMap.map((key, value) => MapEntry(key, value.toString()));
          return true;
        } catch (e) {
          debugPrint('Failed to load candidate localizations: $e');
          return false;
        }
      }
      debugPrint('Failed to load candidate localizations: $e');
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
  static CandidateLocalizations get current {
    final context = Get.context;
    if (context != null) {
      return of(context) ?? CandidateLocalizations(const Locale('en'));
    }
    return CandidateLocalizations(const Locale('en'));
  }

  // Getter methods for common candidate strings
  String get candidateDataNotFound => translate('candidateDataNotFound');
  String get info => translate('info');
  String get manifesto => translate('manifesto');
  String get achievements => translate('achievements');
  String get media => translate('media');
  String get contact => translate('contact');
  String get events => translate('events');
  String get analytics => translate('analytics');
  String get candidateProfile => translate('candidateProfile');
  String get candidateDataNotAvailable => translate('candidateDataNotAvailable');
  String get candidateDashboard => translate('candidateDashboard');
  String get basicInfo => translate('basicInfo');
  String get searchCandidates => translate('searchCandidates');
  String get noCandidatesFound => translate('noCandidatesFound');
  String get selectWardToViewCandidates => translate('selectWardToViewCandidates');
  String get candidateDetails => translate('candidateDetails');
  String get fullName => translate('fullName');
  String get personalInformation => translate('personalInformation');
  String get wardInfo => translate('wardInfo');
  String get joinedDate => translate('joinedDate');
  String get age => translate('age');
  String get gender => translate('gender');
  String get education => translate('education');
  String get address => translate('address');
}

class _CandidateLocalizationsDelegate extends LocalizationsDelegate<CandidateLocalizations> {
  const _CandidateLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'mr'].contains(locale.languageCode);
  }

  @override
  Future<CandidateLocalizations> load(Locale locale) async {
    CandidateLocalizations localizations = CandidateLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_CandidateLocalizationsDelegate old) => false;
}

// Helper methods to make it easy to use
class CandidateTranslations {
  static String tr(String key, {Map<String, String>? args}) {
    return CandidateLocalizations.current.translate(key, args: args);
  }

  static String trArgs(String key, Map<String, String> args) {
    return CandidateLocalizations.current.translate(key, args: args);
  }
}