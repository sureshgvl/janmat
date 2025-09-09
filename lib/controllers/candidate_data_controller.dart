import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/candidate_model.dart';
import '../repositories/candidate_repository.dart';
import '../services/trial_service.dart';

class CandidateDataController extends GetxController {
  final CandidateRepository _candidateRepository = CandidateRepository();
  final TrialService _trialService = TrialService();

  var candidateData = Rx<Candidate?>(null);
  var editedData = Rx<Candidate?>(null);
  var isLoading = false.obs;
  var isPaid = false.obs;

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
      print('Candidate data updated, refreshing UI');
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

        print('🎯 Candidate access check:');
        print('   Sponsored: $isSponsored');
        print('   In Trial: $isInTrial');
        print('   Has Access: ${isPaid.value}');
      }
    } catch (e) {
      print('Error fetching candidate data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void updateExtraInfo(String field, dynamic value) {
    if (editedData.value == null) return;

    final currentExtra = editedData.value!.extraInfo ?? ExtraInfo();
    final updatedExtra = ExtraInfo(
      bio: field == 'bio' ? value : currentExtra.bio,
      achievements: field == 'achievements' ? value : currentExtra.achievements,
      manifesto: field == 'manifesto' ? value : currentExtra.manifesto,
      manifestoPdf: field == 'manifesto_pdf' ? value : currentExtra.manifestoPdf,
      contact: field == 'contact' ? value : currentExtra.contact,
      media: field == 'media' ? value : currentExtra.media,
      highlight: field == 'highlight' ? value : currentExtra.highlight,
      events: field == 'events' ? value : currentExtra.events,
    );

    editedData.value = editedData.value!.copyWith(extraInfo: updatedExtra);
  }

  void updateContact(String field, String value) {
    if (editedData.value == null) return;

    final currentContact = editedData.value!.extraInfo?.contact ?? Contact(phone: '', email: null, socialLinks: null);
    final updatedContact = Contact(
      phone: field == 'phone' ? value : currentContact.phone,
      email: field == 'email' ? value : currentContact.email,
      socialLinks: field.startsWith('social_') ? {
        ...?currentContact.socialLinks,
        field.substring(7): value,
      } : currentContact.socialLinks,
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
      final success = await _candidateRepository.updateCandidateExtraInfo(editedData.value!);
      if (!success) {
        print('Warning: Failed to save photo URL to Firebase');
      }
    } catch (e) {
      print('Error saving photo URL: $e');
    }
  }

  Future<bool> saveExtraInfo() async {
    if (editedData.value == null) return false;

    try {
      final success = await _candidateRepository.updateCandidateExtraInfo(editedData.value!);
      if (success) {
        candidateData.value = editedData.value;
      }
      return success;
    } catch (e) {
      print('Error saving extra info: $e');
      return false;
    }
  }

  void resetEditedData() {
    editedData.value = candidateData.value;
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

      print('🔄 Refreshed access status:');
      print('   Sponsored: $isSponsored');
      print('   In Trial: $isInTrial');
      print('   Has Access: ${isPaid.value}');
    } catch (e) {
      print('Error refreshing access status: $e');
    }
  }
}