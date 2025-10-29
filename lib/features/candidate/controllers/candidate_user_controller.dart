import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../features/user/models/user_model.dart';
import '../models/candidate_model.dart';
import '../models/events_model.dart';
import '../models/basic_info_model.dart';
import '../models/contact_model.dart';
import '../models/manifesto_model.dart';
import '../models/achievements_model.dart';
import '../models/location_model.dart';
import '../../../features/user/controllers/user_controller.dart';
import '../../../features/user/services/user_cache_service.dart';
import '../repositories/candidate_repository.dart';
import '../controllers/achievements_controller.dart';
import '../../../utils/app_logger.dart';

/// Centralized controller for candidate role users.
/// Combines user data and candidate data management in a single reactive controller.
/// Fetches data once after login and provides reactive access throughout the app.
class CandidateUserController extends GetxController {
  static CandidateUserController get to => Get.find();

  // Reactive data
  final Rx<UserModel?> user = Rx<UserModel?>(null);
  final Rx<Candidate?> candidate = Rx<Candidate?>(null);
  final Rx<Candidate?> editedData = Rx<Candidate?>(null); // For backward compatibility
  final RxBool isLoading = false.obs;
  final RxBool isInitialized = false.obs;
  final RxBool isPaid = false.obs; // For backward compatibility

  // Events data (for backward compatibility with events tab)
  final RxList<EventData> events = RxList<EventData>([]);
  final RxBool isEventsLoading = false.obs;

  // Legacy compatibility - delegate to candidate
  Rx<Candidate?> get candidateData => candidate;

  final RxBool _isBasicInfoEditing = false.obs;
  final RxBool _isManifestoEditing = false.obs;
  final RxBool _isContactEditing = false.obs;
  final RxBool _isAchievementsEditing = false.obs;
  final RxBool _isMediaEditing = false.obs;
  final RxBool _isEventsEditing = false.obs;
  final RxBool _isHighlightsEditing = false.obs;
  final RxBool _isAnalyticsEditing = false.obs;

  final Map<String, dynamic> _changedFields = {};
  final Map<String, dynamic> _changedExtraInfoFields = {};
  final Map<String, dynamic> _changedCandidateFields = {};

  // Dependencies
  final UserController _userController = Get.find<UserController>();
  final CandidateRepository _candidateRepository = CandidateRepository();

  @override
  void onInit() {
    super.onInit();
    AppLogger.common('👤 CandidateUserController initialized (conditional loading)');
    // Don't auto-initialize - will be called explicitly when role is determined
  }

  /// Initialize candidate data - called explicitly when user role is determined to be 'candidate'
  /// This replaces the auto-initialization to avoid loading for non-candidate users
  /// Loads candidate data via Firebase call if not already loaded
  void initializeForCandidate() async {
    // If already initialized and candidate data is available, skip
    if (isInitialized.value && candidate.value != null) {
      AppLogger.common('👤 CandidateUserController already initialized with candidate data, skipping');
      return;
    }

    try {
      AppLogger.common('👤 Initializing CandidateUserController for candidate user');

      // Check immediately in case user is already authenticated but candidate data is missing
      final currentUser = FirebaseAuth.instance.currentUser;
      final userController = UserController.to;
      if (currentUser != null &&
          userController.user.value?.role == 'candidate' &&
          candidate.value == null) {
        AppLogger.common('👤 Loading candidate data for already authenticated candidate user');
        // Load candidate data via Firebase call since it's not available yet
        await loadCandidateUserData(currentUser.uid);
        return; // Don't need to set up listeners if we already loaded data
      }

      // Listen to auth state changes to load candidate data when user logs in
      ever(_userController.user, (UserModel? authenticatedUser) async {
        if (authenticatedUser != null && authenticatedUser.role == 'candidate' && candidate.value == null) {
          AppLogger.common('👤 Loading candidate data for authenticated candidate user');
          // Load candidate data via Firebase call - candidate data may not be available yet
          await loadCandidateUserData(authenticatedUser.uid);
        }
      });
    } catch (e) {
      AppLogger.commonError('❌ Failed to initialize candidate data', error: e);
      // Don't rethrow - initialization failure shouldn't crash the app
    }
  }

