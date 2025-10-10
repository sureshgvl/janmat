import 'package:get/get.dart';

/// Chat-specific translations extension
class ChatTranslations {
  static String get _currentLanguage {
    // Get current language from GetX locale or default to English
    final locale = Get.locale;
    return locale?.languageCode == 'mr' ? 'mr' : 'en';
  }

  // Direct translation maps for all chat-specific strings
  static const Map<String, Map<String, String>> _translations = {
    'loadingChatRooms': {
      'en': 'Loading chat rooms...',
      'mr': 'गप्पा खोल्या लोड करत आहे...',
    },
    'createWardRoom': {
      'en': 'Create Ward Room',
      'mr': 'वॉर्ड रूम तयार करा',
    },
    'startPrivateChat': {
      'en': 'Start Private Chat',
      'mr': 'खाजगी गप्पा सुरू करा',
    },
    'recording': {
      'en': 'Recording {duration}',
      'mr': 'रेकॉर्डिंग {duration}',
    },
    'voiceMessage': {
      'en': 'Voice message ({duration})',
      'mr': 'व्हॉइस मेसेज ({duration})',
    },
    'send': {
      'en': 'Send',
      'mr': 'पाठवा',
    },
    'deleteRecording': {
      'en': 'Delete recording',
      'mr': 'रेकॉर्डिंग हटवा',
    },
    'typeMessage': {
      'en': 'Type a message...',
      'mr': 'मेसेज टाइप करा...',
    },
    'watchAdToEarnXP': {
      'en': 'Watch ad to earn XP and send messages',
      'mr': 'XP मिळवण्यासाठी आणि मेसेज पाठवण्यासाठी जाहिरात पहा',
    },
    'unableToSendMessages': {
      'en': 'Unable to send messages',
      'mr': 'मेसेज पाठवू शकत नाही',
    },
    'xpPoints': {
      'en': 'XP: {points}',
      'mr': 'XP: {points}',
    },
    'messagesCount': {
      'en': 'Messages: {count}',
      'mr': 'मेसेज: {count}',
    },
    'premium': {
      'en': 'Premium',
      'mr': 'प्रीमियम',
    },
    'cannotSendMessage': {
      'en': 'Cannot Send Message',
      'mr': 'मेसेज पाठवू शकत नाही',
    },
    'noMessagesOrXP': {
      'en': 'You have no remaining messages or XP.',
      'mr': 'आपल्याकडे कोणतेही मेसेज किंवा XP शिल्लक नाही.',
    },
    'stopRecording': {
      'en': 'Stop recording',
      'mr': 'रेकॉर्डिंग थांबवा',
    },
    'startVoiceRecording': {
      'en': 'Start voice recording',
      'mr': 'व्हॉइस रेकॉर्डिंग सुरू करा',
    },
    'recordingError': {
      'en': 'Recording Error',
      'mr': 'रेकॉर्डिंग त्रुटी',
    },
    'failedToSaveRecording': {
      'en': 'Failed to save recording. Please try again.',
      'mr': 'रेकॉर्डिंग सेव्ह करण्यात अयशस्वी. कृपया पुन्हा प्रयत्न करा.',
    },
    'failedToStopRecording': {
      'en': 'Failed to stop recording. Please try again.',
      'mr': 'रेकॉर्डिंग थांबवण्यात अयशस्वी. कृपया पुन्हा प्रयत्न करा.',
    },
    'searchUsersByName': {
      'en': 'Search users by name...',
      'mr': 'नावाने वापरकर्ते शोधा...',
    },
    'noUsersFound': {
      'en': 'No users found',
      'mr': 'कोणतेही वापरकर्ते सापडले नाहीत',
    },
    'success': {
      'en': 'Success',
      'mr': 'यशस्वी',
    },
    'privateChatStarted': {
      'en': 'Private chat started with {name}',
      'mr': '{name} सोबत खाजगी गप्पा सुरू झाली',
    },
    'error': {
      'en': 'Error',
      'mr': 'त्रुटी',
    },
    'failedToStartPrivateChat': {
      'en': 'Failed to start private chat',
      'mr': 'खाजगी गप्पा सुरू करण्यात अयशस्वी',
    },
    'cancel': {
      'en': 'Cancel',
      'mr': 'रद्द करा',
    },
    'pause': {
      'en': 'Pause',
      'mr': 'थांबवा',
    },
    'play': {
      'en': 'Play',
      'mr': 'प्ले करा',
    },
    'createRoom': {
      'en': 'Create Room',
      'mr': 'रूम तयार करा',
    },
    'roomName': {
      'en': 'Room Name',
      'mr': 'रूमचे नाव',
    },
    'enterRoomName': {
      'en': 'Enter room name',
      'mr': 'रूमचे नाव टाका',
    },
    'descriptionOptional': {
      'en': 'Description (Optional)',
      'mr': 'वर्णन (पर्यायी)',
    },
    'briefDescription': {
      'en': 'Brief description of the room',
      'mr': 'रूमचे संक्षिप्त वर्णन',
    },
    'roomType': {
      'en': 'Room Type',
      'mr': 'रूम प्रकार',
    },
    'publicRoom': {
      'en': 'Public Room',
      'mr': 'सार्वजनिक रूम',
    },
    'privateRoom': {
      'en': 'Private Room',
      'mr': 'खाजगी रूम',
    },
    'create': {
      'en': 'Create',
      'mr': 'तयार करा',
    },
    'initializeSampleDataDescription': {
      'en': 'This will create sample chat rooms and messages for testing purposes. This is only available for admin users.\n\nContinue?',
      'mr': 'हे चाचणीच्या उद्देशाने नमुना गप्पा खोल्या आणि मेसेज तयार करेल. हे केवळ प्रशासक वापरकर्त्यांसाठी उपलब्ध आहे.\n\nसुरू ठेवायचे?',
    },
    'initialize': {
      'en': 'Initialize',
      'mr': 'आरंभ करा',
    },
    'candidateDataNotFound': {
      'en': 'Candidate data not found',
      'mr': 'उमेदवाराचा डेटा सापडला नाही',
    },
    'candidateProfile': {
      'en': 'Candidate Profile',
      'mr': 'उमेदवार प्रोफाइल',
    },
    'candidateComparison': {
      'en': 'Candidate Comparison',
      'mr': 'उमेदवार तुलना',
    },
    'candidateDataNotAvailable': {
      'en': 'Candidate data not available',
      'mr': 'उमेदवाराचा डेटा उपलब्ध नाही',
    },
    'verified': {
      'en': 'VERIFIED',
      'mr': 'सत्यापित',
    },
    'followers': {
      'en': 'Followers',
      'mr': 'अनुयायी',
    },
    'following': {
      'en': 'Following',
      'mr': 'अनुयायी आहेत',
    },
    'sponsored': {
      'en': 'SPONSORED',
      'mr': 'प्रायोजित',
    },
    'info': {
      'en': 'Info',
      'mr': 'माहिती',
    },
    'manifesto': {
      'en': 'Manifesto',
      'mr': 'घोषणापत्र',
    },
    'media': {
      'en': 'Media',
      'mr': 'मीडिया',
    },
    'contact': {
      'en': 'Contact',
      'mr': 'संपर्क',
    },
    'wardInfo': {
      'en': 'Ward {cityId} - {wardId}',
      'mr': 'वॉर्ड {cityId} - {wardId}',
    },
    'joinedDate': {
      'en': 'Joined {date}',
      'mr': '{date} रोजी सामील झाले',
    },
    'viewAllFollowers': {
      'en': 'View all followers',
      'mr': 'सर्व अनुयायी पहा',
    },
    'about': {
      'en': 'About',
      'mr': 'बद्दल',
    },
    'achievements': {
      'en': 'Achievements',
      'mr': 'उपलब्धी',
    },
    'upcomingEvents': {
      'en': 'Upcoming Events',
      'mr': 'आगामी कार्यक्रम',
    },
    'translationFailed': {
      'en': 'Translation failed: {error}',
      'mr': 'भाषांतर अयशस्वी: {error}',
    },
    'downloadPdf': {
      'en': 'Download PDF',
      'mr': 'PDF डाउनलोड करा',
    },
    'english': {
      'en': 'English',
      'mr': 'इंग्रजी',
    },
    'marathi': {
      'en': 'Marathi',
      'mr': 'मराठी',
    },
    'noManifestoAvailable': {
      'en': 'No manifesto available',
      'mr': 'कोणतेही घोषणापत्र उपलब्ध नाही',
    },
    'photos': {
      'en': 'Photos',
      'mr': 'फोटो',
    },
    'demoVideo': {
      'en': 'Demo Video',
      'mr': 'डेमो व्हिडिओ',
    },
    'janMatAppDemo': {
      'en': 'JanMat App Demo',
      'mr': 'जनमत अॅप डेमो',
    },
    'fullscreen': {
      'en': 'Fullscreen',
      'mr': 'पूर्ण स्क्रीन',
    },
    'janMatAppDemoDescription': {
      'en': 'Watch our app demo to understand how JanMat works',
      'mr': 'जनमत कसे कार्य करते ते समजून घेण्यासाठी आमचे अॅप डेमो पहा',
    },
    'videos': {
      'en': 'Videos',
      'mr': 'व्हिडिओ',
    },
    'youtubeChannel': {
      'en': 'YouTube Channel',
      'mr': 'यूट्यूब चॅनेल',
    },
    'watchVideosAndUpdates': {
      'en': 'Watch videos and updates',
      'mr': 'व्हिडिओ आणि अपडेट्स पहा',
    },
    'noMediaAvailable': {
      'en': 'No media available',
      'mr': 'कोणतेही मीडिया उपलब्ध नाही',
    },
    'contactInformation': {
      'en': 'Contact Information',
      'mr': 'संपर्क माहिती',
    },
    'phone': {
      'en': 'Phone',
      'mr': 'फोन',
    },
    'email': {
      'en': 'Email',
      'mr': 'ईमेल',
    },
    'socialMedia': {
      'en': 'Social Media',
      'mr': 'सोशल मीडिया',
    },
    'sendImage': {
      'en': 'Send Image',
      'mr': 'प्रतिमा पाठवा',
    },
    'createPoll': {
      'en': 'Create Poll',
      'mr': 'मतदान तयार करा',
    },
    'chatRooms': {
      'en': 'Chat Rooms',
      'mr': 'गप्पा खोल्या',
    },
  };

