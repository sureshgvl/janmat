// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'JanMat';

  @override
  String get welcomeMessage => 'Welcome to JanMat';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get sending => 'Sending...';

  @override
  String get sendOTP => 'Send OTP';

  @override
  String enterOTP(Object phone) {
    return 'Enter OTP sent to +91$phone';
  }

  @override
  String get otp => 'OTP';

  @override
  String get verifying => 'Verifying...';

  @override
  String get verifyOTP => 'Verify OTP';

  @override
  String get changePhoneNumber => 'Change Phone Number';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get notifications => 'Notifications';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get about => 'About';

  @override
  String get home => 'Home';

  @override
  String get candidates => 'Candidates';

  @override
  String get chatRooms => 'Chat Rooms';

  @override
  String get polls => 'Polls';

  @override
  String get profile => 'Profile';

  @override
  String get feed => 'Feed';

  @override
  String get browseCandidates => 'Browse Candidates';

  @override
  String get wardDiscussions => 'Ward Discussions';

  @override
  String get surveysPolls => 'Surveys & Polls';

  @override
  String get userAccount => 'User Account';

  @override
  String get votes => 'votes';
}
