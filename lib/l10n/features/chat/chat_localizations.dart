import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;
import 'chat_localizations_en.dart';
import 'chat_localizations_mr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of ChatLocalizations
/// returned by `ChatLocalizations.of(context)`.
///
/// Applications need to include `ChatLocalizations.delegate()` in their app's
/// `localizationsDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'chat_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: ChatLocalizations.localizationsDelegates,
///   supportedLocales: ChatLocalizations.supportedLocales,
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
/// To configure the locales supported by your app, you'll need to edit this
/// file.
///
/// First, open your project's ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project's Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the ChatLocalizations.supportedLocales
/// property.
abstract class ChatLocalizations {
  ChatLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static ChatLocalizations? of(BuildContext context) {
    return Localizations.of<ChatLocalizations>(context, ChatLocalizations);
  }

  static const LocalizationsDelegate<ChatLocalizations> delegate = _ChatLocalizationsDelegate();

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

  /// No description provided for @loadingChatRooms.
  ///
  /// In en, this message translates to:
  /// **'Loading chat rooms...'**
  String get loadingChatRooms;

  /// No description provided for @createWardRoom.
  ///
  /// In en, this message translates to:
  /// **'Create Ward Room'**
  String get createWardRoom;

  /// No description provided for @startPrivateChat.
  ///
  /// In en, this message translates to:
  /// **'Start Private Chat'**
  String get startPrivateChat;

  /// No description provided for @recording.
  ///
  /// In en, this message translates to:
  /// **'Recording {duration}'**
  String recording(Object duration);

  /// No description provided for @voiceMessage.
  ///
  /// In en, this message translates to:
  /// **'Voice message ({duration})'**
  String voiceMessage(Object duration);

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @deleteRecording.
  ///
  /// In en, this message translates to:
  /// **'Delete recording'**
  String get deleteRecording;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessage;

  /// No description provided for @watchAdToEarnXP.
  ///
  /// In en, this message translates to:
  /// **'Watch ad to earn XP and send messages'**
  String get watchAdToEarnXP;

  /// No description provided for @unableToSendMessages.
  ///
  /// In en, this message translates to:
  /// **'Unable to send messages'**
  String get unableToSendMessages;

  /// No description provided for @xpPoints.
  ///
  /// In en, this message translates to:
  /// **'XP: {points}'**
  String xpPoints(Object points);

  /// No description provided for @messagesCount.
  ///
  /// In en, this message translates to:
  /// **'Messages: {count}'**
  String messagesCount(Object count);

  /// No description provided for @premium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @cannotSendMessage.
  ///
  /// In en, this message translates to:
  /// **'Cannot Send Message'**
  String get cannotSendMessage;

  /// No description provided for @noMessagesOrXP.
  ///
  /// In en, this message translates to:
  /// **'You have no remaining messages or XP. Please watch an ad to earn XP.'**
  String get noMessagesOrXP;

  /// No description provided for @stopRecording.
  ///
  /// In en, this message translates to:
  /// **'Stop recording'**
  String get stopRecording;

  /// No description provided for @startVoiceRecording.
  ///
  /// In en, this message translates to:
  /// **'Start voice recording'**
  String get startVoiceRecording;

  /// No description provided for @recordingError.
  ///
  /// In en, this message translates to:
  /// **'Recording Error'**
  String get recordingError;

  /// No description provided for @failedToSaveRecording.
  ///
  /// In en, this message translates to:
  /// **'Failed to save recording. Please try again.'**
  String get failedToSaveRecording;

  /// No description provided for @failedToStopRecording.
  ///
  /// In en, this message translates to:
  /// **'Failed to stop recording. Please try again.'**
  String get failedToStopRecording;

  /// No description provided for @searchUsersByName.
  ///
  /// In en, this message translates to:
  /// **'Search users by name...'**
  String get searchUsersByName;

  /// No description provided for @noUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get noUsersFound;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @privateChatStarted.
  ///
  /// In en, this message translates to:
  /// **'Private chat started with {name}'**
  String privateChatStarted(Object name);

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @failedToStartPrivateChat.
  ///
  /// In en, this message translates to:
  /// **'Failed to start private chat'**
  String get failedToStartPrivateChat;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @createRoom.
  ///
  /// In en, this message translates to:
  /// **'Create Room'**
  String get createRoom;

  /// No description provided for @roomName.
  ///
  /// In en, this message translates to:
  /// **'Room Name'**
  String get roomName;

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

  /// No description provided for @briefDescription.
  ///
  /// In en, this message translates to:
  /// **'Brief description of the room'**
  String get briefDescription;

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

  /// No description provided for @candidateComparison.
  ///
  /// In en, this message translates to:
  /// **'Candidate Comparison'**
  String get candidateComparison;

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

  /// No description provided for @sponsored.
  ///
  /// In en, this message translates to:
  /// **'SPONSORED'**
  String get sponsored;

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

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

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

  String get createNewChatRoom;

  String get roomTitle;

  String get type;

  String get public;

  String get private;

  String get createPoll;

  String get pollQuestion;

  String get pollQuestionHint;

  String get options;

  String optionLabel(Object index);

  String get removeOption;

  String addOption(Object count);

  String get expirationSettings;

  String get defaultExpiration;

  String get expiresIn;

  String pollExpiresOn(Object date);

  String get pleaseEnterPollQuestion;

  String get pleaseAddAtLeast2Options;
}

class _ChatLocalizationsDelegate extends LocalizationsDelegate<ChatLocalizations> {
  const _ChatLocalizationsDelegate();

  @override
  Future<ChatLocalizations> load(Locale locale) {
    return SynchronousFuture<ChatLocalizations>(lookupChatLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'mr'].contains(locale.languageCode);

  @override
  bool shouldReload(_ChatLocalizationsDelegate old) => false;
}

ChatLocalizations lookupChatLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return ChatLocalizationsEn();
    case 'mr': return ChatLocalizationsMr();
  }

  throw FlutterError(
    'ChatLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}