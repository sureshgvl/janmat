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
  String get aboutDescription => 'जनमत स्वतंत्रपणे विकसित केले गेले आहे आणि कोणत्याही सरकारी अधिकार, निवडणूक आयोग किंवा राजकीय पक्षाशी संलग्न नाही.';

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
  String get error => 'त्रुटी';

  @override
  String get success => 'यशस्वी';

  @override
  String get cancel => 'रद्द करा';

  @override
  String get close => 'बंद करा';

  @override
  String get retry => 'पुन्हा प्रयत्न करा';

  @override
  String get createNewChatRoom => 'नवीन गप्पा खोली तयार करा';

  @override
  String get roomTitle => 'खोलीचे शीर्षक';

  @override
  String get messageLimitReached => 'संदेश मर्यादा संपली';

  @override
  String get messageLimitReachedDescription => 'आपण आपल्या दैनंदिन संदेश मर्यादेत पोहोचला आहात. सुरू ठेवण्यासाठी पर्याय निवडा:';

  @override
  String remainingMessages(Object count) {
    return 'उरलेले संदेश: $count';
  }

  @override
  String get watchAdForXP => 'जाहिरात पहा (+3-5 XP)';

  @override
  String get buyXP => 'XP खरेदी करा';

  @override
  String get initializeSampleData => 'नमुना डेटा सुरू करा';

  @override
  String get initializeSampleDataDescription => 'हे चाचणीसाठी नमुना गप्पा खोल्या आणि संदेश तयार करेल. हे फक्त प्रशासक वापरकर्त्यांसाठी उपलब्ध आहे.\n\nसुरू ठेवायचे?';

  @override
  String get initialize => 'सुरू करा';

  @override
  String get loadingRewardedAd => 'बक्षीस जाहिरात लोड करत आहे...';

  @override
  String get manageYourCampaignAndConnectWithVoters => 'आपली मोहीम व्यवस्थापित करा आणि मतदारांशी जोडा';

  @override
  String get stayInformedAboutYourLocalCandidates => 'आपल्या स्थानिक उमेदवारांबद्दल माहिती मिळवा';

  @override
  String get premiumTrialActive => 'प्रीमियम चाचणी सक्रिय';

  @override
  String get oneDayRemainingUpgrade => '1 दिवस उरला - प्रीमियम वैशिष्ट्ये सुरू ठेवण्यासाठी अपग्रेड करा!';

  @override
  String daysRemainingInTrial(Object days) {
    return 'आपल्या चाचणीत $days दिवस उरले आहेत';
  }

  @override
  String get upgrade => 'अपग्रेड';

  @override
  String get premiumUpgradeFeatureComingSoon => 'प्रीमियम अपग्रेड वैशिष्ट्य लवकरच येत आहे!';

  @override
  String get unlockPremiumFeatures => 'प्रीमियम वैशिष्ट्ये अनलॉक करा';

  @override
  String get enjoyFullPremiumFeaturesDuringTrial => 'आपल्या चाचणीदरम्यान पूर्ण प्रीमियम वैशिष्ट्ये अनुभवा';

  @override
  String get getPremiumVisibilityAndAnalytics => 'प्रीमियम दृश्यमानता आणि विश्लेषण मिळवा';

  @override
  String get accessExclusiveContentAndFeatures => 'विशिष्ट सामग्री आणि वैशिष्ट्यांमध्ये प्रवेश मिळवा';

  @override
  String get explorePremium => 'प्रीमियम एक्सप्लोर करा';

  @override
  String get quickActions => 'द्रुत क्रिया';

  @override
  String get browseCandidates => 'उमेदवार ब्राउझ करा';

  @override
  String get myArea => 'माझा परिसर';

  @override
  String failedToLogout(Object error) {
    return 'लॉगआउट करण्यात अयशस्वी: $error';
  }

  @override
  String get deleteAccountConfirmation => 'आपण खात्री आहात की आपले खाते हटवू इच्छिता? ही क्रिया पूर्ववत केली जाऊ शकत नाही आणि आपली सर्व डेटा कायमची हटवेल यामध्ये:\n\n• आपली प्रोफाइल माहिती\n• गप्पा संभाषणे आणि संदेश\n• XP गुण आणि बक्षिसे\n• फॉलो/फॉलोअर्स डेटा\n\nही क्रिया अपरिवर्तनीय आहे.';

  @override
  String get accountDeletedSuccessfully => 'आपले खाते यशस्वीरित्या हटवले गेले आहे.';

  @override
  String failedToDeleteAccount(Object error) {
    return 'खाते हटवण्यात अयशस्वी: $error';
  }

  @override
  String get myAreaCandidates => 'माझ्या परिसरातील उमेदवार';

  @override
  String get candidateDashboard => 'उमेदवार डॅशबोर्ड';

  @override
  String get changePartySymbolTitle => 'पार्टी चिन्ह बदला';

  @override
  String get searchByWard => 'वॉर्डनुसार शोधा';

  @override
  String get premiumFeatures => 'प्रीमियम वैशिष्ट्ये';

  @override
  String get upgradeToUnlockPremiumFeatures => 'प्रीमियम वैशिष्ट्ये अनलॉक करण्यासाठी अपग्रेड करा';

  @override
  String get deleteAccount => 'खाते हटवा';

  @override
  String get permanentlyDeleteYourAccountAndData => 'आपले खाते आणि डेटा कायमची हटवा';

  @override
  String get logout => 'लॉगआउट';

  @override
  String get signOutOfYourAccount => 'आपल्या खात्यातून साइन आउट करा';

  @override
  String get uploadFiles => 'फायली अपलोड करा';

  @override
  String get uploadPdf => 'PDF अपलोड करा';

  @override
  String get pdfFileLimit => 'PDF फाइल मर्यादा';

  @override
  String get uploadImage => 'प्रतिमा अपलोड करा';

  @override
  String get imageFileLimit => 'प्रतिमा फाइल मर्यादा';

  @override
  String get uploadVideo => 'व्हिडिओ अपलोड करा';

  @override
  String get videoFileLimit => 'व्हिडिओ फाइल मर्यादा';

  @override
  String filesReadyForUpload(Object count) {
    return 'अपलोडसाठी तयार फायली: $count';
  }

  @override
  String get filesUploadMessage => 'फायली अपलोड संदेश';

  @override
  String get features => 'वैशिष्ट्ये';

  @override
  String get buyNow => 'आता खरेदी करा';

  @override
  String get yourXpBalance => 'आपला XP बॅलन्स';

  @override
  String get howToUseXpPoints => 'XP गुण कसे वापरावे';

  @override
  String get symbolImageSizeLimitError => 'चिन्ह प्रतिमा आकार मर्यादा त्रुटी';

  @override
  String get symbolUploadSuccess => 'चिन्ह यशस्वीरित्या अपलोड झाले';

  @override
  String symbolUploadError(Object error) {
    return 'चिन्ह अपलोड त्रुटी: $error';
  }

  @override
  String get partyUpdateSuccess => 'पार्टी यशस्वीरित्या अपडेट झाली';

  @override
  String partyUpdateError(Object error) {
    return 'पार्टी अपडेट त्रुटी: $error';
  }

  @override
  String get updatePartyAffiliationHeader => 'पार्टी संलग्नता अपडेट करा';

  @override
  String get updatePartyAffiliationSubtitle => 'आपली पार्टी संलग्नता आणि चिन्ह अपडेट करा';

  @override
  String get currentParty => 'सध्याची पार्टी';

  @override
  String symbolLabel(Object symbol) {
    return 'चिन्ह: $symbol';
  }

  @override
  String get updateButton => 'अपडेट';

  @override
  String get updateInstructionText => 'आपली पार्टी आणि चिन्ह माहिती अपडेट करा';

  @override
  String get shareFunctionalityComingSoon => 'सामायिकरण कार्यक्षमता लवकरच येत आहे';

  @override
  String get like => 'लाइक';

  @override
  String get likes => 'लाइक';

  @override
  String get party_independent => 'स्वतंत्र';

  @override
  String get basicInformation => 'मूलभूत माहिती';

  @override
  String get age => 'वय';

  @override
  String get gender => 'लिंग';

  @override
  String get education => 'शिक्षण';

  @override
  String get address => 'पत्ता';

  @override
  String get location => 'स्थान';

  @override
  String get district => 'जिल्हा';

  @override
  String get ward => 'वॉर्ड';

  @override
  String get upgradeToPremium => 'प्रीमियममध्ये अपग्रेड करा';

  @override
  String get basicInfoUpdatedSuccessfully => 'मूलभूत माहिती यशस्वीरित्या अपडेट झाली';

  @override
  String get chooseManifestoTitle => 'घोषणापत्र शीर्षक निवडा';

  @override
  String get selectLanguage => 'भाषा निवडा';

  @override
  String get chooseTitle => 'शीर्षक निवडा';

  @override
  String get standardDevelopmentFocus => 'मानक विकास फोकस';

  @override
  String get developmentWithTransparency => 'पारदर्शकतेसह विकास';

  @override
  String get focusOnProgress => 'प्रगतीवर फोकस';

  @override
  String get focusOnCitizenWelfare => 'नागरिक कल्याणावर फोकस';

  @override
  String get manifestoTitle => 'घोषणापत्र शीर्षक';

  @override
  String get manifestoTitleLabel => 'घोषणापत्र शीर्षक';

  @override
  String get manifestoTitleHint => 'घोषणापत्र शीर्षक टाका';

  @override
  String get useDemoTitle => 'डेमो शीर्षक वापरा';

  @override
  String get manifestoPdf => 'घोषणापत्र PDF';

  @override
  String get willBeDeletedWhenYouSave => 'आपण सेव्ह केल्यावर हटवले जाईल';

  @override
  String get markPdfForDeletion => 'PDF हटवण्यासाठी चिन्हांकित करा';

  @override
  String get pdfDeletionWarning => 'हे PDF फाइल कायमची हटवेल';

  @override
  String get markForDeletion => 'हटवण्यासाठी चिन्हांकित करा';

  @override
  String get pdfMarkedForDeletion => 'PDF हटवण्यासाठी चिन्हांकित केले';

  @override
  String get manifestoImage => 'घोषणापत्र प्रतिमा';

  @override
  String get markImageForDeletion => 'प्रतिमा हटवण्यासाठी चिन्हांकित करा';

  @override
  String get imageDeletionWarning => 'हे प्रतिमा फाइल कायमची हटवेल';

  @override
  String get imageMarkedForDeletion => 'प्रतिमा हटवण्यासाठी चिन्हांकित केली';

  @override
  String get manifestoVideo => 'घोषणापत्र व्हिडिओ';

  @override
  String get premiumFeatureMultiResolution => 'प्रीमियम वैशिष्ट्य: बहु-रिझोल्यूशन';

  @override
  String get markVideoForDeletion => 'व्हिडिओ हटवण्यासाठी चिन्हांकित करा';

  @override
  String get videoDeletionWarning => 'हे व्हिडिओ फाइल कायमची हटवेल';

  @override
  String get videoMarkedForDeletion => 'व्हिडिओ हटवण्यासाठी चिन्हांकित केले';

  @override
  String get premiumVideo => 'प्रीमियम व्हिडिओ';

  @override
  String get createPoll => 'मतदान तयार करा';

  @override
  String get pollQuestion => 'मतदान प्रश्न';

  @override
  String get pollQuestionHint => 'आपला मतदान प्रश्न टाका';

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
    return 'मतदान कालबाह्य होईल $date';
  }

  @override
  String get pleaseEnterPollQuestion => 'कृपया मतदान प्रश्न टाका';

  @override
  String get pleaseAddAtLeast2Options => 'कृपया किमान 2 पर्याय जोडा';

  @override
  String promises(Object max) {
    return 'वचन ($max)';
  }

  @override
  String get addPoint => 'बिंदू जोडा';

  @override
  String get addNewPromise => 'नवीन वचन जोडा';

  @override
  String get promisesTitle => 'वचने शीर्षक';

  @override
  String get selectPartyValidation => 'कृपया पार्टी निवडा';

  @override
  String get newPartyLabel => 'नवीन पार्टी';

  @override
  String get symbolNameLabel => 'चिन्ह नाव';

  @override
  String get symbolNameHint => 'चिन्ह नाव टाका';

  @override
  String get symbolNameValidation => 'चिन्ह नाव आवश्यक आहे';

  @override
  String get symbolImageOptional => 'चिन्ह प्रतिमा (पर्यायी)';

  @override
  String get symbolImageDescription => 'आपल्या पार्टीच्या चिन्हासाठी प्रतिमा अपलोड करा';

  @override
  String get uploadSymbolImage => 'चिन्ह प्रतिमा अपलोड करा';

  @override
  String get importantNotice => 'महत्वाचे सूचना';

  @override
  String get partyChangeWarning => 'पार्टी बदलल्याने आपले चिन्ह रीसेट होईल आणि आपल्या मोहिमेच्या दृश्यमानतेला परिणाम होऊ शकतो.';

  @override
  String get updatingText => 'अपडेट करत आहे...';

  @override
  String get profileLiked => 'प्रोफाइल लाइक केले';

  @override
  String get profileUnliked => 'प्रोफाइल अनलाइक केले';

  @override
  String checkOutCandidateProfile(Object name) {
    return '$name चे उमेदवार प्रोफाइल पहा';
  }

  @override
  String partyLabel(Object locale, Object party) {
    return '$party ($locale)';
  }

  @override
  String locationLabel(Object district, Object ward) {
    return '$district, $ward';
  }

  @override
  String get selectValidityPeriod => 'वैधता कालावधी निवडा';

  @override
  String priceForDays(Object days) {
    return '$days दिवसांसाठी किंमत';
  }

  @override
  String purchaseForAmount(Object amount) {
    return '₹$amount साठी खरेदी करा';
  }

  @override
  String purchasePlan(Object planName) {
    return '$planName खरेदी करा';
  }

  @override
  String get electionTypeUpper => 'म्युनिसिपल कॉर्पोरेशन';

  @override
  String validityDays(Object days) {
    return 'वैधता: $days दिवस';
  }

  @override
  String expiresOn(Object date) {
    return '$date पर्यंत वैध';
  }

  @override
  String amount(Object price) {
    return 'रक्कम: ₹$price';
  }

  @override
  String get securePaymentGateway => 'आपणास आमच्या सुरक्षित पेमेंट गेटवेवर पाठवले जाईल.';

  @override
  String get proceedToPayment => 'पेमेंटकडे जा';

  @override
  String get profileDetails => 'प्रोफाइल तपशील';

  @override
  String get bio => 'जीवनी';

  @override
  String get useDemoBio => 'डेमो बायो वापरा';

  @override
  String get noBioAvailable => 'कोणतीही बायो उपलब्ध नाही';

  @override
  String get thankYou => 'धन्यवाद!';

  @override
  String get voteRecorded => 'आपला मत नोंदवला गेला आहे';

  @override
  String shareManifestoText(Object name) {
    return '$nameचे घोषणापत्र PDF पहा';
  }

  @override
  String shareManifestoSubject(Object name, Object title) {
    return '$nameचे $title PDF';
  }

  @override
  String manifestoVision(Object name) {
    return 'आमच्या समुदायासाठी $nameच्या दृष्टीविषयी अधिक जाणून घ्या!';
  }

  @override
  String get downloadAppText => 'पूर्ण घोषणापत्रे एक्सप्लोर करण्यासाठी आणि उमेदवारांशी संपर्क साधण्यासाठी जनमत अॅप डाउनलोड करा.';

  @override
  String get limited => 'मर्यादित';

  @override
  String get current => 'सद्य';

  @override
  String get free => 'विनामूल्य';

  @override
  String get xpPoints => 'XP गुण';

  @override
  String get contactSupport => 'संपर्क सपोर्ट';

  @override
  String get basicInfo => 'मूलभूत माहिती';

  @override
  String get manifesto => 'घोषणापत्र';

  @override
  String get pdfUpload => 'PDF अपलोड';

  @override
  String get videoUpload => 'व्हिडिओ अपलोड';

  @override
  String achievements(Object max) {
    return 'उपलब्धी ($max)';
  }

  @override
  String mediaItems(Object max) {
    return 'मीडिया ($max आयटम)';
  }

  @override
  String get contact => 'संपर्क';

  @override
  String get extendedInfo => 'विस्तारित माहिती';

  @override
  String get socialLinks => 'सामाजिक लिंक्स';

  @override
  String get prioritySupport => 'प्राधान्य सपोर्ट';

  @override
  String events(Object max) {
    return 'कार्यक्रम ($max)';
  }

  @override
  String get analytics => 'विश्लेषण';

  @override
  String get advanced => 'प्रगत';

  @override
  String get fullDashboard => 'पूर्ण डॅशबोर्ड';

  @override
  String get realTime => 'रिअल-टाइम';

  @override
  String get premiumBadge => 'प्रीमियम बॅज';

  @override
  String get sponsoredBanner => 'प्रायोजित बॅनर';

  @override
  String get highlightBanner => 'होम स्क्रीनवर हायलाइट बॅनर';

  @override
  String get pushNotifications => 'पुश नोटिफिकेशन';

  @override
  String get multipleHighlights => 'बहु हायलाइट';

  @override
  String get carouselOnHome => 'होम स्क्रीनवर करूसल';

  @override
  String get adminSupport => 'प्रशासन सपोर्ट';

  @override
  String get customBranding => 'कस्टम ब्रॅंडिंग';

  @override
  String get allocatedSeats => 'वाटप केलेली जागा';

  @override
  String get freePlanActive => 'विनामूल्य योजना सक्रिय';

  @override
  String get basicPlanActive => 'मूलभूत योजना सक्रिय';

  @override
  String get goldPlanActive => 'गोल्ड योजना सक्रिय';

  @override
  String get platinumPlanActive => 'प्लॅटिनम योजना सक्रिय';

  @override
  String get currentActivePlanMessage => 'ही तुमची सद्य सक्रिय योजना आहे';

  @override
  String get higherPlanActive => 'तुमच्याकडे उच्च योजना सक्रिय आहे';

  @override
  String get planAlreadyActive => 'ही योजना आधीच सक्रिय आहे';

  @override
  String get planNotAvailable => 'योजना उपलब्ध नाही';

  @override
  String get freePlanName => 'विनामूल्य योजना';

  @override
  String get basicPlanName => 'मूलभूत योजना';

  @override
  String get goldPlanName => 'गोल्ड योजना';

  @override
  String get platinumPlanName => 'प्लॅटिनम योजना';

  @override
  String get activeFreePlan => 'सक्रिय विनामूल्य योजना';

  @override
  String get activateFreePlan => 'विनामूल्य योजना सक्रिय करा';

  @override
  String get currentPlan => 'सद्य योजना';

  @override
  String get alreadyActive => 'आधीच सक्रिय';

  @override
  String get alreadyActiveButton => 'आधीच सक्रिय';

  @override
  String get planExpired => 'योजना कालबाह्य झाली';

  @override
  String expiresInTime(Object time) {
    return '$time मध्ये कालबाह्य होईल';
  }

  @override
  String get confirmPlanChange => 'योजना बदलाची पुष्टी करा';

  @override
  String get downgradeWarning => 'सावधानता: तुम्ही सर्व प्रीमियम वैशिष्ट्ये गमवाल आणि पेड सामग्रीमध्ये प्रवेश गमवू शकता.';

  @override
  String get yesDowngrade => 'होय, डाउनग्रेड करा';

  @override
  String subscribeFirst(Object plan) {
    return 'प्रथम $plan साठी सब्स्क्राइब करा';
  }

  @override
  String get loadingPremiumPlans => 'प्रीमियम योजना लोड करत आहे...';

  @override
  String get noPlansAvailable => 'सद्या कोणतीही प्रीमियम योजना उपलब्ध नाही.';

  @override
  String get highlightBannerFeatures => 'होम स्क्रीनवरील प्रोफेशनल हायलाइट बॅनर वैशिष्ट्ये';

  @override
  String get highlightBannerDescription => '• होम स्क्रीनवर जास्तीत जास्त 4 बॅनर\n• तुमच्या मोहिमेची प्रीमियम दृश्यमानता\n• प्लॅटिनम योजनेची आवश्यकता';

  @override
  String get carouselProfile => 'होम स्क्रीनवर करूसल प्रोफाइल';

  @override
  String get carouselDescription => '• होम स्क्रीनवर जास्तीत जास्त 10 करूसल स्लॉट\n• तुमच्या मोहिमेची कमाल दृश्यमानता\n• प्लॅटिनम योजनेची आवश्यकता';

  @override
  String get locked => 'लॉक केलेले';

  @override
  String requiresPlanOrPlatinum(Object plan) {
    return '$plan किंवा प्लॅटिनम योजनेची आवश्यकता';
  }

  @override
  String get refreshPlans => 'योजना रिफ्रेश करा';

  @override
  String get premiumPlansRefreshed => 'प्रीमियम योजना यशस्वीरित्या रिफ्रेश झाल्या!';

  @override
  String failedToRefreshPlans(Object error) {
    return 'योजना रिफ्रेश करण्यात अयशस्वी: $error';
  }

  @override
  String get noPlansAvailableShort => 'कोणतीही योजना उपलब्ध नाही';

  @override
  String get loading => 'लोड करत आहे...';

  @override
  String get allocateSeats => 'वाटप केलेली जागा';

  @override
  String get multiResolution => 'बहु-रिझोल्यूशन';

  @override
  String get uploadPhoto => 'फोटो अपलोड करा';

  @override
  String get viewPhoto => 'फोटो पहा';

  @override
  String get profilePhoto => 'प्रोफाइल फोटो';
}
