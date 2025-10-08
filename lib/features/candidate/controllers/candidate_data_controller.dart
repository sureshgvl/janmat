import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/candidate_model.dart';
import '../models/candidate_achievement_model.dart';
import '../repositories/candidate_repository.dart';
import '../repositories/candidate_event_repository.dart';
import '../../../services/trial_service.dart';
import '../../../services/file_upload_service.dart';
import '../../../services/notifications/constituency_notifications.dart';
import '../../../services/notifications/campaign_milestones_notifications.dart';
import '../../../utils/symbol_utils.dart';
import '../../../utils/app_logger.dart';
import '../../chat/controllers/chat_controller.dart';

class CandidateDataController extends GetxController {
  final CandidateRepository _candidateRepository = CandidateRepository();
  final EventRepository _eventRepository = EventRepository();
  final TrialService _trialService = TrialService();

  var candidateData = Rx<Candidate?>(null);
  var editedData = Rx<Candidate?>(null);
  var isLoading = false.obs;
  var isPaid = false.obs;

  // Events management
  var events = RxList<EventData>([]);
  var isEventsLoading = false.obs;
  var eventsLastFetched = Rx<DateTime?>(null);

  // Change tracking for field-level updates
  final Map<String, dynamic> _changedFields = {};
  final Map<String, dynamic> _changedExtraInfoFields = {};

  @override
  void onInit() {
    super.onInit();
    fetchCandidateData();
  }

  @override
  void onReady() {
    super.onReady();
    // Refresh data when coming back to the dashboard
    ever(candidateData, (_) {
      // This will trigger when candidateData changes
      AppLogger.database('Candidate data updated, refreshing UI', tag: 'CANDIDATE_CONTROLLER');
    });
  }

  Future<void> fetchCandidateData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    isLoading.value = true;
    try {
      // First check if user has completed their profile
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        AppLogger.database('User document not found, skipping candidate data fetch', tag: 'CANDIDATE_CONTROLLER');
        return;
      }

      final userData = userDoc.data()!;
      final profileCompleted = userData['profileCompleted'] ?? false;
      final userRole = userData['role'] ?? 'voter';

      // Only fetch candidate data for candidates, not voters
      if (userRole != 'candidate') {
        AppLogger.database('User is not a candidate (role: $userRole), skipping candidate data fetch', tag: 'CANDIDATE_CONTROLLER');
        return;
      }

      if (!profileCompleted) {
        AppLogger.database('Profile not completed, skipping candidate data fetch', tag: 'CANDIDATE_CONTROLLER');
        return;
      }

