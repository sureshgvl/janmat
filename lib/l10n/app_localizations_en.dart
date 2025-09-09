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
  String get searchByWard => 'Search by Ward';

  @override
  String get premiumFeatures => 'Premium Features';

  @override
  String get upgradeToUnlockPremiumFeatures => 'Upgrade to unlock premium features';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get permanentlyDeleteYourAccountAndData => 'Permanently delete your account and data';

  @override
  String get error => 'Error';

  @override
  String failedToLogout(Object error) {
    return 'Failed to logout: $error';
  }

  @override
  String get manageYourCampaignAndConnectWithVoters => 'Manage your campaign and connect with voters';

  @override
  String get stayInformedAboutYourLocalCandidates => 'Stay informed about your local candidates';

  @override
  String get premiumTrialActive => 'Premium Trial Active';

  @override
  String get oneDayRemainingUpgrade => '1 day remaining - Upgrade to continue premium features!';

  @override
  String daysRemainingInTrial(Object days) {
    return '$days days remaining in your trial';
  }

  @override
  String get upgrade => 'Upgrade';

  @override
  String get upgradeAvailable => 'Upgrade Available';

  @override
  String get premiumUpgradeFeatureComingSoon => 'Premium upgrade feature coming soon!';

  @override
  String get unlockPremiumFeatures => 'Unlock Premium Features';

  @override
  String get enjoyFullPremiumFeaturesDuringTrial => 'Enjoy full premium features during your trial';

  @override
  String get getPremiumVisibilityAndAnalytics => 'Get premium visibility and analytics';

  @override
  String get accessExclusiveContentAndFeatures => 'Access exclusive content and features';

  @override
  String get explorePremium => 'Explore Premium';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get myArea => 'My Area';

  @override
  String get manageYourCampaign => 'Manage Your Campaign';

  @override
  String get viewAnalyticsAndUpdateYourProfile => 'View analytics and update your profile';

  @override
  String get deleteAccountConfirmation => 'Are you sure you want to delete your account? This action cannot be undone and will permanently delete all your data including:\n\n• Your profile information\n• Chat conversations and messages\n• XP points and rewards\n• Following/followers data\n\nThis action is irreversible.';

  @override
  String get cancel => 'Cancel';

  @override
  String get success => 'Success';

  @override
  String get accountDeletedSuccessfully => 'Your account has been deleted successfully.';

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
  String get messageLimitReachedDescription => 'You have reached your daily message limit. Choose an option to continue:';

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
  String get initializeSampleDataDescription => 'This will create sample chat rooms and messages for testing purposes. This is only available for admin users.\n\nContinue?';

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
  String get updatePartyAffiliationSubtitle => 'Change your party or become independent with a custom symbol.';

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
  String get symbolNameValidation => 'Please enter a symbol name for independent candidates';

  @override
  String get symbolImageOptional => 'Symbol Image (Optional)';

  @override
  String get symbolImageDescription => 'Upload an image of your chosen symbol. If not provided, a default icon will be used.';

  @override
  String get uploadSymbolImage => 'Upload Symbol Image';

  @override
  String get importantNotice => 'Important Notice';

  @override
  String get partyChangeWarning => 'Changing your party affiliation will update your profile immediately. This change will be visible to all voters.';

  @override
  String get partyUpdateSuccess => 'Your party and symbol have been updated successfully!';

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
  String get updatingText => 'Updating...';

  @override
  String get updateInstructionText => 'Tap update to save your party and symbol changes';
}
