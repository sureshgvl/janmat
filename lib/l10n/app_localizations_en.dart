// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'JanMat';

  @override
  String get welcomeMessage => 'Welcome to JanMat';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get sending => 'Sending...';

  @override
  String get sendOTP => 'Send OTP';

  @override
  String enterOTP(Object phone) {
    return 'Enter OTP sent to +91$phone';
  }

  @override
  String get otp => 'OTP';

  @override
  String get verifying => 'Verifying...';

  @override
  String get verifyOTP => 'Verify OTP';

  @override
  String get changePhoneNumber => 'Change Phone Number';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get notifications => 'Notifications';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get about => 'About';

  @override
  String get home => 'Home';

  @override
  String get candidates => 'Candidates';

  @override
  String get chatRooms => 'Chat Rooms';

  @override
  String get polls => 'Polls';

  @override
  String get profile => 'Profile';

  @override
  String get feed => 'Feed';

  @override
  String get browseCandidates => 'Browse Candidates';

  @override
  String get wardDiscussions => 'Ward Discussions';

  @override
  String get surveysPolls => 'Surveys & Polls';

  @override
  String get userAccount => 'User Account';

  @override
  String get votes => 'votes';

  @override
  String get myAreaCandidates => 'My Area Candidates';

  @override
  String get candidatesFromYourWard => 'Candidates from your ward';

  @override
  String get candidateDashboard => 'Candidate Dashboard';

  @override
  String get basicInfo => 'Basic Info';

  @override
  String get achievements => 'Achievements';

  @override
  String get manifesto => 'Manifesto';

  @override
  String get contact => 'Contact';

  @override
  String get media => 'Media';

  @override
  String get events => 'Events';

  @override
  String get highlight => 'Highlight';

  @override
  String get analytics => 'Analytics';

  @override
  String get searchByWard => 'Search by Ward';

  @override
  String get premiumFeatures => 'Premium Features';

  @override
  String get upgradeToUnlockPremiumFeatures =>
      'Upgrade to unlock premium features';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get permanentlyDeleteYourAccountAndData =>
      'Permanently delete your account and data';

  @override
  String get error => 'Error';

  @override
  String failedToLogout(Object error) {
    return 'Failed to logout: $error';
  }

  @override
  String get manageYourCampaignAndConnectWithVoters =>
      'Manage your campaign and connect with voters';

  @override
  String get stayInformedAboutYourLocalCandidates =>
      'Stay informed about your local candidates';

  @override
  String get premiumTrialActive => 'Premium Trial Active';

  @override
  String get oneDayRemainingUpgrade =>
      '1 day remaining - Upgrade to continue premium features!';

  @override
  String daysRemainingInTrial(Object days) {
    return '$days days remaining in your trial';
  }

  @override
  String get upgrade => 'Upgrade';

  @override
  String get upgradeAvailable => 'Upgrade Available';

  @override
  String get premiumUpgradeFeatureComingSoon =>
      'Premium upgrade feature coming soon!';

  @override
  String get unlockPremiumFeatures => 'Unlock Premium Features';

  @override
  String get enjoyFullPremiumFeaturesDuringTrial =>
      'Enjoy full premium features during your trial';

  @override
  String get getPremiumVisibilityAndAnalytics =>
      'Get premium visibility and analytics';

  @override
  String get accessExclusiveContentAndFeatures =>
      'Access exclusive content and features';

  @override
  String get explorePremium => 'Explore Premium';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get myArea => 'My Area';

  @override
  String get manageYourCampaign => 'Manage Your Campaign';

  @override
  String get viewAnalyticsAndUpdateYourProfile =>
      'View analytics and update your profile';

  @override
  String get deleteAccountConfirmation =>
      'Are you sure you want to delete your account? This action cannot be undone and will permanently delete all your data including:\n\n• Your profile information\n• Chat conversations and messages\n• XP points and rewards\n• Following/followers data\n\nThis action is irreversible.';

  @override
  String get cancel => 'Cancel';

  @override
  String get success => 'Success';

  @override
  String get accountDeletedSuccessfully =>
      'Your account has been deleted successfully.';

  @override
  String failedToDeleteAccount(Object error) {
    return 'Failed to delete account: $error';
  }

  @override
  String get userDataNotFound => 'User data not found';

  @override
  String get accountDetails => 'Account Details';

  @override
  String get premium => 'Premium';

  @override
  String get xpPoints => 'XP Points';

  @override
  String get logOut => 'Log Out';

  @override
  String get searchCandidates => 'Search Candidates';

  @override
  String get selectCity => 'Select City';

  @override
  String get selectWard => 'Select Ward';

  @override
  String get retry => 'Retry';

  @override
  String get noCandidatesFound => 'No candidates found';

  @override
  String get selectWardToViewCandidates => 'Select a ward to view candidates';

  @override
  String get sponsored => 'SPONSORED';

  @override
  String get loadingMessages => 'Loading messages...';

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String startConversation(Object roomName) {
    return 'Start the conversation in $roomName';
  }

  @override
  String get sendImage => 'Send Image';

  @override
  String get createPoll => 'Create Poll';

  @override
  String get pollCreated => 'Poll Created!';

  @override
  String get pollSharedInChat => 'Your poll has been shared in the chat';

  @override
  String get roomInfo => 'Room Info';

  @override
  String get leaveRoom => 'Leave Room';

  @override
  String get type => 'Type';

  @override
  String get public => 'Public';

  @override
  String get private => 'Private';

  @override
  String get close => 'Close';

  @override
  String get initializeSampleData => 'Initialize Sample Data';

  @override
  String get refreshWardRoom => 'Refresh Ward Room';

  @override
  String get debug => 'Debug';

  @override
  String get userDataRefreshed => 'User data refreshed and ward room checked';

  @override
  String get refreshChatRooms => 'Refresh Chat Rooms';

  @override
  String get refreshed => 'Refreshed';

  @override
  String get chatRoomsUpdated => 'Chat rooms updated';

  @override
  String get noChatRoomsAvailable => 'No chat rooms available';

  @override
  String chatRoomsWillAppearHere(Object userName) {
    return 'Chat rooms will appear here when available\nUser: $userName';
  }

  @override
  String get refreshRooms => 'Refresh Rooms';

  @override
  String get watchAd => 'Watch Ad';

  @override
  String get messageLimitReached => 'Message Limit Reached';

  @override
  String get messageLimitReachedDescription =>
      'You have reached your daily message limit. Choose an option to continue:';

  @override
  String remainingMessages(Object count) {
    return 'Remaining messages: $count';
  }

  @override
  String get watchAdForXP => 'Watch Ad (+3-5 XP)';

  @override
  String get buyXP => 'Buy XP';

  @override
  String get earnedExtraMessages => 'You earned 10 extra messages!';

  @override
  String get loadingRewardedAd => 'Loading rewarded ad...';

  @override
  String get createNewChatRoom => 'Create New Chat Room';

  @override
  String get roomTitle => 'Room Title';

  @override
  String get enterRoomName => 'Enter room name';

  @override
  String get descriptionOptional => 'Description (Optional)';

  @override
  String get briefDescriptionOfRoom => 'Brief description of the room';

  @override
  String get roomType => 'Room Type';

  @override
  String get publicRoom => 'Public Room';

  @override
  String get privateRoom => 'Private Room';

  @override
  String get create => 'Create';

  @override
  String get initializeSampleDataDescription =>
      'This will create sample chat rooms and messages for testing purposes. This is only available for admin users.\n\nContinue?';

  @override
  String get initialize => 'Initialize';

  @override
  String get candidateDataNotFound => 'Candidate data not found';

  @override
  String get candidateProfile => 'Candidate Profile';

  @override
  String get candidateDataNotAvailable => 'Candidate data not available';

  @override
  String get verified => 'VERIFIED';

  @override
  String get followers => 'Followers';

  @override
  String get following => 'Following';

  @override
  String get info => 'Info';

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
  String get janMatAppDemoDescription =>
      'JanMat App Demo - Watch how our platform works';

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
  String get party_bjp => 'Bharatiya Janata Party';

  @override
  String get party_inc => 'Indian National Congress';

  @override
  String get party_ss_ubt => 'Shiv Sena (Uddhav Balasaheb Thackeray)';

  @override
  String get party_ss_shinde => 'Balasahebanchi Shiv Sena (Shinde)';

  @override
  String get party_ncp_ajit => 'Nationalist Congress Party (Ajit Pawar)';

  @override
  String get party_ncp_sp => 'Nationalist Congress Party (Sharad Pawar)';

  @override
  String get party_mns => 'Maharashtra Navnirman Sena';

  @override
  String get party_pwpi => 'Peasants and Workers Party of India';

  @override
  String get party_cpi_m => 'Communist Party of India (Marxist)';

  @override
  String get party_rsp => 'Rashtriya Samaj Paksha';

  @override
  String get party_sp => 'Samajwadi Party';

  @override
  String get party_bsp => 'Bahujan Samaj Party';

  @override
  String get party_bva => 'Bahujan Vikas Aaghadi';

  @override
  String get party_republican_sena => 'Republican Sena';

  @override
  String get party_abs => 'Akhil Bharatiya Sena';

  @override
  String get party_vba => 'Vanchit Bahujan Aghadi';

  @override
  String get party_independent => 'Independents';

  @override
  String get changePartySymbolTitle => 'Change Party & Symbol';

  @override
  String get updateButton => 'Update';

  @override
  String get updatePartyAffiliationHeader => 'Update Your Party Affiliation';

  @override
  String get updatePartyAffiliationSubtitle =>
      'Change your party or become independent with a custom symbol.';

  @override
  String get currentParty => 'Current Party';

  @override
  String symbolLabel(Object symbol) {
    return 'Symbol: $symbol';
  }

  @override
  String get newPartyLabel => 'New Party *';

  @override
  String get selectPartyValidation => 'Please select your party';

  @override
  String get symbolNameLabel => 'Symbol Name *';

  @override
  String get symbolNameHint => 'e.g., Table, Chair, Whistle, Book, etc.';

  @override
  String get symbolNameValidation =>
      'Please enter a symbol name for independent candidates';

  @override
  String get symbolImageOptional => 'Symbol Image (Optional)';

  @override
  String get symbolImageDescription =>
      'Upload an image of your chosen symbol. If not provided, a default icon will be used.';

  @override
  String get uploadSymbolImage => 'Upload Symbol Image';

  @override
  String get importantNotice => 'Important Notice';

  @override
  String get partyChangeWarning =>
      'Changing your party affiliation will update your profile immediately. This change will be visible to all voters.';

  @override
  String get partyUpdateSuccess =>
      'Your party and symbol have been updated successfully!';

  @override
  String partyUpdateError(Object error) {
    return 'Failed to update party and symbol: $error';
  }

  @override
  String get symbolUploadSuccess => 'Symbol image uploaded successfully';

  @override
  String symbolUploadError(Object error) {
    return 'Failed to upload symbol image: $error';
  }

  @override
  String get symbolImageSizeLimitError =>
      'Image size must be less than 5MB. Please select a smaller image.';

  @override
  String get updatingText => 'Updating...';

  @override
  String get updateInstructionText =>
      'Tap update to save your party and symbol changes';

  @override
  String get chooseYourRole => 'Choose Your Role';

  @override
  String get howWouldYouLikeToParticipate =>
      'How would you like to participate?';

  @override
  String get selectYourRoleToCustomizeExperience =>
      'Select your role to customize your experience in the community.';

  @override
  String get voter => 'Voter';

  @override
  String get stayInformedAndParticipateInDiscussions =>
      'Stay informed and participate in discussions';

  @override
  String get accessWardDiscussionsPollsAndCommunityUpdates =>
      'Access ward discussions, polls, and community updates';

  @override
  String get candidate => 'Candidate';

  @override
  String get runForOfficeAndConnectWithVoters =>
      'Run for office and connect with voters';

  @override
  String get createYourProfileShareManifestoAndEngageWithCommunity =>
      'Create your profile, share manifesto, and engage with community';

  @override
  String get continueButton => 'Continue';

  @override
  String get youCanChangeYourRoleLaterInSettings =>
      'You can change your role later in settings';

  @override
  String get pleaseSelectARoleToContinue => 'Please select a role to continue';

  @override
  String get roleSelected => 'Role Selected!';

  @override
  String get youSelectedCandidatePleaseCompleteYourProfile =>
      'You selected Candidate. Please complete your profile.';

  @override
  String get youSelectedVoterPleaseCompleteYourProfile =>
      'You selected Voter. Please complete your profile.';

  @override
  String failedToSaveRole(Object error) {
    return 'Failed to save role: $error';
  }

  @override
  String get completeYourProfile => 'Complete Your Profile';

  @override
  String get welcomeCompleteYourProfile =>
      'Welcome! Please complete your profile to continue.';

  @override
  String preFilledFromAccount(Object loginMethod) {
    return 'Some information has been pre-filled from $loginMethod. This helps us connect you with your local community.';
  }

  @override
  String get fullName => 'Full Name';

  @override
  String get fullNameRequired => 'Full Name *';

  @override
  String get enterYourFullName => 'Enter your full name';

  @override
  String get phoneNumberRequired => 'Phone Number *';

  @override
  String get enterYourPhoneNumber => 'Enter your phone number';

  @override
  String get birthDateRequired => 'Birth Date *';

  @override
  String get selectYourBirthDate => 'Select your birth date';

  @override
  String get genderRequired => 'Gender *';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get other => 'Other';

  @override
  String get preferNotToSay => 'Prefer not to say';

  @override
  String get districtRequired => 'District *';

  @override
  String get selectYourDistrict => 'Select your district';

  @override
  String get bodyRequired => 'Body *';

  @override
  String get selectYourBody => 'Select your body';

  @override
  String get cityRequired => 'City *';

  @override
  String get selectYourCity => 'Select your city';

  @override
  String get wardRequired => 'Ward *';

  @override
  String get selectYourWard => 'Select your ward';

  @override
  String get areaRequired => 'Area *';

  @override
  String get selectYourArea => 'Select your area';

  @override
  String get selectCityFirst => 'Select city first';

  @override
  String get completeProfile => 'Complete Profile';

  @override
  String get requiredFields => '* Required fields';

  @override
  String get pleaseEnterYourName => 'Please enter your name';

  @override
  String get nameMustBeAtLeast2Characters =>
      'Name must be at least 2 characters';

  @override
  String get pleaseEnterYourPhoneNumber => 'Please enter your phone number';

  @override
  String get phoneNumberMustBe10Digits => 'Phone number must be 10 digits';

  @override
  String get pleaseEnterValidPhoneNumber => 'Please enter a valid phone number';

  @override
  String get pleaseSelectYourBirthDate => 'Please select your birth date';

  @override
  String get pleaseSelectYourGender => 'Please select your gender';

  @override
  String get pleaseFillAllRequiredFields => 'Please fill all required fields';

  @override
  String failedToLoadCities(Object error) {
    return 'Failed to load cities: $error';
  }

  @override
  String failedToLoadWards(Object error) {
    return 'Failed to load wards: $error';
  }

  @override
  String failedToSaveProfile(Object error) {
    return 'Failed to save profile: $error';
  }

  @override
  String get profileCompleted => 'Profile Completed!';

  @override
  String get basicProfileCompletedSetupCandidate =>
      'Basic profile completed. Now set up your candidate profile.';

  @override
  String get profileCompletedWardChatCreated =>
      'Profile completed! Your ward chat room has been created.';

  @override
  String get autoFilledFromAccount => 'Auto-filled from your account';

  @override
  String get completeCandidateProfile => 'Complete Candidate Profile';

  @override
  String get completeYourCandidateProfile => 'Complete Your Candidate Profile';

  @override
  String get fillDetailsCreateCandidateProfile =>
      'Fill in your details to create your candidate profile and start engaging with voters.';

  @override
  String get enterFullNameAsOnBallot =>
      'Enter your full name as it appears on ballot';

  @override
  String get politicalPartyRequired => 'Political Party *';

  @override
  String get symbolNameRequired => 'Symbol Name *';

  @override
  String get manifestoOptional => 'Manifesto (Optional)';

  @override
  String get brieflyDescribeKeyPromises =>
      'Briefly describe your key promises and vision for the community';

  @override
  String get updateCandidateProfile => 'Update Candidate Profile';

  @override
  String get whatHappensNext => 'What happens next?';

  @override
  String get candidateProfileBenefits =>
      '• Your profile will be created and visible to voters\n• You can access the Candidate Dashboard to manage your campaign\n• Premium features will be available for enhanced visibility\n• You can update your manifesto, contact info, and media anytime';

  @override
  String get changeRoleSelection => 'Change Role Selection';

  @override
  String get pleaseSelectYourParty => 'Please select your party';

  @override
  String failedToCreateCandidateProfile(Object error) {
    return 'Failed to create candidate profile: $error';
  }

  @override
  String get imageSizeMustBeLessThan5MB =>
      'Image size must be less than 5MB. Please select a smaller image.';

  @override
  String failedToUploadSymbolImage(Object error) {
    return 'Failed to upload symbol image: $error';
  }

  @override
  String get candidateProfileUpdated => 'Success!';

  @override
  String get candidateProfileUpdatedMessage =>
      'Your candidate profile has been updated! You have 3 days of premium access to try all features.';

  @override
  String get basicInfoUpdatedSuccessfully => 'Basic info updated successfully';

  @override
  String get symbolImageUploadedSuccessfully =>
      'Symbol image uploaded successfully';

  @override
  String get uploading => 'Uploading...';

  @override
  String get max5MB => 'Max 5MB';

  @override
  String get uploadImageOfChosenSymbol =>
      'Upload an image of your chosen symbol. If not provided, a default icon will be used.';

  @override
  String get supportedFormatsJPGPNGMax5MB =>
      'Supported formats: JPG, PNG. Maximum file size: 5MB.';

  @override
  String get imageUploadedSuccessfully => 'Image uploaded successfully';

  @override
  String get pleaseEnterSymbolNameForIndependent =>
      'Please enter a symbol name for independent candidates';

  @override
  String get pleaseSelectYourPoliticalParty =>
      'Please select your political party';

  @override
  String get manifestoTitle => 'Manifesto Title';

  @override
  String get manifestoTitleLabel => 'Manifesto Title';

  @override
  String get manifestoTitleHint =>
      'e.g., Ward 23 Development & Transparency Plan';

  @override
  String get useDemoTitle => 'Use demo title';

  @override
  String get promises => 'Promises';

  @override
  String get promisesTitle => 'Promises';

  @override
  String promiseNumber(Object number) {
    return 'Promise $number';
  }

  @override
  String get useDemoTemplate => 'Use demo template';

  @override
  String get deletePromise => 'Delete Promise';

  @override
  String get promiseTitle => 'Promise Title';

  @override
  String get promiseTitleHint => 'e.g., Clean Water and Good Roads';

  @override
  String pointNumber(Object number) {
    return 'Point $number';
  }

  @override
  String get pointHint1 => 'Provide 24x7 clean water to every household';

  @override
  String get pointHint2 => 'Pothole-free ward roads in 1 year';

  @override
  String get deletePoint => 'Delete Point';

  @override
  String get addPoint => 'Add Point';

  @override
  String get addNewPromise => 'Add New Promise';

  @override
  String get uploadFiles => 'Upload Files';

  @override
  String get uploadPdf => 'Upload PDF';

  @override
  String get pdfFileLimit => 'File must be < 20 MB';

  @override
  String get choosePdf => 'Choose PDF';

  @override
  String get uploadImage => 'Upload Image';

  @override
  String get imageFileLimit => 'File must be < 10 MB';

  @override
  String get chooseImage => 'Choose Image';

  @override
  String get uploadVideo => 'Upload Video';

  @override
  String get premiumVideo => 'Premium Video';

  @override
  String get videoFileLimit => 'File must be < 100 MB';

  @override
  String get premiumFeatureRequired => 'Premium feature required';

  @override
  String get chooseVideo => 'Choose Video';

  @override
  String filesReadyForUpload(Object count) {
    return 'Files Ready for Upload ($count)';
  }

  @override
  String get filesUploadMessage =>
      'These files will be uploaded to the server when you press Save.';

  @override
  String get readyForUpload => 'Ready for upload';

  @override
  String get removeFromUploadQueue => 'Remove from upload queue';

  @override
  String get manifestoPdf => 'Manifesto PDF';

  @override
  String get tapToViewDocument => 'Tap to view your manifesto document';

  @override
  String get openPdf => 'Open PDF';

  @override
  String get manifestoImage => 'Manifesto Image';

  @override
  String get tapImageFullscreen => 'Tap image to view in full screen';

  @override
  String get manifestoVideo => 'Manifesto Video';

  @override
  String get premiumVideoContent => 'Premium video content available';

  @override
  String get manifestoAnalytics => 'Manifesto Analytics';

  @override
  String get views => 'Views';

  @override
  String get likes => 'Likes';

  @override
  String get shares => 'Shares';

  @override
  String get downloads => 'Downloads';

  @override
  String get chooseManifestoTitle => 'Choose Manifesto Title';

  @override
  String get selectLanguage => 'Select Language:';

  @override
  String get chooseTitle => 'Choose Title:';

  @override
  String get standardDevelopmentFocus => 'Standard development focus';

  @override
  String get developmentWithTransparency =>
      'Development with transparency focus';

  @override
  String get focusOnProgress => 'Focus on progress and growth';

  @override
  String get focusOnCitizenWelfare => 'Focus on citizen welfare';

  @override
  String get chooseDemoTemplate => 'Choose Demo Template';

  @override
  String get infrastructureCleanliness => 'Infrastructure & Cleanliness';

  @override
  String get infrastructureDescription =>
      'Clean water, roads & waste management';

  @override
  String get transparencyAccountability => 'Transparency & Accountability';

  @override
  String get transparencyDescription =>
      'Open governance & citizen participation';

  @override
  String get educationYouthDevelopment => 'Education & Youth Development';

  @override
  String get educationDescription => 'Digital education & skill training';

  @override
  String get womenSafetyMeasures => 'Women & Safety Measures';

  @override
  String get womenSafetyDescription => 'Women empowerment & security';

  @override
  String get useThisTemplate => 'Use This Template';

  @override
  String get cleanWaterGoodRoads => 'स्वच्छ पाणी व चांगले रस्ते';

  @override
  String get provideCleanWater => 'प्रत्येक घराला २४x७ स्वच्छ पाणी पुरवठा.';

  @override
  String get potholeFreeRoads => 'खड्डेमुक्त वॉर्ड रस्ते १ वर्षात.';

  @override
  String get transparencyAccountabilityTitle => 'पारदर्शकता आणि जबाबदारी';

  @override
  String get regularMeetings => 'नियमित सार्वजनिक बैठक आणि अद्यतने';

  @override
  String get openBudgetDiscussion => 'खुला बजेट चर्चा';

  @override
  String get educationYouthTitle => 'शिक्षण आणि युवा विकास';

  @override
  String get digitalLibrary => 'डिजिटल लायब्ररी आणि ई-लर्निंग केंद्र';

  @override
  String get skillTrainingPrograms => 'कौशल्य प्रशिक्षण कार्यक्रम';

  @override
  String get womenSafetyTitle => 'महिला आणि सुरक्षा';

  @override
  String get specialHealthCenter => 'महिलांसाठी विशेष आरोग्य केंद्र';

  @override
  String get cctvCameras => 'प्रत्येक चौकात CCTV कॅमेरे';

  @override
  String get willBeDeletedWhenYouSave => 'Will be deleted when you save';

  @override
  String get markPdfForDeletion => 'Mark PDF for Deletion';

  @override
  String get pdfDeletionWarning =>
      'This PDF will be permanently deleted when you save changes. This action cannot be undone.';

  @override
  String get markForDeletion => 'Mark for Deletion';

  @override
  String get pdfMarkedForDeletion =>
      'PDF marked for deletion. Press Save to confirm.';

  @override
  String get markImageForDeletion => 'Mark Image for Deletion';

  @override
  String get imageDeletionWarning =>
      'This image will be permanently deleted when you save changes. This action cannot be undone.';

  @override
  String get imageMarkedForDeletion =>
      'Image marked for deletion. Press Save to confirm.';

  @override
  String get markVideoForDeletion => 'Mark Video for Deletion';

  @override
  String get videoDeletionWarning =>
      'This video will be permanently deleted when you save changes. This action cannot be undone.';

  @override
  String get videoMarkedForDeletion =>
      'Video marked for deletion. Press Save to confirm.';

  @override
  String get premiumFeatureMultiResolution =>
      'Premium Feature - Multi-resolution video processing';

  @override
  String get selectDistrict => 'Select District';

  @override
  String get selectArea => 'Select Area (विभाग)';

  @override
  String get searchDistricts => 'Search districts...';

  @override
  String get searchAreas => 'Search areas...';

  @override
  String get searchWards => 'Search wards...';

  @override
  String get noDistrictsFound => 'No districts found';

  @override
  String get noAreasFound => 'No areas found';

  @override
  String get noWardsFound => 'No wards found';

  @override
  String get tryDifferentSearchTerm => 'Try a different search term';

  @override
  String get noAreasAvailable => 'No Areas';

  @override
  String get areas => 'areas';

  @override
  String get selectDistrictFirst => 'Select district first';

  @override
  String get selectAreaFirst => 'Select area first';

  @override
  String get noAreasAvailableInDistrict =>
      'No areas available in this district';

  @override
  String get noWardsAvailableInArea => 'No wards available in this area';

  @override
  String get profilePhotoUpdatedSuccessfully =>
      'Profile photo updated successfully!';

  @override
  String get pollQuestion => 'Poll Question';

  @override
  String get pollQuestionHint => 'What would you like to ask?';

  @override
  String get options => 'Options';

  @override
  String optionLabel(Object number) {
    return 'Option $number';
  }

  @override
  String get removeOption => 'Remove option';

  @override
  String addOption(Object current, Object max) {
    return 'Add Option ($current/$max)';
  }

  @override
  String get expirationSettings => 'Expiration Settings';

  @override
  String get defaultExpiration => 'Default: 24 hours';

  @override
  String get expiresIn => 'Expires in:';

  @override
  String pollExpiresOn(Object dateTime) {
    return 'Poll will expire on: $dateTime';
  }

  @override
  String get pleaseEnterPollQuestion => 'Please enter a poll question';

  @override
  String get pleaseAddAtLeast2Options => 'Please add at least 2 options';

  @override
  String get loadingPoll => 'Loading poll...';

  @override
  String get pollNotFound => 'Poll not found';

  @override
  String get voteRecorded => 'Vote Recorded!';

  @override
  String get voteRecordedMessage => 'Your vote has been recorded';

  @override
  String get voteFailed => 'Vote Failed';

  @override
  String get voteFailedMessage =>
      'Failed to record your vote. Please try again.';

  @override
  String get pollExpiredMessage =>
      'This poll has expired. Voting is no longer available.';

  @override
  String get thankYouForVoting => 'Thank you for voting!';

  @override
  String get maximumOptions => 'Maximum Options';

  @override
  String get maximumOptionsMessage => 'You can add up to 10 options';

  @override
  String get minimumOptions => 'Minimum Options';

  @override
  String get minimumOptionsMessage => 'You need at least 2 options';

  @override
  String get imageUrlCopiedToClipboard => 'Image URL copied to clipboard';

  @override
  String get failedToShare => 'Failed to share';

  @override
  String get failedToLoadVideo => 'Failed to load video';

  @override
  String get shareFunctionalityComingSoon =>
      'Share functionality would open native share dialog';

  @override
  String get pleaseEnterAComment => 'Please enter a comment';

  @override
  String get replyFunctionalityComingSoon => 'Reply functionality coming soon!';

  @override
  String get selectGender => 'Select Gender';

  @override
  String get failedToPickImage => 'Failed to pick image';

  @override
  String get failedToUploadPhoto => 'Failed to upload photo';

  @override
  String get useDemoData => 'Use Demo Data';

  @override
  String get deleteEvent => 'Delete Event';

  @override
  String get areYouSureYouWantToDeleteThisEvent =>
      'Are you sure you want to delete this event?';

  @override
  String get addYouTubeLink => 'Add YouTube Link';

  @override
  String get addImage => 'Add Image';

  @override
  String get addVideo => 'Add Video';

  @override
  String get noMediaItemsYet =>
      'No media items yet. Add your first media item!';

  @override
  String get addMediaItem => 'Add Media Item';

  @override
  String get promiseViewModeNotImplementedYet =>
      'Promise view mode not implemented yet';

  @override
  String get largeFileWarning => 'Large File Warning';

  @override
  String get chooseDifferentPhoto => 'Choose Different Photo';

  @override
  String get chooseDifferentFile => 'Choose Different File';

  @override
  String get continueAnyway => 'Continue Anyway';

  @override
  String get photoSavedLocally => 'Photo saved locally';

  @override
  String get failedToSavePhoto => 'Failed to save photo';

  @override
  String get noAchievementsYet =>
      'No achievements yet. Add your first achievement!';

  @override
  String get addAchievement => 'Add Achievement';

  @override
  String get loggingOut => 'Logging out...';

  @override
  String get failedToUpdateProfilePhoto => 'Failed to update profile photo';

  @override
  String get recordingStarted => 'Recording Started';

  @override
  String get tapMicButtonToStopRecording =>
      'Tap the mic button again to stop recording';

  @override
  String get recordingStopped => 'Recording Stopped';

  @override
  String get sendingVoiceMessage => 'Sending voice message...';

  @override
  String get failedToGetRecordingPath =>
      'Failed to get recording file path. Please try again.';

  @override
  String get recordingFileEmpty =>
      'Voice recording is empty. Please try recording again.';

  @override
  String get failedToSaveVoiceRecording =>
      'Failed to save voice recording. Please try again.';

  @override
  String get permissionDenied => 'Permission Denied';

  @override
  String get microphonePermissionRequired =>
      'Microphone permission is required for voice recording';

  @override
  String get recordingError => 'Recording Error';

  @override
  String get failedToStartVoiceRecording =>
      'Failed to start voice recording. Please try again.';

  @override
  String get messageTooLong => 'Message Too Long';

  @override
  String get messagesCannotExceed4096Characters =>
      'Messages cannot exceed 4096 characters';

  @override
  String get cannotSendMessage => 'Cannot Send Message';

  @override
  String get insufficientQuotaOrXP =>
      'You have no remaining messages or XP. Please watch an ad to earn XP.';

  @override
  String get messageFailed => 'Message Failed';

  @override
  String get failedToSendMessage => 'Failed to send message. Tap to retry.';

  @override
  String get messageSent => 'Message Sent';

  @override
  String get messageSentSuccessfully => 'Message sent successfully!';

  @override
  String get retryFailed => 'Retry Failed';

  @override
  String get failedToSendMessageRetry =>
      'Failed to send message. Tap to retry again.';

  @override
  String get cannotRetry => 'Cannot Retry';

  @override
  String get youHaveNoRemainingMessagesOrXP =>
      'You have no remaining messages or XP.';

  @override
  String get messageDeleted => 'Message Deleted';

  @override
  String get messageHasBeenDeleted => 'Message has been deleted';

  @override
  String get deleteFailed => 'Delete Failed';

  @override
  String get failedToDeleteMessage =>
      'Failed to delete message. Please try again.';

  @override
  String get permissionDeniedDelete => 'Permission Denied';

  @override
  String get youCanOnlyDeleteYourOwnMessages =>
      'You can only delete your own messages';

  @override
  String get pollCreationFailed => 'Poll Creation Failed';

  @override
  String get failedToCreatePoll => 'Failed to create poll. Please try again.';

  @override
  String get fullMessage => 'Full Message';

  @override
  String get addReaction => 'Add Reaction';

  @override
  String get reportMessage => 'Report Message';

  @override
  String get retrySend => 'Retry Send';

  @override
  String get deleteMessage => 'Delete Message';

  @override
  String get messagesRefreshed => 'Messages Refreshed';

  @override
  String get messageListHasBeenRefreshed => 'Message list has been refreshed';

  @override
  String get noChatRoom => 'No Chat Room';

  @override
  String get pleaseSelectAChatRoomFirst => 'Please select a chat room first';

  @override
  String get cacheCleared => 'Cache Cleared';

  @override
  String get clearedMessageCaches => 'Cleared message caches';

  @override
  String get dialogsClosed => 'Dialogs Closed';

  @override
  String get closedStuckDialogs => 'Closed stuck dialog(s)';

  @override
  String get noDialogs => 'No Dialogs';

  @override
  String get noStuckDialogsFound => 'No stuck dialogs found';
}
