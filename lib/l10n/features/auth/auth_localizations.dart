import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

// Embedded translations for synchronous access
const Map<String, Map<String, String>> _embeddedTranslations = {
  'en': {
    "welcomeToJanMat": "Welcome to JanMat",
    "pleaseSelectYourPreferredLanguage": "Please select your preferred language",
    "english": "English",
    "continueInEnglish": "Continue in English",
    "marathi": "मराठी",
    "continueInMarathi": "मराठीमध्ये सुरू ठेवा",
    "continue": "Continue",
    "janmat": "Janmat",
    "phoneVerificationNotice": "📱 For phone verification, a browser may open to complete the security check. Please complete the verification and return to the app.",
    "sendingOTP": "Sending OTP...",
    "verificationMayTakeTime": "This may take a moment if verification is required.",
    "sending": "Sending...",
    "verifyingOTP": "Verifying OTP...",
    "resendOTP": "Resend OTP",
    "resendOTPIn": "Resend OTP in {time}s",
    "continueAs": "Continue as {name}",
    "signInWithDifferentAccount": "Sign in with different account",
    "chooseHowToSignIn": "Choose how you want to sign in",
    "signingIn": "Signing in...",
    "chooseYourRole": "Choose Your Role",
    "howWouldYouLikeToParticipate": "How would you like to participate?",
    "selectYourRoleToCustomizeExperience": "Select your role to customize your experience in the community.",
    "voter": "Voter",
    "stayInformedAndParticipateInDiscussions": "Stay informed and participate in discussions",
    "accessWardDiscussionsPollsAndCommunityUpdates": "Access ward discussions, polls, and community updates",
    "candidate": "Candidate",
    "runForOfficeAndConnectWithVoters": "Run for office and connect with voters",
    "createYourProfileShareManifestoAndEngageWithCommunity": "Create your profile, share manifesto, and engage with community",
    "continueButton": "Continue",
    "youCanChangeYourRoleLaterInSettings": "You can change your role later in settings",
    "phoneNumber": "Phone Number",
    "sendOTP": "Send OTP",
    "enterOTP": "Enter OTP sent to +91{phone}",
    "otp": "OTP",
    "verifyOTP": "Verify OTP",
    "changePhoneNumber": "Change Phone Number",
    "signInWithGoogle": "Sign in with Google",
    "pleaseSelectARoleToContinue": "Please select a role to continue",
    "roleSelected": "Role Selected!",
    "youSelectedCandidatePleaseCompleteYourProfile": "You selected Candidate. Please complete your profile.",
    "youSelectedVoterPleaseCompleteYourProfile": "You selected Voter. Please complete your profile.",
    "failedToSaveRole": "Failed to save role: {error}"
  },
  'mr': {
    "welcomeToJanMat": "जन्मतमध्ये आपले स्वागत",
    "pleaseSelectYourPreferredLanguage": "कृपया आपली पसंतीची भाषा निवडा",
    "english": "English",
    "continueInEnglish": "English मध्ये सुरू ठेवा",
    "marathi": "मराठी",
    "continueInMarathi": "मराठीमध्ये सुरू ठेवा",
    "continue": "सुरू ठेवा",
    "janmat": "जन्मत",
    "phoneVerificationNotice": "📱 फोन वेरिफिकेशनसाठी, सुरक्षा चेक पूर्ण करण्यासाठी ब्राउझर उघडू शकतो. कृपया वेरिफिकेशन पूर्ण करा आणि अॅपमध्ये परत या.",
    "sendingOTP": "OTP पाठवत आहे...",
    "verificationMayTakeTime": "जर वेरिफिकेशन आवश्यक असेल तर याला थोडा वेळ लागू शकतो.",
    "sending": "पाठवत आहे...",
    "verifyingOTP": "OTP वेरिफाई करत आहे...",
    "resendOTP": "OTP पुन्हा पाठवा",
    "resendOTPIn": "OTP पुन्हा पाठवा {time} सेकंदात",
    "continueAs": "{name} म्हणून सुरू ठेवा",
    "signInWithDifferentAccount": "वेगळ्या खात्याने साइन इन करा",
    "chooseHowToSignIn": "आपण कसे साइन इन करू इच्छिता ते निवडा",
    "signingIn": "साइन इन करत आहे...",
    "chooseYourRole": "आपली भूमिका निवडा",
    "howWouldYouLikeToParticipate": "आपण कसे सहभागी होऊ इच्छिता?",
    "selectYourRoleToCustomizeExperience": "आपले अनुभव सानुकूलित करण्यासाठी आपली भूमिका निवडा",
    "voter": "मतदार",
    "stayInformedAndParticipateInDiscussions": "माहितीपूर्ण रहा आणि चर्चेत सहभागी व्हा",
    "accessWardDiscussionsPollsAndCommunityUpdates": "वॉर्ड चर्चा, मतदान आणि समुदाय अपडेट्समध्ये प्रवेश मिळवा",
    "candidate": "उमेदवार",
    "runForOfficeAndConnectWithVoters": "पदासाठी उभे राहा आणि मतदारांशी जोडा",
    "createYourProfileShareManifestoAndEngageWithCommunity": "आपले प्रोफाइल तयार करा, घोषणापत्र सामायिक करा आणि समुदायाशी संलग्न व्हा",
    "continueButton": "सुरू ठेवा",
    "youCanChangeYourRoleLaterInSettings": "आपण नंतर सेटिंग्जमध्ये आपली भूमिका बदलू शकता",
    "phoneNumber": "फोन नंबर",
    "sendOTP": "OTP पाठवा",
    "enterOTP": "+91{phone} वर पाठवलेला OTP टाका",
    "otp": "OTP",
    "verifyOTP": "OTP सत्यापित करा",
    "changePhoneNumber": "फोन नंबर बदला",
    "signInWithGoogle": "Google सह साइन इन करा",
    "pleaseSelectARoleToContinue": "सुरू ठेवण्यासाठी कृपया भूमिका निवडा",
    "roleSelected": "भूमिका निवडली!",
    "youSelectedCandidatePleaseCompleteYourProfile": "आपण उमेदवार निवडला आहे. कृपया आपले प्रोफाइल पूर्ण करा.",
    "youSelectedVoterPleaseCompleteYourProfile": "आपण मतदार निवडला आहे. कृपया आपले प्रोफाइल पूर्ण करा.",
    "failedToSaveRole": "भूमिका जतन करण्यात अयशस्वी: {error}"
  }
};