  static String _getTranslation(String key) {
    final lang = _currentLanguage;
    return _translations[key]?[lang] ?? _translations[key]?['en'] ?? key;
  }

  // Static getters for all translations
  static String get loadingChatRooms => _getTranslation('loadingChatRooms');
  static String get createWardRoom => _getTranslation('createWardRoom');
  static String get startPrivateChat => _getTranslation('startPrivateChat');
  static String recording(Object duration) => _getTranslation('recording').replaceAll('{duration}', duration.toString());
  static String voiceMessage(Object duration) => _getTranslation('voiceMessage').replaceAll('{duration}', duration.toString());
  static String get send => _getTranslation('send');
  static String get deleteRecording => _getTranslation('deleteRecording');
  static String get typeMessage => _getTranslation('typeMessage');
  static String get watchAdToEarnXP => _getTranslation('watchAdToEarnXP');
  static String get unableToSendMessages => _getTranslation('unableToSendMessages');
  static String xpPoints(Object points) => _getTranslation('xpPoints').replaceAll('{points}', points.toString());
  static String messagesCount(Object count) => _getTranslation('messagesCount').replaceAll('{count}', count.toString());
  static String get premium => _getTranslation('premium');
  static String get cannotSendMessage => _getTranslation('cannotSendMessage');
  static String get noMessagesOrXP => _getTranslation('noMessagesOrXP');
  static String get stopRecording => _getTranslation('stopRecording');
  static String get startVoiceRecording => _getTranslation('startVoiceRecording');
  static String get recordingError => _getTranslation('recordingError');
  static String get failedToSaveRecording => _getTranslation('failedToSaveRecording');
  static String get failedToStopRecording => _getTranslation('failedToStopRecording');
  static String get searchUsersByName => _getTranslation('searchUsersByName');
  static String get noUsersFound => _getTranslation('noUsersFound');
  static String get success => _getTranslation('success');
  static String privateChatStarted(Object name) => _getTranslation('privateChatStarted').replaceAll('{name}', name.toString());
  static String get error => _getTranslation('error');
  static String get failedToStartPrivateChat => _getTranslation('failedToStartPrivateChat');
  static String get cancel => _getTranslation('cancel');
  static String get pause => _getTranslation('pause');
  static String get play => _getTranslation('play');
  static String get createRoom => _getTranslation('createRoom');
  static String get roomName => _getTranslation('roomName');
  static String get enterRoomName => _getTranslation('enterRoomName');
  static String get descriptionOptional => _getTranslation('descriptionOptional');
  static String get briefDescription => _getTranslation('briefDescription');
  static String get roomType => _getTranslation('roomType');
  static String get publicRoom => _getTranslation('publicRoom');
  static String get privateRoom => _getTranslation('privateRoom');
  static String get create => _getTranslation('create');
  static String get initializeSampleDataDescription => _getTranslation('initializeSampleDataDescription');
  static String get initialize => _getTranslation('initialize');
  static String get candidateDataNotFound => _getTranslation('candidateDataNotFound');
  static String get candidateProfile => _getTranslation('candidateProfile');
  static String get candidateComparison => _getTranslation('candidateComparison');
  static String get candidateDataNotAvailable => _getTranslation('candidateDataNotAvailable');
  static String get verified => _getTranslation('verified');
  static String get followers => _getTranslation('followers');
  static String get following => _getTranslation('following');
  static String get sponsored => _getTranslation('sponsored');
  static String get info => _getTranslation('info');
  static String get manifesto => _getTranslation('manifesto');
  static String get media => _getTranslation('media');
  static String get contact => _getTranslation('contact');
  static String wardInfo(Object cityId, Object wardId) => _getTranslation('wardInfo').replaceAll('{cityId}', cityId.toString()).replaceAll('{wardId}', wardId.toString());
  static String joinedDate(Object date) => _getTranslation('joinedDate').replaceAll('{date}', date.toString());
  static String get viewAllFollowers => _getTranslation('viewAllFollowers');
  static String get about => _getTranslation('about');
  static String get achievements => _getTranslation('achievements');
  static String get upcomingEvents => _getTranslation('upcomingEvents');
  static String translationFailed(Object error) => _getTranslation('translationFailed').replaceAll('{error}', error.toString());
  static String get downloadPdf => _getTranslation('downloadPdf');
  static String get english => _getTranslation('english');
  static String get marathi => _getTranslation('marathi');
  static String get noManifestoAvailable => _getTranslation('noManifestoAvailable');
  static String get photos => _getTranslation('photos');
  static String get demoVideo => _getTranslation('demoVideo');
  static String get janMatAppDemo => _getTranslation('janMatAppDemo');
  static String get fullscreen => _getTranslation('fullscreen');
  static String get janMatAppDemoDescription => _getTranslation('janMatAppDemoDescription');
  static String get videos => _getTranslation('videos');
  static String get youtubeChannel => _getTranslation('youtubeChannel');
  static String get watchVideosAndUpdates => _getTranslation('watchVideosAndUpdates');
  static String get noMediaAvailable => _getTranslation('noMediaAvailable');
  static String get contactInformation => _getTranslation('contactInformation');
  static String get phone => _getTranslation('phone');
  static String get email => _getTranslation('email');
  static String get socialMedia => _getTranslation('socialMedia');
  static String get sendImage => _getTranslation('sendImage');
  static String get createPoll => _getTranslation('createPoll');
  static String get chatRooms => _getTranslation('chatRooms');
}

