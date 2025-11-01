import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../../l10n/app_localizations.dart';
import '../models/candidate_model.dart';
import '../models/candidate_party_model.dart';
import '../repositories/candidate_repository.dart';
import '../../../utils/symbol_utils.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/candidate_data_manager.dart';


class ChangePartySymbolController extends GetxController {
  final candidateRepository = CandidateRepository();

  // Data
  final RxList<Party> parties = RxList<Party>();
  final Rx<Party?> selectedParty = Rx<Party?>(null);
  final Rx<Candidate?> candidate = Rx<Candidate?>(null);
  final RxBool isLoading = false.obs;

  // Backward compatibility properties
  final RxBool isLoadingParties = false.obs; // Always false since we use static data
  final RxBool isIndependent = false.obs; // Tracks if current selected party is independent
  final RxBool isUploadingImage = false.obs; // Upload progress indicator
  final Rx<String?> symbolImageUrl = Rx<String?>(null); // Firebase Storage URL when uploaded
  final Rx<File?> selectedSymbolImage = Rx<File?>(null); // Local image file before upload
  final symbolNameController = TextEditingController(); // Symbol name input

  @override
  void onInit() {
    super.onInit();
    parties.assignAll(SymbolUtils.getAllParties());
    initializeWithCandidate(candidate.value);
  }

  @override
  void onClose() {
    symbolNameController.dispose();
    super.onClose();
  }

  // Using the global CandidateDataManager for consistent data updates
  final _candidateDataManager = CandidateDataManager();

  void initializeWithCandidate(Candidate? candidate) {
    this.candidate.value = candidate;
    if (candidate != null && parties.isNotEmpty) {
      selectedParty.value = parties.firstWhere(
        (party) => party.id == candidate.party,
        orElse: () => parties.first,
      );

      // Load existing symbol data for independent candidates
      isIndependent.value = candidate.party.toLowerCase().contains('independent');
      if (isIndependent.value) {
        symbolNameController.text = candidate.symbolName ?? '';
        symbolImageUrl.value = candidate.symbolUrl;
      } else {
        symbolNameController.clear();
        symbolImageUrl.value = null;
      }
    }
  }