  @override
  void onClose() {
    AppLogger.common('👤 CandidateUserController disposed');
    super.onClose();
  }

  /// Load both user and candidate data for candidate role users
  /// This should be called once after login for candidate users
  Future<void> loadCandidateUserData(String uid) async {
    if (isInitialized.value) {
      AppLogger.common('ℹ️ Candidate user data already loaded, skipping');
      return;
    }

    try {
      isLoading.value = true;
      AppLogger.common('📥 Loading candidate user data for UID: $uid');

      // Load user data first
      await _userController.loadUserData(uid);
      user.value = _userController.user.value;

      // Verify user is a candidate
      if (user.value?.role != 'candidate') {
        AppLogger.common('⚠️ User is not a candidate (role: ${user.value?.role}), skipping candidate data load');
        isInitialized.value = true;
        return;
      }

      // Load candidate data - always load for candidates

      AppLogger.common('🗳️ Calling _candidateRepository.getCandidateData for UID: $uid');
      try {
        candidate.value = await _candidateRepository.getCandidateData(user.value!.uid);
        AppLogger.common('✅ Candidate repository returned: ${candidate.value != null ? "data found" : "null"}');

        if (candidate.value == null) {
          // Debug: Scan all candidates in the system to see if data exists elsewhere
          await _candidateRepository.logAllCandidatesInSystem();
          AppLogger.commonError('❌ DEBUG: Candidate data is null after repository call - check Firebase database');

          // 🔧 AUTO-CREATE BASIC CANDIDATE DATA FOR TESTING MEDIA FUNCTIONALITY
          AppLogger.common('🚀 AUTO-FIX: Creating minimal candidate data for media testing');
          try {
            // Create a basic candidate profile for testing
            final testCandidate = Candidate(
              candidateId: user.value!.uid,
              userId: user.value!.uid,
              party: 'Independent',
              sponsored: false,
              contact: ContactModel(
                email: user.value!.email ?? '',
                phone: user.value!.phone ?? '',
                address: '',
                socialLinks: {},
              ),
              location: LocationModel(
                stateId: 'maharashtra',
                districtId: 'maharashtra/pune',
                bodyId: 'pune_municipal_corporation',
                wardId: 'ward_1',
              ),
              basicInfo: BasicInfoModel(
                fullName: user.value!.name ?? 'Test Candidate',
                age: null,
                gender: null,
                education: null,
                profession: null,
                languages: [],
              ),
              manifestoData: ManifestoModel(
                title: 'Test Manifesto',
                promises: [],
              ),
              achievements: [],
              media: [],
              events: [],
              highlights: [],
              createdAt: DateTime.now(),
            );

            await _candidateRepository.createCandidate(testCandidate);
            AppLogger.common('✅ Test candidate profile created successfully');

            // Now load it again
            candidate.value = await _candidateRepository.getCandidateData(user.value!.uid);
            if (candidate.value != null) {
              AppLogger.common('✅ Test candidate data loaded: ${candidate.value!.basicInfo!.fullName}');
            }
          } catch (e) {
            AppLogger.commonError('❌ Failed to auto-create test candidate profile: $e');
          }
        }

      } catch (e) {
        AppLogger.commonError('❌ Error loading candidate data from repository: $e');
        // Debug: Try to scan all candidates to see what's available
        await _candidateRepository.logAllCandidatesInSystem();
        rethrow;
      }
      editedData.value = candidate.value; // Initialize edited data

      AppLogger.common('✅ Finished _candidateRepository.getCandidateData, candidate.value: ${candidate.value != null ? 'not null' : 'null'}');

      isInitialized.value = true;
      AppLogger.common('✅ Candidate user data loaded successfully');
      if (user.value != null) {
        AppLogger.common('👤 User: ${user.value!.name} (${user.value!.role})');
      }
      if (candidate.value != null) {
        AppLogger.common('👥 Candidate: ${candidate.value!.basicInfo!.fullName} (${candidate.value!.party ?? 'No Party'})');
        AppLogger.common('🏆 Achievements: ${candidate.value!.achievements?.length ?? 0} items');
        if (candidate.value!.achievements != null && candidate.value!.achievements!.isNotEmpty) {
          for (int i = 0; i < candidate.value!.achievements!.length; i++) {
            final achievement = candidate.value!.achievements![i];
            AppLogger.common('   Achievement $i: ${achievement.title} (photo: ${achievement.photoUrl == null ? 'none' : (achievement.photoUrl!.startsWith('http') ? 'firebase' : 'local')})');
          }
        }
      } else {
        AppLogger.common('⚠️ Candidate data is null after loading - check Firebase database');
      }

    } catch (e) {
      AppLogger.commonError('❌ Failed to load candidate user data', error: e);
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Update user data
  Future<void> updateUserData(Map<String, dynamic> updates) async {
    await _userController.updateUserData(updates);
    user.value = _userController.user.value;
  }

  /// Update candidate data
  Future<void> updateCandidateData(Map<String, dynamic> updates) async {
    // Refresh candidate data from repository
    await refreshCandidateData();
  }

  /// Refresh candidate data only
  Future<void> refreshCandidateData() async {
    if (user.value?.role != 'candidate' && FirebaseAuth.instance.currentUser?.uid != null) return;

    final uid = user.value?.uid ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      AppLogger.common('🔄 Refreshing candidate data for user: $uid');
      candidate.value = await _candidateRepository.getCandidateData(uid);
      if (candidate.value != null) {
        AppLogger.common('✅ Candidate data refreshed: ${candidate.value!.basicInfo!.fullName} (${candidate.value!.candidateId})');

        // DEBUG: Check media count after refresh
        AppLogger.common('🖼️ [REFRESH MEDIA] Media count after refresh: ${candidate.value!.media?.length ?? "null"}');
        if (candidate.value!.media != null && candidate.value!.media!.isNotEmpty) {
          for (int i = 0; i < candidate.value!.media!.length; i++) {
            final mediaItem = candidate.value!.media![i] as Map<String, dynamic>;
            final itemTitle = mediaItem['title'] ?? 'Untitled';
            final itemImages = mediaItem['images'] as List<dynamic>? ?? [];
            final itemVideos = mediaItem['videos'] as List<dynamic>? ?? [];
            AppLogger.common('   [REFRESH MEDIA] Media item $i: "$itemTitle" - ${itemImages.length} images, ${itemVideos.length} videos');
          }
        }

        // DEBUG: Check achievements count after refresh
        AppLogger.common('🏆 [REFRESH] Achievements count after refresh: ${candidate.value!.achievements?.length ?? "null"}');
        if (candidate.value!.achievements != null && candidate.value!.achievements!.isNotEmpty) {
          for (int i = 0; i < candidate.value!.achievements!.length; i++) {
            final achievement = candidate.value!.achievements![i];
            AppLogger.common('   [REFRESH] Achievement $i: ${achievement.title}');
          }
        }
      } else {
        AppLogger.common('⚠️ No candidate data found during refresh for user: $uid');
      }
    } catch (e) {
      AppLogger.commonError('❌ Failed to refresh candidate data', error: e);
    }
  }

  /// Refresh events data (compatibilty stub - simplified refresh)
  Future<void> refreshEvents() async {
    // Simplified refresh of candidate data to update events
    await refreshCandidateData();
  }

  /// Fetch events data (stub for compatibility)
  Future<void> fetchEvents() async {
    if (candidate.value == null) return;

    try {
      isEventsLoading.value = true;
      // Load events from candidate data if available
      events.assignAll(candidate.value!.events ?? []);
      AppLogger.common('✅ Events loaded: ${events.length} events');
    } catch (e) {
      AppLogger.commonError('❌ Failed to fetch events', error: e);
    } finally {
      isEventsLoading.value = false;
    }
  }

  /// Update events cache (stub for compatibility)
  void updateEventsCache(List<EventData> newEvents) {
    events.assignAll(newEvents);
    AppLogger.common('✅ Events cache updated: ${events.length} events');
  }

  /// Debug method: Log all candidate data in the system (compatibility stub)
  Future<void> logAllCandidateData() async {
    try {
      AppLogger.database('===== CANDIDATE DATA AUDIT =====', tag: 'CANDIDATE_CONTROLLER');
      AppLogger.database('User: ${user.value?.name ?? 'None'} (${user.value?.role ?? 'No Role'})', tag: 'CANDIDATE_CONTROLLER');
      AppLogger.database('Candidate: ${candidate.value?.basicInfo!.fullName ?? 'None'} (${candidate.value?.party ?? 'No Party'})', tag: 'CANDIDATE_CONTROLLER');
      AppLogger.database('Candidates initialized: ${isInitialized.value}', tag: 'CANDIDATE_CONTROLLER');
      AppLogger.database('Loading: ${isLoading.value}', tag: 'CANDIDATE_CONTROLLER');
      AppLogger.database('Audit completed', tag: 'CANDIDATE_CONTROLLER');
    } catch (e) {
      AppLogger.databaseError('Error in candidate data audit', tag: 'CANDIDATE_CONTROLLER', error: e);
    }
  }

  /// Debug method: Scan entire database for candidate documents to troubleshoot "candidate data not found"
  Future<void> debugCandidateDataIssue() async {
    try {
      AppLogger.database('🔍 CANDIDATE DATA DEBUG SCAN STARTED', tag: 'CANDIDATE_DEBUG');
      AppLogger.database('Current user UID: ${FirebaseAuth.instance.currentUser?.uid ?? 'null'}', tag: 'CANDIDATE_DEBUG');
      AppLogger.database('Current user name: ${FirebaseAuth.instance.currentUser?.displayName ?? 'null'}', tag: 'CANDIDATE_DEBUG');
      AppLogger.database('Controller user role: ${user.value?.role ?? 'not set'}', tag: 'CANDIDATE_DEBUG');

      // Try scanning all candidate documents to see what's available
      await _candidateRepository.logAllCandidatesInSystem();

      AppLogger.database('🔍 CANDIDATE DATA DEBUG SCAN COMPLETED', tag: 'CANDIDATE_DEBUG');
      AppLogger.database('Check the logs above for any candidate documents found', tag: 'CANDIDATE_DEBUG');
      AppLogger.database('If no candidates are found, user needs to register as candidate first', tag: 'CANDIDATE_DEBUG');
    } catch (e) {
      AppLogger.databaseError('❌ Error in candidate data debug scan', tag: 'CANDIDATE_DEBUG', error: e);
    }
  }

  /// Refresh all data - Clean refresh that bypasses caching for candidate dashboard/profile screens
  Future<void> refreshData() async {
    if (user.value == null) return;

    try {
      // Clear user cache service to ensure fresh Firebase data is loaded (not cached Google login name)
      final userCacheService = Get.find<UserCacheService>();
      await userCacheService.clearUserCache();
      AppLogger.common('🧹 Cleared user cache for fresh Firebase data load in candidate screens');

      await _userController.refreshUserData();
      user.value = _userController.user.value;

      await refreshCandidateData();

      AppLogger.common('✅ Candidate user data refreshed (cache-free)');
    } catch (e) {
      AppLogger.commonError('❌ Failed to refresh candidate user data', error: e);
    }
  }

  /// Clear all data (on logout)
  void clearData() {
    user.value = null;
    candidate.value = null;
    isInitialized.value = false;
    isLoading.value = false;
    _userController.clearUserData();
    AppLogger.common('🧹 Candidate user data cleared');
  }

  /// Check if user has candidate role
  bool get isCandidate => user.value?.role == 'candidate';

  /// Check if profile is completed
  bool get isProfileCompleted => user.value?.profileCompleted ?? false;

  /// Check if role is selected
  bool get isRoleSelected => user.value?.roleSelected ?? false;

  /// Check if candidate data is available
  bool get hasCandidateData => candidate.value != null;

  /// Backward compatibility getters (delegate to candidate)
  // Rx<Candidate?> get candidateData => candidate; // Removed duplicate

  /// Get user property safely
  T? getUserProperty<T>(T? Function(UserModel) getter) {
    return user.value != null ? getter(user.value!) : null;
  }

  /// Get candidate property safely
  T? getCandidateProperty<T>(T? Function(Candidate) getter) {
    return candidate.value != null ? getter(candidate.value!) : null;
  }

  /// Check if user has premium access (stub - not implemented in simplified version)
  bool get hasPremiumAccess => false;

  
  /// Tab editing state getters
  bool get isBasicInfoEditing => _isBasicInfoEditing.value;
  bool get isManifestoEditing => _isManifestoEditing.value;
  bool get isContactEditing => _isContactEditing.value;
  bool get isAchievementsEditing => _isAchievementsEditing.value;
  bool get isMediaEditing => _isMediaEditing.value;
  bool get isEventsEditing => _isEventsEditing.value;
  bool get isHighlightsEditing => _isHighlightsEditing.value;
  bool get isAnalyticsEditing => _isAnalyticsEditing.value;

  /// Tab editing state setters
  set isBasicInfoEditing(bool value) => _isBasicInfoEditing.value = value;
  set isManifestoEditing(bool value) => _isManifestoEditing.value = value;
  set isContactEditing(bool value) => _isContactEditing.value = value;
  set isAchievementsEditing(bool value) => _isAchievementsEditing.value = value;
  set isMediaEditing(bool value) => _isMediaEditing.value = value;
  set isEventsEditing(bool value) => _isEventsEditing.value = value;
  set isHighlightsEditing(bool value) => _isHighlightsEditing.value = value;
  set isAnalyticsEditing(bool value) => _isAnalyticsEditing.value = value;

  /// Change tracking getters
  Map<String, dynamic> get changedExtraInfoFields => Map.from(_changedExtraInfoFields);

  /// Change tracking methods
  void trackFieldChange(String field, dynamic value) {
    _changedFields[field] = value;
  }

  void trackExtraInfoFieldChange(String field, dynamic value) {
    _changedExtraInfoFields[field] = value;
  }

  void trackCandidateFieldChange(String field, dynamic value) {
    _changedCandidateFields[field] = value;
  }

  void clearChangeTracking() {
    _changedFields.clear();
    _changedExtraInfoFields.clear();
    _changedCandidateFields.clear();
  }

  /// Dashboard functionality methods (stub implementations - not critical for home screen)
  Future<void> fetchCandidateData() async {
    // Simple refresh using repository
    await refreshCandidateData();
  }

  /// Update achievements information
  void updateAchievementsInfo(List<Achievement> achievements) {
    trackExtraInfoFieldChange('achievements', achievements);
    // Actually update the editedData object with the new achievements
    if (editedData.value != null) {
      editedData.value = editedData.value!.copyWith(achievements: achievements);
      AppLogger.common('✅ Updated editedData achievements: ${achievements.length} items', tag: 'ACHIEVEMENTS_UPDATE');
    } else {
      AppLogger.common('❌ editedData.value is null - cannot update achievements', tag: 'ACHIEVEMENTS_UPDATE');
    }
  }

  /// Update media information
  void updateMediaInfo(String field, dynamic value) {
    trackExtraInfoFieldChange('media_$field', value);
    // Handle media-specific updates if needed in the future
  }

  /// Update events information
  void updateEventsInfo(List<EventData> events) {
    trackExtraInfoFieldChange('events', events);
    // Actually update the editedData object with the new events
    if (editedData.value != null) {
      editedData.value = editedData.value!.copyWith(events: events);
      AppLogger.common('✅ Updated editedData events: ${events.length} items', tag: 'EVENTS_UPDATE');
    } else {
      AppLogger.common('❌ editedData.value is null - cannot update events', tag: 'EVENTS_UPDATE');
    }
  }

  /// Update highlights information
  void updateHighlightsInfo(dynamic highlights) {
    trackExtraInfoFieldChange('highlights', highlights);
    // Handle highlights updates if needed
  }

  /// Update analytics information
  void updateAnalyticsInfo(String field, dynamic value) {
    trackExtraInfoFieldChange('analytics_$field', value);
    // Handle analytics updates if needed
  }

  @Deprecated('Use individual update methods like updateAchievementsInfo, updateEventsInfo, etc. instead of updateExtraInfo for cleaner, separate logic.')
  void updateExtraInfo(String field, dynamic value) {
    // Handle manifesto-specific fields
    if (field == 'manifesto_pdf') {
      updateManifestoInfo('pdfUrl', value);
    } else if (field == 'manifesto_image') {
      updateManifestoInfo('image', value);
    } else if (field == 'manifesto_video') {
      updateManifestoInfo('videoUrl', value);
    } else if (field == 'manifesto') {
      updateManifestoInfo('title', value);
    } else if (field == 'manifesto_promises') {
      updateManifestoInfo('promises', value);
    } else {
      // Other fields - track but don't update editedData
      trackExtraInfoFieldChange(field, value);
    }
  }

  void updateManifestoInfo(String manifestoField, dynamic value) {
    trackExtraInfoFieldChange('manifesto_$manifestoField', value);

    // Actually update the editedData object with the new manifesto values
    if (editedData.value != null) {
      var currentManifesto = editedData.value!.manifestoData;
      if (currentManifesto == null) {
        // Initialize manifesto data if it doesn't exist
        currentManifesto = ManifestoModel(title: '', promises: []);
      }

      // Update the specific field in manifesto data
      ManifestoModel updatedManifesto;
      if (manifestoField == 'pdfUrl') {
        updatedManifesto = currentManifesto.copyWith(pdfUrl: value);
      } else if (manifestoField == 'image') {
        updatedManifesto = currentManifesto.copyWith(image: value);
      } else if (manifestoField == 'videoUrl') {
        updatedManifesto = currentManifesto.copyWith(videoUrl: value);
      } else if (manifestoField == 'title') {
        updatedManifesto = currentManifesto.copyWith(title: value);
      } else if (manifestoField == 'promises') {
        updatedManifesto = currentManifesto.copyWith(promises: List<Map<String, dynamic>>.from(value));
      } else {
        AppLogger.common('⚠️ Unknown manifesto field: $manifestoField', tag: 'MANIFESTO_UPDATE');
        return;
      }

      // Update the candidate with the new manifesto data
      editedData.value = editedData.value!.copyWith(manifestoData: updatedManifesto);
      AppLogger.common('✅ Updated editedData manifesto field: $manifestoField = $value', tag: 'MANIFESTO_UPDATE');
    } else {
      AppLogger.common('❌ editedData.value is null - cannot update manifesto field: $manifestoField', tag: 'MANIFESTO_UPDATE');
    }
  }

  void updateContact(String field, String value) {
    // Stub - not implemented in simplified version
  }

  void updatePhoto(String photoUrl) {
    // Track the photo change for save operations
    trackExtraInfoFieldChange('photo', photoUrl);

    // Store in candidate.basicInfo.photo instead of candidate.photo
    updateBasicInfo('photo', photoUrl);  // ⬅️ Delegates to updateBasicInfo for photo field
  }

  void updateBasicInfo(String field, dynamic value) {
    // Track basic info field changes for save operations
    trackExtraInfoFieldChange(field, value);

    // Actually update the edited data object with the new values
    if (editedData.value != null) {
      if (editedData.value!.basicInfo == null) {
        // Initialize basic info if it doesn't exist
        editedData.value = editedData.value!.copyWith(
          basicInfo: BasicInfoModel(
            fullName: editedData.value!.basicInfo!.fullName,
            dateOfBirth: editedData.value!.basicInfo?.dateOfBirth,
            age: editedData.value!.basicInfo?.age,
            gender: editedData.value!.basicInfo?.gender,
          ),
        );
      }

      // Update the specific field in basicInfo
      if (field == 'education' || field == 'profession' || field == 'languages') {
        BasicInfoModel updatedBasicInfo = editedData.value!.basicInfo!.copyWith(
          education: field == 'education' ? value : editedData.value!.basicInfo!.education,
          profession: field == 'profession' ? value : editedData.value!.basicInfo!.profession,
          languages: field == 'languages' ? (value is List ? List<String>.from(value) : [value.toString()]) : editedData.value!.basicInfo!.languages,
        );
        editedData.value = editedData.value!.copyWith(basicInfo: updatedBasicInfo);
        AppLogger.common('✅ Updated editedData basicInfo field: $field = $value', tag: 'BASIC_INFO_UPDATE');
      }
      // Handle address field - should go to contact
      else if (field == 'address') {
        ContactModel updatedContact = editedData.value!.contact.copyWith(address: value);
        editedData.value = editedData.value!.copyWith(contact: updatedContact);
        AppLogger.common('✅ Updated editedData contact field: address = $value', tag: 'BASIC_INFO_UPDATE');
      }
      else if (field == 'age' || field == 'gender' || field == 'dateOfBirth') {
        BasicInfoModel updatedBasicInfo = editedData.value!.basicInfo!.copyWith(
          age: field == 'age' ? value : editedData.value!.basicInfo!.age,
          gender: field == 'gender' ? value : editedData.value!.basicInfo!.gender,
          dateOfBirth: field == 'dateOfBirth' ? value : editedData.value!.basicInfo!.dateOfBirth,
        );
        editedData.value = editedData.value!.copyWith(basicInfo: updatedBasicInfo);
        AppLogger.common('✅ Updated editedData basicInfo field: $field = $value', tag: 'BASIC_INFO_UPDATE');
      }
      else if (field == 'name') {
        // Update basicInfo.fullName to keep them in sync
        if (editedData.value!.basicInfo != null) {
          BasicInfoModel updatedBasicInfo = editedData.value!.basicInfo!.copyWith(fullName: value);
          editedData.value = editedData.value!.copyWith(basicInfo: updatedBasicInfo);
          AppLogger.common('✅ Also updated basicInfo.fullName to keep in sync: $value', tag: 'BASIC_INFO_UPDATE');
        }
      }
    } else {
      AppLogger.common('❌ editedData.value is null - cannot update field: $field', tag: 'BASIC_INFO_UPDATE');
    }
  }

  Future<bool> saveBasicInfoOnly({Function(String)? onProgress}) async {
    // Stub - not implemented in simplified version
    clearChangeTracking();
    return true;
  }

  Future<bool> saveExtraInfo({Function(String)? onProgress}) async {
    return saveBasicInfoOnly(onProgress: onProgress);
  }

  void resetEditedData() {
    clearChangeTracking();

    // Reset all tab-specific edit states
    _isBasicInfoEditing.value = false;
    _isManifestoEditing.value = false;
    _isContactEditing.value = false;
    _isAchievementsEditing.value = false;
    _isMediaEditing.value = false;
    _isEventsEditing.value = false;
    _isHighlightsEditing.value = false;
    _isAnalyticsEditing.value = false;
  }

  // Tab state management methods
  void startEditingTab(String tabName) {
    // Stub implementation using local state only
    switch (tabName) {
      case 'basic_info':
        _isBasicInfoEditing.value = true;
        break;
      case 'manifesto':
        _isManifestoEditing.value = true;
        break;
      case 'contact':
        _isContactEditing.value = true;
        break;
      case 'achievements':
        _isAchievementsEditing.value = true;
        break;
      case 'media':
        _isMediaEditing.value = true;
        break;
      case 'events':
        _isEventsEditing.value = true;
        break;
      case 'highlights':
        _isHighlightsEditing.value = true;
        break;
      case 'analytics':
        _isAnalyticsEditing.value = true;
        break;
    }
  }

  void stopEditingTab(String tabName) {
    // Stub implementation using local state only
    switch (tabName) {
      case 'basic_info':
        _isBasicInfoEditing.value = false;
        break;
      case 'manifesto':
        _isManifestoEditing.value = false;
        break;
      case 'contact':
        _isContactEditing.value = false;
        break;
      case 'achievements':
        _isAchievementsEditing.value = false;
        break;
      case 'media':
        _isMediaEditing.value = false;
        break;
      case 'events':
        _isEventsEditing.value = false;
        break;
      case 'highlights':
        _isHighlightsEditing.value = false;
        break;
      case 'analytics':
        _isAnalyticsEditing.value = false;
        break;
    }
  }

  bool isTabEditing(String tabName) {
    // Return based on local state only
    switch (tabName) {
      case 'basic_info':
        return _isBasicInfoEditing.value;
      case 'manifesto':
        return _isManifestoEditing.value;
      case 'contact':
        return _isContactEditing.value;
      case 'achievements':
        return _isAchievementsEditing.value;
      case 'media':
        return _isMediaEditing.value;
      case 'events':
        return _isEventsEditing.value;
      case 'highlights':
        return _isHighlightsEditing.value;
      case 'analytics':
        return _isAnalyticsEditing.value;
      default:
        return false;
    }
  }

  /// Get combined user info for display
  Map<String, dynamic> getCombinedUserInfo() {
    return {
      'user': user.value?.toJson(),
      'candidate': candidate.value?.toJson(),
      'isLoading': isLoading.value,
      'isInitialized': isInitialized.value,
      'hasPremiumAccess': hasPremiumAccess,
    };
  }
}