      final data = await _candidateRepository.getCandidateData(user.uid);
      if (data != null) {
        candidateData.value = data;
        editedData.value = data;

        // Check if user has premium access (sponsored OR in trial)
        final isSponsored = data.sponsored;
        final isInTrial = await _trialService.isTrialActive(user.uid);
        isPaid.value = isSponsored || isInTrial;

        AppLogger.database('Candidate access check:', tag: 'CANDIDATE_CONTROLLER');
        AppLogger.database('  Sponsored: $isSponsored', tag: 'CANDIDATE_CONTROLLER');
        AppLogger.database('  In Trial: $isInTrial', tag: 'CANDIDATE_CONTROLLER');
        AppLogger.database('  Has Access: ${isPaid.value}', tag: 'CANDIDATE_CONTROLLER');
      }
    } catch (e) {
      AppLogger.databaseError('Error fetching candidate data', tag: 'CANDIDATE_CONTROLLER', error: e);
    } finally {
      isLoading.value = false;
    }
  }

  // Track field changes for optimized updates
  void trackFieldChange(String field, dynamic value) {
    _changedFields[field] = value;
  }

  void trackExtraInfoFieldChange(String field, dynamic value) {
    _changedExtraInfoFields[field] = value;
  }

  // Clear change tracking
  void clearChangeTracking() {
    _changedFields.clear();
    _changedExtraInfoFields.clear();
  }

  void updateExtraInfo(String field, dynamic value) {
    if (editedData.value == null) return;

    final currentExtra = editedData.value!.extraInfo ?? ExtraInfo();

    // Update the edited data (for UI updates)
    ExtraInfo updatedExtra;

    // Handle different field types
    switch (field) {
      case 'bio':
        // Track the change for field-level updates
        trackExtraInfoFieldChange(field, value);
        updatedExtra = currentExtra.copyWith(bio: value);
        break;
      case 'achievements':
        // Convert Achievement objects to JSON for Firestore compatibility
        final achievementsJson = (value as List<Achievement>?)
            ?.map((a) => a.toJson())
            .toList();
        // Track the JSON version for field-level updates
        trackExtraInfoFieldChange(field, achievementsJson);
        updatedExtra = currentExtra.copyWith(achievements: value);
        break;
      case 'manifesto':
        updatedExtra = currentExtra.copyWith(manifesto: value);
        break;
      case 'manifesto_promises':
        // Store the structured promises directly (no conversion needed)
        final promisesList = value as List<Map<String, dynamic>>;

        // Update the manifesto with the structured promises
        final currentManifesto = currentExtra.manifesto ?? ManifestoData();
        final updatedManifesto = ManifestoData(
          title: currentManifesto.title,
          promises: promisesList,
          pdfUrl: currentManifesto.pdfUrl,
          image: currentManifesto.image,
          videoUrl: currentManifesto.videoUrl,
        );
        trackExtraInfoFieldChange('manifesto', updatedManifesto.toJson());
        updatedExtra = currentExtra.copyWith(manifesto: updatedManifesto);
        break;
      case 'manifesto_title':
        final currentManifesto = currentExtra.manifesto ?? ManifestoData();
        final updatedManifesto = ManifestoData(
          title: value,
          promises: currentManifesto.promises,
          pdfUrl: currentManifesto.pdfUrl,
          image: currentManifesto.image,
          videoUrl: currentManifesto.videoUrl,
        );
        trackExtraInfoFieldChange('manifesto', updatedManifesto.toJson());
        updatedExtra = currentExtra.copyWith(manifesto: updatedManifesto);
        break;
      case 'manifesto_pdf':
        final currentManifesto = currentExtra.manifesto ?? ManifestoData();
        final updatedManifesto = ManifestoData(
          title: currentManifesto.title,
          promises: currentManifesto.promises,
          pdfUrl: value,
          image: currentManifesto.image,
          videoUrl: currentManifesto.videoUrl,
        );
        trackExtraInfoFieldChange('manifesto', updatedManifesto.toJson());
        updatedExtra = currentExtra.copyWith(manifesto: updatedManifesto);
        break;
      case 'manifesto_image':
        final currentManifesto = currentExtra.manifesto ?? ManifestoData();
        final updatedManifesto = ManifestoData(
          title: currentManifesto.title,
          promises: currentManifesto.promises,
          pdfUrl: currentManifesto.pdfUrl,
          image: value,
          videoUrl: currentManifesto.videoUrl,
        );
        trackExtraInfoFieldChange('manifesto', updatedManifesto.toJson());
        updatedExtra = currentExtra.copyWith(manifesto: updatedManifesto);
        break;
      case 'manifesto_video':
        final currentManifesto = currentExtra.manifesto ?? ManifestoData();
        final updatedManifesto = ManifestoData(
          title: currentManifesto.title,
          promises: currentManifesto.promises,
          pdfUrl: currentManifesto.pdfUrl,
          image: currentManifesto.image,
          videoUrl: value,
        );
        trackExtraInfoFieldChange('manifesto', updatedManifesto.toJson());
        updatedExtra = currentExtra.copyWith(manifesto: updatedManifesto);
        break;
      case 'contact':
        updatedExtra = currentExtra.copyWith(contact: value);
        break;
      case 'media':
        // Track the change for field-level updates
        trackExtraInfoFieldChange(field, value);
        updatedExtra = currentExtra.copyWith(media: value);
        break;
      case 'events':
        updatedExtra = currentExtra.copyWith(events: value);
        break;
      case 'highlight':
        // Handle both Map and HighlightData inputs
        HighlightData? highlightData;
        if (value is Map<String, dynamic>) {
          // Check if this is HighlightConfig data (has bannerStyle) or HighlightData (has title/message)
          if (value.containsKey('bannerStyle') || value.containsKey('callToAction')) {
            // This is HighlightConfig data - map all fields to HighlightData
            final currentHighlight = currentExtra.highlight;
            highlightData = HighlightData(
              enabled: value['enabled'] ?? currentHighlight?.enabled ?? false,
              title: value['callToAction'] ?? currentHighlight?.title ?? 'View Profile',
              message: value['customMessage'] ?? currentHighlight?.message ?? '',
              imageUrl: currentHighlight?.imageUrl, // Keep existing image
              priority: value['priorityLevel'] ?? currentHighlight?.priority ?? 'normal',
              expiresAt: currentHighlight?.expiresAt,
              // Banner config fields
              bannerStyle: value['bannerStyle'] ?? currentHighlight?.bannerStyle ?? 'premium',
              callToAction: value['callToAction'] ?? currentHighlight?.callToAction ?? 'View Profile',
              priorityLevel: value['priorityLevel'] ?? currentHighlight?.priorityLevel ?? 'normal',
              targetLocations: value['targetLocations'] != null
                  ? List<String>.from(value['targetLocations'])
                  : currentHighlight?.targetLocations ?? [],
              showAnalytics: value['showAnalytics'] ?? currentHighlight?.showAnalytics ?? false,
              customMessage: value['customMessage'] ?? currentHighlight?.customMessage ?? '',
            );
            // Track the full config for field-level updates
            trackExtraInfoFieldChange(field, highlightData.toJson());

            // If this is banner config data and enabled, sync with highlights collection
            if (highlightData.enabled && value.containsKey('bannerStyle')) {
              _syncBannerToHighlightsCollection(highlightData, value);
            }
          } else {
            // This is regular HighlightData
            final currentHighlight = currentExtra.highlight;
            highlightData = HighlightData(
              enabled: value['enabled'] ?? currentHighlight?.enabled ?? false,
              title: value['title'] ?? currentHighlight?.title,
              message: value['message'] ?? currentHighlight?.message,
              imageUrl: value['image_url'] ?? currentHighlight?.imageUrl,
              priority: value['priority'] ?? currentHighlight?.priority,
              expiresAt: value['expires_at'] ?? currentHighlight?.expiresAt,
              // Keep existing banner config if present
              bannerStyle: currentHighlight?.bannerStyle,
              callToAction: currentHighlight?.callToAction,
              priorityLevel: currentHighlight?.priorityLevel,
              targetLocations: currentHighlight?.targetLocations,
              showAnalytics: currentHighlight?.showAnalytics,
              customMessage: currentHighlight?.customMessage,
            );
            // Track the JSON version for field-level updates
            trackExtraInfoFieldChange(field, highlightData.toJson());
          }
        } else if (value is HighlightData?) {
          highlightData = value;
          // Track the JSON version for field-level updates
          trackExtraInfoFieldChange(field, highlightData?.toJson());
        }
        updatedExtra = currentExtra.copyWith(highlight: highlightData);
        break;
      case 'analytics':
        updatedExtra = currentExtra.copyWith(analytics: value);
        break;
      case 'basic_info':
        updatedExtra = currentExtra.copyWith(basicInfo: value);
        break;
      // Handle individual basic info fields
      case 'age':
      case 'gender':
      case 'education':
      case 'address':
      case 'dateOfBirth':
        final currentBasicInfo = currentExtra.basicInfo ?? BasicInfoData();
        BasicInfoData updatedBasicInfo;

        switch (field) {
          case 'age':
            updatedBasicInfo = BasicInfoData(
              fullName: currentBasicInfo.fullName,
              dateOfBirth: currentBasicInfo.dateOfBirth,
              age: value,
              gender: currentBasicInfo.gender,
              education: currentBasicInfo.education,
              profession: currentBasicInfo.profession,
              languages: currentBasicInfo.languages,
              experienceYears: currentBasicInfo.experienceYears,
              previousPositions: currentBasicInfo.previousPositions,
            );
            break;
          case 'gender':
            updatedBasicInfo = BasicInfoData(
              fullName: currentBasicInfo.fullName,
              dateOfBirth: currentBasicInfo.dateOfBirth,
              age: currentBasicInfo.age,
              gender: value,
              education: currentBasicInfo.education,
              profession: currentBasicInfo.profession,
              languages: currentBasicInfo.languages,
              experienceYears: currentBasicInfo.experienceYears,
              previousPositions: currentBasicInfo.previousPositions,
            );
            break;
          case 'education':
            updatedBasicInfo = BasicInfoData(
              fullName: currentBasicInfo.fullName,
              dateOfBirth: currentBasicInfo.dateOfBirth,
              age: currentBasicInfo.age,
              gender: currentBasicInfo.gender,
              education: value,
              profession: currentBasicInfo.profession,
              languages: currentBasicInfo.languages,
              experienceYears: currentBasicInfo.experienceYears,
              previousPositions: currentBasicInfo.previousPositions,
            );
            break;
          case 'profession':
            updatedBasicInfo = BasicInfoData(
              fullName: currentBasicInfo.fullName,
              dateOfBirth: currentBasicInfo.dateOfBirth,
              age: currentBasicInfo.age,
              gender: currentBasicInfo.gender,
              education: currentBasicInfo.education,
              profession: value,
              languages: currentBasicInfo.languages,
              experienceYears: currentBasicInfo.experienceYears,
              previousPositions: currentBasicInfo.previousPositions,
            );
            break;
          case 'languages':
            updatedBasicInfo = BasicInfoData(
              fullName: currentBasicInfo.fullName,
              dateOfBirth: currentBasicInfo.dateOfBirth,
              age: currentBasicInfo.age,
              gender: currentBasicInfo.gender,
              education: currentBasicInfo.education,
              profession: currentBasicInfo.profession,
              languages: value is List ? List<String>.from(value) : [value.toString()],
              experienceYears: currentBasicInfo.experienceYears,
              previousPositions: currentBasicInfo.previousPositions,
            );
            break;
          case 'experienceYears':
            updatedBasicInfo = BasicInfoData(
              fullName: currentBasicInfo.fullName,
              dateOfBirth: currentBasicInfo.dateOfBirth,
              age: currentBasicInfo.age,
              gender: currentBasicInfo.gender,
              education: currentBasicInfo.education,
              profession: currentBasicInfo.profession,
              languages: currentBasicInfo.languages,
              experienceYears: value is int ? value : int.tryParse(value.toString()) ?? 0,
              previousPositions: currentBasicInfo.previousPositions,
            );
            break;
          case 'previousPositions':
            updatedBasicInfo = BasicInfoData(
              fullName: currentBasicInfo.fullName,
              dateOfBirth: currentBasicInfo.dateOfBirth,
              age: currentBasicInfo.age,
              gender: currentBasicInfo.gender,
              education: currentBasicInfo.education,
              profession: currentBasicInfo.profession,
              languages: currentBasicInfo.languages,
              experienceYears: currentBasicInfo.experienceYears,
              previousPositions: value is List ? List<String>.from(value) : [value.toString()],
            );
            break;
          case 'address':
            // Address is stored in contact, not basicInfo
            final currentContact = currentExtra.contact ?? ExtendedContact();
            final updatedContact = ExtendedContact(
              phone: currentContact.phone,
              email: currentContact.email,
              address: value,
              socialLinks: currentContact.socialLinks,
              officeAddress: currentContact.officeAddress,
              officeHours: currentContact.officeHours,
            );
            updatedExtra = currentExtra.copyWith(contact: updatedContact);
            editedData.value = editedData.value!.copyWith(
              extraInfo: updatedExtra,
            );
            return;
          case 'date_of_birth':
                updatedBasicInfo = BasicInfoData(
                  fullName: currentBasicInfo.fullName,
                  dateOfBirth: value,
                  age: currentBasicInfo.age,
                  gender: currentBasicInfo.gender,
                  education: currentBasicInfo.education,
                  profession: currentBasicInfo.profession,
                  languages: currentBasicInfo.languages,
                  experienceYears: currentBasicInfo.experienceYears,
                  previousPositions: currentBasicInfo.previousPositions,
                );
                break;
          default:
            updatedBasicInfo = currentBasicInfo;
        }

        updatedExtra = currentExtra.copyWith(basicInfo: updatedBasicInfo);
        break;
      default:
        updatedExtra = currentExtra;
    }

    editedData.value = editedData.value!.copyWith(extraInfo: updatedExtra);
  }

  void updateContact(String field, String value) {
    if (editedData.value == null) return;

    final currentContact = editedData.value!.extraInfo?.contact;
    ExtendedContact updatedContact;

    if (currentContact is ExtendedContact) {
      updatedContact = ExtendedContact(
        phone: field == 'phone' ? value : currentContact.phone,
        email: field == 'email' ? value : currentContact.email,
        address: field == 'address' ? value : currentContact.address,
        socialLinks: field.startsWith('social_')
            ? {...?currentContact.socialLinks, field.substring(7): value}
            : currentContact.socialLinks,
        officeAddress: field == 'officeAddress' ? value : currentContact.officeAddress,
        officeHours: field == 'officeHours' ? value : currentContact.officeHours,
      );
    } else {
      // Fallback to basic Contact if not ExtendedContact
      final basicContact = currentContact as Contact? ?? Contact(phone: '', email: null, socialLinks: null);
      updatedContact = ExtendedContact(
        phone: field == 'phone' ? value : basicContact.phone,
        email: field == 'email' ? value : basicContact.email,
        socialLinks: field.startsWith('social_')
            ? {...?basicContact.socialLinks, field.substring(7): value}
            : basicContact.socialLinks,
        officeAddress: field == 'officeAddress' ? value : null,
        officeHours: field == 'officeHours' ? value : null,
      );
    }

    updateExtraInfo('contact', updatedContact);
  }

  void updatePhoto(String photoUrl) async {
    if (editedData.value == null) return;

    // Update both editedData and candidateData immediately
    editedData.value = editedData.value!.copyWith(photo: photoUrl);
    candidateData.value = candidateData.value?.copyWith(photo: photoUrl);

    // Save immediately to Firebase
    try {
      final success = await _candidateRepository.updateCandidateExtraInfo(
        editedData.value!,
      );
      if (!success) {
        AppLogger.database('Warning: Failed to save photo URL to Firebase', tag: 'CANDIDATE_CONTROLLER');
      }
    } catch (e) {
      AppLogger.databaseError('Error saving photo URL', tag: 'CANDIDATE_CONTROLLER', error: e);
    }
  }

  void updateBasicInfo(String field, dynamic value) {
    if (editedData.value == null) return;

    AppLogger.database('updateBasicInfo called: field=$field, value=$value', tag: 'CANDIDATE_CONTROLLER');

    switch (field) {
      case 'name':
        editedData.value = editedData.value!.copyWith(name: value);
        break;
      case 'party':
        editedData.value = editedData.value!.copyWith(party: value);
        // Clear symbol cache when party changes to ensure fresh data
        SymbolUtils.clearCache();
        break;
      case 'districtId':
        editedData.value = editedData.value!.copyWith(districtId: value);
        break;
      case 'bodyId':
        editedData.value = editedData.value!.copyWith(bodyId: value);
        break;
      case 'wardId':
        editedData.value = editedData.value!.copyWith(wardId: value);
        break;
      case 'symbolName':
        editedData.value = editedData.value!.copyWith(symbolName: value);
        break;
      case 'age':
      case 'gender':
      case 'education':
      case 'profession':
      case 'languages':
      case 'experienceYears':
      case 'previousPositions':
      case 'address':
      case 'date_of_birth':
        // Track the change for field-level updates
        AppLogger.database('Tracking field change: $field = $value', tag: 'CANDIDATE_CONTROLLER');
        trackExtraInfoFieldChange(field, value);
        updateExtraInfo(field, value);
        break;
    }
  }

  Future<bool> saveExtraInfo({Function(String)? onProgress}) async {
    if (editedData.value == null) return false;

    try {
      bool success = false;

      AppLogger.database('saveExtraInfo - Changed fields: $_changedExtraInfoFields', tag: 'CANDIDATE_CONTROLLER');

      // First, upload any local photos to Firebase
      onProgress?.call('Uploading photos to cloud...');
      await _uploadLocalPhotosToFirebase();

      // Update user document for basic info fields (name, photo)
      final userDocumentUpdated = await _updateUserDocumentForBasicInfo(onProgress);

      // Use field-level updates for better performance
      if (_changedExtraInfoFields.isNotEmpty) {
        AppLogger.database('Using field-level updates', tag: 'CANDIDATE_CONTROLLER');
        onProgress?.call('Saving data...');
        success = await _candidateRepository.updateCandidateExtraInfoFields(
          editedData.value!.candidateId,
          _changedExtraInfoFields,
        );
      }

      // Fallback to full update if no field-level changes tracked
      if (!success && _changedExtraInfoFields.isEmpty) {
        AppLogger.database('Using full update', tag: 'CANDIDATE_CONTROLLER');
        onProgress?.call('Saving data...');
        success = await _candidateRepository.updateCandidateExtraInfo(
          editedData.value!,
        );
      }

      if (success) {
        AppLogger.database('Save successful, updating candidateData', tag: 'CANDIDATE_CONTROLLER');
        onProgress?.call('Basic info saved successfully!');
        candidateData.value = editedData.value;
        clearChangeTracking(); // Clear tracking after successful save

        // Send constituency notification for profile updates
        await _sendProfileUpdateNotification();

        // Send manifesto update notification if manifesto was changed
        await _sendManifestoUpdateNotification();

        // Check for campaign milestones
        await _checkCampaignMilestones();

        // Refresh highlight banner if basic info (name/photo) was updated
        if (userDocumentUpdated) {
          _refreshHighlightBanner();
        }
      }

      return success;
    } catch (e) {
      AppLogger.databaseError('Error saving extra info', tag: 'CANDIDATE_CONTROLLER', error: e);
      return false;
    }
  }

  // Update user document for basic info fields (name, photo)
  Future<bool> _updateUserDocumentForBasicInfo(Function(String)? onProgress) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || editedData.value == null) return false;

      final candidate = editedData.value!;
      Map<String, dynamic> userUpdates = {};

      // Check if name was changed
      if (candidate.name != candidateData.value?.name) {
        userUpdates['name'] = candidate.name;
        AppLogger.database('Updating user name: ${candidate.name}', tag: 'CANDIDATE_CONTROLLER');
      }

      // Check if photo was changed
      if (candidate.photo != candidateData.value?.photo) {
        userUpdates['photo'] = candidate.photo;
        AppLogger.database('Updating user photo: ${candidate.photo}', tag: 'CANDIDATE_CONTROLLER');
      }

      // Update user document if there are changes
      if (userUpdates.isNotEmpty) {
        onProgress?.call('Updating user profile...');
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update(userUpdates);

        AppLogger.database('User document updated with: ${userUpdates.keys.join(', ')}', tag: 'CANDIDATE_CONTROLLER');

        // Invalidate cached user data in ChatController and other controllers
        try {
          final chatController = Get.find<ChatController>();
          chatController.invalidateUserCache(user.uid);
          AppLogger.database('Invalidated user cache after profile update', tag: 'CANDIDATE_CONTROLLER');
        } catch (e) {
          AppLogger.database('Could not invalidate chat controller cache: $e', tag: 'CANDIDATE_CONTROLLER');
        }

        return true; // Indicate that user document was updated
      }
      return false; // No updates made
    } catch (e) {
      AppLogger.databaseError('Error updating user document', tag: 'CANDIDATE_CONTROLLER', error: e);
      // Don't throw - allow candidate data to still be saved
      return false;
    }
  }

  // Upload local photos to Firebase before saving
  Future<void> _uploadLocalPhotosToFirebase() async {
    try {
      final achievements = editedData.value?.extraInfo?.achievements;
      if (achievements == null) return;

      final fileUploadService = _getFileUploadService();

      for (int i = 0; i < achievements.length; i++) {
        final achievement = achievements[i];
        if (achievement.photoUrl != null &&
            fileUploadService.isLocalPath(achievement.photoUrl!)) {
          AppLogger.database(
            'Uploading local photo for achievement: ${achievement.title}',
            tag: 'CANDIDATE_CONTROLLER',
          );

          try {
            final firebaseUrl = await fileUploadService
                .uploadLocalPhotoToFirebase(achievement.photoUrl!);

            if (firebaseUrl != null) {
              // Update the achievement with the Firebase URL
              achievements[i] = achievement.copyWith(photoUrl: firebaseUrl);

              // Also update the changed fields if this achievement was modified
              if (_changedExtraInfoFields.containsKey('achievements')) {
                final achievementsJson =
                    _changedExtraInfoFields['achievements'] as List<dynamic>;
                if (i < achievementsJson.length &&
                    achievementsJson[i] is Map<String, dynamic>) {
                  (achievementsJson[i] as Map<String, dynamic>)['photoUrl'] =
                      firebaseUrl;
                }
              }

              AppLogger.database(
                'Successfully uploaded photo for: ${achievement.title}',
                tag: 'CANDIDATE_CONTROLLER',
              );
            }
          } catch (e) {
            AppLogger.databaseError('Failed to upload photo for ${achievement.title}', tag: 'CANDIDATE_CONTROLLER', error: e);
            // Continue with other photos even if one fails
          }
        }
      }

      // Update the edited data with the new Firebase URLs
      if (editedData.value?.extraInfo != null) {
        editedData.value = editedData.value!.copyWith(
          extraInfo: editedData.value!.extraInfo!.copyWith(
            achievements: achievements,
          ),
        );
      }
    } catch (e) {
      AppLogger.databaseError('Error uploading local photos', tag: 'CANDIDATE_CONTROLLER', error: e);
    }
  }

  // Get file upload service instance
  FileUploadService _getFileUploadService() {
    return FileUploadService();
  }

  void resetEditedData() {
    editedData.value = candidateData.value;
    clearChangeTracking(); // Clear change tracking when resetting
  }

  // Refresh candidate data (useful when navigating back to dashboard)
  Future<void> refreshCandidateData() async {
    await fetchCandidateData();
  }

  /// Refresh premium access status (useful after trial changes)
  Future<void> refreshAccessStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || candidateData.value == null) return;

    try {
      final isSponsored = candidateData.value!.sponsored;
      final isInTrial = await _trialService.isTrialActive(user.uid);
      isPaid.value = isSponsored || isInTrial;

      AppLogger.database('Refreshed access status:', tag: 'CANDIDATE_CONTROLLER');
      AppLogger.database('  Sponsored: $isSponsored', tag: 'CANDIDATE_CONTROLLER');
      AppLogger.database('  In Trial: $isInTrial', tag: 'CANDIDATE_CONTROLLER');
      AppLogger.database('  Has Access: ${isPaid.value}', tag: 'CANDIDATE_CONTROLLER');
    } catch (e) {
      AppLogger.databaseError('Error refreshing access status', tag: 'CANDIDATE_CONTROLLER', error: e);
    }
  }

  // Events Management Methods

  /// Fetch events for the current candidate with caching
  Future<void> fetchEvents({bool forceRefresh = false}) async {
    final candidate = candidateData.value;
    if (candidate == null) {
      AppLogger.database('No candidate data available, clearing events', tag: 'CANDIDATE_CONTROLLER');
      events.clear();
      eventsLastFetched.value = null;
      isEventsLoading.value = false;
      return;
    }

    // Check if we have recent data and don't need to refresh
    if (!forceRefresh &&
        eventsLastFetched.value != null &&
        events.isNotEmpty &&
        DateTime.now().difference(eventsLastFetched.value!) <
            const Duration(minutes: 5)) {
      AppLogger.database('Using cached events data', tag: 'CANDIDATE_CONTROLLER');
      return;
    }

    isEventsLoading.value = true;
    try {
      AppLogger.database('Fetching events for candidate: ${candidate.candidateId}', tag: 'CANDIDATE_CONTROLLER');
      final fetchedEvents = await _eventRepository.getCandidateEvents(
        candidate.candidateId,
      );

      events.assignAll(fetchedEvents);
      eventsLastFetched.value = DateTime.now();

      AppLogger.database('Successfully loaded ${fetchedEvents.length} events', tag: 'CANDIDATE_CONTROLLER');
    } catch (e) {
      AppLogger.databaseError('Error fetching events', tag: 'CANDIDATE_CONTROLLER', error: e);
      // Clear events on error to show empty state
      events.clear();
      eventsLastFetched.value = null;
      // Don't show error snackbar for missing candidate data - this is expected
      if (!e.toString().contains('No candidate found')) {
        Get.snackbar('Error', 'Failed to load events: $e');
      }
    } finally {
      isEventsLoading.value = false;
    }
  }

  /// Refresh events data (force reload from server)
  Future<void> refreshEvents() async {
    await fetchEvents(forceRefresh: true);
  }

  /// Get events data (ensures data is loaded if not already)
  Future<List<EventData>> getEventsData() async {
    if (events.isEmpty && !isEventsLoading.value) {
      await fetchEvents();
    }
    return events.toList();
  }

  /// Clear events cache
  void clearEventsCache() {
    events.clear();
    eventsLastFetched.value = null;
  }

  /// Update events after creation/editing/deletion
  void updateEventsCache(List<EventData> updatedEvents) {
    events.assignAll(updatedEvents);
    eventsLastFetched.value = DateTime.now();
  }

  /// Sync banner configuration to highlights collection for home screen display
  Future<void> _syncBannerToHighlightsCollection(HighlightData highlightData, Map<String, dynamic> config) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || candidateData.value == null) return;

      final candidate = candidateData.value!;
      final districtId = candidate.districtId ?? 'unknown';
      final bodyId = candidate.bodyId ?? 'unknown';
      final wardId = candidate.wardId ?? 'unknown';

      AppLogger.database('Syncing banner to highlights collection for ${candidate.name}', tag: 'CANDIDATE_CONTROLLER');

      // Check if highlight already exists
      final existingHighlights = await FirebaseFirestore.instance
          .collection('highlights')
          .where('candidateId', isEqualTo: user.uid)
          .where('locationKey', isEqualTo: '${districtId}_${bodyId}_$wardId')
          .where('placement', arrayContains: 'top_banner')
          .limit(1)
          .get();

      String? highlightId;

      if (existingHighlights.docs.isNotEmpty) {
        // Update existing highlight
        highlightId = existingHighlights.docs.first.id;
        AppLogger.database('Updating existing highlight: $highlightId', tag: 'CANDIDATE_CONTROLLER');

        await FirebaseFirestore.instance
            .collection('highlights')
            .doc(highlightId)
            .update({
              'bannerStyle': config['bannerStyle'] ?? 'premium',
              'callToAction': config['callToAction'] ?? 'View Profile',
              'priorityLevel': config['priorityLevel'] ?? 'normal',
              'customMessage': config['customMessage'] ?? '',
              'showAnalytics': config['showAnalytics'] ?? false,
              'active': highlightData.enabled,
              'priority': _getPriorityValue(config['priorityLevel'] ?? 'normal'),
              'exclusive': (config['priorityLevel'] ?? 'normal') == 'urgent',
              'rotation': (config['priorityLevel'] ?? 'normal') != 'urgent',
              'updatedAt': FieldValue.serverTimestamp(),
            });
      } else if (highlightData.enabled) {
        // Create new highlight
        highlightId = 'platinum_hl_${DateTime.now().millisecondsSinceEpoch}';
        AppLogger.database('Creating new highlight: $highlightId', tag: 'CANDIDATE_CONTROLLER');

        final highlight = {
          'highlightId': highlightId,
          'candidateId': user.uid,
          'wardId': wardId,
          'districtId': districtId,
          'bodyId': bodyId,
          'locationKey': '${districtId}_${bodyId}_$wardId',
          'package': 'platinum',
          'placement': ['carousel', 'top_banner'],
          'priority': _getPriorityValue(config['priorityLevel'] ?? 'normal'),
          'startDate': FieldValue.serverTimestamp(),
          'endDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 365))),
          'active': true,
          'exclusive': (config['priorityLevel'] ?? 'normal') == 'urgent',
          'rotation': (config['priorityLevel'] ?? 'normal') != 'urgent',
          'views': 0,
          'clicks': 0,
          'imageUrl': candidate.photo,
          'candidateName': candidate.name ?? 'Candidate',
          'party': candidate.party ?? 'Party',
          'createdAt': FieldValue.serverTimestamp(),
          // Banner configuration
          'bannerStyle': config['bannerStyle'] ?? 'premium',
          'callToAction': config['callToAction'] ?? 'View Profile',
          'priorityLevel': config['priorityLevel'] ?? 'normal',
          'customMessage': config['customMessage'] ?? '',
          'showAnalytics': config['showAnalytics'] ?? false,
        };

        await FirebaseFirestore.instance
            .collection('highlights')
            .doc(highlightId)
            .set(highlight);
      }

      if (highlightId != null) {
        AppLogger.database('Banner synced to highlights collection: $highlightId', tag: 'CANDIDATE_CONTROLLER');
        AppLogger.database('  Style: ${config['bannerStyle']}, Priority: ${config['priorityLevel']}', tag: 'CANDIDATE_CONTROLLER');
      }
    } catch (e) {
      AppLogger.databaseError('Error syncing banner to highlights collection', tag: 'CANDIDATE_CONTROLLER', error: e);
    }
  }

  // Helper method to convert priority level to numeric value
  int _getPriorityValue(String priorityLevel) {
    switch (priorityLevel) {
      case 'normal':
        return 5;
      case 'high':
        return 8;
      case 'urgent':
        return 10;
      default:
        return 5;
    }
  }

  /// Refresh highlight banner when candidate profile is updated
  void _refreshHighlightBanner() {
    try {
      AppLogger.database('Triggering highlight banner refresh', tag: 'CANDIDATE_CONTROLLER');

      // Since we can't directly access the banner widget, we'll use a simple approach:
      // The banner will refresh itself on next location change or we can implement
      // a more sophisticated refresh mechanism later

      // For now, we'll just log that a refresh was requested
      // In a future implementation, we could use:
      // 1. A stream that the banner listens to
      // 2. A global key to call refresh directly
      // 3. Provider/Bloc pattern for state management

      AppLogger.database('Highlight banner refresh requested - banner will reload on next location change', tag: 'CANDIDATE_CONTROLLER');
    } catch (e) {
      AppLogger.databaseError('Error refreshing highlight banner', tag: 'CANDIDATE_CONTROLLER', error: e);
    }
  }

  /// Send constituency notification when candidate profile is updated
  Future<void> _sendProfileUpdateNotification() async {
    try {
      if (candidateData.value == null) return;

      final candidate = candidateData.value!;
      AppLogger.database('Checking for profile update notifications...', tag: 'CANDIDATE_CONTROLLER');

      // Determine what type of update occurred
      String updateType = 'profile';
      String updateDescription = 'updated their profile';

      // Check what fields were changed to provide more specific notifications
      if (_changedExtraInfoFields.containsKey('profession')) {
        updateType = 'profession';
        updateDescription = 'updated their profession to ${_changedExtraInfoFields['profession']}';
      } else if (_changedExtraInfoFields.containsKey('bio')) {
        updateType = 'bio';
        updateDescription = 'updated their bio';
      } else if (_changedExtraInfoFields.containsKey('education')) {
        updateType = 'education';
        updateDescription = 'updated their education details';
      } else if (_changedExtraInfoFields.containsKey('manifesto')) {
        updateType = 'manifesto';
        updateDescription = 'updated their manifesto';
      } else if (_changedExtraInfoFields.containsKey('contact')) {
        updateType = 'contact';
        updateDescription = 'updated their contact information';
      } else if (_changedExtraInfoFields.containsKey('achievements')) {
        updateType = 'achievements';
        updateDescription = 'updated their achievements';
      }

      AppLogger.database('Sending notification: $updateType - $updateDescription', tag: 'CANDIDATE_CONTROLLER');

      // Send constituency notification
      final constituencyNotifications = ConstituencyNotifications();
      await constituencyNotifications.sendProfileUpdateNotification(
        candidateId: candidate.candidateId,
        updateType: updateType,
        updateDescription: updateDescription,
      );

      AppLogger.database('Profile update notification sent successfully', tag: 'CANDIDATE_CONTROLLER');
    } catch (e) {
      AppLogger.databaseError('Error sending profile update notification', tag: 'CANDIDATE_CONTROLLER', error: e);
      // Don't throw - profile save should succeed even if notification fails
    }
  }

  /// Check for campaign milestones after profile updates
  Future<void> _checkCampaignMilestones() async {
    try {
      if (candidateData.value == null) return;

      final candidate = candidateData.value!;
      final candidateId = candidate.candidateId ?? candidate.userId ?? '';
      if (candidateId.isEmpty) return;

      final campaignMilestones = CampaignMilestonesNotifications();

      // Check profile completion milestones
      final profileData = {
        'name': candidate.name,
        'party': candidate.party,
        'photo': candidate.photo,
        'extraInfo': candidate.extraInfo?.toJson(),
      };
      await campaignMilestones.checkProfileCompletionMilestone(
        candidateId: candidateId,
        profileData: profileData,
      );

      // Check manifesto completion milestones if manifesto was updated
      if (_changedExtraInfoFields.containsKey('manifesto')) {
        final manifestoData = _changedExtraInfoFields['manifesto'];
        if (manifestoData is Map<String, dynamic>) {
          await campaignMilestones.checkManifestoCompletionMilestone(
            candidateId: candidateId,
            manifestoData: manifestoData,
          );
        }
      }

      AppLogger.database('Milestone checks completed', tag: 'CANDIDATE_CONTROLLER');
    } catch (e) {
      AppLogger.databaseError('Error checking milestones', tag: 'CANDIDATE_CONTROLLER', error: e);
      // Don't throw - milestone checks shouldn't block profile saves
    }
  }

  /// Send manifesto update notification when candidate updates their manifesto
  Future<void> _sendManifestoUpdateNotification() async {
    try {
      if (candidateData.value == null) return;

      // Check if manifesto was actually changed
      if (!_changedExtraInfoFields.containsKey('manifesto')) {
        AppLogger.database('No manifesto changes detected, skipping notification', tag: 'CANDIDATE_CONTROLLER');
        return;
      }

      final candidate = candidateData.value!;
      AppLogger.database('Manifesto changes detected, sending notification...', tag: 'CANDIDATE_CONTROLLER');

      // Get manifesto details from the changed data
      final manifestoData = _changedExtraInfoFields['manifesto'];
      if (manifestoData is! Map<String, dynamic>) {
        AppLogger.database('Invalid manifesto data format, skipping notification', tag: 'CANDIDATE_CONTROLLER');
        return;
      }

      // Determine update type and details
      String updateType = 'update';
      String manifestoTitle = manifestoData['title'] ?? 'Manifesto';
      String? manifestoDescription;

      // Check if this is a new manifesto or an update
      final originalManifesto = candidateData.value?.extraInfo?.manifesto;
      if (originalManifesto == null || originalManifesto.title == null || originalManifesto.title!.isEmpty) {
        updateType = 'new';
        AppLogger.database('Detected new manifesto creation', tag: 'CANDIDATE_CONTROLLER');
      } else {
        updateType = 'update';
        AppLogger.database('Detected manifesto update', tag: 'CANDIDATE_CONTROLLER');
      }

      // Get description from promises if available
      final promises = manifestoData['promises'];
      if (promises is List && promises.isNotEmpty) {
        manifestoDescription = '${promises.length} key promises';
      }

      AppLogger.database('Sending manifesto notification:', tag: 'CANDIDATE_CONTROLLER');
      AppLogger.database('  - Type: $updateType', tag: 'CANDIDATE_CONTROLLER');
      AppLogger.database('  - Title: $manifestoTitle', tag: 'CANDIDATE_CONTROLLER');
      AppLogger.database('  - Description: $manifestoDescription', tag: 'CANDIDATE_CONTROLLER');

      // Send manifesto update notification
      final constituencyNotifications = ConstituencyNotifications();
      await constituencyNotifications.sendManifestoUpdateNotification(
        candidateId: candidate.candidateId,
        updateType: updateType,
        manifestoTitle: manifestoTitle,
        manifestoDescription: manifestoDescription,
      );

      AppLogger.database('Manifesto update notification sent successfully', tag: 'CANDIDATE_CONTROLLER');
    } catch (e) {
      AppLogger.databaseError('Error sending manifesto update notification', tag: 'CANDIDATE_CONTROLLER', error: e);
      // Don't throw - manifesto save should succeed even if notification fails
    }
  }

  /// Debug method: Log all candidate data in the system
  Future<void> logAllCandidateData() async {
    try {
      AppLogger.database('===== CANDIDATE DATA CONTROLLER AUDIT =====', tag: 'CANDIDATE_CONTROLLER');
      AppLogger.database('Current user candidate data:', tag: 'CANDIDATE_CONTROLLER');
      AppLogger.database('  candidateData.value: ${candidateData.value}', tag: 'CANDIDATE_CONTROLLER');
      AppLogger.database('  isLoading.value: ${isLoading.value}', tag: 'CANDIDATE_CONTROLLER');
      AppLogger.database('  isPaid.value: ${isPaid.value}', tag: 'CANDIDATE_CONTROLLER');

      // Log events data
      AppLogger.database('Events data:', tag: 'CANDIDATE_CONTROLLER');
      AppLogger.database('  events.length: ${events.length}', tag: 'CANDIDATE_CONTROLLER');
      AppLogger.database('  isEventsLoading.value: ${isEventsLoading.value}', tag: 'CANDIDATE_CONTROLLER');
      AppLogger.database('  eventsLastFetched.value: ${eventsLastFetched.value}', tag: 'CANDIDATE_CONTROLLER');

      // Call the repository audit method
      await _candidateRepository.logAllCandidatesInSystem();
    } catch (e) {
      AppLogger.databaseError('Error in candidate data audit', tag: 'CANDIDATE_CONTROLLER', error: e);
    }
  }
}

