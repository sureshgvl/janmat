import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_mr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('mr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'JanMat'**
  String get appTitle;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome to JanMat'**
  String get welcomeMessage;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get sending;

  /// No description provided for @sendOTP.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOTP;

  /// No description provided for @enterOTP.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP sent to +91{phone}'**
  String enterOTP(Object phone);

  /// No description provided for @otp.
  ///
  /// In en, this message translates to:
  /// **'OTP'**
  String get otp;

  /// No description provided for @verifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying...'**
  String get verifying;

  /// No description provided for @verifyOTP.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verifyOTP;

  /// No description provided for @changePhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Change Phone Number'**
  String get changePhoneNumber;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @candidates.
  ///
  /// In en, this message translates to:
  /// **'Candidates'**
  String get candidates;

  /// No description provided for @chatRooms.
  ///
  /// In en, this message translates to:
  /// **'Chat Rooms'**
  String get chatRooms;

  /// No description provided for @polls.
  ///
  /// In en, this message translates to:
  /// **'Polls'**
  String get polls;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @feed.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get feed;

  /// No description provided for @browseCandidates.
  ///
  /// In en, this message translates to:
  /// **'Browse Candidates'**
  String get browseCandidates;

  /// No description provided for @wardDiscussions.
  ///
  /// In en, this message translates to:
  /// **'Ward Discussions'**
  String get wardDiscussions;

  /// No description provided for @surveysPolls.
  ///
  /// In en, this message translates to:
  /// **'Surveys & Polls'**
  String get surveysPolls;

  /// No description provided for @userAccount.
  ///
  /// In en, this message translates to:
  /// **'User Account'**
  String get userAccount;

  /// No description provided for @votes.
  ///
  /// In en, this message translates to:
  /// **'votes'**
  String get votes;

  /// No description provided for @myAreaCandidates.
  ///
  /// In en, this message translates to:
  /// **'My Area Candidates'**
  String get myAreaCandidates;

  /// No description provided for @candidatesFromYourWard.
  ///
  /// In en, this message translates to:
  /// **'Candidates from your ward'**
  String get candidatesFromYourWard;

  /// No description provided for @candidateDashboard.
  ///
  /// In en, this message translates to:
  /// **'Candidate Dashboard'**
  String get candidateDashboard;

  /// No description provided for @searchByWard.
  ///
  /// In en, this message translates to:
  /// **'Search by Ward'**
  String get searchByWard;

  /// No description provided for @premiumFeatures.
  ///
  /// In en, this message translates to:
  /// **'Premium Features'**
  String get premiumFeatures;

  /// No description provided for @upgradeToUnlockPremiumFeatures.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to unlock premium features'**
  String get upgradeToUnlockPremiumFeatures;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @permanentlyDeleteYourAccountAndData.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account and data'**
  String get permanentlyDeleteYourAccountAndData;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @failedToLogout.
  ///
  /// In en, this message translates to:
  /// **'Failed to logout: {error}'**
  String failedToLogout(Object error);

  /// No description provided for @manageYourCampaignAndConnectWithVoters.
  ///
  /// In en, this message translates to:
  /// **'Manage your campaign and connect with voters'**
  String get manageYourCampaignAndConnectWithVoters;

  /// No description provided for @stayInformedAboutYourLocalCandidates.
  ///
  /// In en, this message translates to:
  /// **'Stay informed about your local candidates'**
  String get stayInformedAboutYourLocalCandidates;

  /// No description provided for @premiumTrialActive.
  ///
  /// In en, this message translates to:
  /// **'Premium Trial Active'**
  String get premiumTrialActive;

  /// No description provided for @oneDayRemainingUpgrade.
  ///
  /// In en, this message translates to:
  /// **'1 day remaining - Upgrade to continue premium features!'**
  String get oneDayRemainingUpgrade;

  /// No description provided for @daysRemainingInTrial.
  ///
  /// In en, this message translates to:
  /// **'{days} days remaining in your trial'**
  String daysRemainingInTrial(Object days);

  /// No description provided for @upgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgrade;

  /// No description provided for @upgradeAvailable.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Available'**
  String get upgradeAvailable;

  /// No description provided for @premiumUpgradeFeatureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Premium upgrade feature coming soon!'**
  String get premiumUpgradeFeatureComingSoon;

  /// No description provided for @unlockPremiumFeatures.
  ///
  /// In en, this message translates to:
  /// **'Unlock Premium Features'**
  String get unlockPremiumFeatures;

  /// No description provided for @enjoyFullPremiumFeaturesDuringTrial.
  ///
  /// In en, this message translates to:
  /// **'Enjoy full premium features during your trial'**
  String get enjoyFullPremiumFeaturesDuringTrial;

  /// No description provided for @getPremiumVisibilityAndAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Get premium visibility and analytics'**
  String get getPremiumVisibilityAndAnalytics;

  /// No description provided for @accessExclusiveContentAndFeatures.
  ///
  /// In en, this message translates to:
  /// **'Access exclusive content and features'**
  String get accessExclusiveContentAndFeatures;

  /// No description provided for @explorePremium.
  ///
  /// In en, this message translates to:
  /// **'Explore Premium'**
  String get explorePremium;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @myArea.
  ///
  /// In en, this message translates to:
  /// **'My Area'**
  String get myArea;

  /// No description provided for @manageYourCampaign.
  ///
  /// In en, this message translates to:
  /// **'Manage Your Campaign'**
  String get manageYourCampaign;

  /// No description provided for @viewAnalyticsAndUpdateYourProfile.
  ///
  /// In en, this message translates to:
  /// **'View analytics and update your profile'**
  String get viewAnalyticsAndUpdateYourProfile;

  /// No description provided for @deleteAccountConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This action cannot be undone and will permanently delete all your data including:\n\n• Your profile information\n• Chat conversations and messages\n• XP points and rewards\n• Following/followers data\n\nThis action is irreversible.'**
  String get deleteAccountConfirmation;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @accountDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted successfully.'**
  String get accountDeletedSuccessfully;

  /// No description provided for @failedToDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete account: {error}'**
  String failedToDeleteAccount(Object error);

  /// No description provided for @userDataNotFound.
  ///
  /// In en, this message translates to:
  /// **'User data not found'**
  String get userDataNotFound;

  /// No description provided for @accountDetails.
  ///
  /// In en, this message translates to:
  /// **'Account Details'**
  String get accountDetails;

  /// No description provided for @premium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @xpPoints.
  ///
  /// In en, this message translates to:
  /// **'XP Points'**
  String get xpPoints;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @searchCandidates.
  ///
  /// In en, this message translates to:
  /// **'Search Candidates'**
  String get searchCandidates;

  /// No description provided for @selectCity.
  ///
  /// In en, this message translates to:
  /// **'Select City'**
  String get selectCity;

  /// No description provided for @selectWard.
  ///
  /// In en, this message translates to:
  /// **'Select Ward'**
  String get selectWard;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @noCandidatesFound.
  ///
  /// In en, this message translates to:
  /// **'No candidates found'**
  String get noCandidatesFound;

  /// No description provided for @selectWardToViewCandidates.
  ///
  /// In en, this message translates to:
  /// **'Select a ward to view candidates'**
  String get selectWardToViewCandidates;

  /// No description provided for @sponsored.
  ///
  /// In en, this message translates to:
  /// **'SPONSORED'**
  String get sponsored;

  /// No description provided for @loadingMessages.
  ///
  /// In en, this message translates to:
  /// **'Loading messages...'**
  String get loadingMessages;

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYet;

  /// No description provided for @startConversation.
  ///
  /// In en, this message translates to:
  /// **'Start the conversation in {roomName}'**
  String startConversation(Object roomName);

  /// No description provided for @sendImage.
  ///
  /// In en, this message translates to:
  /// **'Send Image'**
  String get sendImage;

  /// No description provided for @createPoll.
  ///
  /// In en, this message translates to:
  /// **'Create Poll'**
  String get createPoll;

  /// No description provided for @pollCreated.
  ///
  /// In en, this message translates to:
  /// **'Poll Created!'**
  String get pollCreated;

  /// No description provided for @pollSharedInChat.
  ///
  /// In en, this message translates to:
  /// **'Your poll has been shared in the chat'**
  String get pollSharedInChat;

  /// No description provided for @roomInfo.
  ///
  /// In en, this message translates to:
  /// **'Room Info'**
  String get roomInfo;

  /// No description provided for @leaveRoom.
  ///
  /// In en, this message translates to:
  /// **'Leave Room'**
  String get leaveRoom;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @public.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get public;

  /// No description provided for @private.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get private;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @initializeSampleData.
  ///
  /// In en, this message translates to:
  /// **'Initialize Sample Data'**
  String get initializeSampleData;

  /// No description provided for @refreshWardRoom.
  ///
  /// In en, this message translates to:
  /// **'Refresh Ward Room'**
  String get refreshWardRoom;

  /// No description provided for @debug.
  ///
  /// In en, this message translates to:
  /// **'Debug'**
  String get debug;

  /// No description provided for @userDataRefreshed.
  ///
  /// In en, this message translates to:
  /// **'User data refreshed and ward room checked'**
  String get userDataRefreshed;

  /// No description provided for @refreshChatRooms.
  ///
  /// In en, this message translates to:
  /// **'Refresh Chat Rooms'**
  String get refreshChatRooms;

  /// No description provided for @refreshed.
  ///
  /// In en, this message translates to:
  /// **'Refreshed'**
  String get refreshed;

  /// No description provided for @chatRoomsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Chat rooms updated'**
  String get chatRoomsUpdated;

  /// No description provided for @noChatRoomsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No chat rooms available'**
  String get noChatRoomsAvailable;

  /// No description provided for @chatRoomsWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Chat rooms will appear here when available\nUser: {userName}'**
  String chatRoomsWillAppearHere(Object userName);

  /// No description provided for @refreshRooms.
  ///
  /// In en, this message translates to:
  /// **'Refresh Rooms'**
  String get refreshRooms;

  /// No description provided for @watchAd.
  ///
  /// In en, this message translates to:
  /// **'Watch Ad'**
  String get watchAd;

  /// No description provided for @messageLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Message Limit Reached'**
  String get messageLimitReached;

  /// No description provided for @messageLimitReachedDescription.
  ///
  /// In en, this message translates to:
  /// **'You have reached your daily message limit. Choose an option to continue:'**
  String get messageLimitReachedDescription;

  /// No description provided for @remainingMessages.
  ///
  /// In en, this message translates to:
  /// **'Remaining messages: {count}'**
  String remainingMessages(Object count);

  /// No description provided for @watchAdForXP.
  ///
  /// In en, this message translates to:
  /// **'Watch Ad (+3-5 XP)'**
  String get watchAdForXP;

  /// No description provided for @buyXP.
  ///
  /// In en, this message translates to:
  /// **'Buy XP'**
  String get buyXP;

  /// No description provided for @earnedExtraMessages.
  ///
  /// In en, this message translates to:
  /// **'You earned 10 extra messages!'**
  String get earnedExtraMessages;

  /// No description provided for @loadingRewardedAd.
  ///
  /// In en, this message translates to:
  /// **'Loading rewarded ad...'**
  String get loadingRewardedAd;

  /// No description provided for @createNewChatRoom.
  ///
  /// In en, this message translates to:
  /// **'Create New Chat Room'**
  String get createNewChatRoom;

  /// No description provided for @roomTitle.
  ///
  /// In en, this message translates to:
  /// **'Room Title'**
  String get roomTitle;

  /// No description provided for @enterRoomName.
  ///
  /// In en, this message translates to:
  /// **'Enter room name'**
  String get enterRoomName;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get descriptionOptional;

  /// No description provided for @briefDescriptionOfRoom.
  ///
  /// In en, this message translates to:
  /// **'Brief description of the room'**
  String get briefDescriptionOfRoom;

  /// No description provided for @roomType.
  ///
  /// In en, this message translates to:
  /// **'Room Type'**
  String get roomType;

  /// No description provided for @publicRoom.
  ///
  /// In en, this message translates to:
  /// **'Public Room'**
  String get publicRoom;

  /// No description provided for @privateRoom.
  ///
  /// In en, this message translates to:
  /// **'Private Room'**
  String get privateRoom;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @initializeSampleDataDescription.
  ///
  /// In en, this message translates to:
  /// **'This will create sample chat rooms and messages for testing purposes. This is only available for admin users.\n\nContinue?'**
  String get initializeSampleDataDescription;

  /// No description provided for @initialize.
  ///
  /// In en, this message translates to:
  /// **'Initialize'**
  String get initialize;

  /// No description provided for @candidateDataNotFound.
  ///
  /// In en, this message translates to:
  /// **'Candidate data not found'**
  String get candidateDataNotFound;

  /// No description provided for @candidateProfile.
  ///
  /// In en, this message translates to:
  /// **'Candidate Profile'**
  String get candidateProfile;

  /// No description provided for @candidateDataNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Candidate data not available'**
  String get candidateDataNotAvailable;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'VERIFIED'**
  String get verified;

  /// No description provided for @followers.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get followers;

  /// No description provided for @following.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get following;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @manifesto.
  ///
  /// In en, this message translates to:
  /// **'Manifesto'**
  String get manifesto;

  /// No description provided for @media.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get media;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @wardInfo.
  ///
  /// In en, this message translates to:
  /// **'Ward {wardId} • {cityId}'**
  String wardInfo(Object cityId, Object wardId);

  /// No description provided for @joinedDate.
  ///
  /// In en, this message translates to:
  /// **'Joined {date}'**
  String joinedDate(Object date);

  /// No description provided for @viewAllFollowers.
  ///
  /// In en, this message translates to:
  /// **'View all followers'**
  String get viewAllFollowers;

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @upcomingEvents.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Events'**
  String get upcomingEvents;

  /// No description provided for @translationFailed.
  ///
  /// In en, this message translates to:
  /// **'Translation failed: {error}'**
  String translationFailed(Object error);

  /// No description provided for @downloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get downloadPdf;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @marathi.
  ///
  /// In en, this message translates to:
  /// **'मराठी'**
  String get marathi;

  /// No description provided for @noManifestoAvailable.
  ///
  /// In en, this message translates to:
  /// **'No manifesto available'**
  String get noManifestoAvailable;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @demoVideo.
  ///
  /// In en, this message translates to:
  /// **'Demo Video'**
  String get demoVideo;

  /// No description provided for @janMatAppDemo.
  ///
  /// In en, this message translates to:
  /// **'JanMat App Demo'**
  String get janMatAppDemo;

  /// No description provided for @fullscreen.
  ///
  /// In en, this message translates to:
  /// **'Fullscreen'**
  String get fullscreen;

  /// No description provided for @janMatAppDemoDescription.
  ///
  /// In en, this message translates to:
  /// **'JanMat App Demo - Watch how our platform works'**
  String get janMatAppDemoDescription;

  /// No description provided for @videos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get videos;

  /// No description provided for @youtubeChannel.
  ///
  /// In en, this message translates to:
  /// **'YouTube Channel'**
  String get youtubeChannel;

  /// No description provided for @watchVideosAndUpdates.
  ///
  /// In en, this message translates to:
  /// **'Watch videos and updates'**
  String get watchVideosAndUpdates;

  /// No description provided for @noMediaAvailable.
  ///
  /// In en, this message translates to:
  /// **'No media available'**
  String get noMediaAvailable;

  /// No description provided for @contactInformation.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get contactInformation;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @socialMedia.
  ///
  /// In en, this message translates to:
  /// **'Social Media'**
  String get socialMedia;

  /// No description provided for @party_bjp.
  ///
  /// In en, this message translates to:
  /// **'Bharatiya Janata Party'**
  String get party_bjp;

  /// No description provided for @party_inc.
  ///
  /// In en, this message translates to:
  /// **'Indian National Congress'**
  String get party_inc;

  /// No description provided for @party_ss_ubt.
  ///
  /// In en, this message translates to:
  /// **'Shiv Sena (Uddhav Balasaheb Thackeray)'**
  String get party_ss_ubt;

  /// No description provided for @party_ss_shinde.
  ///
  /// In en, this message translates to:
  /// **'Balasahebanchi Shiv Sena (Shinde)'**
  String get party_ss_shinde;

  /// No description provided for @party_ncp_ajit.
  ///
  /// In en, this message translates to:
  /// **'Nationalist Congress Party (Ajit Pawar)'**
  String get party_ncp_ajit;

  /// No description provided for @party_ncp_sp.
  ///
  /// In en, this message translates to:
  /// **'Nationalist Congress Party (Sharad Pawar)'**
  String get party_ncp_sp;

  /// No description provided for @party_mns.
  ///
  /// In en, this message translates to:
  /// **'Maharashtra Navnirman Sena'**
  String get party_mns;

  /// No description provided for @party_pwpi.
  ///
  /// In en, this message translates to:
  /// **'Peasants and Workers Party of India'**
  String get party_pwpi;

  /// No description provided for @party_cpi_m.
  ///
  /// In en, this message translates to:
  /// **'Communist Party of India (Marxist)'**
  String get party_cpi_m;

  /// No description provided for @party_rsp.
  ///
  /// In en, this message translates to:
  /// **'Rashtriya Samaj Paksha'**
  String get party_rsp;

  /// No description provided for @party_sp.
  ///
  /// In en, this message translates to:
  /// **'Samajwadi Party'**
  String get party_sp;

  /// No description provided for @party_bsp.
  ///
  /// In en, this message translates to:
  /// **'Bahujan Samaj Party'**
  String get party_bsp;

  /// No description provided for @party_bva.
  ///
  /// In en, this message translates to:
  /// **'Bahujan Vikas Aaghadi'**
  String get party_bva;

  /// No description provided for @party_republican_sena.
  ///
  /// In en, this message translates to:
  /// **'Republican Sena'**
  String get party_republican_sena;

  /// No description provided for @party_abs.
  ///
  /// In en, this message translates to:
  /// **'Akhil Bharatiya Sena'**
  String get party_abs;

  /// No description provided for @party_vba.
  ///
  /// In en, this message translates to:
  /// **'Vanchit Bahujan Aghadi'**
  String get party_vba;

  /// No description provided for @party_independent.
  ///
  /// In en, this message translates to:
  /// **'Independents'**
  String get party_independent;

  /// No description provided for @changePartySymbolTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Party & Symbol'**
  String get changePartySymbolTitle;

  /// No description provided for @updateButton.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateButton;

  /// No description provided for @updatePartyAffiliationHeader.
  ///
  /// In en, this message translates to:
  /// **'Update Your Party Affiliation'**
  String get updatePartyAffiliationHeader;

  /// No description provided for @updatePartyAffiliationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Change your party or become independent with a custom symbol.'**
  String get updatePartyAffiliationSubtitle;

  /// No description provided for @currentParty.
  ///
  /// In en, this message translates to:
  /// **'Current Party'**
  String get currentParty;

  /// No description provided for @symbolLabel.
  ///
  /// In en, this message translates to:
  /// **'Symbol: {symbol}'**
  String symbolLabel(Object symbol);

  /// No description provided for @newPartyLabel.
  ///
  /// In en, this message translates to:
  /// **'New Party *'**
  String get newPartyLabel;

  /// No description provided for @selectPartyValidation.
  ///
  /// In en, this message translates to:
  /// **'Please select your party'**
  String get selectPartyValidation;

  /// No description provided for @symbolNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Symbol Name *'**
  String get symbolNameLabel;

  /// No description provided for @symbolNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Table, Chair, Whistle, Book, etc.'**
  String get symbolNameHint;

  /// No description provided for @symbolNameValidation.
  ///
  /// In en, this message translates to:
  /// **'Please enter a symbol name for independent candidates'**
  String get symbolNameValidation;

  /// No description provided for @symbolImageOptional.
  ///
  /// In en, this message translates to:
  /// **'Symbol Image (Optional)'**
  String get symbolImageOptional;

  /// No description provided for @symbolImageDescription.
  ///
  /// In en, this message translates to:
  /// **'Upload an image of your chosen symbol. If not provided, a default icon will be used.'**
  String get symbolImageDescription;

  /// No description provided for @uploadSymbolImage.
  ///
  /// In en, this message translates to:
  /// **'Upload Symbol Image'**
  String get uploadSymbolImage;

  /// No description provided for @importantNotice.
  ///
  /// In en, this message translates to:
  /// **'Important Notice'**
  String get importantNotice;

  /// No description provided for @partyChangeWarning.
  ///
  /// In en, this message translates to:
  /// **'Changing your party affiliation will update your profile immediately. This change will be visible to all voters.'**
  String get partyChangeWarning;

  /// No description provided for @partyUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your party and symbol have been updated successfully!'**
  String get partyUpdateSuccess;

  /// No description provided for @partyUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Failed to update party and symbol: {error}'**
  String partyUpdateError(Object error);

  /// No description provided for @symbolUploadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Symbol image uploaded successfully'**
  String get symbolUploadSuccess;

  /// No description provided for @symbolUploadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload symbol image: {error}'**
  String symbolUploadError(Object error);

  /// No description provided for @symbolImageSizeLimitError.
  ///
  /// In en, this message translates to:
  /// **'Image size must be less than 5MB. Please select a smaller image.'**
  String get symbolImageSizeLimitError;

  /// No description provided for @updatingText.
  ///
  /// In en, this message translates to:
  /// **'Updating...'**
  String get updatingText;

  /// No description provided for @updateInstructionText.
  ///
  /// In en, this message translates to:
  /// **'Tap update to save your party and symbol changes'**
  String get updateInstructionText;

  /// No description provided for @chooseYourRole.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Role'**
  String get chooseYourRole;

  /// No description provided for @howWouldYouLikeToParticipate.
  ///
  /// In en, this message translates to:
  /// **'How would you like to participate?'**
  String get howWouldYouLikeToParticipate;

  /// No description provided for @selectYourRoleToCustomizeExperience.
  ///
  /// In en, this message translates to:
  /// **'Select your role to customize your experience in the community.'**
  String get selectYourRoleToCustomizeExperience;

  /// No description provided for @voter.
  ///
  /// In en, this message translates to:
  /// **'Voter'**
  String get voter;

  /// No description provided for @stayInformedAndParticipateInDiscussions.
  ///
  /// In en, this message translates to:
  /// **'Stay informed and participate in discussions'**
  String get stayInformedAndParticipateInDiscussions;

  /// No description provided for @accessWardDiscussionsPollsAndCommunityUpdates.
  ///
  /// In en, this message translates to:
  /// **'Access ward discussions, polls, and community updates'**
  String get accessWardDiscussionsPollsAndCommunityUpdates;

  /// No description provided for @candidate.
  ///
  /// In en, this message translates to:
  /// **'Candidate'**
  String get candidate;

  /// No description provided for @runForOfficeAndConnectWithVoters.
  ///
  /// In en, this message translates to:
  /// **'Run for office and connect with voters'**
  String get runForOfficeAndConnectWithVoters;

  /// No description provided for @createYourProfileShareManifestoAndEngageWithCommunity.
  ///
  /// In en, this message translates to:
  /// **'Create your profile, share manifesto, and engage with community'**
  String get createYourProfileShareManifestoAndEngageWithCommunity;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @youCanChangeYourRoleLaterInSettings.
  ///
  /// In en, this message translates to:
  /// **'You can change your role later in settings'**
  String get youCanChangeYourRoleLaterInSettings;

  /// No description provided for @pleaseSelectARoleToContinue.
  ///
  /// In en, this message translates to:
  /// **'Please select a role to continue'**
  String get pleaseSelectARoleToContinue;

  /// No description provided for @roleSelected.
  ///
  /// In en, this message translates to:
  /// **'Role Selected!'**
  String get roleSelected;

  /// No description provided for @youSelectedCandidatePleaseCompleteYourProfile.
  ///
  /// In en, this message translates to:
  /// **'You selected Candidate. Please complete your profile.'**
  String get youSelectedCandidatePleaseCompleteYourProfile;

  /// No description provided for @youSelectedVoterPleaseCompleteYourProfile.
  ///
  /// In en, this message translates to:
  /// **'You selected Voter. Please complete your profile.'**
  String get youSelectedVoterPleaseCompleteYourProfile;

  /// No description provided for @failedToSaveRole.
  ///
  /// In en, this message translates to:
  /// **'Failed to save role: {error}'**
  String failedToSaveRole(Object error);

  /// No description provided for @completeYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete Your Profile'**
  String get completeYourProfile;

  /// No description provided for @welcomeCompleteYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Welcome! Please complete your profile to continue.'**
  String get welcomeCompleteYourProfile;

  /// No description provided for @preFilledFromAccount.
  ///
  /// In en, this message translates to:
  /// **'Some information has been pre-filled from {loginMethod}. This helps us connect you with your local community.'**
  String preFilledFromAccount(Object loginMethod);

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @fullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full Name *'**
  String get fullNameRequired;

  /// No description provided for @enterYourFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterYourFullName;

  /// No description provided for @phoneNumberRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone Number *'**
  String get phoneNumberRequired;

  /// No description provided for @enterYourPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get enterYourPhoneNumber;

  /// No description provided for @birthDateRequired.
  ///
  /// In en, this message translates to:
  /// **'Birth Date *'**
  String get birthDateRequired;

  /// No description provided for @selectYourBirthDate.
  ///
  /// In en, this message translates to:
  /// **'Select your birth date'**
  String get selectYourBirthDate;

  /// No description provided for @genderRequired.
  ///
  /// In en, this message translates to:
  /// **'Gender *'**
  String get genderRequired;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @preferNotToSay.
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get preferNotToSay;

  /// No description provided for @cityRequired.
  ///
  /// In en, this message translates to:
  /// **'City *'**
  String get cityRequired;

  /// No description provided for @selectYourCity.
  ///
  /// In en, this message translates to:
  /// **'Select your city'**
  String get selectYourCity;

  /// No description provided for @wardRequired.
  ///
  /// In en, this message translates to:
  /// **'Ward *'**
  String get wardRequired;

  /// No description provided for @selectYourWard.
  ///
  /// In en, this message translates to:
  /// **'Select your ward'**
  String get selectYourWard;

  /// No description provided for @selectCityFirst.
  ///
  /// In en, this message translates to:
  /// **'Select city first'**
  String get selectCityFirst;

  /// No description provided for @completeProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete Profile'**
  String get completeProfile;

  /// No description provided for @requiredFields.
  ///
  /// In en, this message translates to:
  /// **'* Required fields'**
  String get requiredFields;

  /// No description provided for @pleaseEnterYourName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get pleaseEnterYourName;

  /// No description provided for @nameMustBeAtLeast2Characters.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get nameMustBeAtLeast2Characters;

  /// No description provided for @pleaseEnterYourPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get pleaseEnterYourPhoneNumber;

  /// No description provided for @phoneNumberMustBe10Digits.
  ///
  /// In en, this message translates to:
  /// **'Phone number must be 10 digits'**
  String get phoneNumberMustBe10Digits;

  /// No description provided for @pleaseEnterValidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get pleaseEnterValidPhoneNumber;

  /// No description provided for @pleaseSelectYourBirthDate.
  ///
  /// In en, this message translates to:
  /// **'Please select your birth date'**
  String get pleaseSelectYourBirthDate;

  /// No description provided for @pleaseSelectYourGender.
  ///
  /// In en, this message translates to:
  /// **'Please select your gender'**
  String get pleaseSelectYourGender;

  /// No description provided for @pleaseFillAllRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all required fields'**
  String get pleaseFillAllRequiredFields;

  /// No description provided for @failedToLoadCities.
  ///
  /// In en, this message translates to:
  /// **'Failed to load cities: {error}'**
  String failedToLoadCities(Object error);

  /// No description provided for @failedToLoadWards.
  ///
  /// In en, this message translates to:
  /// **'Failed to load wards: {error}'**
  String failedToLoadWards(Object error);

  /// No description provided for @failedToSaveProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to save profile: {error}'**
  String failedToSaveProfile(Object error);

  /// No description provided for @profileCompleted.
  ///
  /// In en, this message translates to:
  /// **'Profile Completed!'**
  String get profileCompleted;

  /// No description provided for @basicProfileCompletedSetupCandidate.
  ///
  /// In en, this message translates to:
  /// **'Basic profile completed. Now set up your candidate profile.'**
  String get basicProfileCompletedSetupCandidate;

  /// No description provided for @profileCompletedWardChatCreated.
  ///
  /// In en, this message translates to:
  /// **'Profile completed! Your ward chat room has been created.'**
  String get profileCompletedWardChatCreated;

  /// No description provided for @autoFilledFromAccount.
  ///
  /// In en, this message translates to:
  /// **'Auto-filled from your account'**
  String get autoFilledFromAccount;

  /// No description provided for @completeCandidateProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete Candidate Profile'**
  String get completeCandidateProfile;

  /// No description provided for @completeYourCandidateProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete Your Candidate Profile'**
  String get completeYourCandidateProfile;

  /// No description provided for @fillDetailsCreateCandidateProfile.
  ///
  /// In en, this message translates to:
  /// **'Fill in your details to create your candidate profile and start engaging with voters.'**
  String get fillDetailsCreateCandidateProfile;

  /// No description provided for @enterFullNameAsOnBallot.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name as it appears on ballot'**
  String get enterFullNameAsOnBallot;

  /// No description provided for @politicalPartyRequired.
  ///
  /// In en, this message translates to:
  /// **'Political Party *'**
  String get politicalPartyRequired;

  /// No description provided for @symbolNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Symbol Name *'**
  String get symbolNameRequired;

  /// No description provided for @manifestoOptional.
  ///
  /// In en, this message translates to:
  /// **'Manifesto (Optional)'**
  String get manifestoOptional;

  /// No description provided for @brieflyDescribeKeyPromises.
  ///
  /// In en, this message translates to:
  /// **'Briefly describe your key promises and vision for the community'**
  String get brieflyDescribeKeyPromises;

  /// No description provided for @updateCandidateProfile.
  ///
  /// In en, this message translates to:
  /// **'Update Candidate Profile'**
  String get updateCandidateProfile;

  /// No description provided for @whatHappensNext.
  ///
  /// In en, this message translates to:
  /// **'What happens next?'**
  String get whatHappensNext;

  /// No description provided for @candidateProfileBenefits.
  ///
  /// In en, this message translates to:
  /// **'• Your profile will be created and visible to voters\n• You can access the Candidate Dashboard to manage your campaign\n• Premium features will be available for enhanced visibility\n• You can update your manifesto, contact info, and media anytime'**
  String get candidateProfileBenefits;

  /// No description provided for @changeRoleSelection.
  ///
  /// In en, this message translates to:
  /// **'Change Role Selection'**
  String get changeRoleSelection;

  /// No description provided for @pleaseSelectYourParty.
  ///
  /// In en, this message translates to:
  /// **'Please select your party'**
  String get pleaseSelectYourParty;

  /// No description provided for @failedToCreateCandidateProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to create candidate profile: {error}'**
  String failedToCreateCandidateProfile(Object error);

  /// No description provided for @imageSizeMustBeLessThan5MB.
  ///
  /// In en, this message translates to:
  /// **'Image size must be less than 5MB. Please select a smaller image.'**
  String get imageSizeMustBeLessThan5MB;

  /// No description provided for @failedToUploadSymbolImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload symbol image: {error}'**
  String failedToUploadSymbolImage(Object error);

  /// No description provided for @candidateProfileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Success!'**
  String get candidateProfileUpdated;

  /// No description provided for @candidateProfileUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your candidate profile has been updated! You have 3 days of premium access to try all features.'**
  String get candidateProfileUpdatedMessage;

  /// No description provided for @symbolImageUploadedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Symbol image uploaded successfully'**
  String get symbolImageUploadedSuccessfully;

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get uploading;

  /// No description provided for @max5MB.
  ///
  /// In en, this message translates to:
  /// **'Max 5MB'**
  String get max5MB;

  /// No description provided for @uploadImageOfChosenSymbol.
  ///
  /// In en, this message translates to:
  /// **'Upload an image of your chosen symbol. If not provided, a default icon will be used.'**
  String get uploadImageOfChosenSymbol;

  /// No description provided for @supportedFormatsJPGPNGMax5MB.
  ///
  /// In en, this message translates to:
  /// **'Supported formats: JPG, PNG. Maximum file size: 5MB.'**
  String get supportedFormatsJPGPNGMax5MB;

  /// No description provided for @imageUploadedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Image uploaded successfully'**
  String get imageUploadedSuccessfully;

  /// No description provided for @pleaseEnterSymbolNameForIndependent.
  ///
  /// In en, this message translates to:
  /// **'Please enter a symbol name for independent candidates'**
  String get pleaseEnterSymbolNameForIndependent;

  /// No description provided for @pleaseSelectYourPoliticalParty.
  ///
  /// In en, this message translates to:
  /// **'Please select your political party'**
  String get pleaseSelectYourPoliticalParty;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'mr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'mr': return AppLocalizationsMr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
