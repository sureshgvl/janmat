import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:janmat/utils/app_logger.dart';

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
          AppLogger.candidate('Failed to load candidate localizations: $e');
          return false;
        }
      }
      AppLogger.candidate('Failed to load candidate localizations: $e');
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
  String get profile => translate('profile');
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
  String get profession => translate('profession');
  String get languages => translate('languages');
  String get experienceYears => translate('experienceYears');
  String get previousPositions => translate('previousPositions');
  String get city => translate('city');
  String get ward => translate('ward');
  String get independentCandidate => translate('independentCandidate');
  String symbolLabel({required String symbol}) => translate('symbolLabel', args: {'symbol': symbol});
  String get notSpecified => translate('notSpecified');
  String get tapToSelectGender => translate('tapToSelectGender');
  String get languagesCommaSeparated => translate('languagesCommaSeparated');
  String get previousPositionsCommaSeparated => translate('previousPositionsCommaSeparated');
  String get symbolNameForIndependent => translate('symbolNameForIndependent');
  String get useDemoData => translate('useDemoData');
  String get locationNonEditable => translate('locationNonEditable');
  String districtLabel({required String district}) => translate('districtLabel', args: {'district': district});
  String wardLabel({required String ward}) => translate('wardLabel', args: {'ward': ward});
  String get selectDistrict => translate('selectDistrict');
  String get male => translate('male');
  String get female => translate('female');
  String get other => translate('other');
  String get selectArea => translate('selectArea');
  String get selectWard => translate('selectWard');
  String get searchCandidatesHint => translate('searchCandidatesHint');
  String get selectDistrictFirst => translate('selectDistrictFirst');
  String get noAreasAvailable => translate('noAreasAvailable');
  String get selectAreaFirst => translate('selectAreaFirst');
  String get noWardsAvailable => translate('noWardsAvailable');
  String get selectWardFirst => translate('selectWardFirst');
  String get municipalCorporation => translate('municipalCorporation');
  String get municipalCouncil => translate('municipalCouncil');
  String get nagarPanchayat => translate('nagarPanchayat');
  String get zillaParishad => translate('zillaParishad');
  String get panchayatSamiti => translate('panchayatSamiti');
  String get cantonmentBoard => translate('cantonmentBoard');
  String get townAreaCommittee => translate('townAreaCommittee');
  String get notifiedAreaCommittee => translate('notifiedAreaCommittee');
  String get industrialTownship => translate('industrialTownship');

  // Helper method to translate body types
  String translateBodyType(String bodyType) {
    switch (bodyType) {
      case 'municipal_corporation':
        return municipalCorporation;
      case 'municipal_council':
        return municipalCouncil;
      case 'nagar_panchayat':
        return nagarPanchayat;
      case 'zilla_parishad':
        return zillaParishad;
      case 'panchayat_samiti':
        return panchayatSamiti;
      case 'cantonment_board':
        return cantonmentBoard;
      case 'town_area_committee':
        return townAreaCommittee;
      case 'notified_area_committee':
        return notifiedAreaCommittee;
      case 'industrial_township':
        return industrialTownship;
      default:
        return bodyType; // Fallback to original if not found
    }
  }
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

