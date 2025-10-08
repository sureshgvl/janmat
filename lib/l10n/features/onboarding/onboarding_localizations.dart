import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:janmat/utils/app_logger.dart';

// Embedded translations for synchronous access
const Map<String, Map<String, String>> _embeddedTranslations = {
  'en': {
    "welcomeTitle": "Welcome to JanMat",
    "welcomeSubtitle": "Connect with your ward's future leaders through transparent, direct communication",
    "candidatesTitle": "Know Your Candidates",
    "candidatesSubtitle": "Browse comprehensive candidate profiles, read manifestos, and access contact information for ward-specific election insights",
    "chatTitle": "Real-Time Dialogue",
    "chatSubtitle": "Direct messaging with ward candidates, group discussions, and gamified communication with XP rewards",
    "pollsTitle": "Participate in Democracy",
    "pollsSubtitle": "Vote in election-related polls, view real-time results, and engage in community discussions",
    "locationTitle": "Ward-Specific Content",
    "locationSubtitle": "Location-based candidate discovery, ward discussions, and localized election information",
    "premiumTitle": "Enhanced Engagement",
    "premiumSubtitle": "XP rewards, premium messaging, advanced analytics, and achievement badges for active participation",
    "skip": "Skip",
    "next": "Next",
    "getStarted": "Get Started"
  },
  'mr': {
    "welcomeTitle": "जनमतमध्ये आपले स्वागत",
    "welcomeSubtitle": "आपल्या वॉर्डच्या भविष्यातील नेत्यांशी पारदर्शक, थेट संवादाद्वारे जोडा",
    "candidatesTitle": "आपल्या उमेदवारांना जाणून घ्या",
    "candidatesSubtitle": "सर्वसमावेशक उमेदवार प्रोफाइल ब्राउझ करा, घोषणापत्र वाचा आणि वॉर्ड-विशिष्ट निवडणूक माहितीसाठी संपर्क माहिती मिळवा",
    "chatTitle": "रिअल-टाइम संवाद",
    "chatSubtitle": "वॉर्ड उमेदवारांशी थेट मेसेजिंग, ग्रुप चर्चा आणि XP बक्षीसांसह गेमिफाइड संवाद",
    "pollsTitle": "लोकशाहीत सहभागी व्हा",
    "pollsSubtitle": "निवडणूक-संबंधित मतदानात मत द्या, रिअल-टाइम निकाल पहा आणि समुदाय चर्चेत सहभागी व्हा",
    "locationTitle": "वॉर्ड-विशिष्ट सामग्री",
    "locationSubtitle": "स्थान-आधारित उमेदवार शोध, वॉर्ड चर्चा आणि स्थानिक निवडणूक माहिती",
    "premiumTitle": "वर्धित सहभाग",
    "premiumSubtitle": "XP बक्षिसे, प्रीमियम मेसेजिंग, प्रगत विश्लेषण आणि सक्रिय सहभागासाठी achievement badges",
    "skip": "वगळा",
    "next": "पुढे",
    "getStarted": "सुरू करा"
  }
};

class OnboardingLocalizations {
  final Locale locale;
  late final Map<String, String> _localizedStrings;

  OnboardingLocalizations(this.locale) {
    _localizedStrings = _embeddedTranslations[locale.languageCode] ?? _embeddedTranslations['en'] ?? {};
    AppLogger.common('✅ OnboardingLocalizations: Initialized ${locale.languageCode} with ${_localizedStrings.length} embedded strings');
  }

  static OnboardingLocalizations? of(BuildContext context) {
    return Localizations.of<OnboardingLocalizations>(context, OnboardingLocalizations);
  }

  static const LocalizationsDelegate<OnboardingLocalizations> delegate = _OnboardingLocalizationsDelegate();

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

  // Getter methods for common onboarding strings
  String get welcomeTitle => translate('welcomeTitle');
  String get welcomeSubtitle => translate('welcomeSubtitle');
  String get candidatesTitle => translate('candidatesTitle');
  String get candidatesSubtitle => translate('candidatesSubtitle');
  String get chatTitle => translate('chatTitle');
  String get chatSubtitle => translate('chatSubtitle');
  String get pollsTitle => translate('pollsTitle');
  String get pollsSubtitle => translate('pollsSubtitle');
  String get locationTitle => translate('locationTitle');
  String get locationSubtitle => translate('locationSubtitle');
  String get premiumTitle => translate('premiumTitle');
  String get premiumSubtitle => translate('premiumSubtitle');
  String get skip => translate('skip');
  String get next => translate('next');
  String get getStarted => translate('getStarted');

  // Get the current instance
  static OnboardingLocalizations get current {
    final context = Get.context;
    if (context != null) {
      return of(context) ?? OnboardingLocalizations(const Locale('en'));
    }
    return OnboardingLocalizations(const Locale('en'));
  }
}

class _OnboardingLocalizationsDelegate extends LocalizationsDelegate<OnboardingLocalizations> {
  const _OnboardingLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'mr'].contains(locale.languageCode);
  }

  @override
  Future<OnboardingLocalizations> load(Locale locale) {
    return SynchronousFuture<OnboardingLocalizations>(OnboardingLocalizations(locale));
  }

  @override
  bool shouldReload(_OnboardingLocalizationsDelegate old) => false;
}

// Helper methods to make it easy to use
class OnboardingTranslations {
  static String tr(String key, {Map<String, String>? args}) {
    return OnboardingLocalizations.current.translate(key, args: args);
  }

  static String trArgs(String key, Map<String, String> args) {
    return OnboardingLocalizations.current.translate(key, args: args);
  }
}