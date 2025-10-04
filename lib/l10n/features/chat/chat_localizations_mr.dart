import 'chat_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Marathi (`mr`).
class ChatLocalizationsMr extends ChatLocalizations {
  ChatLocalizationsMr([String locale = 'mr']) : super(locale);

  @override
  String get loadingChatRooms => 'गप्पा खोल्या लोड होत आहेत...';

  @override
  String get createWardRoom => 'वॉर्ड खोली तयार करा';

  @override
  String get startPrivateChat => 'खाजगी गप्पा सुरू करा';

  @override
  String recording(Object duration) {
    return '$duration रेकॉर्ड होत आहे';
  }

  @override
  String voiceMessage(Object duration) {
    return 'व्हॉइस संदेश ($duration)';
  }

  @override
  String get send => 'पाठवा';

  @override
  String get deleteRecording => 'रेकॉर्डिंग हटवा';

  @override
  String get typeMessage => 'संदेश टाका...';

  @override
  String get watchAdToEarnXP => 'XP मिळवण्यासाठी आणि संदेश पाठवण्यासाठी जाहिरात पहा';

  @override
  String get unableToSendMessages => 'संदेश पाठवू शकत नाही';

  @override
  String xpPoints(Object points) {
    return 'XP: $points';
  }

  @override
  String messagesCount(Object count) {
    return 'संदेश: $count';
  }

  @override
  String get premium => 'प्रीमियम';

  @override
  String get cannotSendMessage => 'संदेश पाठवू शकत नाही';

  @override
  String get noMessagesOrXP => 'तुम्हाला कोणतेही शिल्लक संदेश नाहीत किंवा XP नाही. XP मिळवण्यासाठी कृपया जाहिरात पहा.';

  @override
  String get stopRecording => 'रेकॉर्डिंग थांबवा';

  @override
  String get startVoiceRecording => 'व्हॉइस रेकॉर्डिंग सुरू करा';

  @override
  String get recordingError => 'रेकॉर्डिंग त्रुटी';

  @override
  String get failedToSaveRecording => 'रेकॉर्डिंग जतन करण्यात अयशस्वी. कृपया पुन्हा प्रयत्न करा.';

  @override
  String get failedToStopRecording => 'रेकॉर्डिंग थांबवण्यात अयशस्वी. कृपया पुन्हा प्रयत्न करा.';

  @override
  String get searchUsersByName => 'नावानुसार वापरकर्ते शोधा...';

  @override
  String get noUsersFound => 'कोणतेही वापरकर्ते सापडले नाहीत';

  @override
  String get success => 'यशस्वी';

  @override
  String privateChatStarted(Object name) {
    return '$name सोबत खाजगी गप्पा सुरू झाली';
  }

  @override
  String get error => 'त्रुटी';

  @override
  String get failedToStartPrivateChat => 'खाजगी गप्पा सुरू करण्यात अयशस्वी';

  @override
  String get cancel => 'रद्द करा';

  @override
  String get pause => 'थांबवा';

  @override
  String get play => 'प्ले करा';

  @override
  String get createRoom => 'खोली तयार करा';

  @override
  String get roomName => 'खोलीचे नाव';

  @override
  String get enterRoomName => 'खोलीचे नाव टाका';

  @override
  String get descriptionOptional => 'वर्णन (पर्यायी)';

  @override
  String get briefDescription => 'खोलीचे संक्षिप्त वर्णन';

  @override
  String get roomType => 'खोली प्रकार';

  @override
  String get publicRoom => 'सार्वजनिक खोली';

  @override
  String get privateRoom => 'खाजगी खोली';

  @override
  String get create => 'तयार करा';

  @override
  String get initializeSampleDataDescription => 'हे चाचणीच्या उद्देशाने नमुना गप्पा खोल्या आणि संदेश तयार करेल. हे फक्त प्रशासक वापरकर्त्यांसाठी उपलब्ध आहे.\n\nसुरू ठेवायचे का?';

  @override
  String get initialize => 'सुरू करा';

