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

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'JanMat is independently developed and not affiliated with any government authority, election commission, or political party.'**
  String get aboutDescription;

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

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

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

  /// No description provided for @initializeSampleData.
  ///
  /// In en, this message translates to:
  /// **'Initialize Sample Data'**
  String get initializeSampleData;

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

  /// No description provided for @loadingRewardedAd.
  ///
  /// In en, this message translates to:
  /// **'Loading rewarded ad...'**
  String get loadingRewardedAd;

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

  /// No description provided for @browseCandidates.
  ///
  /// In en, this message translates to:
  /// **'Browse Candidates'**
  String get browseCandidates;

  /// No description provided for @myArea.
  ///
  /// In en, this message translates to:
  /// **'My Area'**
  String get myArea;

  /// No description provided for @failedToLogout.
  ///
  /// In en, this message translates to:
  /// **'Failed to logout: {error}'**
  String failedToLogout(Object error);

  /// No description provided for @deleteAccountConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This action cannot be undone and will permanently delete all your data including:\n\n• Your profile information\n• Chat conversations and messages\n• XP points and rewards\n• Following/followers data\n\nThis action is irreversible.'**
  String get deleteAccountConfirmation;

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

  /// No description provided for @myAreaCandidates.
  ///
  /// In en, this message translates to:
  /// **'My Area Candidates'**
  String get myAreaCandidates;

  /// No description provided for @candidateDashboard.
  ///
  /// In en, this message translates to:
  /// **'Candidate Dashboard'**
  String get candidateDashboard;

  /// No description provided for @changePartySymbolTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Party Symbol'**
  String get changePartySymbolTitle;

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

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @signOutOfYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign out of your account'**
  String get signOutOfYourAccount;

  /// No description provided for @uploadFiles.
  ///
  /// In en, this message translates to:
  /// **'Upload Files'**
  String get uploadFiles;

  /// No description provided for @uploadPdf.
  ///
  /// In en, this message translates to:
  /// **'Upload PDF'**
  String get uploadPdf;

  /// No description provided for @pdfFileLimit.
  ///
  /// In en, this message translates to:
  /// **'PDF File Limit'**
  String get pdfFileLimit;

  /// No description provided for @uploadImage.
  ///
  /// In en, this message translates to:
  /// **'Upload Image'**
  String get uploadImage;

  /// No description provided for @imageFileLimit.
  ///
  /// In en, this message translates to:
  /// **'Image File Limit'**
  String get imageFileLimit;

  /// No description provided for @uploadVideo.
  ///
  /// In en, this message translates to:
  /// **'Upload Video'**
  String get uploadVideo;

  /// No description provided for @videoFileLimit.
  ///
  /// In en, this message translates to:
  /// **'Video File Limit'**
  String get videoFileLimit;

  /// No description provided for @filesReadyForUpload.
  ///
  /// In en, this message translates to:
  /// **'Files ready for upload: {count}'**
  String filesReadyForUpload(Object count);

  /// No description provided for @filesUploadMessage.
  ///
  /// In en, this message translates to:
  /// **'Files Upload Message'**
  String get filesUploadMessage;

  /// No description provided for @features.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get features;

  /// No description provided for @buyNow.
  ///
  /// In en, this message translates to:
  /// **'Buy Now'**
  String get buyNow;

  /// No description provided for @yourXpBalance.
  ///
  /// In en, this message translates to:
  /// **'Your XP Balance'**
  String get yourXpBalance;

  /// No description provided for @howToUseXpPoints.
  ///
  /// In en, this message translates to:
  /// **'How to Use XP Points'**
  String get howToUseXpPoints;

  /// No description provided for @symbolImageSizeLimitError.
  ///
  /// In en, this message translates to:
  /// **'Symbol image size limit error'**
  String get symbolImageSizeLimitError;

  /// No description provided for @symbolUploadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Symbol uploaded successfully'**
  String get symbolUploadSuccess;

  /// No description provided for @symbolUploadError.
  ///
  /// In en, this message translates to:
  /// **'Symbol upload error: {error}'**
  String symbolUploadError(Object error);

  /// No description provided for @partyUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Party updated successfully'**
  String get partyUpdateSuccess;

  /// No description provided for @partyUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Party update error: {error}'**
  String partyUpdateError(Object error);

  /// No description provided for @updatePartyAffiliationHeader.
  ///
  /// In en, this message translates to:
  /// **'Update Party Affiliation'**
  String get updatePartyAffiliationHeader;

  /// No description provided for @updatePartyAffiliationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your party affiliation and symbol'**
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

  /// No description provided for @updateButton.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateButton;

  /// No description provided for @updateInstructionText.
  ///
  /// In en, this message translates to:
  /// **'Update your party and symbol information'**
  String get updateInstructionText;

  /// No description provided for @shareFunctionalityComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Share functionality coming soon'**
  String get shareFunctionalityComingSoon;

  /// No description provided for @like.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get like;

  /// No description provided for @likes.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get likes;

  /// No description provided for @party_independent.
  ///
  /// In en, this message translates to:
  /// **'Independent'**
  String get party_independent;

  /// No description provided for @basicInformation.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInformation;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @education.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get education;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @district.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get district;

  /// No description provided for @ward.
  ///
  /// In en, this message translates to:
  /// **'Ward'**
  String get ward;

  /// No description provided for @upgradeToPremium.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium'**
  String get upgradeToPremium;

  /// No description provided for @basicInfoUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Basic info updated successfully'**
  String get basicInfoUpdatedSuccessfully;

  /// No description provided for @chooseManifestoTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Manifesto Title'**
  String get chooseManifestoTitle;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @chooseTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Title'**
  String get chooseTitle;

  /// No description provided for @standardDevelopmentFocus.
  ///
  /// In en, this message translates to:
  /// **'Standard Development Focus'**
  String get standardDevelopmentFocus;

  /// No description provided for @developmentWithTransparency.
  ///
  /// In en, this message translates to:
  /// **'Development with Transparency'**
  String get developmentWithTransparency;

  /// No description provided for @focusOnProgress.
  ///
  /// In en, this message translates to:
  /// **'Focus on Progress'**
  String get focusOnProgress;

  /// No description provided for @focusOnCitizenWelfare.
  ///
  /// In en, this message translates to:
  /// **'Focus on Citizen Welfare'**
  String get focusOnCitizenWelfare;

  /// No description provided for @manifestoTitle.
  ///
  /// In en, this message translates to:
  /// **'Manifesto Title'**
  String get manifestoTitle;

  /// No description provided for @manifestoTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Manifesto Title'**
  String get manifestoTitleLabel;

  /// No description provided for @manifestoTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Enter manifesto title'**
  String get manifestoTitleHint;

  /// No description provided for @useDemoTitle.
  ///
  /// In en, this message translates to:
  /// **'Use Demo Title'**
  String get useDemoTitle;

  /// No description provided for @manifestoPdf.
  ///
  /// In en, this message translates to:
  /// **'Manifesto PDF'**
  String get manifestoPdf;

  /// No description provided for @willBeDeletedWhenYouSave.
  ///
  /// In en, this message translates to:
  /// **'Will be deleted when you save'**
  String get willBeDeletedWhenYouSave;

  /// No description provided for @markPdfForDeletion.
  ///
  /// In en, this message translates to:
  /// **'Mark PDF for Deletion'**
  String get markPdfForDeletion;

  /// No description provided for @pdfDeletionWarning.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete the PDF file'**
  String get pdfDeletionWarning;

  /// No description provided for @markForDeletion.
  ///
  /// In en, this message translates to:
  /// **'Mark for Deletion'**
  String get markForDeletion;

  /// No description provided for @pdfMarkedForDeletion.
  ///
  /// In en, this message translates to:
  /// **'PDF marked for deletion'**
  String get pdfMarkedForDeletion;

  /// No description provided for @manifestoImage.
  ///
  /// In en, this message translates to:
  /// **'Manifesto Image'**
  String get manifestoImage;

  /// No description provided for @markImageForDeletion.
  ///
  /// In en, this message translates to:
  /// **'Mark Image for Deletion'**
  String get markImageForDeletion;

  /// No description provided for @imageDeletionWarning.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete the image file'**
  String get imageDeletionWarning;

  /// No description provided for @imageMarkedForDeletion.
  ///
  /// In en, this message translates to:
  /// **'Image marked for deletion'**
  String get imageMarkedForDeletion;

  /// No description provided for @manifestoVideo.
  ///
  /// In en, this message translates to:
  /// **'Manifesto Video'**
  String get manifestoVideo;

  /// No description provided for @premiumFeatureMultiResolution.
  ///
  /// In en, this message translates to:
  /// **'Premium Feature: Multi-Resolution'**
  String get premiumFeatureMultiResolution;

  /// No description provided for @markVideoForDeletion.
  ///
  /// In en, this message translates to:
  /// **'Mark Video for Deletion'**
  String get markVideoForDeletion;

  /// No description provided for @videoDeletionWarning.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete the video file'**
  String get videoDeletionWarning;

  /// No description provided for @videoMarkedForDeletion.
  ///
  /// In en, this message translates to:
  /// **'Video marked for deletion'**
  String get videoMarkedForDeletion;

  /// No description provided for @premiumVideo.
  ///
  /// In en, this message translates to:
  /// **'Premium Video'**
  String get premiumVideo;

  /// No description provided for @createPoll.
  ///
  /// In en, this message translates to:
  /// **'Create Poll'**
  String get createPoll;

  /// No description provided for @pollQuestion.
  ///
  /// In en, this message translates to:
  /// **'Poll Question'**
  String get pollQuestion;

  /// No description provided for @pollQuestionHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your poll question'**
  String get pollQuestionHint;

  /// No description provided for @options.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get options;

  /// No description provided for @optionLabel.
  ///
  /// In en, this message translates to:
  /// **'Option {index}'**
  String optionLabel(Object index);

  /// No description provided for @removeOption.
  ///
  /// In en, this message translates to:
  /// **'Remove Option'**
  String get removeOption;

  /// No description provided for @addOption.
  ///
  /// In en, this message translates to:
  /// **'Add Option {count}'**
  String addOption(Object count);

  /// No description provided for @expirationSettings.
  ///
  /// In en, this message translates to:
  /// **'Expiration Settings'**
  String get expirationSettings;

  /// No description provided for @defaultExpiration.
  ///
  /// In en, this message translates to:
  /// **'Default Expiration'**
  String get defaultExpiration;

  /// No description provided for @expiresIn.
  ///
  /// In en, this message translates to:
  /// **'Expires in'**
  String get expiresIn;

  /// No description provided for @pollExpiresOn.
  ///
  /// In en, this message translates to:
  /// **'Poll expires on {date}'**
  String pollExpiresOn(Object date);

  /// No description provided for @pleaseEnterPollQuestion.
  ///
  /// In en, this message translates to:
  /// **'Please enter a poll question'**
  String get pleaseEnterPollQuestion;

  /// No description provided for @pleaseAddAtLeast2Options.
  ///
  /// In en, this message translates to:
  /// **'Please add at least 2 options'**
  String get pleaseAddAtLeast2Options;

  /// No description provided for @promises.
  ///
  /// In en, this message translates to:
  /// **'Promises'**
  String get promises;

  /// No description provided for @addPoint.
  ///
  /// In en, this message translates to:
  /// **'Add Point'**
  String get addPoint;

  /// No description provided for @addNewPromise.
  ///
  /// In en, this message translates to:
  /// **'Add New Promise'**
  String get addNewPromise;

  /// No description provided for @promisesTitle.
  ///
  /// In en, this message translates to:
  /// **'Promises Title'**
  String get promisesTitle;

  /// No description provided for @selectPartyValidation.
  ///
  /// In en, this message translates to:
  /// **'Please select a party'**
  String get selectPartyValidation;

  /// No description provided for @newPartyLabel.
  ///
  /// In en, this message translates to:
  /// **'New Party'**
  String get newPartyLabel;

  /// No description provided for @symbolNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Symbol Name'**
  String get symbolNameLabel;

  /// No description provided for @symbolNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter symbol name'**
  String get symbolNameHint;

  /// No description provided for @symbolNameValidation.
  ///
  /// In en, this message translates to:
  /// **'Symbol name is required'**
  String get symbolNameValidation;

  /// No description provided for @symbolImageOptional.
  ///
  /// In en, this message translates to:
  /// **'Symbol Image (Optional)'**
  String get symbolImageOptional;

  /// No description provided for @symbolImageDescription.
  ///
  /// In en, this message translates to:
  /// **'Upload an image for your party symbol'**
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
  /// **'Changing your party will reset your symbol and may affect your campaign visibility.'**
  String get partyChangeWarning;

  /// No description provided for @updatingText.
  ///
  /// In en, this message translates to:
  /// **'Updating...'**
  String get updatingText;

  /// No description provided for @profileLiked.
  ///
  /// In en, this message translates to:
  /// **'Profile Liked'**
  String get profileLiked;

  /// No description provided for @profileUnliked.
  ///
  /// In en, this message translates to:
  /// **'Profile Unliked'**
  String get profileUnliked;

  /// No description provided for @checkOutCandidateProfile.
  ///
  /// In en, this message translates to:
  /// **'Check out {name}\'s candidate profile'**
  String checkOutCandidateProfile(Object name);

  /// No description provided for @partyLabel.
  ///
  /// In en, this message translates to:
  /// **'{party} ({locale})'**
  String partyLabel(Object locale, Object party);

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'{district}, {ward}'**
  String locationLabel(Object district, Object ward);
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

