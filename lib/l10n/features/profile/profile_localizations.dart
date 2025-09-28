import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class ProfileLocalizations {
  final Locale locale;
  Map<String, String> _localizedStrings = {};

  ProfileLocalizations(this.locale);

  static ProfileLocalizations? of(BuildContext context) {
    return Localizations.of<ProfileLocalizations>(context, ProfileLocalizations);
  }

  static const LocalizationsDelegate<ProfileLocalizations> delegate = _ProfileLocalizationsDelegate();

  Future<bool> load() async {
    try {
      String jsonString = await rootBundle.loadString('lib/l10n/features/profile/profile_${locale.languageCode}.arb');
      Map<String, dynamic> jsonMap = json.decode(jsonString);
      _localizedStrings = jsonMap.map((key, value) => MapEntry(key, value.toString()));
      return true;
    } catch (e) {
      // Fallback to English if the language file doesn't exist
      if (locale.languageCode != 'en') {
        try {
          String jsonString = await rootBundle.loadString('lib/l10n/features/profile/profile_en.arb');
          Map<String, dynamic> jsonMap = json.decode(jsonString);
          _localizedStrings = jsonMap.map((key, value) => MapEntry(key, value.toString()));
          return true;
        } catch (e) {
          debugPrint('Failed to load profile localizations: $e');
          return false;
        }
      }
      debugPrint('Failed to load profile localizations: $e');
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
  static ProfileLocalizations get current {
    final context = Get.context;
    if (context != null) {
      return of(context) ?? ProfileLocalizations(const Locale('en'));
    }
    return ProfileLocalizations(const Locale('en'));
  }

  // Convenience getters for common translations
  String get welcomeCompleteYourProfile => translate('welcomeCompleteYourProfile');
  String get autoFilledFromAccount => translate('autoFilledFromAccount');
  String get fullNameRequired => translate('fullNameRequired');
  String get enterYourFullName => translate('enterYourFullName');
  String get phoneNumberRequired => translate('phoneNumberRequired');
  String get enterYourPhoneNumber => translate('enterYourPhoneNumber');
  String get birthDateRequired => translate('birthDateRequired');
  String get selectYourBirthDate => translate('selectYourBirthDate');
  String get genderRequired => translate('genderRequired');
  String get male => translate('male');
  String get female => translate('female');
  String get other => translate('other');
  String get preferNotToSay => translate('preferNotToSay');
  String get stateRequired => translate('stateRequired');
  String get selectYourState => translate('selectYourState');
  String get selectStateFirst => translate('selectStateFirst');
  String get districtRequired => translate('districtRequired');
  String get selectYourDistrict => translate('selectYourDistrict');
  String get selectDistrictFirst => translate('selectDistrictFirst');
  String get selectAreaFirst => translate('selectAreaFirst');
  String get bodyRequired => translate('bodyRequired');
  String get selectYourBody => translate('selectYourBody');
  String get cityRequired => translate('cityRequired');
  String get selectYourCity => translate('selectYourCity');
  String get wardRequired => translate('wardRequired');
  String get selectYourWard => translate('selectYourWard');
  String get areaRequired => translate('areaRequired');
  String get selectYourArea => translate('selectYourArea');
  String get politicalPartyRequired => translate('politicalPartyRequired');
  String get pleaseSelectYourPoliticalParty => translate('pleaseSelectYourPoliticalParty');
  String get completeProfile => translate('completeProfile');
  String get requiredFields => translate('requiredFields');
  String get pleaseEnterYourName => translate('pleaseEnterYourName');
  String get nameMustBeAtLeast2Characters => translate('nameMustBeAtLeast2Characters');
  String get pleaseEnterYourPhoneNumber => translate('pleaseEnterYourPhoneNumber');
  String get phoneNumberMustBe10Digits => translate('phoneNumberMustBe10Digits');
  String get pleaseEnterValidPhoneNumber => translate('pleaseEnterValidPhoneNumber');
  String get pleaseSelectYourBirthDate => translate('pleaseSelectYourBirthDate');
  String get pleaseSelectYourGender => translate('pleaseSelectYourGender');
  String get pleaseFillAllRequiredFields => translate('pleaseFillAllRequiredFields');
  String get error => translate('error');
  String get success => translate('success');
  String get profileCompleted => translate('profileCompleted');
  String failedToSaveProfile(String error) => translate('failedToSaveProfile', args: {'error': error});
  String get completeYourProfile => translate('completeYourProfile');
  String preFilledFromAccount(String loginMethod) => translate('preFilledFromAccount', args: {'loginMethod': loginMethod});
  String failedToLoadWards(String error) => translate('failedToLoadWards', args: {'error': error});
  String get profileCompletedMessage => translate('profileCompletedMessage');
  String get selectDistrict => translate('selectDistrict');
  String get searchDistricts => translate('searchDistricts');
  String get areaLabel => translate('areaLabel');
  String get selectAreaLabel => translate('selectAreaLabel');
  String get noAreasAvailable => translate('noAreasAvailable');
  String wardDisplayFormat(String number, String name) => translate('wardDisplayFormat', args: {'number': number, 'name': name});
  String get selectWardLabel => translate('selectWardLabel');
  String get noWardsAvailable => translate('noWardsAvailable');
  String get sampleStatesAdded => translate('sampleStatesAdded');
  String failedToAddSampleStates(String error) => translate('failedToAddSampleStates', args: {'error': error});
  String get addSampleStatesDebug => translate('addSampleStatesDebug');
  String get viewWardAreas => translate('viewWardAreas');
  String get searchWards => translate('searchWards');
  String get wardAreasTitle => translate('wardAreasTitle');

  // ZP+PS Election strings
  String get selectElectionType => translate('selectElectionType');
  String get electionTypeRequired => translate('electionTypeRequired');
  String get municipalCorporation => translate('municipalCorporation');
  String get municipalCouncil => translate('municipalCouncil');
  String get nagarPanchayat => translate('nagarPanchayat');
  String get zillaParishad => translate('zillaParishad');
  String get panchayatSamiti => translate('panchayatSamiti');
  String get zpPsCombined => translate('zpPsCombined');
  String get regularElection => translate('regularElection');
  String get zpBodyRequired => translate('zpBodyRequired');
  String get selectZPBody => translate('selectZPBody');
  String get zpWardRequired => translate('zpWardRequired');
  String get selectZPWard => translate('selectZPWard');
  String get zpAreaRequired => translate('zpAreaRequired');
  String get selectZPArea => translate('selectZPArea');
  String get psBodyRequired => translate('psBodyRequired');
  String get selectPSBody => translate('selectPSBody');
  String get psWardRequired => translate('psWardRequired');
  String get selectPSWard => translate('selectPSWard');
  String get psAreaRequired => translate('psAreaRequired');
  String get selectPSArea => translate('selectPSArea');
  String get selectElectionTypeFirst => translate('selectElectionTypeFirst');
  String get selectZPBodyFirst => translate('selectZPBodyFirst');
  String get selectPSBodyFirst => translate('selectPSBodyFirst');
  String get noZPBodiesAvailable => translate('noZPBodiesAvailable');
  String get noPSBodiesAvailable => translate('noPSBodiesAvailable');
  String get noZPWardsAvailable => translate('noZPWardsAvailable');
  String get noPSWardsAvailable => translate('noPSWardsAvailable');
  String get zpAreaLabel => translate('zpAreaLabel');
  String get psAreaLabel => translate('psAreaLabel');
  String get selectZPWardLabel => translate('selectZPWardLabel');
  String get selectPSWardLabel => translate('selectPSWardLabel');
  String get selectZPAreaLabel => translate('selectZPAreaLabel');
  String get selectPSAreaLabel => translate('selectPSAreaLabel');
  String zpWardDisplayFormat(String id) => translate('zpWardDisplayFormat', args: {'id': id});
  String psWardDisplayFormat(String id) => translate('psWardDisplayFormat', args: {'id': id});
  String get combinedElectionDescription => translate('combinedElectionDescription');
  String get regularElectionDescription => translate('regularElectionDescription');
  String get selectPoliticalParty => translate('selectPoliticalParty');
  String get selectYourPoliticalParty => translate('selectYourPoliticalParty');

}

class _ProfileLocalizationsDelegate extends LocalizationsDelegate<ProfileLocalizations> {
  const _ProfileLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'mr'].contains(locale.languageCode);
  }

  @override
  Future<ProfileLocalizations> load(Locale locale) async {
    ProfileLocalizations localizations = ProfileLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_ProfileLocalizationsDelegate old) => false;
}

// Helper methods to make it easy to use
class ProfileTranslations {
  static String tr(String key, {Map<String, String>? args}) {
    return ProfileLocalizations.current.translate(key, args: args);
  }

  static String trArgs(String key, Map<String, String> args) {
    return ProfileLocalizations.current.translate(key, args: args);
  }
}