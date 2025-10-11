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

class ChangePartySymbolScreen extends StatefulWidget {
  final Candidate? currentCandidate;
  final User? currentUser;

  const ChangePartySymbolScreen({
    super.key,
    required this.currentCandidate,
    required this.currentUser,
  });

  @override
  State<ChangePartySymbolScreen> createState() =>
      _ChangePartySymbolScreenState();
}

class _ChangePartySymbolScreenState extends State<ChangePartySymbolScreen> {
   final _formKey = GlobalKey<FormState>();
   final candidateRepository = CandidateRepository();
   final partyRepository = PartyRepository();

   // Form controllers
   final symbolNameController = TextEditingController();

   Party? selectedParty;
   String? symbolImageUrl;
   bool isLoading = false;
   bool isLoadingParties = true;
   bool isUploadingImage = false;
   List<Party> parties = [];
   bool isIndependent = false;
   Candidate? _currentCandidate;

  @override
  void initState() {
    super.initState();
    _currentCandidate = widget.currentCandidate;
    AppLogger.candidate('🎯 ChangePartySymbolScreen: Initializing screen');
    AppLogger.candidate(
      '   Current candidate: ${_currentCandidate?.name ?? 'null'}',
    );
    AppLogger.candidate('   Current user: ${widget.currentUser?.uid ?? 'null'}');
    _loadParties();
    _loadCurrentData();
  }

  void _loadCurrentData() {
    AppLogger.candidate('📋 ChangePartySymbolScreen: Loading current candidate data');
    if (_currentCandidate != null) {
      AppLogger.candidate('   Candidate: ${_currentCandidate!.name}');
      AppLogger.candidate('   Current party: ${_currentCandidate!.party}');
      AppLogger.candidate(
        '   Current symbol: ${_currentCandidate!.symbolName ?? 'none'}',
      );

      // Find current party
      if (parties.isNotEmpty) {
        selectedParty = parties.firstWhere(
          (party) => party.name == _currentCandidate!.party,
          orElse: () => parties.first,
        );
        AppLogger.candidate('   Selected party: ${selectedParty?.name ?? 'none'}');
      }

      // Load symbol data
      if (_currentCandidate!.symbolName != null) {
        symbolNameController.text = _currentCandidate!.symbolName!;
        AppLogger.candidate('   Symbol name loaded: ${_currentCandidate!.symbolName}');
      }

      // Load existing symbol image URL from extraInfo.media
      if (_currentCandidate!.extraInfo?.media != null &&
          _currentCandidate!.extraInfo!.media!.isNotEmpty) {
        final symbolImageItem = _currentCandidate!.extraInfo!.media!
            .firstWhere(
              (item) => item['type'] == 'symbolImage',
              orElse: () => <String, dynamic>{},
            );
        if (symbolImageItem.isNotEmpty) {
          symbolImageUrl = symbolImageItem['url'] as String?;
          AppLogger.candidate('   Symbol image URL loaded: ${symbolImageUrl ?? 'none'}');
        }
      }

      isIndependent = _currentCandidate!.party.toLowerCase().contains(
        'independent',
      );
      AppLogger.candidate('   Is independent: $isIndependent');
    } else {
      AppLogger.candidate('   No candidate data available');
    }
  }

  Future<void> _loadParties() async {
    try {
      AppLogger.candidate('🚀 ChangePartySymbolScreen: Starting to load parties...');
      final fetchedParties = await partyRepository.getActiveParties();
      AppLogger.candidate(
        '📦 ChangePartySymbolScreen: Received ${fetchedParties.length} parties',
      );

      if (mounted) {
        setState(() {
          parties = fetchedParties;
          isLoadingParties = false;
        });
        AppLogger.candidate(
          '✅ ChangePartySymbolScreen: Parties loaded successfully, calling _loadCurrentData()',
        );
        _loadCurrentData(); // Reload current data now that parties are loaded
      } else {
        AppLogger.candidate(
          '⚠️ ChangePartySymbolScreen: Widget not mounted, skipping setState',
        );
      }
    } catch (e) {
      AppLogger.candidateError('❌ ChangePartySymbolScreen: Error loading parties: $e');
      if (mounted) {
        setState(() {
          isLoadingParties = false;
        });
      }
    }
  }