  Future<void> changeParty(Party newParty) async {
    if (candidate.value == null) return;

    isLoading.value = true;
    try {
      // Determine if this is an independent candidate
      final isIndependentParty = newParty.id.toLowerCase().contains('independent');

      // For independent candidates, upload local image to Firebase first
      String? firebaseUrl;
      if (isIndependentParty && selectedSymbolImage.value != null) {
        AppLogger.candidate('📤 ChangePartySymbolController: Uploading symbol image for independent candidate');
        firebaseUrl = await _uploadSymbolImageToFirebase();
        if (firebaseUrl != null) {
          symbolImageUrl.value = firebaseUrl; // Update the uploaded URL
          AppLogger.candidate('✅ ChangePartySymbolController: Symbol image uploaded to Firebase: $firebaseUrl');
        } else {
          AppLogger.candidateError('❌ ChangePartySymbolController: Failed to upload symbol image');
          throw Exception('Symbol image upload failed');
        }
      }

      // For independent candidates, include symbol data if available
      final updatedCandidate = candidate.value!.copyWith(
        party: newParty.id,
        symbolUrl: isIndependentParty ? symbolImageUrl.value : null,
        symbolName: isIndependentParty ? symbolNameController.text.trim() : SymbolUtils.getPartySymbolNameLocal(newParty.id, Get.locale?.languageCode ?? 'en'),
      );

      // Update only party, symbol, and symbol name in Firebase database
      await candidateRepository.updateCandidateExtraInfo(updatedCandidate);

      // Update local cache using the manager
      _candidateDataManager.updateCandidateInLocalCache(updatedCandidate);

      // Update this controller's local candidate as well
      candidate.value = updatedCandidate;
      selectedParty.value = newParty;

      AppLogger.candidate('✅ Party, Symbol, and Symbol Name updated successfully');

      // Update independent flag for UI
      isIndependent.value = isIndependentParty;

      Get.snackbar(
        AppLocalizations.of(Get.context!)?.success ?? 'Success',
        AppLocalizations.of(Get.context!)?.partyUpdateSuccess ?? 'Party updated successfully',
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      AppLogger.candidateError('Error updating party: $e');
      Get.snackbar(
        AppLocalizations.of(Get.context!)?.error ?? 'Error',
        AppLocalizations.of(Get.context!)?.partyUpdateError(e.toString()) ?? 'Failed to update party',
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Backward compatibility methods
  Rx<Candidate?> get currentCandidate => candidate;

  Future<bool> updatePartyAndSymbol(BuildContext context) async {
    if (selectedParty.value == null) return false;
    await changeParty(selectedParty.value!);
    return true;
  }

  void selectParty(Party party) {
    selectedParty.value = party;

    // Update independent flag for UI - this triggers showing/hiding symbol fields
    isIndependent.value = party.id.toLowerCase().contains('independent');
    AppLogger.candidate('Party selected: ${party.name}, isIndependent: ${isIndependent.value}');
  }

  String getCurrentPartyDisplayName(BuildContext context) {
    if (candidate.value == null) return '';

    final currentParty = parties.firstWhere(
      (party) => party.id == candidate.value!.party,
      orElse: () => Party(
        id: 'unknown',
        name: candidate.value!.party,
        nameMr: candidate.value!.party,
        abbreviation: '',
      ),
    );

    return currentParty.getDisplayName(Localizations.localeOf(context).languageCode);
  }

  String getCurrentSymbolDisplayName() {
    return candidate.value?.symbolName ?? '';
  }

  // Local image selection for independent candidates (upload happens on save)
  Future<void> pickSymbolImage(BuildContext context) async {
    final localizations = AppLocalizations.of(context)!;

    AppLogger.candidate('📸 ChangePartySymbolController: Starting local image selection');
    isUploadingImage.value = true; // Using this to show loading during selection

    try {
      final ImagePicker picker = ImagePicker();
      AppLogger.candidate('📸 ChangePartySymbolController: Opening image picker');
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        AppLogger.candidate(
          '📸 ChangePartySymbolController: Image selected - Path: ${image.path}',
        );
        AppLogger.candidate('📸 ChangePartySymbolController: Image name: ${image.name}');

        // Check image file size (5MB limit)
        final file = File(image.path);
        final fileSize = await file.length();
        const maxSizeInBytes = 5 * 1024 * 1024; // 5MB

        AppLogger.candidate(
          '📏 ChangePartySymbolController: File size check - Size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB, Limit: 5MB',
        );

        if (fileSize > maxSizeInBytes) {
          AppLogger.candidate(
            '❌ ChangePartySymbolController: File too large - rejecting selection',
          );
          Get.snackbar(
            localizations.error,
            localizations.symbolImageSizeLimitError,
          );
          isUploadingImage.value = false;
          return;
        }

        AppLogger.candidate('✅ ChangePartySymbolController: File size validation passed');

        // Store locally - will upload to Firebase on save
        selectedSymbolImage.value = file;
        AppLogger.candidate('🎯 ChangePartySymbolController: Image stored locally for upload on save');

        isUploadingImage.value = false;

        Get.snackbar(
          localizations.success ?? 'Success',
          localizations.symbolUploadSuccess ?? 'Symbol image selected successfully',
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
        );
      } else {
        AppLogger.candidate('❌ ChangePartySymbolController: No image selected by user');
        isUploadingImage.value = false;
      }
    } catch (e) {
      AppLogger.candidateError('💥 ChangePartySymbolController: Error during image selection: $e');
      isUploadingImage.value = false;
      Get.snackbar(
        localizations.error,
        localizations.symbolUploadError(e.toString()),
      );
    }
  }

  // Upload local image to Firebase Storage (called during party update)
  Future<String?> _uploadSymbolImageToFirebase() async {
    if (selectedSymbolImage.value == null) return null;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      AppLogger.candidate('❌ ChangePartySymbolController: No authenticated user for upload');
      return null;
    }

    try {
      AppLogger.candidate('📤 ChangePartySymbolController: Starting Firebase upload for selected image');

      final fileName = '${currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      AppLogger.candidate('� ChangePartySymbolController: Firebase Storage path: candidate_symbols/$fileName');

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('candidate_symbols')
          .child(fileName);

      // Upload the local file
      final snapshot = await storageRef.putFile(selectedSymbolImage.value!);
      final downloadUrl = await snapshot.ref.getDownloadURL();

      AppLogger.candidate('✅ ChangePartySymbolController: Firebase upload completed');

      // Clear local storage now that it's uploaded
      selectedSymbolImage.value = null;

      return downloadUrl;
    } catch (e) {
      AppLogger.candidateError('💥 ChangePartySymbolController: Firebase upload failed: $e');
      return null;
    }
  }
}
