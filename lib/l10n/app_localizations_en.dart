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
  String get aboutDescription => 'JanMat is independently developed and not affiliated with any government authority, election commission, or political party.';

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
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get retry => 'Retry';

  @override
  String get createNewChatRoom => 'Create New Chat Room';

  @override
  String get roomTitle => 'Room Title';

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
  String get initializeSampleData => 'Initialize Sample Data';

  @override
  String get initializeSampleDataDescription => 'This will create sample chat rooms and messages for testing purposes. This is only available for admin users.\n\nContinue?';

  @override
  String get initialize => 'Initialize';

  @override
  String get loadingRewardedAd => 'Loading rewarded ad...';

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
  String get browseCandidates => 'Browse Candidates';

  @override
  String get myArea => 'My Area';

  @override
  String failedToLogout(Object error) {
    return 'Failed to logout: $error';
  }

  @override
  String get deleteAccountConfirmation => 'Are you sure you want to delete your account? This action cannot be undone and will permanently delete all your data including:\n\n• Your profile information\n• Chat conversations and messages\n• XP points and rewards\n• Following/followers data\n\nThis action is irreversible.';

  @override
  String get accountDeletedSuccessfully => 'Your account has been deleted successfully.';

  @override
  String failedToDeleteAccount(Object error) {
    return 'Failed to delete account: $error';
  }

  @override
  String get myAreaCandidates => 'My Area Candidates';

  @override
  String get candidateDashboard => 'Candidate Dashboard';

  @override
  String get changePartySymbolTitle => 'Change Party Symbol';

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
  String get logout => 'Logout';

  @override
  String get signOutOfYourAccount => 'Sign out of your account';

  @override
  String get uploadFiles => 'Upload Files';

  @override
  String get uploadPdf => 'Upload PDF';

  @override
  String get pdfFileLimit => 'PDF File Limit';

  @override
  String get uploadImage => 'Upload Image';

  @override
  String get imageFileLimit => 'Image File Limit';

  @override
  String get uploadVideo => 'Upload Video';

  @override
  String get videoFileLimit => 'Video File Limit';

  @override
  String filesReadyForUpload(Object count) {
    return 'Files ready for upload: $count';
  }

  @override
  String get filesUploadMessage => 'Files Upload Message';

  @override
  String get features => 'Features';

  @override
  String get buyNow => 'Buy Now';

  @override
  String get yourXpBalance => 'Your XP Balance';

  @override
  String get howToUseXpPoints => 'How to Use XP Points';

  @override
  String get symbolImageSizeLimitError => 'Symbol image size limit error';

  @override
  String get symbolUploadSuccess => 'Symbol uploaded successfully';

  @override
  String symbolUploadError(Object error) {
    return 'Symbol upload error: $error';
  }

  @override
  String get partyUpdateSuccess => 'Party updated successfully';

  @override
  String partyUpdateError(Object error) {
    return 'Party update error: $error';
  }

  @override
  String get updatePartyAffiliationHeader => 'Update Party Affiliation';

  @override
  String get updatePartyAffiliationSubtitle => 'Update your party affiliation and symbol';

  @override
  String get currentParty => 'Current Party';

  @override
  String symbolLabel(Object symbol) {
    return 'Symbol: $symbol';
  }

  @override
  String get updateButton => 'Update';

  @override
  String get updateInstructionText => 'Update your party and symbol information';

  @override
  String get shareFunctionalityComingSoon => 'Share functionality coming soon';

  @override
  String get like => 'Like';

  @override
  String get likes => 'Likes';

  @override
  String get party_independent => 'Independent';

  @override
  String get basicInformation => 'Basic Information';

  @override
  String get age => 'Age';

  @override
  String get gender => 'Gender';

  @override
  String get education => 'Education';

  @override
  String get address => 'Address';

  @override
  String get location => 'Location';

  @override
  String get district => 'District';

  @override
  String get ward => 'Ward';

  @override
  String get upgradeToPremium => 'Upgrade to Premium';

  @override
  String get basicInfoUpdatedSuccessfully => 'Basic info updated successfully';

  @override
  String get chooseManifestoTitle => 'Choose Manifesto Title';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get chooseTitle => 'Choose Title';

  @override
  String get standardDevelopmentFocus => 'Standard Development Focus';

  @override
  String get developmentWithTransparency => 'Development with Transparency';

  @override
  String get focusOnProgress => 'Focus on Progress';

  @override
  String get focusOnCitizenWelfare => 'Focus on Citizen Welfare';

  @override
  String get manifestoTitle => 'Manifesto Title';

  @override
  String get manifestoTitleLabel => 'Manifesto Title';

  @override
  String get manifestoTitleHint => 'Enter manifesto title';

  @override
  String get useDemoTitle => 'Use Demo Title';

  @override
  String get manifestoPdf => 'Manifesto PDF';

  @override
  String get willBeDeletedWhenYouSave => 'Will be deleted when you save';

  @override
  String get markPdfForDeletion => 'Mark PDF for Deletion';

  @override
  String get pdfDeletionWarning => 'This will permanently delete the PDF file';

  @override
  String get markForDeletion => 'Mark for Deletion';

  @override
  String get pdfMarkedForDeletion => 'PDF marked for deletion';

  @override
  String get manifestoImage => 'Manifesto Image';

  @override
  String get markImageForDeletion => 'Mark Image for Deletion';

  @override
  String get imageDeletionWarning => 'This will permanently delete the image file';

  @override
  String get imageMarkedForDeletion => 'Image marked for deletion';

  @override
  String get manifestoVideo => 'Manifesto Video';

  @override
  String get premiumFeatureMultiResolution => 'Premium Feature: Multi-Resolution';

  @override
  String get markVideoForDeletion => 'Mark Video for Deletion';

  @override
  String get videoDeletionWarning => 'This will permanently delete the video file';

  @override
  String get videoMarkedForDeletion => 'Video marked for deletion';

  @override
  String get premiumVideo => 'Premium Video';

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

  @override
  String promises(Object max) {
    return 'Promises ($max)';
  }

  @override
  String get addPoint => 'Add Point';

  @override
  String get addNewPromise => 'Add New Promise';

  @override
  String get promisesTitle => 'Promises Title';

  @override
  String get selectPartyValidation => 'Please select a party';

  @override
  String get newPartyLabel => 'New Party';

  @override
  String get symbolNameLabel => 'Symbol Name';

  @override
  String get symbolNameHint => 'Enter symbol name';

  @override
  String get symbolNameValidation => 'Symbol name is required';

  @override
  String get symbolImageOptional => 'Symbol Image (Optional)';

  @override
  String get symbolImageDescription => 'Upload an image for your party symbol';

  @override
  String get uploadSymbolImage => 'Upload Symbol Image';

  @override
  String get importantNotice => 'Important Notice';

  @override
  String get partyChangeWarning => 'Changing your party will reset your symbol and may affect your campaign visibility.';

  @override
  String get updatingText => 'Updating...';

  @override
  String get profileLiked => 'Profile Liked';

  @override
  String get profileUnliked => 'Profile Unliked';

  @override
  String checkOutCandidateProfile(Object name) {
    return 'Check out $name\'s candidate profile';
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
  String get selectValidityPeriod => 'Select Validity Period';

  @override
  String priceForDays(Object days) {
    return 'Price for $days Days';
  }

  @override
  String purchaseForAmount(Object amount) {
    return 'Purchase for ₹$amount';
  }

  @override
  String purchasePlan(Object planName) {
    return 'Purchase $planName';
  }

  @override
  String get electionTypeUpper => 'MUNICIPAL CORPORATION';

  @override
  String validityDays(Object days) {
    return 'Validity: $days days';
  }

  @override
  String expiresOn(Object date) {
    return 'Valid until $date';
  }

  @override
  String amount(Object price) {
    return 'Amount: ₹$price';
  }

  @override
  String get securePaymentGateway => 'You will be redirected to our secure payment gateway.';

  @override
  String get proceedToPayment => 'Proceed to Payment';

  @override
  String get profileDetails => 'Profile Details';

  @override
  String get bio => 'Bio';

  @override
  String get useDemoBio => 'Use Demo Bio';

  @override
  String get noBioAvailable => 'No bio available';

  @override
  String get thankYou => 'Thank you!';

  @override
  String get voteRecorded => 'Your vote is recorded';

  @override
  String shareManifestoText(Object name) {
    return 'Check out $name\'s Manifesto PDF';
  }

  @override
  String shareManifestoSubject(Object name, Object title) {
    return '$name\'s $title PDF';
  }

  @override
  String manifestoVision(Object name) {
    return 'Learn more about $name\'s vision for our community!';
  }

  @override
  String get downloadAppText => 'Download JanMat app to explore complete manifestos and connect with candidates.';

  @override
  String get limited => 'LIMITED';

  @override
  String get current => 'CURRENT';

  @override
  String get free => 'FREE';

  @override
  String get xpPoints => 'XP Points';

  @override
  String get contactSupport => 'Contact Support';

  @override
  String get basicInfo => 'Basic Info';

  @override
  String get manifesto => 'Manifesto';

  @override
  String get pdfUpload => 'PDF Upload';

  @override
  String get videoUpload => 'Video Upload';

  @override
  String achievements(Object max) {
    return 'Achievements ($max)';
  }

  @override
  String mediaItems(Object max) {
    return 'Media ($max items)';
  }

  @override
  String get contact => 'Contact';

  @override
  String get extendedInfo => 'Extended Info';

  @override
  String get socialLinks => 'Social Links';

  @override
  String get prioritySupport => 'Priority Support';

  @override
  String events(Object max) {
    return 'Events ($max)';
  }

  @override
  String get analytics => 'Analytics';

  @override
  String get advanced => 'Advanced';

  @override
  String get fullDashboard => 'Full Dashboard';

  @override
  String get realTime => 'Real-time';

  @override
  String get premiumBadge => 'Premium Badge';

  @override
  String get sponsoredBanner => 'Sponsored Banner';

  @override
  String get highlightBanner => 'Highlight Banner on Home Screen';

  @override
  String get pushNotifications => 'Push Notifications';

  @override
  String get multipleHighlights => 'Multiple Highlights';

  @override
  String get carouselOnHome => 'Carousel on Home Screen';

  @override
  String get adminSupport => 'Admin Support';

  @override
  String get customBranding => 'Custom Branding';

  @override
  String get allocatedSeats => 'Allocated Seats';

  @override
  String get freePlanActive => 'Free Plan Active';

  @override
  String get basicPlanActive => 'Basic Plan Active';

  @override
  String get goldPlanActive => 'Gold Plan Active';

  @override
  String get platinumPlanActive => 'Platinum Plan Active';

  @override
  String get currentActivePlanMessage => 'This is your current active plan';

  @override
  String get higherPlanActive => 'You have a higher plan active';

  @override
  String get planAlreadyActive => 'This plan is already active';

  @override
  String get planNotAvailable => 'Plan not available';

  @override
  String get freePlanName => 'Free Plan';

  @override
  String get basicPlanName => 'Basic Plan';

  @override
  String get goldPlanName => 'Gold Plan';

  @override
  String get platinumPlanName => 'Platinum Plan';

  @override
  String get activeFreePlan => 'Active Free Plan';

  @override
  String get activateFreePlan => 'Activate Free Plan';

  @override
  String get currentPlan => 'Current Plan';

  @override
  String get alreadyActive => 'Already Active';

  @override
  String get alreadyActiveButton => 'Already Active';

  @override
  String get planExpired => 'Plan Expired';

  @override
  String expiresInTime(Object time) {
    return 'Expires in $time';
  }

  @override
  String get confirmPlanChange => 'Confirm Plan Change';

  @override
  String get downgradeWarning => 'Warning: You will lose all premium features and may lose access to paid content.';

  @override
  String get yesDowngrade => 'Yes, Downgrade';

  @override
  String subscribeFirst(Object plan) {
    return 'Subscribe to $plan First';
  }

  @override
  String get loadingPremiumPlans => 'Loading premium plans...';

  @override
  String get noPlansAvailable => 'No premium plans available at the moment.';

  @override
  String get highlightBannerFeatures => 'Professional Highlight Banner On Home Screen Features';

  @override
  String get highlightBannerDescription => '• Up to 4 banners on home screen\n• Premium visibility for your campaign\n• Requires Platinum Plan to unlock';

  @override
  String get carouselProfile => 'Carousel Profile on Home Screen';

  @override
  String get carouselDescription => '• Up to 10 carousel slots on home screen\n• Maximum visibility for your campaign\n• Requires Platinum Plan to unlock';

  @override
  String get locked => 'LOCKED';

  @override
  String requiresPlanOrPlatinum(Object plan) {
    return 'Requires $plan or Platinum Plan';
  }

  @override
  String get refreshPlans => 'Refresh Plans';

  @override
  String get premiumPlansRefreshed => 'Premium plans refreshed successfully!';

  @override
  String failedToRefreshPlans(Object error) {
    return 'Failed to refresh plans: $error';
  }

  @override
  String get noPlansAvailableShort => 'No plans available';

  @override
  String get loading => 'Loading...';

  @override
  String get allocateSeats => 'Allocated Seats';

  @override
  String get multiResolution => 'Multi-Resolution';
}