class AuthLocalizations {
  final Locale locale;
  late final Map<String, String> _localizedStrings;

  AuthLocalizations(this.locale) {
    _localizedStrings = _embeddedTranslations[locale.languageCode] ?? _embeddedTranslations['en'] ?? {};
    debugPrint('✅ AuthLocalizations: Initialized ${locale.languageCode} with ${_localizedStrings.length} embedded strings');
  }

  static AuthLocalizations? of(BuildContext context) {
    return Localizations.of<AuthLocalizations>(context, AuthLocalizations);
  }

  static const LocalizationsDelegate<AuthLocalizations> delegate = _AuthLocalizationsDelegate();

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

  // Getter methods for common auth strings (like flutter gen-l10n)
  String get janmat => translate('janmat');
  String get phoneVerificationNotice => translate('phoneVerificationNotice');
  String get sendingOTP => translate('sendingOTP');
  String get verificationMayTakeTime => translate('verificationMayTakeTime');
  String get sending => translate('sending');
  String get verifyingOTP => translate('verifyingOTP');
  String get resendOTP => translate('resendOTP');
  String resendOTPIn(Object time) => translate('resendOTPIn', args: {'time': time.toString()});
  String continueAs(Object name) => translate('continueAs', args: {'name': name.toString()});
  String get signInWithDifferentAccount => translate('signInWithDifferentAccount');
  String get chooseHowToSignIn => translate('chooseHowToSignIn');
  String get signingIn => translate('signingIn');
  String get chooseYourRole => translate('chooseYourRole');
  String get howWouldYouLikeToParticipate => translate('howWouldYouLikeToParticipate');
  String get selectYourRoleToCustomizeExperience => translate('selectYourRoleToCustomizeExperience');
  String get voter => translate('voter');
  String get stayInformedAndParticipateInDiscussions => translate('stayInformedAndParticipateInDiscussions');
  String get accessWardDiscussionsPollsAndCommunityUpdates => translate('accessWardDiscussionsPollsAndCommunityUpdates');
  String get candidate => translate('candidate');
  String get runForOfficeAndConnectWithVoters => translate('runForOfficeAndConnectWithVoters');
  String get createYourProfileShareManifestoAndEngageWithCommunity => translate('createYourProfileShareManifestoAndEngageWithCommunity');
  String get continueButton => translate('continueButton');
  String get youCanChangeYourRoleLaterInSettings => translate('youCanChangeYourRoleLaterInSettings');
  String get pleaseSelectARoleToContinue => translate('pleaseSelectARoleToContinue');
  String get roleSelected => translate('roleSelected');
  String get youSelectedCandidatePleaseCompleteYourProfile => translate('youSelectedCandidatePleaseCompleteYourProfile');
  String get youSelectedVoterPleaseCompleteYourProfile => translate('youSelectedVoterPleaseCompleteYourProfile');
  String failedToSaveRole(Object error) => translate('failedToSaveRole', args: {'error': error.toString()});
  String enterOTP(Object phone) => translate('enterOTP', args: {'phone': phone.toString()});
  String get otp => translate('otp');
  String get verifyOTP => translate('verifyOTP');
  String get changePhoneNumber => translate('changePhoneNumber');

  // Get the current instance
  static AuthLocalizations get current {
    final context = Get.context;
    if (context != null) {
      return of(context) ?? AuthLocalizations(const Locale('en'));
    }
    return AuthLocalizations(const Locale('en'));
  }
}

class _AuthLocalizationsDelegate extends LocalizationsDelegate<AuthLocalizations> {
  const _AuthLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'mr'].contains(locale.languageCode);
  }

  @override
  Future<AuthLocalizations> load(Locale locale) {
    return SynchronousFuture<AuthLocalizations>(AuthLocalizations(locale));
  }

  @override
  bool shouldReload(_AuthLocalizationsDelegate old) => false;
}

// Helper methods to make it easy to use
class AuthTranslations {
  static String tr(String key, {Map<String, String>? args}) {
    return AuthLocalizations.current.translate(key, args: args);
  }

  static String trArgs(String key, Map<String, String> args) {
    return AuthLocalizations.current.translate(key, args: args);
  }
}

