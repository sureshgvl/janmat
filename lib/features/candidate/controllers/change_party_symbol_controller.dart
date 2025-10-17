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
import '../repositories/candidate_party_repository.dart';
import '../../../utils/symbol_utils.dart';
import '../../../utils/app_logger.dart';

class ChangePartySymbolController extends GetxController {
  final candidateRepository = CandidateRepository();
  final partyRepository = PartyRepository();

  // State
  final RxBool isLoading = false.obs;
  final RxBool isLoadingParties = true.obs;
  final RxBool isUploadingImage = false.obs;
  final RxBool isIndependent = false.obs;

  // Data
  final RxList<Party> parties = <Party>[].obs;
  final Rx<Party?> selectedParty = Rx<Party?>(null);
  final Rx<String?> symbolImageUrl = Rx<String?>(null);
  final Rx<Candidate?> currentCandidate = Rx<Candidate?>(null);

  // Controllers
  final symbolNameController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadParties();
  }

  @override
  void onClose() {
    symbolNameController.dispose();
    super.onClose();
  }

  void initializeWithCandidate(Candidate? candidate) {
    currentCandidate.value = candidate;
    _loadCurrentData();
  }

  Future<void> loadParties() async {
    try {
      AppLogger.candidate('🚀 ChangePartySymbolController: Starting to load parties...');
      final fetchedParties = await partyRepository.getActiveParties();
      AppLogger.candidate(
        '📦 ChangePartySymbolController: Received ${fetchedParties.length} parties',
      );

      parties.assignAll(fetchedParties);
      isLoadingParties.value = false;
      _loadCurrentData();
    } catch (e) {
      AppLogger.candidateError('❌ ChangePartySymbolController: Error loading parties: $e');
      isLoadingParties.value = false;
    }
  }

  void _loadCurrentData() {
    AppLogger.candidate('📋 ChangePartySymbolController: Loading current candidate data');
    final candidate = currentCandidate.value;
    if (candidate != null) {
      AppLogger.candidate('   Candidate: ${candidate.name}');
      AppLogger.candidate('   Current party: ${candidate.party}');
      AppLogger.candidate(
        '   Current symbol: ${candidate.symbolName ?? 'none'}',
      );

      // Find current party
      if (parties.isNotEmpty) {
        selectedParty.value = parties.firstWhere(
          (party) => party.id == candidate.party,
          orElse: () => parties.first,
        );
        AppLogger.candidate('   Selected party: ${selectedParty.value?.name ?? 'none'}');
      }

      // Load symbol data
      if (candidate.symbolName != null) {
        symbolNameController.text = candidate.symbolName!;
        AppLogger.candidate('   Symbol name loaded: ${candidate.symbolName}');
      }

      // Load existing symbol image URL from extraInfo.media
      if (candidate.extraInfo?.media != null &&
          candidate.extraInfo!.media!.isNotEmpty) {
        final symbolImageItem = candidate.extraInfo!.media!
            .firstWhere(
              (item) => item['type'] == 'symbolImage',
              orElse: () => <String, dynamic>{},
            );
        if (symbolImageItem.isNotEmpty) {
          symbolImageUrl.value = symbolImageItem['url'] as String?;
          AppLogger.candidate('   Symbol image URL loaded: ${symbolImageUrl.value ?? 'none'}');
        }
      }

      isIndependent.value = candidate.party.toLowerCase().contains('independent');
      AppLogger.candidate('   Is independent: ${isIndependent.value}');
    } else {
      AppLogger.candidate('   No candidate data available');
    }
  }

  Future<void> pickSymbolImage(BuildContext context) async {
    final localizations = AppLocalizations.of(context)!;

    AppLogger.candidate('📸 ChangePartySymbolController: Starting image upload process');
    isUploadingImage.value = true;

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
            '❌ ChangePartySymbolController: File too large - rejecting upload',
          );
          Get.snackbar(
            localizations.error,
            localizations.symbolImageSizeLimitError,
          );
          isUploadingImage.value = false;
          return;
        }

        AppLogger.candidate('✅ ChangePartySymbolController: File size validation passed');

        // Upload to Firebase Storage
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          AppLogger.candidate('❌ ChangePartySymbolController: No authenticated user found');
          isUploadingImage.value = false;
          return;
        }

        final fileName =
            '${currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        AppLogger.candidate(
          '📤 ChangePartySymbolController: Preparing upload - User: ${currentUser.uid}, File: $fileName',
        );
        AppLogger.candidate(
          '📂 ChangePartySymbolController: Firebase Storage path: candidate_symbols/$fileName',
        );

        final storageRef = FirebaseStorage.instance
            .ref()
            .child('candidate_symbols')
            .child(fileName);

        AppLogger.candidate(
          '📤 ChangePartySymbolController: Starting Firebase Storage upload',
        );
        final uploadTask = storageRef.putFile(File(image.path));

        // Monitor upload progress
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress =
              (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
          AppLogger.candidate(
            '📊 ChangePartySymbolController: Upload progress: ${progress.toStringAsFixed(1)}%',
          );
        });

        final snapshot = await uploadTask.whenComplete(() => null);
        AppLogger.candidate('✅ ChangePartySymbolController: Upload completed successfully');

        final downloadUrl = await snapshot.ref.getDownloadURL();
        AppLogger.candidate(
          '🔗 ChangePartySymbolController: Download URL obtained: ${downloadUrl.substring(0, 50)}...',
        );
        AppLogger.candidate(
          '📍 ChangePartySymbolController: Firebase Console path: candidate_symbols/ → $fileName',
        );

        symbolImageUrl.value = downloadUrl;
        isUploadingImage.value = false;

        AppLogger.candidate(
          '🎉 ChangePartySymbolController: Image upload process completed successfully',
        );
        Get.snackbar(
          localizations.success,
          localizations.symbolUploadSuccess,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
        );
      } else {
        AppLogger.candidate('❌ ChangePartySymbolController: No image selected by user');
        isUploadingImage.value = false;
      }
    } catch (e) {
      AppLogger.candidateError('💥 ChangePartySymbolController: Error during image upload: $e');
      isUploadingImage.value = false;
      Get.snackbar(
        localizations.error,
        localizations.symbolUploadError(e.toString()),
      );
    }
  }

  Future<bool> updatePartyAndSymbol(BuildContext context) async {
    final localizations = AppLocalizations.of(context)!;

    AppLogger.candidate(
      '📝 ChangePartySymbolController: Starting party and symbol update process',
    );

    if (selectedParty.value == null) {
      AppLogger.candidate('❌ ChangePartySymbolController: No party selected');
      Get.snackbar(localizations.error, localizations.selectPartyValidation);
      return false;
    }

    AppLogger.candidate('✅ ChangePartySymbolController: Form validation passed');
    AppLogger.candidate('   Selected party: ${selectedParty.value!.name}');
    AppLogger.candidate('   Is independent: ${isIndependent.value}');
    AppLogger.candidate(
      '   Symbol name: ${isIndependent.value ? symbolNameController.text.trim() : 'N/A'}',
    );
    AppLogger.candidate('   Symbol image URL: ${symbolImageUrl.value ?? 'none'}');

    isLoading.value = true;

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        AppLogger.candidate('❌ ChangePartySymbolController: User not authenticated');
        throw Exception('User not authenticated');
      }

      final candidate = currentCandidate.value;
      if (candidate == null) {
        AppLogger.candidate('❌ ChangePartySymbolController: Candidate data not found');
        throw Exception('Candidate data not found');
      }

      AppLogger.candidate(
        '👤 ChangePartySymbolController: Authenticated user: ${currentUser.uid}',
      );
      AppLogger.candidate(
        '👤 ChangePartySymbolController: Updating candidate: ${candidate.candidateId}',
      );

      // Update candidate with new party and symbol
      final currentMedia = candidate.extraInfo?.media ?? [];
      final updatedMedia = List<Map<String, dynamic>>.from(currentMedia);

      // Remove existing symbol image if present
      updatedMedia.removeWhere((item) => item['type'] == 'symbolImage');

      // Add new symbol image if provided
      if (symbolImageUrl.value != null) {
        updatedMedia.add({
          'type': 'symbolImage',
          'url': symbolImageUrl.value!,
          'title': 'Party Symbol',
          'uploadedAt': DateTime.now().toIso8601String(),
        });
      }

      final updatedExtraInfo =
          candidate.extraInfo?.copyWith(media: updatedMedia) ??
          (symbolImageUrl.value != null
              ? ExtraInfo(
                  media: [
                    {
                      'type': 'symbolImage',
                      'url': symbolImageUrl.value!,
                      'title': 'Party Symbol',
                      'uploadedAt': DateTime.now().toIso8601String(),
                    },
                  ],
                )
              : ExtraInfo());

      final updatedCandidate = candidate.copyWith(
        party: selectedParty.value!.id, // Use party key instead of full name for proper symbol resolution
        symbolUrl: isIndependent.value ? symbolImageUrl.value : null,
        symbolName: isIndependent.value ? symbolNameController.text.trim() : SymbolUtils.getPartySymbolNameLocal(selectedParty.value!.id, Localizations.localeOf(context).languageCode),
        extraInfo: updatedExtraInfo,
      );

      AppLogger.candidate('💾 ChangePartySymbolController: Data to be saved:');
      AppLogger.candidate('   Party: ${updatedCandidate.party}');
      AppLogger.candidate('   Symbol Name: ${updatedCandidate.symbolName}');
      AppLogger.candidate('   Symbol URL: ${updatedCandidate.symbolUrl}');
      AppLogger.candidate('   Symbol Image URL: ${updatedCandidate.extraInfo?.media}');

      AppLogger.candidate('📤 ChangePartySymbolController: Sending update to database...');
      // Update candidate in database
      await candidateRepository.updateCandidateExtraInfo(updatedCandidate);
      AppLogger.candidate('✅ ChangePartySymbolController: Database update successful');

      // Update the local candidate data to reflect changes immediately
      currentCandidate.value = updatedCandidate;
      isLoading.value = false;

      AppLogger.candidate(
        '🎉 ChangePartySymbolController: Party and symbol update completed successfully',
      );

      // Show success message
      Get.snackbar(
        localizations.success,
        localizations.partyUpdateSuccess,
        duration: const Duration(seconds: 2),
      );

      return true;
    } catch (e) {
      AppLogger.candidateError(
        '💥 ChangePartySymbolController: Error updating party and symbol: $e',
      );
      isLoading.value = false;
      Get.snackbar(
        localizations.error,
        localizations.partyUpdateError(e.toString()),
      );
      return false;
    }
  }

  void selectParty(Party party) {
    AppLogger.candidate(
      '🎯 ChangePartySymbolController: Party selected',
    );
    AppLogger.candidate('   Selected party: ${party.name}');
    selectedParty.value = party;
    isIndependent.value = party.name.toLowerCase().contains('independent');
    AppLogger.candidate('   Is independent: ${isIndependent.value}');
    if (!isIndependent.value) {
      symbolNameController.clear();
      symbolImageUrl.value = null;
      AppLogger.candidate(
        '   Cleared symbol data for non-independent party',
      );
    } else {
      // Load existing symbol image URL for independent candidates
      final candidate = currentCandidate.value;
      if (candidate!.extraInfo?.media != null &&
          candidate.extraInfo!.media!.isNotEmpty) {
        final symbolImageItem = candidate.extraInfo!.media!
            .firstWhere(
              (item) => item['type'] == 'symbolImage',
              orElse: () => <String, dynamic>{},
            );
        if (symbolImageItem.isNotEmpty) {
          symbolImageUrl.value = symbolImageItem['url'] as String?;
          AppLogger.candidate(
            '   Loaded existing symbol image URL for independent party',
          );
        }
      }
    }
  }

  String getCurrentPartyDisplayName(BuildContext context) {
    final candidate = currentCandidate.value;
    if (candidate == null) return '';

    // Find the party object from the parties list
    final currentParty = parties.firstWhere(
      (party) => party.name == candidate.party,
      orElse: () => Party(
        id: 'unknown',
        name: candidate.party,
        nameMr: candidate.party,
        abbreviation: '',
      ),
    );

    // Return the display name based on current locale
    return currentParty.getDisplayName(
      Localizations.localeOf(context).languageCode,
    );
  }

  String getCurrentSymbolDisplayName() {
    final candidate = currentCandidate.value;
    if (candidate == null || candidate.symbolName == null) {
      return '';
    }

    return candidate.symbolName!;
  }
}