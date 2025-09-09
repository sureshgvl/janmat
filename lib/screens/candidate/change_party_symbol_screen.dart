import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../l10n/app_localizations.dart';
import '../../models/candidate_model.dart';
import '../../models/party_model.dart';
import '../../repositories/candidate_repository.dart';
import '../../repositories/party_repository.dart';

class ChangePartySymbolScreen extends StatefulWidget {
  final Candidate? currentCandidate;
  final User? currentUser;

  const ChangePartySymbolScreen({
    super.key,
    required this.currentCandidate,
    required this.currentUser,
  });

  @override
  State<ChangePartySymbolScreen> createState() => _ChangePartySymbolScreenState();
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
  List<Party> parties = [];
  bool isIndependent = false;

  @override
  void initState() {
    super.initState();
    _loadParties();
    _loadCurrentData();
  }

  void _loadCurrentData() {
    if (widget.currentCandidate != null) {
      // Find current party
      if (parties.isNotEmpty) {
        selectedParty = parties.firstWhere(
          (party) => party.name == widget.currentCandidate!.party,
          orElse: () => parties.first,
        );
      }

      // Load symbol data
      if (widget.currentCandidate!.symbol != null) {
        symbolNameController.text = widget.currentCandidate!.symbol!;
      }

      isIndependent = widget.currentCandidate!.party.toLowerCase().contains('independent');
    }
  }

  Future<void> _loadParties() async {
    try {
      print('🚀 ChangePartySymbolScreen: Starting to load parties...');
      final fetchedParties = await partyRepository.getActiveParties();
      print('📦 ChangePartySymbolScreen: Received ${fetchedParties.length} parties');

      if (mounted) {
        setState(() {
          parties = fetchedParties;
          isLoadingParties = false;
        });
        print('✅ ChangePartySymbolScreen: Parties loaded successfully, calling _loadCurrentData()');
        _loadCurrentData(); // Reload current data now that parties are loaded
      } else {
        print('⚠️ ChangePartySymbolScreen: Widget not mounted, skipping setState');
      }
    } catch (e) {
      print('❌ ChangePartySymbolScreen: Error loading parties: $e');
      if (mounted) {
        setState(() {
          isLoadingParties = false;
        });
      }
    }
  }

  String _getCurrentPartyDisplayName() {
    if (widget.currentCandidate == null) return '';

    // Find the party object from the parties list
    final currentParty = parties.firstWhere(
      (party) => party.name == widget.currentCandidate!.party,
      orElse: () => Party(
        id: 'unknown',
        name: widget.currentCandidate!.party,
        nameMr: widget.currentCandidate!.party,
        abbreviation: '',
      ),
    );

    // Return the display name based on current locale
    return currentParty.getDisplayName(Localizations.localeOf(context).languageCode);
  }

  String _getCurrentSymbolDisplayName() {
    if (widget.currentCandidate == null || widget.currentCandidate!.symbol == null) return '';

    return widget.currentCandidate!.symbol!;
  }

  Future<void> _pickSymbolImage() async {
    final localizations = AppLocalizations.of(context)!;

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        // Upload to Firebase Storage
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) return;

        final storageRef = FirebaseStorage.instance
            .ref()
            .child('candidate_symbols')
            .child('${currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');

        final uploadTask = storageRef.putFile(File(image.path));
        final snapshot = await uploadTask.whenComplete(() => null);

        final downloadUrl = await snapshot.ref.getDownloadURL();

        setState(() {
          symbolImageUrl = downloadUrl;
        });

        Get.snackbar(localizations.success, localizations.symbolUploadSuccess);
      }
    } catch (e) {
      Get.snackbar(localizations.error, localizations.symbolUploadError(e.toString()));
    }
  }

  Future<void> _updatePartyAndSymbol() async {
    final localizations = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) return;

    if (selectedParty == null) {
      Get.snackbar(localizations.error, localizations.selectPartyValidation);
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

      if (widget.currentCandidate == null) {
        throw Exception('Candidate data not found');
      }

      // Update candidate with new party and symbol
      final updatedCandidate = widget.currentCandidate!.copyWith(
        party: selectedParty!.name,
        symbol: isIndependent ? symbolNameController.text.trim() : null,
      );

      // Update candidate in database
      await candidateRepository.updateCandidateExtraInfo(updatedCandidate);

      // Update the local candidate data to reflect changes immediately
      setState(() {
        // Update the current candidate with new party and symbol
        // This will refresh the current party display
      });

      Get.snackbar(
        localizations.success,
        localizations.partyUpdateSuccess,
        duration: const Duration(seconds: 3),
      );

      // Navigate back to refresh the parent screen
      Get.back(result: updatedCandidate);

    } catch (e) {
      Get.snackbar(localizations.error, localizations.partyUpdateError(e.toString()));
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
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
            onPressed: isLoading ? null : _updatePartyAndSymbol,
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
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 32),

                // Current Party Display
                if (widget.currentCandidate != null) ...[
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
                                style: TextStyle(
                                  color: Color(0xFF1976D2),
                                ),
                              ),
                              if (widget.currentCandidate!.symbol != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  localizations.symbolLabel(_getCurrentSymbolDisplayName()),
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

                // Party Selection
                isLoadingParties
                    ? const CircularProgressIndicator()
                    : DropdownButtonFormField<Party>(
                        value: selectedParty,
                        decoration: InputDecoration(
                          labelText: localizations.newPartyLabel,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.flag),
                        ),
                        items: parties.map((party) {
                          return DropdownMenuItem<Party>(
                            value: party,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 250),
                              child: Text(
                                party.getDisplayName(Localizations.localeOf(context).languageCode),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedParty = value;
                            isIndependent = value?.name.toLowerCase().contains('independent') ?? false;
                            if (!isIndependent) {
                              symbolNameController.clear();
                              symbolImageUrl = null;
                            }
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return localizations.selectPartyValidation;
                          }
                          return null;
                        },
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
                      if (isIndependent && (value == null || value.trim().isEmpty)) {
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
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.symbolImageOptional,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          localizations.symbolImageDescription,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            if (symbolImageUrl != null)
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: NetworkImage(symbolImageUrl!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                            else
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.image,
                                  color: Colors.grey,
                                  size: 30,
                                ),
                              ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _pickSymbolImage,
                                icon: const Icon(Icons.upload),
                                label: Text(localizations.uploadSymbolImage),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
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