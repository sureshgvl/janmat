import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'chat_localizations.dart';

/// Chat-specific translations extension
class ChatTranslations {
  static ChatLocalizations get _chatLocalizations {
    final context = Get.context;
    if (context != null) {
      return ChatLocalizations.of(context)!;
    }
    // Fallback to English if context is not available
    return lookupChatLocalizations(const Locale('en'));
  }

  static String get loadingChatRooms => _chatLocalizations.loadingChatRooms;
  static String get createWardRoom => _chatLocalizations.createWardRoom;
  static String get startPrivateChat => _chatLocalizations.startPrivateChat;
  static String recording(Object duration) => _chatLocalizations.recording(duration);
  static String voiceMessage(Object duration) => _chatLocalizations.voiceMessage(duration);
  static String get send => _chatLocalizations.send;
  static String get deleteRecording => _chatLocalizations.deleteRecording;
  static String get typeMessage => _chatLocalizations.typeMessage;
  static String get watchAdToEarnXP => _chatLocalizations.watchAdToEarnXP;
  static String get unableToSendMessages => _chatLocalizations.unableToSendMessages;
  static String xpPoints(Object points) => _chatLocalizations.xpPoints(points);
  static String messagesCount(Object count) => _chatLocalizations.messagesCount(count);
  static String get premium => _chatLocalizations.premium;
  static String get cannotSendMessage => _chatLocalizations.cannotSendMessage;
  static String get noMessagesOrXP => _chatLocalizations.noMessagesOrXP;
  static String get stopRecording => _chatLocalizations.stopRecording;
  static String get startVoiceRecording => _chatLocalizations.startVoiceRecording;
  static String get recordingError => _chatLocalizations.recordingError;
  static String get failedToSaveRecording => _chatLocalizations.failedToSaveRecording;
  static String get failedToStopRecording => _chatLocalizations.failedToStopRecording;
  static String get searchUsersByName => _chatLocalizations.searchUsersByName;
  static String get noUsersFound => _chatLocalizations.noUsersFound;
  static String get success => _chatLocalizations.success;
  static String privateChatStarted(Object name) => _chatLocalizations.privateChatStarted(name);
  static String get error => _chatLocalizations.error;
  static String get failedToStartPrivateChat => _chatLocalizations.failedToStartPrivateChat;
  static String get cancel => _chatLocalizations.cancel;
  static String get pause => _chatLocalizations.pause;
  static String get play => _chatLocalizations.play;
  static String get createRoom => _chatLocalizations.createRoom;
  static String get roomName => _chatLocalizations.roomName;
  static String get enterRoomName => _chatLocalizations.enterRoomName;
  static String get descriptionOptional => _chatLocalizations.descriptionOptional;
  static String get briefDescription => _chatLocalizations.briefDescription;
  static String get roomType => _chatLocalizations.roomType;
  static String get publicRoom => _chatLocalizations.publicRoom;
  static String get privateRoom => _chatLocalizations.privateRoom;
  static String get create => _chatLocalizations.create;
  static String get initializeSampleDataDescription => _chatLocalizations.initializeSampleDataDescription;
  static String get initialize => _chatLocalizations.initialize;
  static String get candidateDataNotFound => _chatLocalizations.candidateDataNotFound;
  static String get candidateProfile => _chatLocalizations.candidateProfile;
  static String get candidateComparison => _chatLocalizations.candidateComparison;
  static String get candidateDataNotAvailable => _chatLocalizations.candidateDataNotAvailable;
  static String get verified => _chatLocalizations.verified;
  static String get followers => _chatLocalizations.followers;
  static String get following => _chatLocalizations.following;
  static String get sponsored => _chatLocalizations.sponsored;
  static String get info => _chatLocalizations.info;
  static String get manifesto => _chatLocalizations.manifesto;
  static String get media => _chatLocalizations.media;
  static String get contact => _chatLocalizations.contact;
  static String wardInfo(Object cityId, Object wardId) => _chatLocalizations.wardInfo(cityId, wardId);
  static String joinedDate(Object date) => _chatLocalizations.joinedDate(date);
  static String get viewAllFollowers => _chatLocalizations.viewAllFollowers;
  static String get about => _chatLocalizations.about;
  static String get achievements => _chatLocalizations.achievements;
  static String get upcomingEvents => _chatLocalizations.upcomingEvents;
  static String translationFailed(Object error) => _chatLocalizations.translationFailed(error);
  static String get downloadPdf => _chatLocalizations.downloadPdf;
  static String get english => _chatLocalizations.english;
  static String get marathi => _chatLocalizations.marathi;
  static String get noManifestoAvailable => _chatLocalizations.noManifestoAvailable;
  static String get photos => _chatLocalizations.photos;
  static String get demoVideo => _chatLocalizations.demoVideo;
  static String get janMatAppDemo => _chatLocalizations.janMatAppDemo;
  static String get fullscreen => _chatLocalizations.fullscreen;
  static String get janMatAppDemoDescription => _chatLocalizations.janMatAppDemoDescription;
  static String get videos => _chatLocalizations.videos;
  static String get youtubeChannel => _chatLocalizations.youtubeChannel;
  static String get watchVideosAndUpdates => _chatLocalizations.watchVideosAndUpdates;
  static String get noMediaAvailable => _chatLocalizations.noMediaAvailable;
  static String get contactInformation => _chatLocalizations.contactInformation;
  static String get phone => _chatLocalizations.phone;
  static String get email => _chatLocalizations.email;
  static String get socialMedia => _chatLocalizations.socialMedia;
}

/// Extension method for easier access to chat translations
extension ChatTranslationsExtension on String {
  String get ctr => ChatTranslations._chatLocalizations.toString(); // This is a placeholder - actual implementation would need proper extension
}