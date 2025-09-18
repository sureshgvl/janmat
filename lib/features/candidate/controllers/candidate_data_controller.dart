import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/candidate_model.dart';
import '../models/candidate_achievement_model.dart';
import '../repositories/candidate_repository.dart';
import '../repositories/candidate_event_repository.dart';
import '../../../services/trial_service.dart';
import '../../../services/file_upload_service.dart';

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
      debugPrint('Candidate data updated, refreshing UI');
    });
  }

  Future<void> fetchCandidateData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    isLoading.value = true;
    try {
      final data = await _candidateRepository.getCandidateData(user.uid);
      if (data != null) {
        candidateData.value = data;
        editedData.value = data;

        // Check if user has premium access (sponsored OR in trial)
        final isSponsored = data.sponsored;
        final isInTrial = await _trialService.isTrialActive(user.uid);
        isPaid.value = isSponsored || isInTrial;

        debugPrint('🎯 Candidate access check:');
        debugPrint('   Sponsored: $isSponsored');
        debugPrint('   In Trial: $isInTrial');
        debugPrint('   Has Access: ${isPaid.value}');
      }
    } catch (e) {
      debugPrint('Error fetching candidate data: $e');
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
        updatedExtra = currentExtra.copyWith(media: value);
        break;
      case 'events':
        updatedExtra = currentExtra.copyWith(events: value);
        break;
      case 'highlight':
        updatedExtra = currentExtra.copyWith(highlight: value);
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
          case 'dateOfBirth':
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

    final currentContact =
        (editedData.value!.extraInfo?.contact ??
                Contact(phone: '', email: null, socialLinks: null))
            as Contact;
    final updatedContact = Contact(
      phone: field == 'phone' ? value : currentContact.phone,
      email: field == 'email' ? value : currentContact.email,
      socialLinks: field.startsWith('social_')
          ? {...?currentContact.socialLinks, field.substring(7): value}
          : currentContact.socialLinks,
    );

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
        debugPrint('Warning: Failed to save photo URL to Firebase');
      }
    } catch (e) {
      debugPrint('Error saving photo URL: $e');
    }
  }

  void updateBasicInfo(String field, dynamic value) {
    if (editedData.value == null) return;

    switch (field) {
      case 'name':
        editedData.value = editedData.value!.copyWith(name: value);
        break;
      case 'party':
        editedData.value = editedData.value!.copyWith(party: value);
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
      case 'age':
      case 'gender':
      case 'education':
      case 'address':
      case 'dateOfBirth':
        // Track the change for field-level updates
        trackExtraInfoFieldChange(field, value);
        updateExtraInfo(field, value);
        break;
    }
  }

  Future<bool> saveExtraInfo({Function(String)? onProgress}) async {
    if (editedData.value == null) return false;

    try {
      bool success = false;

      debugPrint('💾 saveExtraInfo - Changed fields: $_changedExtraInfoFields');

      // First, upload any local photos to Firebase
      onProgress?.call('Uploading photos to cloud...');
      await _uploadLocalPhotosToFirebase();

      // Use field-level updates for better performance
      if (_changedExtraInfoFields.isNotEmpty) {
        debugPrint('   Using field-level updates');
        onProgress?.call('Saving data...');
        success = await _candidateRepository.updateCandidateExtraInfoFields(
          editedData.value!.candidateId,
          _changedExtraInfoFields,
        );
      }

      // Fallback to full update if no field-level changes tracked
      if (!success && _changedExtraInfoFields.isEmpty) {
        debugPrint('   Using full update');
        onProgress?.call('Saving data...');
        success = await _candidateRepository.updateCandidateExtraInfo(
          editedData.value!,
        );
      }

      if (success) {
        debugPrint('   Save successful, updating candidateData');
        onProgress?.call('Achievements saved successfully!');
        candidateData.value = editedData.value;
        clearChangeTracking(); // Clear tracking after successful save
      }

      return success;
    } catch (e) {
      debugPrint('Error saving extra info: $e');
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
          debugPrint(
            '📤 Uploading local photo for achievement: ${achievement.title}',
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

              debugPrint(
                '✅ Successfully uploaded photo for: ${achievement.title}',
              );
            }
          } catch (e) {
            debugPrint('❌ Failed to upload photo for ${achievement.title}: $e');
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
      debugPrint('❌ Error uploading local photos: $e');
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

      debugPrint('🔄 Refreshed access status:');
      debugPrint('   Sponsored: $isSponsored');
      debugPrint('   In Trial: $isInTrial');
      debugPrint('   Has Access: ${isPaid.value}');
    } catch (e) {
      debugPrint('Error refreshing access status: $e');
    }
  }

  // Events Management Methods

  /// Fetch events for the current candidate with caching
  Future<void> fetchEvents({bool forceRefresh = false}) async {
    final candidate = candidateData.value;
    if (candidate == null) {
      debugPrint('🎪 No candidate data available, clearing events');
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
      debugPrint('🎪 Using cached events data');
      return;
    }

    isEventsLoading.value = true;
    try {
      debugPrint('🎪 Fetching events for candidate: ${candidate.candidateId}');
      final fetchedEvents = await _eventRepository.getCandidateEvents(
        candidate.candidateId,
      );

      events.assignAll(fetchedEvents);
      eventsLastFetched.value = DateTime.now();

      debugPrint('🎪 Successfully loaded ${fetchedEvents.length} events');
    } catch (e) {
      debugPrint('❌ Error fetching events: $e');
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

  /// Debug method: Log all candidate data in the system
  Future<void> logAllCandidateData() async {
    try {
      debugPrint('🔍 ===== CANDIDATE DATA CONTROLLER AUDIT =====');
      debugPrint('🔍 Current user candidate data:');
      debugPrint('   candidateData.value: ${candidateData.value}');
      debugPrint('   isLoading.value: ${isLoading.value}');
      debugPrint('   isPaid.value: ${isPaid.value}');

      // Log events data
      debugPrint('🎪 Events data:');
      debugPrint('   events.length: ${events.length}');
      debugPrint('   isEventsLoading.value: ${isEventsLoading.value}');
      debugPrint('   eventsLastFetched.value: ${eventsLastFetched.value}');

      // Call the repository audit method
      await _candidateRepository.logAllCandidatesInSystem();
    } catch (e) {
      debugPrint('❌ Error in candidate data audit: $e');
    }
  }
}
