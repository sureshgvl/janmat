// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Marathi (`mr`).
class AppLocalizationsMr extends AppLocalizations {
  AppLocalizationsMr([String locale = 'mr']) : super(locale);

  @override
  String get appTitle => 'जनमत';

  @override
  String get welcomeMessage => 'जनमतमध्ये आपले स्वागत आहे';

  @override
  String get phoneNumber => 'फोन नंबर';

  @override
  String get sending => 'पाठवत आहे...';

  @override
  String get sendOTP => 'OTP पाठवा';

  @override
  String enterOTP(Object phone) {
    return '+91$phone वर पाठवलेला OTP टाका';
  }

  @override
  String get otp => 'OTP';

  @override
  String get verifying => 'तपासत आहे...';

  @override
  String get verifyOTP => 'OTP सत्यापित करा';

  @override
  String get changePhoneNumber => 'फोन नंबर बदला';

  @override
  String get signInWithGoogle => 'Google सह साइन इन करा';

  @override
  String get settings => 'सेटिंग्ज';

  @override
  String get language => 'भाषा';

  @override
  String get notifications => 'अधिसूचना';

  @override
  String get darkMode => 'डार्क मोड';

  @override
  String get about => 'विषयी';

  @override
  String get home => 'मुख्यपृष्ठ';

  @override
  String get candidates => 'उमेदवार';

  @override
  String get chatRooms => 'गप्पा खोल्या';

  @override
  String get polls => 'मतदान';

  @override
  String get profile => 'प्रोफाइल';

  @override
  String get feed => 'फीड';

  @override
  String get browseCandidates => 'उमेदवार पाहा';

  @override
  String get wardDiscussions => 'वॉर्ड चर्चा';

  @override
  String get surveysPolls => 'सर्वेक्षणे आणि मतदान';

  @override
  String get userAccount => 'वापरकर्ता खाते';

  @override
  String get votes => 'मत';
}