  String _getCurrentPartyDisplayName() {
    if (_currentCandidate == null) return '';

    // Find the party object from the parties list
    final currentParty = parties.firstWhere(
      (party) => party.name == _currentCandidate!.party,
      orElse: () => Party(
        id: 'unknown',
        name: _currentCandidate!.party,
        nameMr: _currentCandidate!.party,
        abbreviation: '',
      ),
    );

    // Return the display name based on current locale
    return currentParty.getDisplayName(
      Localizations.localeOf(context).languageCode,
    );
  }

  String _getCurrentSymbolDisplayName() {
    if (_currentCandidate == null ||
        _currentCandidate!.symbolName == null) {
      return '';
    }

    return _currentCandidate!.symbolName!;
  }

  Future<void> _pickSymbolImage() async {
    final localizations = AppLocalizations.of(context)!;

    AppLogger.candidate('📸 ChangePartySymbolScreen: Starting image upload process');
    setState(() {
      isUploadingImage = true;
    });

    try {
      final ImagePicker picker = ImagePicker();
      AppLogger.candidate('📸 ChangePartySymbolScreen: Opening image picker');
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        AppLogger.candidate(
          '📸 ChangePartySymbolScreen: Image selected - Path: ${image.path}',
        );
        AppLogger.candidate('📸 ChangePartySymbolScreen: Image name: ${image.name}');

        // Check image file size (5MB limit)
        final file = File(image.path);
        final fileSize = await file.length();
        const maxSizeInBytes = 5 * 1024 * 1024; // 5MB

        AppLogger.candidate(
          '📏 ChangePartySymbolScreen: File size check - Size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB, Limit: 5MB',
        );

        if (fileSize > maxSizeInBytes) {
          AppLogger.candidate(
            '❌ ChangePartySymbolScreen: File too large - rejecting upload',
          );
          Get.snackbar(
            localizations.error,
            localizations.symbolImageSizeLimitError,
          );
          setState(() {
            isUploadingImage = false;
          });
          return;
        }

        AppLogger.candidate('✅ ChangePartySymbolScreen: File size validation passed');

        // Upload to Firebase Storage
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          AppLogger.candidate('❌ ChangePartySymbolScreen: No authenticated user found');
          setState(() {
            isUploadingImage = false;
          });
          return;
        }

        final fileName =
            '${currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        AppLogger.candidate(
          '📤 ChangePartySymbolScreen: Preparing upload - User: ${currentUser.uid}, File: $fileName',
        );
        AppLogger.candidate(
          '📂 ChangePartySymbolScreen: Firebase Storage path: candidate_symbols/$fileName',
        );

        final storageRef = FirebaseStorage.instance
            .ref()
            .child('candidate_symbols')
            .child(fileName);

        AppLogger.candidate(
          '📤 ChangePartySymbolScreen: Starting Firebase Storage upload',
        );
        final uploadTask = storageRef.putFile(File(image.path));

