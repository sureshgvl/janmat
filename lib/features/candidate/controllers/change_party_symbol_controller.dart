import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../l10n/app_localizations.dart';
import '../../../../core/services/firebase_uploader.dart';
import '../../../../core/models/unified_file.dart';
import '../models/candidate_model.dart';
import '../models/candidate_party_model.dart';
import '../repositories/candidate_repository.dart';
import '../../../utils/symbol_utils.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/snackbar_utils.dart';
import '../../../utils/candidate_data_manager.dart';

class ChangePartySymbolController extends GetxController {
  final candidateRepository = CandidateRepository();

  // Data
  final RxList<Party> parties = RxList<Party>();
  final Rx<Party?> selectedParty = Rx<Party?>(null);
  final Rx<Candidate?> candidate = Rx<Candidate?>(null);
  final RxBool isLoading = false.obs;

  // Symbol management with cross-platform unified file handling
  final RxBool isIndependent = false.obs;
  final RxBool isUploadingImage = false.obs;
  final Rx<String?> symbolImageUrl = Rx<String?>(null);
  final Rx<UnifiedFile?> selectedSymbolFile = Rx<UnifiedFile?>(null);
  final symbolNameController = TextEditingController();

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
      if (isIndependentParty && selectedSymbolFile.value != null) {
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

      SnackbarUtils.showSuccess(AppLocalizations.of(Get.context!)?.partyUpdateSuccess ?? 'Party updated successfully');
    } catch (e) {
      AppLogger.candidateError('Error updating party: $e');
      SnackbarUtils.showError(AppLocalizations.of(Get.context!)?.partyUpdateError(e.toString()) ?? 'Failed to update party');
    } finally {
      isLoading.value = false;
    }
  }

  // Backward compatibility methods
  Rx<Candidate?> get currentCandidate => candidate;

  // Backward compatibility getter for isLoadingParties
  RxBool get isLoadingParties => isLoading;

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

  // Cross-platform unified file selection for independent candidates
  Future<void> selectSymbolFile(UnifiedFile file) async {
    try {
      AppLogger.candidate('📸 ChangePartySymbolController: Unified file selected - Name: ${file.name}, Size: ${file.size} bytes');

      // Check image file size (5MB limit)
      const maxSizeInBytes = 5 * 1024 * 1024; // 5MB
      if (file.size > maxSizeInBytes) {
        AppLogger.candidate('❌ ChangePartySymbolController: File too large - rejecting selection');
        SnackbarUtils.showError('Symbol image exceeds 5MB limit');
        return;
      }

      // Store the unified file - will upload to Firebase on save
      selectedSymbolFile.value = file;
      AppLogger.candidate('🎯 ChangePartySymbolController: Unified file stored for upload on save');

      SnackbarUtils.showSuccess('Symbol image selected successfully');
    } catch (e) {
      AppLogger.candidateError('💥 ChangePartySymbolController: Error selecting unified file: $e');
      SnackbarUtils.showError('Failed to select symbol image');
    }
  }

  // Upload unified file to Firebase Storage (called during party update)
  Future<String?> _uploadSymbolImageToFirebase() async {
    if (selectedSymbolFile.value == null) return null;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      AppLogger.candidate('❌ ChangePartySymbolController: No authenticated user for upload');
      return null;
    }

    try {
      AppLogger.candidate('📤 ChangePartySymbolController: Starting Firebase upload for selected unified file');

      final fileName = '${currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = 'candidate_symbols/$fileName';

      AppLogger.candidate('📤 ChangePartySymbolController: Firebase Storage path: $storagePath');

      // Upload using our cross-platform FirebaseUploader
      final url = await FirebaseUploader.uploadUnifiedFile(
        f: selectedSymbolFile.value!,
        storagePath: storagePath,
        onProgress: (progress) {
          AppLogger.candidate('📤 Upload progress: $progress%');
        },
      );

      if (url != null) {
        AppLogger.candidate('✅ ChangePartySymbolController: Firebase upload completed - URL: $url');

        // Clear local storage now that it's uploaded
        selectedSymbolFile.value = null;

        return url;
      } else {
        AppLogger.candidateError('❌ ChangePartySymbolController: Firebase upload failed - no URL returned');
        return null;
      }
    } catch (e) {
      AppLogger.candidateError('💥 ChangePartySymbolController: Firebase upload failed: $e');
      return null;
    }
  }
}
