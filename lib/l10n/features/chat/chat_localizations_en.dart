import 'chat_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class ChatLocalizationsEn extends ChatLocalizations {
  ChatLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get loadingChatRooms => 'Loading chat rooms...';

  @override
  String get createWardRoom => 'Create Ward Room';

  @override
  String get startPrivateChat => 'Start Private Chat';

  @override
  String recording(Object duration) {
    return 'Recording $duration';
  }

  @override
  String voiceMessage(Object duration) {
    return 'Voice message ($duration)';
  }

  @override
  String get send => 'Send';

  @override
  String get deleteRecording => 'Delete recording';

  @override
  String get typeMessage => 'Type a message...';

  @override
  String get watchAdToEarnXP => 'Watch ad to earn XP and send messages';

  @override
  String get unableToSendMessages => 'Unable to send messages';

  @override
  String xpPoints(Object points) {
    return 'XP: $points';
  }

  @override
  String messagesCount(Object count) {
    return 'Messages: $count';
  }

  @override
  String get premium => 'Premium';

  @override
  String get cannotSendMessage => 'Cannot Send Message';

  @override
  String get noMessagesOrXP => 'You have no remaining messages or XP. Please watch an ad to earn XP.';

  @override
  String get stopRecording => 'Stop recording';

  @override
  String get startVoiceRecording => 'Start voice recording';

  @override
  String get recordingError => 'Recording Error';

  @override
  String get failedToSaveRecording => 'Failed to save recording. Please try again.';

  @override
  String get failedToStopRecording => 'Failed to stop recording. Please try again.';

  @override
  String get searchUsersByName => 'Search users by name...';

  @override
  String get noUsersFound => 'No users found';

  @override
  String get success => 'Success';

  @override
  String privateChatStarted(Object name) {
    return 'Private chat started with $name';
  }

  @override
  String get error => 'Error';

  @override
  String get failedToStartPrivateChat => 'Failed to start private chat';

  @override
  String get cancel => 'Cancel';

  @override
  String get pause => 'Pause';

  @override
  String get play => 'Play';

  @override
  String get createRoom => 'Create Room';

  @override
  String get roomName => 'Room Name';

  @override
  String get enterRoomName => 'Enter room name';

  @override
  String get descriptionOptional => 'Description (Optional)';

  @override
  String get briefDescription => 'Brief description of the room';

  @override
  String get roomType => 'Room Type';

  @override
  String get publicRoom => 'Public Room';

  @override
  String get privateRoom => 'Private Room';

  @override
  String get create => 'Create';

  @override
  String get initializeSampleDataDescription => 'This will create sample chat rooms and messages for testing purposes. This is only available for admin users.\n\nContinue?';

  @override
  String get initialize => 'Initialize';

  @override
  String get candidateDataNotFound => 'Candidate data not found';

  @override
  String get candidateProfile => 'Candidate Profile';

  @override
  String get candidateComparison => 'Candidate Comparison';

  @override
  String get candidateDataNotAvailable => 'Candidate data not available';

  @override
  String get verified => 'VERIFIED';

  @override
  String get followers => 'Followers';

  @override
  String get following => 'Following';

  @override
  String get sponsored => 'SPONSORED';

  @override
  String get info => 'Info';

  @override
  String get manifesto => 'Manifesto';

  @override
  String get media => 'Media';

  @override
  String get contact => 'Contact';

  @override
  String wardInfo(Object cityId, Object wardId) {
    return 'Ward $wardId • $cityId';
  }

  @override
  String joinedDate(Object date) {
    return 'Joined $date';
  }

  @override
  String get viewAllFollowers => 'View all followers';

  @override
  String get about => 'About';

  @override
  String get achievements => 'Achievements';

  @override
  String get upcomingEvents => 'Upcoming Events';

  @override
  String translationFailed(Object error) {
    return 'Translation failed: $error';
  }

  @override
  String get downloadPdf => 'Download PDF';

  @override
  String get english => 'English';

  @override
  String get marathi => 'मराठी';

  @override
  String get noManifestoAvailable => 'No manifesto available';

  @override
  String get photos => 'Photos';

  @override
  String get demoVideo => 'Demo Video';

  @override
  String get janMatAppDemo => 'JanMat App Demo';

  @override
  String get fullscreen => 'Fullscreen';

  @override
  String get janMatAppDemoDescription => 'JanMat App Demo - Watch how our platform works';

  @override
  String get videos => 'Videos';

  @override
  String get youtubeChannel => 'YouTube Channel';

  @override
  String get watchVideosAndUpdates => 'Watch videos and updates';

  @override
  String get noMediaAvailable => 'No media available';

  @override
  String get contactInformation => 'Contact Information';

  @override
  String get phone => 'Phone';

  @override
  String get email => 'Email';

  @override
  String get socialMedia => 'Social Media';

  @override
  String get createNewChatRoom => 'Create New Chat Room';

  @override
  String get roomTitle => 'Room Title';

  @override
  String get type => 'Type';

  @override
  String get public => 'Public';

  @override
  String get private => 'Private';

  @override
  String get createPoll => 'Create Poll';

  @override
  String get pollQuestion => 'Poll Question';

  @override
  String get pollQuestionHint => 'Enter your poll question';

  @override
  String get options => 'Options';

  @override
  String optionLabel(Object index) {
    return 'Option $index';
  }

  @override
  String get removeOption => 'Remove Option';

  @override
  String addOption(Object count) {
    return 'Add Option $count';
  }

  @override
  String get expirationSettings => 'Expiration Settings';

  @override
  String get defaultExpiration => 'Default Expiration';

  @override
  String get expiresIn => 'Expires in';

  @override
  String pollExpiresOn(Object date) {
    return 'Poll expires on $date';
  }

  @override
  String get pleaseEnterPollQuestion => 'Please enter a poll question';

  @override
  String get pleaseAddAtLeast2Options => 'Please add at least 2 options';
}