        // Monitor upload progress
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress =
              (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
          AppLogger.candidate(
            '📊 ChangePartySymbolScreen: Upload progress: ${progress.toStringAsFixed(1)}%',
          );
        });

        final snapshot = await uploadTask.whenComplete(() => null);
        AppLogger.candidate('✅ ChangePartySymbolScreen: Upload completed successfully');

        final downloadUrl = await snapshot.ref.getDownloadURL();
        AppLogger.candidate(
          '🔗 ChangePartySymbolScreen: Download URL obtained: ${downloadUrl.substring(0, 50)}...',
        );
        AppLogger.candidate(
          '📍 ChangePartySymbolScreen: Firebase Console path: candidate_symbols/ → $fileName',
        );

        setState(() {
          symbolImageUrl = downloadUrl;
          isUploadingImage = false;
        });

        AppLogger.candidate(
          '🎉 ChangePartySymbolScreen: Image upload process completed successfully',
        );
        Get.snackbar(
          localizations.success,
          localizations.symbolUploadSuccess,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
        );
      } else {
        AppLogger.candidate('❌ ChangePartySymbolScreen: No image selected by user');
        setState(() {
          isUploadingImage = false;
        });
      }
    } catch (e) {
      AppLogger.candidateError('💥 ChangePartySymbolScreen: Error during image upload: $e');
      setState(() {
        isUploadingImage = false;
      });
      Get.snackbar(
        localizations.error,
        localizations.symbolUploadError(e.toString()),
      );
    }
  }

  Future<void> _updatePartyAndSymbol() async {
    final localizations = AppLocalizations.of(context)!;

    AppLogger.candidate(
      '📝 ChangePartySymbolScreen: Starting party and symbol update process',
    );

    if (!_formKey.currentState!.validate()) {
      AppLogger.candidate('❌ ChangePartySymbolScreen: Form validation failed');
      return;
    }

    if (selectedParty == null) {
      AppLogger.candidate('❌ ChangePartySymbolScreen: No party selected');
      Get.snackbar(localizations.error, localizations.selectPartyValidation);
      return;
    }

    AppLogger.candidate('✅ ChangePartySymbolScreen: Form validation passed');
    AppLogger.candidate('   Selected party: ${selectedParty!.name}');
    AppLogger.candidate('   Is independent: $isIndependent');
    AppLogger.candidate(
      '   Symbol name: ${isIndependent ? symbolNameController.text.trim() : 'N/A'}',
    );
    AppLogger.candidate('   Symbol image URL: ${symbolImageUrl ?? 'none'}');

    setState(() {
      isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        AppLogger.candidate('❌ ChangePartySymbolScreen: User not authenticated');
        throw Exception('User not authenticated');
      }

      if (_currentCandidate == null) {
        AppLogger.candidate('❌ ChangePartySymbolScreen: Candidate data not found');
        throw Exception('Candidate data not found');
      }

      AppLogger.candidate(
        '👤 ChangePartySymbolScreen: Authenticated user: ${currentUser.uid}',
      );
      AppLogger.candidate(
        '👤 ChangePartySymbolScreen: Updating candidate: ${_currentCandidate!.candidateId}',
      );

      // Update candidate with new party and symbol
      final currentMedia = _currentCandidate!.extraInfo?.media ?? [];
      final updatedMedia = List<Map<String, dynamic>>.from(currentMedia);

      // Remove existing symbol image if present
      updatedMedia.removeWhere((item) => item['type'] == 'symbolImage');

      // Add new symbol image if provided
      if (symbolImageUrl != null) {
        updatedMedia.add({
          'type': 'symbolImage',
          'url': symbolImageUrl!,
          'title': 'Party Symbol',
          'uploadedAt': DateTime.now().toIso8601String(),
        });
      }

      final updatedExtraInfo =
          widget.currentCandidate!.extraInfo?.copyWith(media: updatedMedia) ??
          (symbolImageUrl != null
              ? ExtraInfo(
                  media: [
                    {
                      'type': 'symbolImage',
                      'url': symbolImageUrl!,
                      'title': 'Party Symbol',
                      'uploadedAt': DateTime.now().toIso8601String(),
                    },
                  ],
                )
              : ExtraInfo());

      final updatedCandidate = _currentCandidate!.copyWith(
        party: selectedParty!.name, // Use party name
        symbolUrl: isIndependent ? symbolImageUrl : null,
        symbolName: isIndependent ? symbolNameController.text.trim() : SymbolUtils.getPartySymbolNameLocal(selectedParty!.id, Localizations.localeOf(context).languageCode),
        extraInfo: updatedExtraInfo,
      );

      AppLogger.candidate('💾 ChangePartySymbolScreen: Data to be saved:');
      AppLogger.candidate('   Party: ${updatedCandidate.party}');
      AppLogger.candidate('   Symbol Name: ${updatedCandidate.symbolName}');
      AppLogger.candidate('   Symbol URL: ${updatedCandidate.symbolUrl}');
      AppLogger.candidate('   Symbol Image URL: ${updatedCandidate.extraInfo?.media}');

      AppLogger.candidate('📤 ChangePartySymbolScreen: Sending update to database...');
      // Update candidate in database
      await candidateRepository.updateCandidateExtraInfo(updatedCandidate);
      AppLogger.candidate('✅ ChangePartySymbolScreen: Database update successful');

      // Update the local candidate data to reflect changes immediately
      setState(() {
        _currentCandidate = updatedCandidate;
        isLoading = false;
      });

      AppLogger.candidate(
        '🎉 ChangePartySymbolScreen: Party and symbol update completed successfully',
      );

      // Show success message
      Get.snackbar(
        localizations.success,
        localizations.partyUpdateSuccess,
        duration: const Duration(seconds: 2),
      );

      // Small delay to ensure UI updates before navigation
      await Future.delayed(const Duration(milliseconds: 500));

      // Navigate back to previous screen (which should lead to home)
      AppLogger.candidate(
        '🔙 ChangePartySymbolScreen: Navigating back to previous screen',
      );
      if (mounted) {
        Get.back(result: updatedCandidate);
      }
    } catch (e) {
      AppLogger.candidateError(
        '💥 ChangePartySymbolScreen: Error updating party and symbol: $e',
      );
      setState(() {
        isLoading = false;
      });
      Get.snackbar(
        localizations.error,
        localizations.partyUpdateError(e.toString()),
      );
    }

    AppLogger.candidate('🏁 ChangePartySymbolScreen: Update process completed');
  }

  void _showPartySelectionModal(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.flag, color: Colors.blue, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      localizations.newPartyLabel,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.blue,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),

              // Party List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: parties.length,
                  itemBuilder: (context, index) {
                    final party = parties[index];
                    final isSelected = selectedParty?.id == party.id;

                    return InkWell(
                      onTap: () {
                        AppLogger.candidate(
                          '🎯 ChangePartySymbolScreen: Party selected from modal',
                        );
                        AppLogger.candidate('   Selected party: ${party.name}');
                        setState(() {
                          selectedParty = party;
                          isIndependent = party.name.toLowerCase().contains(
                            'independent',
                          );
                          AppLogger.candidate('   Is independent: $isIndependent');
                          if (!isIndependent) {
                            symbolNameController.clear();
                            symbolImageUrl = null;
                            AppLogger.candidate(
                              '   Cleared symbol data for non-independent party',
                            );
                          } else {
                            // Load existing symbol image URL for independent candidates
                            if (_currentCandidate!.extraInfo?.media !=
                                    null &&
                                _currentCandidate!
                                    .extraInfo!
                                    .media!
                                    .isNotEmpty) {
                              final symbolImageItem = _currentCandidate!
                                  .extraInfo!
                                  .media!
                                  .firstWhere(
                                    (item) => item['type'] == 'symbolImage',
                                    orElse: () => <String, dynamic>{},
                                  );
                              if (symbolImageItem.isNotEmpty) {
                                symbolImageUrl =
                                    symbolImageItem['url'] as String?;
                                AppLogger.candidate(
                                  '   Loaded existing symbol image URL for independent party',
                                );
                              }
                            }
                          }
                        });
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blue.shade50
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.blue.shade200
                                : Colors.grey.shade200,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.blue.shade100,
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            // Party Symbol
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(7),
                                child: Image(
                                  image: SymbolUtils.getSymbolImageProvider(
                                    SymbolUtils.getPartySymbolPathFromParty(
                                      party,
                                    ),
                                  ),
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey.shade100,
                                      child: const Icon(
                                        Icons.flag,
                                        size: 32,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),

                            const SizedBox(width: 16),

                            // Party Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    party.getDisplayName(
                                      Localizations.localeOf(
                                        context,
                                      ).languageCode,
                                    ),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Colors.blue.shade800
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    party.abbreviation,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Selection Indicator
                            if (isSelected)
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    AppLogger.candidate('🗑️ ChangePartySymbolScreen: Disposing screen');
    AppLogger.candidate(
      '   Final state - Party: ${selectedParty?.name ?? 'none'}, Symbol: ${symbolNameController.text}, Image: ${symbolImageUrl != null ? 'uploaded' : 'none'}',
    );
    symbolNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.changePartySymbolTitle),
        actions: [
          TextButton(
            onPressed: isLoading
                ? null
                : () {
                    AppLogger.candidate(
                      '🔘 ChangePartySymbolScreen: Update button pressed',
                    );
                    _updatePartyAndSymbol();
                  },
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    localizations.updateButton,
                    style: const TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  localizations.updatePartyAffiliationHeader,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  localizations.updatePartyAffiliationSubtitle,
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 32),

                // Current Party Display
                if (_currentCandidate != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info, color: Colors.blue),
                        const SizedBox(width: 12),
                        // Current Party Symbol
                        Container(
                          width: 32,
                          height: 32,
                          margin: const EdgeInsets.only(right: 12),
                          child: Image(
                            image: SymbolUtils.getSymbolImageProvider(
                              SymbolUtils.getPartySymbolPath(
                                _getCurrentPartyDisplayName(),
                              ),
                            ),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.flag,
                                size: 24,
                                color: Colors.grey,
                              );
                            },
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                localizations.currentParty,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1976D2),
                                ),
                              ),
                              Text(
                                _getCurrentPartyDisplayName(),
                                style: TextStyle(color: Color(0xFF1976D2)),
                              ),
                              if (_currentCandidate!.symbolName != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  localizations.symbolLabel(
                                    _getCurrentSymbolDisplayName(),
                                  ),
                                  style: TextStyle(
                                    color: Colors.blue.shade600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Party Selection with Custom Modal
                isLoadingParties
                    ? const CircularProgressIndicator()
                    : InkWell(
                        onTap: () => _showPartySelectionModal(context),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: localizations.newPartyLabel,
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.flag),
                            suffixIcon: const Icon(Icons.arrow_drop_down),
                          ),
                          child: selectedParty != null
                              ? Row(
                                  children: [
                                    // Selected Party Symbol
                                    Container(
                                      width: 32,
                                      height: 32,
                                      margin: const EdgeInsets.only(right: 12),
                                      child: Image(
                                        image: SymbolUtils.getSymbolImageProvider(
                                          SymbolUtils.getPartySymbolPathFromParty(
                                            selectedParty!,
                                          ),
                                        ),
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return const Icon(
                                                Icons.flag,
                                                size: 28,
                                                color: Colors.grey,
                                              );
                                            },
                                      ),
                                    ),
                                    // Selected Party Name
                                    Expanded(
                                      child: Text(
                                        selectedParty!.getDisplayName(
                                          Localizations.localeOf(
                                            context,
                                          ).languageCode,
                                        ),
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  localizations.selectPartyValidation,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                const SizedBox(height: 24),

                // Independent Symbol Fields
                if (isIndependent) ...[
                  // Symbol Name Field
                  TextFormField(
                    controller: symbolNameController,
                    decoration: InputDecoration(
                      labelText: localizations.symbolNameLabel,
                      hintText: localizations.symbolNameHint,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.label),
                    ),
                    validator: (value) {
                      if (isIndependent &&
                          (value == null || value.trim().isEmpty)) {
                        return localizations.symbolNameValidation;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Symbol Image Upload
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade50,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              localizations.symbolImageOptional,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Max 5MB',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          localizations.symbolImageDescription,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Supported formats: JPG, PNG. Maximum file size: 5MB.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            // Image Preview
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: isUploadingImage
                                  ? const Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : symbolImageUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.network(
                                        symbolImageUrl!,
                                        fit: BoxFit.cover,
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                              if (loadingProgress == null) {
                                                return child;
                                              }
                                              return const Center(
                                                child: SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                ),
                                              );
                                            },
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return const Icon(
                                                Icons.broken_image,
                                                color: Colors.grey,
                                                size: 30,
                                              );
                                            },
                                      ),
                                    )
                                  : Container(
                                      color: Colors.grey.shade100,
                                      child: const Icon(
                                        Icons.image,
                                        color: Colors.grey,
                                        size: 30,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 16),
                            // Upload Button
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: isUploadingImage
                                    ? null
                                    : () {
                                        AppLogger.candidate(
                                          '🔘 ChangePartySymbolScreen: Upload symbol image button pressed',
                                        );
                                        _pickSymbolImage();
                                      },
                                icon: isUploadingImage
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.upload),
                                label: Text(
                                  isUploadingImage
                                      ? 'Uploading...'
                                      : localizations.uploadSymbolImage,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isUploadingImage
                                      ? Colors.grey
                                      : Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (symbolImageUrl != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Image uploaded successfully',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Warning Text
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizations.importantNotice,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              localizations.partyChangeWarning,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Prominent Update Button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.blue.shade800],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade200,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _updatePartyAndSymbol,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                localizations.updatingText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.save,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                localizations.updateButton,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                // Additional Info Text
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    localizations.updateInstructionText,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

