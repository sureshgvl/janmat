import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

/// Callers can lookup localized strings with an instance of ChatLocalizations
/// returned by `ChatLocalizations.of(context)`.
///
/// Applications need to include `ChatLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
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
/// Please make sure the following is an entry in your pubspec.yaml:
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
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
/// you wish to add from the pop-up menu of locale identifiers.
/// Note that the App Store does not differentiate between different
/// variants of the same language. For example, consider that if the ‘en’
/// locale is supported, both English and English (UK) are recognized
/// as ‘en’ language variants. Therefore, you only need to add the base
/// locale for each language you support.
///
/// Finally, you’ll want to add the following key to your Info.plist file.
/// By default, Xcode will automatically generate this key for you when
/// you add a localization to your project.
///
/// ```xml
/// <key>CFBundleLocalizations</key>
/// <array>
/// 	<string>en</string>
/// 	<string>mr</string>
/// </array>
/// ```
///
/// ## Android Applications
///
/// Android applications define key application metadata, including
/// supported locales, in an AndroidManifest.xml file that is built into the
/// application bundle. To configure the locales supported by your app, you’ll
/// need to edit this file.
///
/// First, open your project’s android/app/src/main/AndroidManifest.xml
/// file.
///
/// Next, add the following key to your AndroidManifest.xml file:
///
/// ```xml
/// <manifest xmlns:android="http://schemas.android.com/apk/res/android">
///   <application
///       android:label="janmat">
///     <meta-data
///        android:name="flutterTranslationLocales"
///        android:value="en,mr" />
///   </application>
/// </manifest>
/// ```
///
/// ## Windows Applications
///
/// Windows applications define key application metadata, including supported
/// locales, in a .rc file that is built into the application bundle. To
/// configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s windows/runner/Runner.rc file.
///
/// Next, add the following key to your Runner.rc file:
///
/// ```cpp
/// IDI_APP_ICON	ICON	DISCARDABLE	"resources\\app_icon.ico"
/// STRINGTABLE
/// BEGIN
///     IDS_APP_TITLE			"janmat"
///     IDS_FLUTTER_TRANSLATION_LOCALES	"en\\0mr\\0"
/// END
/// ```
///
class ChatLocalizations {
  ChatLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static ChatLocalizations of(BuildContext context) {
    return Localizations.of<ChatLocalizations>(context, ChatLocalizations)!;
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
  String get loadingChatRooms => 'Loading chat rooms...';

  /// No description provided for @createWardRoom.
  ///
  /// In en, this message translates to:
  /// **'Create Ward Room'**
  String get createWardRoom => 'Create Ward Room';

  /// No description provided for @startPrivateChat.
  ///
  /// In en, this message translates to:
  /// **'Start Private Chat'**
  String get startPrivateChat => 'Start Private Chat';

  /// No description provided for @recording.
  ///
  /// In en, this message translates to:
  /// **'Recording {duration}'**
  String recording(String duration) => 'Recording $duration';

  /// No description provided for @voiceMessage.
  ///
  /// In en, this message translates to:
  /// **'Voice message ({duration})'**
  String voiceMessage(String duration) => 'Voice message ($duration)';

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send => 'Send';

  /// No description provided for @deleteRecording.
  ///
  /// In en, this message translates to:
  /// **'Delete recording'**
  String get deleteRecording => 'Delete recording';

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessage => 'Type a message...';

  /// No description provided for @watchAdToEarnXP.
  ///
  /// In en, this message translates to:
  /// **'Watch ad to earn XP and send messages'**
  String get watchAdToEarnXP => 'Watch ad to earn XP and send messages';

  /// No description provided for @unableToSendMessages.
  ///
  /// In en, this message translates to:
  /// **'Unable to send messages'**
  String get unableToSendMessages => 'Unable to send messages';

  /// No description provided for @xpPoints.
  ///
  /// In en, this message translates to:
  /// **'XP: {points}'**
  String xpPoints(String points) => 'XP: $points';

  /// No description provided for @messagesCount.
  ///
  /// In en, this message translates to:
  /// **'Messages: {count}'**
  String messagesCount(String count) => 'Messages: $count';

  /// No description provided for @premium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premium => 'Premium';

  /// No description provided for @cannotSendMessage.
  ///
  /// In en, this message translates to:
  /// **'Cannot Send Message'**
  String get cannotSendMessage => 'Cannot Send Message';

  /// No description provided for @noMessagesOrXP.
  ///
  /// In en, this message translates to:
  /// **'You have no remaining messages or XP. Please watch an ad to earn XP.'**
  String get noMessagesOrXP => 'You have no remaining messages or XP. Please watch an ad to earn XP.';

  /// No description provided for @stopRecording.
  ///
  /// In en, this message translates to:
  /// **'Stop recording'**
  String get stopRecording => 'Stop recording';

  /// No description provided for @startVoiceRecording.
  ///
  /// In en, this message translates to:
  /// **'Start voice recording'**
  String get startVoiceRecording => 'Start voice recording';

  /// No description provided for @recordingError.
  ///
  /// In en, this message translates to:
  /// **'Recording Error'**
  String get recordingError => 'Recording Error';

  /// No description provided for @failedToSaveRecording.
  ///
  /// In en, this message translates to:
  /// **'Failed to save recording. Please try again.'**
  String get failedToSaveRecording => 'Failed to save recording. Please try again.';

  /// No description provided for @failedToStopRecording.
  ///
  /// In en, this message translates to:
  /// **'Failed to stop recording. Please try again.'**
  String get failedToStopRecording => 'Failed to stop recording. Please try again.';

  /// No description provided for @searchUsersByName.
  ///
  /// In en, this message translates to:
  /// **'Search users by name...'**
  String get searchUsersByName => 'Search users by name...';

  /// No description provided for @noUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get noUsersFound => 'No users found';

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success => 'Success';

  /// No description provided for @privateChatStarted.
  ///
  /// In en, this message translates to:
  /// **'Private chat started with {name}'**
  String privateChatStarted(String name) => 'Private chat started with $name';

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error => 'Error';

  /// No description provided for @failedToStartPrivateChat.
  ///
  /// In en, this message translates to:
  /// **'Failed to start private chat'**
  String get failedToStartPrivateChat => 'Failed to start private chat';

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel => 'Cancel';

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause => 'Pause';

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play => 'Play';


  /// No description provided for @createRoom.
  ///
  /// In en, this message translates to:
  /// **'Create Room'**
  String get createRoom => 'Create Room';

  /// No description provided for @roomName.
  ///
  /// In en, this message translates to:
  /// **'Room Name'**
  String get roomName => 'Room Name';

  /// No description provided for @enterRoomName.
  ///
  /// In en, this message translates to:
  /// **'Enter room name'**
  String get enterRoomName => 'Enter room name';

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get descriptionOptional => 'Description (Optional)';

  /// No description provided for @briefDescription.
  ///
  /// In en, this message translates to:
  /// **'Brief description of the room'**
  String get briefDescription => 'Brief description of the room';

  /// No description provided for @roomType.
  ///
  /// In en, this message translates to:
  /// **'Room Type'**
  String get roomType => 'Room Type';

  /// No description provided for @publicRoom.
  ///
  /// In en, this message translates to:
  /// **'Public Room'**
  String get publicRoom => 'Public Room';

  /// No description provided for @privateRoom.
  ///
  /// In en, this message translates to:
  /// **'Private Room'**
  String get privateRoom => 'Private Room';

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create => 'Create';

  /// No description provided for @initializeSampleDataDescription.
  ///
  /// In en, this message translates to:
  /// **'This will create sample chat rooms and messages for testing purposes. This is only available for admin users.\n\nContinue?'**
  String get initializeSampleDataDescription => 'This will create sample chat rooms and messages for testing purposes. This is only available for admin users.\n\nContinue?';

  /// No description provided for @initialize.
  ///
  /// In en, this message translates to:
  /// **'Initialize'**
  String get initialize => 'Initialize';

  /// No description provided for @candidateDataNotFound.
  ///
  /// In en, this message translates to:
  /// **'Candidate data not found'**
  String get candidateDataNotFound => 'Candidate data not found';

  /// No description provided for @candidateProfile.
  ///
  /// In en, this message translates to:
  /// **'Candidate Profile'**
  String get candidateProfile => 'Candidate Profile';

  /// No description provided for @candidateComparison.
  ///
  /// In en, this message translates to:
  /// **'Candidate Comparison'**
  String get candidateComparison => 'Candidate Comparison';

  /// No description provided for @candidateDataNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Candidate data not available'**
  String get candidateDataNotAvailable => 'Candidate data not available';

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'VERIFIED'**
  String get verified => 'VERIFIED';

  /// No description provided for @followers.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get followers => 'Followers';

  /// No description provided for @following.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get following => 'Following';

  /// No description provided for @sponsored.
  ///
  /// In en, this message translates to:
  /// **'SPONSORED'**
  String get sponsored => 'SPONSORED';

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info => 'Info';

  /// No description provided for @manifesto.
  ///
  /// In en, this message translates to:
  /// **'Manifesto'**
  String get manifesto => 'Manifesto';

  /// No description provided for @media.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get media => 'Media';

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact => 'Contact';

  /// No description provided for @wardInfo.
  ///
  /// In en, this message translates to:
  /// **'Ward {wardId} • {cityId}'**
  String wardInfo(String wardId, String cityId) => 'Ward $wardId • $cityId';

  /// No description provided for @joinedDate.
  ///
  /// In en, this message translates to:
  /// **'Joined {date}'**
  String joinedDate(String date) => 'Joined $date';

  /// No description provided for @viewAllFollowers.
  ///
  /// In en, this message translates to:
  /// **'View all followers'**
  String get viewAllFollowers => 'View all followers';

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about => 'About';

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements => 'Achievements';

  /// No description provided for @upcomingEvents.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Events'**
  String get upcomingEvents => 'Upcoming Events';

  /// No description provided for @translationFailed.
  ///
  /// In en, this message translates to:
  /// **'Translation failed: {error}'**
  String translationFailed(String error) => 'Translation failed: $error';

  /// No description provided for @downloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get downloadPdf => 'Download PDF';

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english => 'English';

  /// No description provided for @marathi.
  ///
  /// In en, this message translates to:
  /// **'मराठी'**
  String get marathi => 'मराठी';

  /// No description provided for @noManifestoAvailable.
  ///
  /// In en, this message translates to:
  /// **'No manifesto available'**
  String get noManifestoAvailable => 'No manifesto available';

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos => 'Photos';

  /// No description provided for @demoVideo.
  ///
  /// In en, this message translates to:
  /// **'Demo Video'**
  String get demoVideo => 'Demo Video';

  /// No description provided for @janMatAppDemo.
  ///
  /// In en, this message translates to:
  /// **'JanMat App Demo'**
  String get janMatAppDemo => 'JanMat App Demo';

  /// No description provided for @fullscreen.
  ///
  /// In en, this message translates to:
  /// **'Fullscreen'**
  String get fullscreen => 'Fullscreen';

  /// No description provided for @janMatAppDemoDescription.
  ///
  /// In en, this message translates to:
  /// **'JanMat App Demo - Watch how our platform works'**
  String get janMatAppDemoDescription => 'JanMat App Demo - Watch how our platform works';

  /// No description provided for @videos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get videos => 'Videos';

  /// No description provided for @youtubeChannel.
  ///
  /// In en, this message translates to:
  /// **'YouTube Channel'**
  String get youtubeChannel => 'YouTube Channel';

  /// No description provided for @watchVideosAndUpdates.
  ///
  /// In en, this message translates to:
  /// **'Watch videos and updates'**
  String get watchVideosAndUpdates => 'Watch videos and updates';

  /// No description provided for @noMediaAvailable.
  ///
  /// In en, this message translates to:
  /// **'No media available'**
  String get noMediaAvailable => 'No media available';

  /// No description provided for @contactInformation.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get contactInformation => 'Contact Information';

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone => 'Phone';

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email => 'Email';

  /// No description provided for @socialMedia.
  ///
  /// In en, this message translates to:
  /// **'Social Media'**
  String get socialMedia => 'Social Media';

  /// No description provided for @loadingMessages.
  ///
  /// In en, this message translates to:
  /// **'Loading messages...'**
  String get loadingMessages => 'Loading messages...';

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYet => 'No messages yet';

  /// No description provided for @startConversation.
  ///
  /// In en, this message translates to:
  /// **'Start the conversation in {roomName}'**
  String startConversation(String roomName) => 'Start the conversation in $roomName';

  /// No description provided for @sendImage.
  ///
  /// In en, this message translates to:
  /// **'Send Image'**
  String get sendImage => 'Send Image';

  /// No description provided for @createPoll.
  ///
  /// In en, this message translates to:
  /// **'Create Poll'**
  String get createPoll => 'Create Poll';

  /// No description provided for @pollCreated.
  ///
  /// In en, this message translates to:
  /// **'Poll Created!'**
  String get pollCreated => 'Poll Created!';

  /// No description provided for @pollSharedInChat.
  ///
  /// In en, this message translates to:
  /// **'Your poll has been shared in the chat'**
  String get pollSharedInChat => 'Your poll has been shared in the chat';

  /// No description provided for @roomInfo.
  ///
  /// In en, this message translates to:
  /// **'Room Info'**
  String get roomInfo => 'Room Info';

  /// No description provided for @leaveRoom.
  ///
  /// In en, this message translates to:
  /// **'Leave Room'**
  String get leaveRoom => 'Leave Room';

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type => 'Type';

  /// No description provided for @public.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get public => 'Public';

  /// No description provided for @private.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get private => 'Private';

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close => 'Close';

  /// No description provided for @initializeSampleData.
  ///
  /// In en, this message translates to:
  /// **'Initialize Sample Data'**
  String get initializeSampleData => 'Initialize Sample Data';

  /// No description provided for @refreshWardRoom.
  ///
  /// In en, this message translates to:
  /// **'Refresh Ward Room'**
  String get refreshWardRoom => 'Refresh Ward Room';

  /// No description provided for @debug.
  ///
  /// In en, this message translates to:
  /// **'Debug'**
  String get debug => 'Debug';

  /// No description provided for @userDataRefreshed.
  ///
  /// In en, this message translates to:
  /// **'User data refreshed and ward room checked'**
  String get userDataRefreshed => 'User data refreshed and ward room checked';

  /// No description provided for @refreshChatRooms.
  ///
  /// In en, this message translates to:
  /// **'Refresh Chat Rooms'**
  String get refreshChatRooms => 'Refresh Chat Rooms';

  /// No description provided for @refreshed.
  ///
  /// In en, this message translates to:
  /// **'Refreshed'**
  String get refreshed => 'Refreshed';

  /// No description provided for @chatRoomsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Chat rooms updated'**
  String get chatRoomsUpdated => 'Chat rooms updated';

  /// No description provided for @noChatRoomsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No chat rooms available'**
  String get noChatRoomsAvailable => 'No chat rooms available';

  /// No description provided for @chatRoomsWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Chat rooms will appear here when available\nUser: {userName}'**
  String chatRoomsWillAppearHere(String userName) => 'Chat rooms will appear here when available\nUser: $userName';

  /// No description provided for @refreshRooms.
  ///
  /// In en, this message translates to:
  /// **'Refresh Rooms'**
  String get refreshRooms => 'Refresh Rooms';

  /// No description provided for @watchAd.
  ///
  /// In en, this message translates to:
  /// **'Watch Ad'**
  String get watchAd => 'Watch Ad';

  /// No description provided for @messageLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Message Limit Reached'**
  String get messageLimitReached => 'Message Limit Reached';

  /// No description provided for @messageLimitReachedDescription.
  ///
  /// In en, this message translates to:
  /// **'You have reached your daily message limit. Choose an option to continue:'**
  String get messageLimitReachedDescription => 'You have reached your daily message limit. Choose an option to continue:';

  /// No description provided for @remainingMessages.
  ///
  /// In en, this message translates to:
  /// **'Remaining messages: {count}'**
  String remainingMessages(String count) => 'Remaining messages: $count';

  /// No description provided for @watchAdForXP.
  ///
  /// In en, this message translates to:
  /// **'Watch Ad (+3-5 XP)'**
  String get watchAdForXP => 'Watch Ad (+3-5 XP)';

  /// No description provided for @buyXP.
  ///
  /// In en, this message translates to:
  /// **'Buy XP'**
  String get buyXP => 'Buy XP';

  /// No description provided for @earnedExtraMessages.
  ///
  /// In en, this message translates to:
  /// **'You earned 10 extra messages!'**
  String get earnedExtraMessages => 'You earned 10 extra messages!';

  /// No description provided for @loadingRewardedAd.
  ///
  /// In en, this message translates to:
  /// **'Loading rewarded ad...'**
  String get loadingRewardedAd => 'Loading rewarded ad...';

  /// No description provided for @chatRooms.
  ///
  /// In en, this message translates to:
  /// **'Chat Rooms'**
  String get chatRooms => 'Chat Rooms';

  /// No description provided for @createNewChatRoom.
  ///
  /// In en, this message translates to:
  /// **'Create New Chat Room'**
  String get createNewChatRoom => 'Create New Chat Room';

  /// No description provided for @roomTitle.
  ///
  /// In en, this message translates to:
  /// **'Room Title'**
  String get roomTitle => 'Room Title';

  /// No description provided for @briefDescriptionOfRoom.
  ///
  /// In en, this message translates to:
  /// **'Brief description of the room'**
  String get briefDescriptionOfRoom => 'Brief description of the room';
}

class _ChatLocalizationsDelegate extends LocalizationsDelegate<ChatLocalizations> {
  const _ChatLocalizationsDelegate();

  @override
  Future<ChatLocalizations> load(Locale locale) {
    return SynchronousFuture<ChatLocalizations>(ChatLocalizations(locale.toString()));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'mr'].contains(locale.languageCode);

  @override
  bool shouldReload(_ChatLocalizationsDelegate old) => false;
}
