import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/candidate_model.dart';
import '../repositories/candidate_repository.dart';

class CandidateDataController extends GetxController {
  final CandidateRepository _candidateRepository = CandidateRepository();

  var candidateData = Rx<Candidate?>(null);
  var editedData = Rx<Candidate?>(null);
  var isLoading = false.obs;
  var isPaid = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCandidateData();
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
        isPaid.value = data.sponsored; // Assuming sponsored means paid
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

  void updatePhoto(String photoUrl) {
    if (editedData.value == null) return;

    editedData.value = editedData.value!.copyWith(photo: photoUrl);
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
}