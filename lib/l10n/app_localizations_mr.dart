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

  @override
  String get myAreaCandidates => 'माझ्या क्षेत्रातील उमेदवार';

  @override
  String get candidatesFromYourWard => 'तुमच्या वॉर्डमधील उमेदवार';

  @override
  String get candidateDashboard => 'उमेदवार डॅशबोर्ड';

  @override
  String get searchByWard => 'वॉर्डनुसार शोधा';

  @override
  String get premiumFeatures => 'प्रीमियम वैशिष्ट्ये';

  @override
  String get upgradeToUnlockPremiumFeatures => 'प्रीमियम वैशिष्ट्ये अनलॉक करण्यासाठी अपग्रेड करा';

  @override
  String get deleteAccount => 'खाते हटवा';

  @override
  String get permanentlyDeleteYourAccountAndData => 'तुमचे खाते आणि डेटा कायमचा हटवा';

  @override
  String get error => 'त्रुटी';

  @override
  String failedToLogout(Object error) {
    return 'लॉगआउट करण्यात अयशस्वी: $error';
  }

  @override
  String get manageYourCampaignAndConnectWithVoters => 'तुमच्या प्रचाराचे व्यवस्थापन करा आणि मतदारांशी संपर्क साधा';

  @override
  String get stayInformedAboutYourLocalCandidates => 'तुमच्या स्थानिक उमेदवारांबद्दल माहिती मिळवा';

  @override
  String get premiumTrialActive => 'प्रीमियम ट्रायल सक्रिय';

  @override
  String get oneDayRemainingUpgrade => '1 दिवस शिल्लक - प्रीमियम वैशिष्ट्ये सुरू ठेवण्यासाठी अपग्रेड करा!';

  @override
  String daysRemainingInTrial(Object days) {
    return 'तुमच्या ट्रायलमध्ये $days दिवस शिल्लक';
  }

  @override
  String get upgrade => 'अपग्रेड';

  @override
  String get upgradeAvailable => 'अपग्रेड उपलब्ध';

  @override
  String get premiumUpgradeFeatureComingSoon => 'प्रीमियम अपग्रेड वैशिष्ट्य लवकरच येत आहे!';

  @override
  String get unlockPremiumFeatures => 'प्रीमियम वैशिष्ट्ये अनलॉक करा';

  @override
  String get enjoyFullPremiumFeaturesDuringTrial => 'तुमच्या ट्रायल दरम्यान संपूर्ण प्रीमियम वैशिष्ट्ये अनुभवा';

  @override
  String get getPremiumVisibilityAndAnalytics => 'प्रीमियम दृश्यमानता आणि विश्लेषण मिळवा';

  @override
  String get accessExclusiveContentAndFeatures => 'विशेष सामग्री आणि वैशिष्ट्ये मिळवा';

  @override
  String get explorePremium => 'प्रीमियम एक्सप्लोर करा';

  @override
  String get quickActions => 'द्रुत क्रिया';

  @override
  String get myArea => 'माझे क्षेत्र';

  @override
  String get manageYourCampaign => 'तुमच्या प्रचाराचे व्यवस्थापन करा';

  @override
  String get viewAnalyticsAndUpdateYourProfile => 'विश्लेषण पहा आणि तुमचे प्रोफाइल अपडेट करा';

  @override
  String get deleteAccountConfirmation => 'तुम्हाला खरोखर तुमचे खाते हटवायचे आहे का? ही क्रिया पूर्ववत केली जाऊ शकत नाही आणि तुमचे सर्व डेटा कायमचा हटवेल यात:\n\n• तुमची प्रोफाइल माहिती\n• गप्पा आणि संदेश\n• XP गुण आणि बक्षिसे\n• फॉलोइंग/फॉलोअर्स डेटा\n\nही क्रिया अपरिवर्तनीय आहे.';

  @override
  String get cancel => 'रद्द करा';

  @override
  String get success => 'यशस्वी';

  @override
  String get accountDeletedSuccessfully => 'तुमचे खाते यशस्वीरित्या हटवले गेले आहे.';

  @override
  String failedToDeleteAccount(Object error) {
    return 'खाते हटवण्यात अयशस्वी: $error';
  }

  @override
  String get userDataNotFound => 'वापरकर्ता डेटा सापडला नाही';

  @override
  String get accountDetails => 'खाते तपशील';

  @override
  String get premium => 'प्रीमियम';

  @override
  String get xpPoints => 'XP गुण';

  @override
  String get logOut => 'लॉग आउट';

  @override
  String get searchCandidates => 'उमेदवार शोधा';

  @override
  String get selectCity => 'शहर निवडा';

  @override
  String get selectWard => 'वॉर्ड निवडा';

  @override
  String get retry => 'पुन्हा प्रयत्न करा';

  @override
  String get noCandidatesFound => 'कोणतेही उमेदवार सापडले नाहीत';

  @override
  String get selectWardToViewCandidates => 'उमेदवार पाहण्यासाठी वॉर्ड निवडा';

  @override
  String get sponsored => 'प्रायोजित';

  @override
  String get loadingMessages => 'संदेश लोड होत आहेत...';

  @override
  String get noMessagesYet => 'अद्याप कोणतेही संदेश नाहीत';

  @override
  String startConversation(Object roomName) {
    return '$roomName मध्ये संभाषण सुरू करा';
  }

  @override
  String get sendImage => 'प्रतिमा पाठवा';

  @override
  String get createPoll => 'मतदान तयार करा';

  @override
  String get pollCreated => 'मतदान तयार झाले!';

  @override
  String get pollSharedInChat => 'तुमचे मतदान गप्पामध्ये सामायिक केले गेले आहे';

  @override
  String get roomInfo => 'खोली माहिती';

  @override
  String get leaveRoom => 'खोली सोडा';

  @override
  String get type => 'प्रकार';

  @override
  String get public => 'सार्वजनिक';

  @override
  String get private => 'खाजगी';

  @override
  String get close => 'बंद करा';

  @override
  String get initializeSampleData => 'नमुना डेटा सुरू करा';

  @override
  String get refreshWardRoom => 'वॉर्ड खोली रिफ्रेश करा';

  @override
  String get debug => 'डीबग';

  @override
  String get userDataRefreshed => 'वापरकर्ता डेटा रिफ्रेश झाला आणि वॉर्ड खोली तपासली गेली';

  @override
  String get refreshChatRooms => 'गप्पा खोल्या रिफ्रेश करा';

  @override
  String get refreshed => 'रिफ्रेश झाले';

  @override
  String get chatRoomsUpdated => 'गप्पा खोल्या अपडेट झाल्या';

  @override
  String get noChatRoomsAvailable => 'कोणत्याही गप्पा खोल्या उपलब्ध नाहीत';

  @override
  String chatRoomsWillAppearHere(Object userName) {
    return 'गप्पा खोल्या उपलब्ध झाल्यावर येथे दिसतील\nवापरकर्ता: $userName';
  }

  @override
  String get refreshRooms => 'खोल्या रिफ्रेश करा';

  @override
  String get watchAd => 'जाहिरात पहा';

  @override
  String get messageLimitReached => 'संदेश मर्यादा संपली';

  @override
  String get messageLimitReachedDescription => 'तुम्ही तुमच्या दैनंदिन संदेश मर्यादेत पोहोचलात. सुरू ठेवण्यासाठी पर्याय निवडा:';

  @override
  String remainingMessages(Object count) {
    return 'शिल्लक संदेश: $count';
  }

  @override
  String get watchAdForXP => 'जाहिरात पहा (+3-5 XP)';

  @override
  String get buyXP => 'XP खरेदी करा';

  @override
  String get earnedExtraMessages => 'तुम्हाला 10 अतिरिक्त संदेश मिळाले!';

  @override
  String get loadingRewardedAd => 'रिवॉर्डेड जाहिरात लोड होत आहे...';

  @override
  String get createNewChatRoom => 'नवीन गप्पा खोली तयार करा';

  @override
  String get roomTitle => 'खोली शीर्षक';

  @override
  String get enterRoomName => 'खोलीचे नाव टाका';

  @override
  String get descriptionOptional => 'वर्णन (पर्यायी)';

  @override
  String get briefDescriptionOfRoom => 'खोलीचे संक्षिप्त वर्णन';

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
  String get candidateDataNotAvailable => 'उमेदवार डेटा उपलब्ध नाही';

  @override
  String get verified => 'सत्यापित';

  @override
  String get followers => 'फॉलोअर्स';

  @override
  String get following => 'फॉलोइंग';

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
    return 'सामील झाले $date';
  }

  @override
  String get viewAllFollowers => 'सर्व फॉलोअर्स पहा';

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
  String get party_bjp => 'भारतीय जनता पक्ष';

  @override
  String get party_inc => 'भारतीय राष्ट्रीय काँग्रेस';

  @override
  String get party_ss_ubt => 'शिवसेना (उद्धव बाळासाहेब ठाकरे)';

  @override
  String get party_ss_shinde => 'बाळासाहेबांची शिवसेना';

  @override
  String get party_ncp_ajit => 'राष्ट्रवादी काँग्रेस पक्ष (अजित पवार)';

  @override
  String get party_ncp_sp => 'राष्ट्रवादी काँग्रेस पक्ष (शरदचंद्र पवार)';

  @override
  String get party_mns => 'महाराष्ट्र नवनिर्माण सेना';

  @override
  String get party_pwpi => 'शेतकरी कामगार पक्ष';

  @override
  String get party_cpi_m => 'भारतीय कम्युनिस्ट पक्ष (मार्क्सवादी)';

  @override
  String get party_rsp => 'राष्ट्रीय समाज पक्ष';

  @override
  String get party_sp => 'समाजवादी पक्ष';

  @override
  String get party_bsp => 'बहुजन समाज पार्टी';

  @override
  String get party_bva => 'बहुजन विकास आघाडी';

  @override
  String get party_republican_sena => 'रिपब्लिकन सेना';

  @override
  String get party_abs => 'अखिल भारतीय सेना';

  @override
  String get party_vba => 'वंचित बहुजन आघाडी';

  @override
  String get party_independent => 'अपक्ष';

  @override
  String get changePartySymbolTitle => 'पक्ष आणि चिन्ह बदला';

  @override
  String get updateButton => 'अपडेट करा';

  @override
  String get updatePartyAffiliationHeader => 'तुमच्या पक्षाच्या संलग्नतेचे अपडेट करा';

  @override
  String get updatePartyAffiliationSubtitle => 'तुमचा पक्ष बदला किंवा स्वतंत्र होऊन सानुकूल चिन्ह वापरा.';

  @override
  String get currentParty => 'सध्याचा पक्ष';

  @override
  String symbolLabel(Object symbol) {
    return 'चिन्ह: $symbol';
  }

  @override
  String get newPartyLabel => 'नवीन पक्ष *';

  @override
  String get selectPartyValidation => 'कृपया तुमचा पक्ष निवडा';

  @override
  String get symbolNameLabel => 'चिन्हाचे नाव *';

  @override
  String get symbolNameHint => 'उदा., टेबल, खुर्ची, शिट्टी, पुस्तक, इ.';

  @override
  String get symbolNameValidation => 'कृपया अपक्ष उमेदवारांसाठी चिन्हाचे नाव टाका';

  @override
  String get symbolImageOptional => 'चिन्ह प्रतिमा (पर्यायी)';

  @override
  String get symbolImageDescription => 'तुमच्या निवडलेल्या चिन्हाची प्रतिमा अपलोड करा. न दिल्यास, डिफॉल्ट आयकॉन वापरला जाईल.';

  @override
  String get uploadSymbolImage => 'चिन्ह प्रतिमा अपलोड करा';

  @override
  String get importantNotice => 'महत्वाची सूचना';

  @override
  String get partyChangeWarning => 'तुमच्या पक्षाच्या संलग्नतेत बदल केल्याने तुमचे प्रोफाइल त्वरित अपडेट होईल. हा बदल सर्व मतदारांना दिसेल.';

  @override
  String get partyUpdateSuccess => 'तुमचा पक्ष आणि चिन्ह यशस्वीरित्या अपडेट झाले आहेत!';

  @override
  String partyUpdateError(Object error) {
    return 'पक्ष आणि चिन्ह अपडेट करण्यात अयशस्वी: $error';
  }

  @override
  String get symbolUploadSuccess => 'चिन्ह प्रतिमा यशस्वीरित्या अपलोड झाली';

  @override
  String symbolUploadError(Object error) {
    return 'चिन्ह प्रतिमा अपलोड करण्यात अयशस्वी: $error';
  }

  @override
  String get updatingText => 'अपडेट होत आहे...';

  @override
  String get updateInstructionText => 'तुमचा पक्ष आणि चिन्ह बदल जतन करण्यासाठी अपडेट टॅप करा';
}
