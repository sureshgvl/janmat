import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../l10n/app_localizations.dart';
import '../../models/party_model.dart';
import '../../repositories/candidate_repository.dart';
import '../../repositories/party_repository.dart';
import '../../controllers/chat_controller.dart';
import '../../services/trial_service.dart';
import '../../utils/symbol_utils.dart';

class CandidateSetupScreen extends StatefulWidget {
  const CandidateSetupScreen({super.key});

  @override
  State<CandidateSetupScreen> createState() => _CandidateSetupScreenState();
}

class _CandidateSetupScreenState extends State<CandidateSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final candidateRepository = CandidateRepository();
  final partyRepository = PartyRepository();
  final chatController = Get.find<ChatController>();
  final trialService = TrialService();

  // Form controllers
  final nameController = TextEditingController();
  final partyController = TextEditingController();
  final manifestoController = TextEditingController();
  final symbolNameController = TextEditingController();

  Party? selectedParty;
  String? symbolImageUrl;
  bool isLoading = false;
  bool isIndependent = false;
  bool isLoadingParties = true;
  bool isUploadingImage = false;
  List<Party> parties = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadParties();
  }

  Future<void> _loadParties() async {
    try {
      final fetchedParties = await partyRepository.getActiveParties();
      setState(() {
        parties = fetchedParties;
        isLoadingParties = false;
      });
    } catch (e) {
      print('Error loading parties: $e');
      setState(() {
        isLoadingParties = false;
      });
    }
  }

  Future<void> _loadUserData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      // Load existing candidate data if available
      final existingCandidate = await candidateRepository.getCandidateData(currentUser.uid);
      if (existingCandidate != null) {
        // Pre-fill form with existing data
        nameController.text = existingCandidate.name;
        // Find the party by name from the loaded parties
        if (parties.isNotEmpty) {
          selectedParty = parties.firstWhere(
            (party) => party.name == existingCandidate.party,
            orElse: () => parties.first, // Default to first party if not found
          );
        }
        manifestoController.text = existingCandidate.manifesto ?? '';
      } else {
        // Fallback to user display name
        nameController.text = currentUser.displayName ?? '';
      }
    } catch (e) {
    debugPrint('Error loading candidate data: $e');
      // Fallback to user display name
      nameController.text = currentUser.displayName ?? '';
    }
  }

  Future<void> _createCandidateProfile(BuildContext context) async {
    final localizations = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) return;

    if (selectedParty == null) {
      Get.snackbar(localizations.error, localizations.pleaseSelectYourParty);
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get existing candidate data
    debugPrint('🔍 Candidate Setup: Looking for candidate data for user: ${currentUser.uid}');
      final existingCandidate = await candidateRepository.getCandidateData(currentUser.uid);
      if (existingCandidate == null) {
      debugPrint('❌ Candidate Setup: No candidate data found for user: ${currentUser.uid}');
        throw Exception('Candidate profile not found. Please complete your basic profile first.');
      }
    debugPrint('✅ Candidate Setup: Found candidate data: ${existingCandidate.name}, ID: ${existingCandidate.candidateId}');

      // Update candidate with additional details
      final updatedCandidate = existingCandidate.copyWith(
        name: nameController.text.trim(),
        party: selectedParty!.name,
        symbol: isIndependent ? symbolNameController.text.trim() : null,
        manifesto: manifestoController.text.trim().isNotEmpty
            ? manifestoController.text.trim()
            : null,
      );

      // Update candidate in hierarchical structure
      await candidateRepository.updateCandidateExtraInfo(updatedCandidate);

      // Update user role to candidate (in case it wasn't set)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({
            'role': 'candidate',
            'candidateId': existingCandidate.candidateId,
          });

      // Start 3-day free trial for new candidate
      try {
        await trialService.startTrialForCandidate(currentUser.uid);
      debugPrint('✅ Started 3-day trial for new candidate');
      } catch (e) {
      debugPrint('⚠️ Failed to start trial, but candidate profile created: $e');
        // Don't fail the entire process if trial start fails
      }

      // Create candidate's personal chat room
      try {
        await chatController.createCandidateChatRoom(currentUser.uid, nameController.text.trim());
      debugPrint('✅ Candidate personal chat room created');
      } catch (e) {
      debugPrint('⚠️ Failed to create candidate chat room: $e');
        // Don't fail the entire process if room creation fails
      }

      // Refresh user data
      await chatController.refreshUserDataAndChat();

      Get.snackbar(
        localizations.candidateProfileUpdated,
        localizations.candidateProfileUpdatedMessage,
        duration: const Duration(seconds: 4),
      );

      // Navigate to home (trial will be active)
      Get.offAllNamed('/home');

    } catch (e) {
      Get.snackbar(localizations.error, localizations.failedToCreateCandidateProfile(e.toString()));
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _pickSymbolImage() async {
    setState(() {
      isUploadingImage = true;
    });

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        // Check image file size (5MB limit)
        final file = File(image.path);
        final fileSize = await file.length();
        const maxSizeInBytes = 5 * 1024 * 1024; // 5MB

        if (fileSize > maxSizeInBytes) {
          final localizations = AppLocalizations.of(context)!;
          Get.snackbar(localizations.error, localizations.imageSizeMustBeLessThan5MB);
          setState(() {
            isUploadingImage = false;
          });
          return;
        }

        // Upload to Firebase Storage
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          setState(() {
            isUploadingImage = false;
          });
          return;
        }

        final storageRef = FirebaseStorage.instance
            .ref()
            .child('candidate_symbols')
            .child('${currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');

        final uploadTask = storageRef.putFile(File(image.path));
        final snapshot = await uploadTask.whenComplete(() => null);

        final downloadUrl = await snapshot.ref.getDownloadURL();

        setState(() {
          symbolImageUrl = downloadUrl;
          isUploadingImage = false;
        });

        final localizations = AppLocalizations.of(context)!;
        Get.snackbar(localizations.success, localizations.symbolImageUploadedSuccessfully);
      } else {
        setState(() {
          isUploadingImage = false;
        });
      }
    } catch (e) {
      setState(() {
        isUploadingImage = false;
      });
      final localizations = AppLocalizations.of(context)!;
      Get.snackbar(localizations.error, localizations.failedToUploadSymbolImage(e.toString()));
    }
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
                    const Icon(
                      Icons.flag,
                      color: Colors.blue,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      localizations.politicalPartyRequired,
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
                        setState(() {
                          selectedParty = party;
                          isIndependent = party.name.toLowerCase().contains('independent');
                          if (!isIndependent) {
                            symbolNameController.clear();
                            symbolImageUrl = null;
                          }
                        });
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue.shade50 : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? Colors.blue.shade200 : Colors.grey.shade200,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.blue.shade100,
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            // Party Symbol
                            Container(
                              width: 100,
                              height: 100,
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
                                    SymbolUtils.getPartySymbolPathFromParty(party)
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
                                    party.getDisplayName(Localizations.localeOf(context).languageCode),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? Colors.blue.shade800 : Colors.black87,
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
    nameController.dispose();
    partyController.dispose();
    manifestoController.dispose();
    symbolNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.completeCandidateProfile),
        automaticallyImplyLeading: false,
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
                  localizations.completeYourCandidateProfile,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  localizations.fillDetailsCreateCandidateProfile,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 32),

                // Name Field
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: localizations.fullNameRequired,
                    hintText: localizations.enterFullNameAsOnBallot,
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return localizations.pleaseEnterYourName;
                    }
                    if (value.trim().length < 2) {
                      return localizations.nameMustBeAtLeast2Characters;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Party Selection with Custom Modal
                isLoadingParties
                    ? const CircularProgressIndicator()
                    : InkWell(
                        onTap: () => _showPartySelectionModal(context),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: localizations.politicalPartyRequired,
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
                                          SymbolUtils.getPartySymbolPathFromParty(selectedParty!)
                                        ),
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) {
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
                                        selectedParty!.getDisplayName(Localizations.localeOf(context).languageCode),
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  localizations.pleaseSelectYourPoliticalParty,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                const SizedBox(height: 24),

                // Independent Symbol Fields (only show when Independent is selected)
                if (isIndependent) ...[
                  // Symbol Name Field
                  TextFormField(
                    controller: symbolNameController,
                    decoration: InputDecoration(
                      labelText: localizations.symbolNameRequired,
                      hintText: localizations.symbolNameHint,
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.label),
                    ),
                    validator: (value) {
                      if (isIndependent && (value == null || value.trim().isEmpty)) {
                        return localizations.pleaseEnterSymbolNameForIndependent;
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
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                localizations.max5MB,
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
                          localizations.uploadImageOfChosenSymbol,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          localizations.supportedFormatsJPGPNGMax5MB,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
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
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return const Center(
                                                child: SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                  ),
                                                ),
                                              );
                                            },
                                            errorBuilder: (context, error, stackTrace) {
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
                                onPressed: isUploadingImage ? null : _pickSymbolImage,
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
                                      ? localizations.uploading
                                      : localizations.uploadSymbolImage,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isUploadingImage ? Colors.grey : Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
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
                                localizations.imageUploadedSuccessfully,
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

                // Manifesto Field
                TextFormField(
                  controller: manifestoController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: localizations.manifestoOptional,
                    hintText: localizations.brieflyDescribeKeyPromises,
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  validator: (value) {
                    // Manifesto is optional, so no validation needed
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Info Text
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            localizations.whatHappensNext,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        localizations.candidateProfileBenefits,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () => _createCandidateProfile(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            localizations.updateCandidateProfile,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Back to Role Selection
                Center(
                  child: TextButton(
                    onPressed: () {
                      Get.offAllNamed('/role-selection');
                    },
                    child: Text(localizations.changeRoleSelection),
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