  @override
  String get candidateDataNotFound => 'उमेदवार डेटा सापडला नाही';

  @override
  String get candidateProfile => 'उमेदवार प्रोफाइल';

  @override
  String get candidateComparison => 'उमेदवार तुलना';

  @override
  String get candidateDataNotAvailable => 'उमेदवार डेटा उपलब्ध नाही';

  @override
  String get verified => 'सत्यापित';

  @override
  String get followers => 'फॉलोअर्स';

  @override
  String get following => 'फॉलोइंग';

  @override
  String get sponsored => 'प्रायोजित';

  @override
  String get info => 'माहिती';

  @override
  String get manifesto => 'घोषणापत्र';

  @override
  String get media => 'मीडिया';

  @override
  String get contact => 'संपर्क';

  @override
  String wardInfo(Object cityId, Object wardId) {
    return 'वॉर्ड $wardId • $cityId';
  }

  @override
  String joinedDate(Object date) {
    return '$date रोजी सामील झाले';
  }

  @override
  String get viewAllFollowers => 'सर्व फॉलोअर्स पहा';

  @override
  String get about => 'विषयी';

  @override
  String get achievements => 'उपलब्धी';

  @override
  String get upcomingEvents => 'आगामी कार्यक्रम';

  @override
  String translationFailed(Object error) {
    return 'भाषांतर अयशस्वी: $error';
  }

  @override
  String get downloadPdf => 'PDF डाउनलोड करा';

  @override
  String get english => 'इंग्रजी';

  @override
  String get marathi => 'मराठी';

  @override
  String get noManifestoAvailable => 'कोणतेही घोषणापत्र उपलब्ध नाही';

  @override
  String get photos => 'फोटो';

  @override
  String get demoVideo => 'डेमो व्हिडिओ';

  @override
  String get janMatAppDemo => 'जनमत अॅप डेमो';

  @override
  String get fullscreen => 'पूर्ण स्क्रीन';

  @override
  String get janMatAppDemoDescription => 'जनमत अॅप डेमो - आमचे प्लॅटफॉर्म कसे कार्य करते ते पहा';

  @override
  String get videos => 'व्हिडिओ';

  @override
  String get youtubeChannel => 'यूट्यूब चॅनेल';

  @override
  String get watchVideosAndUpdates => 'व्हिडिओ आणि अपडेट्स पहा';

  @override
  String get noMediaAvailable => 'कोणतेही मीडिया उपलब्ध नाही';

  @override
  String get contactInformation => 'संपर्क माहिती';

  @override
  String get phone => 'फोन';

  @override
  String get email => 'ईमेल';

  @override
  String get socialMedia => 'सोशल मीडिया';

  @override
  String get createNewChatRoom => 'नवीन गप्पा खोली तयार करा';

  @override
  String get roomTitle => 'खोली शीर्षक';

  @override
  String get type => 'प्रकार';

  @override
  String get public => 'सार्वजनिक';

  @override
  String get private => 'खाजगी';

  @override
  String get createPoll => 'मतदान तयार करा';

  @override
  String get pollQuestion => 'मतदान प्रश्न';

  @override
  String get pollQuestionHint => 'तुमचा मतदान प्रश्न टाका';

  @override
  String get options => 'पर्याय';

  @override
  String optionLabel(Object index) {
    return 'पर्याय $index';
  }

  @override
  String get removeOption => 'पर्याय काढा';

  @override
  String addOption(Object count) {
    return 'पर्याय जोडा $count';
  }

  @override
  String get expirationSettings => 'कालबाह्यता सेटिंग्ज';

  @override
  String get defaultExpiration => 'डीफॉल्ट कालबाह्यता';

  @override
  String get expiresIn => 'मध्ये कालबाह्य होईल';

  @override
  String pollExpiresOn(Object date) {
    return 'मतदान $date रोजी कालबाह्य होईल';
  }

  @override
  String get pleaseEnterPollQuestion => 'कृपया मतदान प्रश्न टाका';

  @override
  String get pleaseAddAtLeast2Options => 'कृपया किमान 2 पर्याय जोडा';
}

