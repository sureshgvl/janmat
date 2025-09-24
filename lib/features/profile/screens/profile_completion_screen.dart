import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../chat/controllers/chat_controller.dart';
import '../../../models/user_model.dart';
import '../../../models/ward_model.dart';
import '../../../models/state_model.dart' as state_model;
import '../../candidate/models/candidate_model.dart';
import '../../candidate/models/candidate_party_model.dart';
import '../../../models/district_model.dart';
import '../../../models/body_model.dart';
import '../../candidate/repositories/candidate_repository.dart';
import '../../candidate/repositories/candidate_party_repository.dart';
import '../../../utils/symbol_utils.dart';
import '../../../utils/add_sample_states.dart';
import '../../../widgets/profile/state_selection_modal.dart';
import '../../../widgets/profile/district_selection_modal.dart';
import '../../../widgets/profile/area_selection_modal.dart';
import '../../../widgets/profile/area_in_ward_selection_modal.dart';
import '../../../widgets/profile/party_selection_modal.dart';
import '../../../widgets/profile/ward_selection_modal.dart';
import '../../../utils/add_sample_states.dart';

class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  State<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  // User data passed from main.dart to avoid duplicate Firebase call
  Map<String, dynamic>? _passedUserData;
  bool _profileCompleted = false;

  final _formKey = GlobalKey<FormState>();
  final loginController = Get.find<AuthController>();
  final chatController = Get.find<ChatController>();
  final candidateRepository = CandidateRepository();
  final partyRepository = PartyRepository();

  // Form controllers
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final birthDateController = TextEditingController();
  DateTime? selectedBirthDate;
  String? selectedGender;
  String? selectedStateId;
  String? selectedDistrictId;
  String? selectedBodyId;
  Ward? selectedWard;
  String? selectedArea;
  Party? selectedParty;

  List<District> districts = [];
  Map<String, List<Body>> districtBodies = {};
  Map<String, List<Ward>> bodyWards = {};
  List<Party> parties = [];
  List<state_model.State> states = [];
  bool isLoading = false;
  bool isLoadingDistricts = true;
  bool isLoadingParties = true;
  bool isLoadingStates = true;
  bool _isNamePreFilled = false;
  bool _isPhonePreFilled = false;
  String? currentUserRole;

  @override
  void initState() {
    super.initState();

    // Get user data passed from main.dart
    final args = Get.arguments;
    if (args is Map<String, dynamic> && args.containsKey('userData')) {
      _passedUserData = args['userData'];
      _profileCompleted = _passedUserData?['profileCompleted'] ?? false;

      debugPrint(
        '📥 Received user data from main.dart: profileCompleted = $_profileCompleted',
      );

      // If profile is already completed, navigate to home immediately
      if (_profileCompleted) {
        debugPrint(
          '✅ Profile already completed (from passed data), navigating to home',
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.offAllNamed('/home');
        });
        return;
      }
    } else {
      // Fallback: fetch user data if not passed (for direct navigation)
      debugPrint('⚠️ No user data passed, falling back to Firebase fetch');
      _checkProfileCompletion();
    }

    // Continue with normal initialization
    // Add a small delay to ensure Firebase auth is fully initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _loadStates();
        _loadDistricts();
        _loadParties();
        _loadUserRole();
        _preFillUserData();
      });
    });
  }

  // Check if profile is already completed and navigate accordingly
  Future<void> _checkProfileCompletion() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        final profileCompleted = userData?['profileCompleted'] ?? false;

        if (profileCompleted) {
          // Profile is already completed, navigate to home
          debugPrint('✅ Profile already completed, navigating to home');
          Get.offAllNamed('/home');
          return;
        }
      }

      // Profile not completed, continue with normal flow
      debugPrint('📝 Profile not completed, showing completion screen');
    } catch (e) {
      debugPrint('⚠️ Error checking profile completion: $e');
      // Continue with normal flow if there's an error
    }
  }

  // Pre-fill user data from Firebase Auth
  void _preFillUserData() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Pre-fill name from display name (Google login) or email prefix
    if (currentUser.displayName != null &&
        currentUser.displayName!.isNotEmpty) {
      nameController.text = currentUser.displayName!;
      _isNamePreFilled = true;
    } else if (currentUser.email != null && currentUser.email!.isNotEmpty) {
      // Extract name from email (before @)
      final emailPrefix = currentUser.email!.split('@').first;
      // Capitalize first letter of each word
      final nameParts = emailPrefix.split('.');
      final formattedName = nameParts
          .map((part) {
            if (part.isNotEmpty) {
              return part[0].toUpperCase() + part.substring(1).toLowerCase();
            }
            return part;
          })
          .join(' ');
      nameController.text = formattedName;
      _isNamePreFilled = true;
    }

    // Pre-fill phone number from Firebase Auth (remove +91 prefix for display)
    if (currentUser.phoneNumber != null &&
        currentUser.phoneNumber!.isNotEmpty) {
      phoneController.text = currentUser.phoneNumber!.replaceFirst('+91', '');
      _isPhonePreFilled = true;
    }

    debugPrint('🔍 Pre-filled user data:');
    debugPrint(
      '  Name: ${nameController.text} (${_isNamePreFilled ? 'from auth' : 'manual'})',
    );
    debugPrint(
      '  Phone: ${phoneController.text} (${_isPhonePreFilled ? 'from auth' : 'manual'})',
    );
    debugPrint('  Email: ${currentUser.email}');
    debugPrint('  Photo: ${currentUser.photoURL}');

    // Trigger rebuild to show helper text
    setState(() {});
  }

  // Build input decoration with dynamic helper text
  InputDecoration _buildInputDecoration(
    BuildContext context, {
    required String label,
    required String hint,
    required IconData icon,
    bool showPreFilledHelper = false,
  }) {
    final localizations = AppLocalizations.of(context)!;

    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: const OutlineInputBorder(),
      prefixIcon: Icon(icon),
      helperText: showPreFilledHelper
          ? localizations.autoFilledFromAccount
          : null,
      helperStyle: const TextStyle(color: Colors.blue, fontSize: 12),
    );
  }


  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    birthDateController.dispose();
    super.dispose();
  }

  Future<void> _loadStates() async {
    try {
      debugPrint('🔍 Loading states from Firestore');

      // Load states from Firestore
      final statesSnapshot = await FirebaseFirestore.instance
          .collection('states')
          .get();

      debugPrint(
        '📊 Found ${statesSnapshot.docs.length} states in Firestore',
      );

      // If no states found, add sample states
      if (statesSnapshot.docs.isEmpty) {
        debugPrint('⚠️ No states found in database, adding sample states...');
        try {
          await SampleStatesManager.addSampleStates();
          await SampleStatesManager.addSampleDistrictsForMaharashtra();

          // Reload states after adding samples
          final updatedSnapshot = await FirebaseFirestore.instance
              .collection('states')
              .get();

          states = updatedSnapshot.docs.map((doc) {
            final data = doc.data();
            debugPrint('🏛️ State: ${doc.id} - ${data['name'] ?? 'Unknown'}');
            return state_model.State.fromJson({'stateId': doc.id, ...data});
          }).toList();

          debugPrint('✅ Sample states added and loaded successfully');
        } catch (e) {
          debugPrint('❌ Failed to add sample states: $e');
          // Continue with empty states list
          states = [];
        }
      } else {
        states = statesSnapshot.docs.map((doc) {
          final data = doc.data();
          debugPrint('🏛️ State: ${doc.id} - ${data['name'] ?? 'Unknown'} - Marathi: ${data['marathiName']} - Code: ${data['code']}');
          return state_model.State.fromJson({'stateId': doc.id, ...data});
        }).toList();
      }

      // Set default state to Maharashtra if available
      final maharashtraState = states.firstWhere(
        (state) => state.name == 'Maharashtra',
        orElse: () => states.isNotEmpty ? states.first : state_model.State(stateId: '', name: ''),
      );

      if (maharashtraState.stateId.isNotEmpty) {
        selectedStateId = maharashtraState.stateId;
        debugPrint('✅ Default state set to: ${maharashtraState.name}');
      }

      setState(() {
        isLoadingStates = false;
      });

      debugPrint('✅ Successfully loaded ${states.length} states');
    } catch (e) {
      debugPrint('❌ Failed to load states: $e');
      Get.snackbar('Error', 'Failed to load states: $e');
      setState(() {
        isLoadingStates = false;
      });
    }
  }

  Future<void> _loadDistricts() async {
    const int maxRetries = 3;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        // Ensure user is authenticated before making the query
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          debugPrint(
            '⚠️ No authenticated user found, waiting for authentication...',
          );
          // Wait for authentication to be established
          await Future.delayed(const Duration(seconds: 2));
          final retryUser = FirebaseAuth.instance.currentUser;
          if (retryUser == null) {
            throw Exception('User not authenticated');
          }
        }

        debugPrint(
          '🔍 Loading districts for user: ${currentUser?.uid} (attempt ${retryCount + 1})',
        );

        // Load districts from Firestore (state-based structure)
        if (selectedStateId == null) {
          throw Exception('No state selected');
        }

        final districtsSnapshot = await FirebaseFirestore.instance
            .collection('states')
            .doc(selectedStateId!)
            .collection('districts')
            .get();

        debugPrint(
          '📊 Found ${districtsSnapshot.docs.length} districts in Firestore',
        );

        districts = districtsSnapshot.docs.map((doc) {
          final data = doc.data();
          debugPrint('🏙️ District: ${doc.id} - ${data['name'] ?? 'Unknown'}');
          return District.fromJson({'districtId': doc.id, ...data});
        }).toList();

        // Load bodies for each district
        for (final district in districts) {
          final bodiesSnapshot = await FirebaseFirestore.instance
              .collection('states')
              .doc(selectedStateId!)
              .collection('districts')
              .doc(district.districtId)
              .collection('bodies')
              .get();

          debugPrint(
            '📊 Found ${bodiesSnapshot.docs.length} bodies in district ${district.districtId}',
          );

          districtBodies[district.districtId] = bodiesSnapshot.docs.map((doc) {
            final data = doc.data();
            debugPrint(
              '🏢 Body: ${doc.id} - ${data['name'] ?? 'Unknown'} (${data['type'] ?? 'Unknown'})',
            );
            return Body.fromJson({
              'bodyId': doc.id,
              'districtId': district.districtId,
              ...data,
            });
          }).toList();
        }

        setState(() {
          isLoadingDistricts = false;
        });

        debugPrint(
          '✅ Successfully loaded ${districts.length} districts with bodies',
        );
        return; // Success, exit the retry loop
      } catch (e) {
        retryCount++;
        debugPrint('❌ Failed to load districts (attempt $retryCount): $e');

        if (retryCount < maxRetries) {
          debugPrint('🔄 Retrying in ${retryCount * 2} seconds...');
          await Future.delayed(Duration(seconds: retryCount * 2));
        } else {
          // Final attempt failed
          debugPrint('❌ All retry attempts failed for loading districts');
          // For now, keep the error message in English since we don't have context here
          Get.snackbar(
            'Error',
            'Failed to load districts after $maxRetries attempts: $e',
          );
          setState(() {
            isLoadingDistricts = false;
          });
        }
      }
    }
  }

  Future<void> _loadParties() async {
    try {
      parties = await partyRepository.getActiveParties();
      setState(() {
        isLoadingParties = false;
      });
    } catch (e) {
      Get.snackbar('Error', 'Failed to load parties: $e');
      setState(() {
        isLoadingParties = false;
      });
    }
  }

  Future<void> _loadUserRole() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      setState(() {
        currentUserRole = userDoc.data()?['role'] ?? 'voter';
      });
    } catch (e) {
      debugPrint('Error loading user role: $e');
      setState(() {
        currentUserRole = 'voter';
      });
    }
  }

  Future<void> _loadWards(
    String districtId,
    String bodyId,
    BuildContext context,
  ) async {
    final localizations = AppLocalizations.of(context)!;

    try {
      final wards = await candidateRepository.getWardsByDistrictAndBody(
        districtId,
        bodyId,
      );
      bodyWards[bodyId] = wards;
      setState(() {});
    } catch (e) {
      Get.snackbar(
        localizations.error,
        localizations.failedToLoadWards(e.toString()),
      );
    }
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(
        const Duration(days: 365 * 18),
      ), // 18 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(
        const Duration(days: 365 * 13),
      ), // 13 years ago (minimum age)
    );

    if (picked != null) {
      setState(() {
        selectedBirthDate = picked;
        birthDateController.text =
            '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  void _showStateSelectionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StateSelectionModal(
          states: states,
          selectedStateId: selectedStateId,
          onStateSelected: (stateId) {
            setState(() {
              selectedStateId = stateId;
              selectedDistrictId = null;
              selectedBodyId = null;
              selectedWard = null;
              districts.clear();
              districtBodies.clear();
              bodyWards.clear();
              isLoadingDistricts = true;
            });
            // Reload districts for the selected state
            _loadDistricts();
          },
        );
      },
    );
  }

  void _showDistrictSelectionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DistrictSelectionModal(
          districts: districts,
          districtBodies: districtBodies,
          selectedDistrictId: selectedDistrictId,
          onDistrictSelected: (districtId) {
            setState(() {
              selectedDistrictId = districtId;
              selectedBodyId = null;
              selectedWard = null;
              bodyWards.clear();
            });
          },
        );
      },
    );
  }

  void _showBodySelectionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return AreaSelectionModal(
          bodies: districtBodies[selectedDistrictId!]!,
          selectedBodyId: selectedBodyId,
          onBodySelected: (bodyId) {
            setState(() {
              selectedBodyId = bodyId;
              selectedWard = null;
              bodyWards.clear();
            });
            _loadWards(selectedDistrictId!, bodyId, context);
          },
        );
      },
    );
  }

  void _showWardSelectionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return WardSelectionModal(
          wards: bodyWards[selectedBodyId!] ?? [],
          selectedWardId: selectedWard?.wardId,
          onWardSelected: (wardId) {
            final ward = bodyWards[selectedBodyId!]!.firstWhere(
              (w) => w.wardId == wardId,
            );
            setState(() {
              selectedWard = ward;
              selectedArea = null; // Reset area when ward changes
            });
          },
        );
      },
    );
  }

  void _showAreaSelectionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return AreaInWardSelectionModal(
          ward: selectedWard!,
          selectedArea: selectedArea,
          onAreaSelected: (area) {
            setState(() {
              selectedArea = area;
            });
          },
        );
      },
    );
  }

  void _showPartySelectionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return PartySelectionModal(
          parties: parties,
          selectedPartyId: selectedParty?.id,
          onPartySelected: (partyId) {
            setState(() {
              selectedParty = parties.firstWhere(
                (party) => party.id == partyId,
              );
            });
          },
        );
      },
    );
  }


  Future<void> _saveProfile(BuildContext context) async {
    final localizations = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) return;

    if (selectedStateId == null ||
        selectedDistrictId == null ||
        selectedBodyId == null ||
        selectedWard == null ||
        selectedGender == null) {
      Get.snackbar(
        localizations.error,
        localizations.pleaseFillAllRequiredFields,
      );
      return;
    }

    // Check if area selection is required and selected (only for non-candidates)
    if (currentUserRole != 'candidate' &&
        selectedWard!.areas != null &&
        selectedWard!.areas!.isNotEmpty &&
        selectedArea == null) {
      Get.snackbar(localizations.error, localizations.selectYourArea);
      return;
    }

    // For candidates, party selection is required
    if (currentUserRole == 'candidate' && selectedParty == null) {
      Get.snackbar(
        localizations.error,
        localizations.pleaseSelectYourPoliticalParty,
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get current user role from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final currentRole = userDoc.data()?['role'] ?? 'voter';


      // Create updated user model
      final updatedUser = UserModel(
        uid: currentUser.uid,
        name: nameController.text.trim(),
        phone: '+91${phoneController.text.trim()}',
        email: currentUser.email,
        role: currentRole,
        roleSelected: true,
        profileCompleted: true,
        districtId: selectedDistrictId!,
        stateId: selectedStateId!,
        bodyId: selectedBodyId!,
        wardId: selectedWard!.wardId,
        area: selectedArea,
        xpPoints: 0,
        premium: false,
        createdAt: DateTime.now(),
        photoURL: currentUser.photoURL,
      );

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .set({
            ...updatedUser.toJson(),
            'birthDate': selectedBirthDate?.toIso8601String(),
            'gender': selectedGender,
            'area': selectedArea, // Save selected area
            'profileCompleted': true,
          });

      // Refresh chat controller with new user data (creates ward rooms only for candidates)
      try {
        await chatController.refreshUserDataAndChat();
        debugPrint(
          '✅ Chat data refreshed successfully for user: ${currentUser.uid}',
        );
      } catch (e) {
        debugPrint('⚠️ Failed to refresh chat data, but profile saved: $e');
        // Don't fail the entire process if chat refresh fails
      }

      // If user is a candidate, create basic candidate record immediately
      if (currentRole == 'candidate') {
        try {
          // Calculate age from birthdate
          int? age;
          if (selectedBirthDate != null) {
            final now = DateTime.now();
            age = now.year - selectedBirthDate!.year;
            if (now.month < selectedBirthDate!.month ||
                (now.month == selectedBirthDate!.month &&
                    now.day < selectedBirthDate!.day)) {
              age--;
            }
          }

          // Create basic candidate record with birthdate, gender, and selected party
           final candidate = Candidate(
             candidateId: 'temp_${currentUser.uid}', // Temporary ID
             userId: currentUser.uid,
             name: nameController.text.trim(),
             party: selectedParty!.id, // Use selected party key
            districtId: selectedDistrictId!,
            stateId: selectedStateId!,
            bodyId: selectedBodyId!,
            wardId: selectedWard!.wardId,
            contact: Contact(
              phone: '+91${phoneController.text.trim()}',
              email: currentUser.email,
            ),
            sponsored: false,
            premium: false,
            createdAt: DateTime.now(),
            manifesto: null, // Can be updated later in dashboard
            extraInfo: ExtraInfo(
              basicInfo: BasicInfoData(
                fullName: nameController.text.trim(),
                dateOfBirth: selectedBirthDate?.toIso8601String(),
                age: age,
                gender: selectedGender,
              ),
            ),
          );

          // Save basic candidate record to make them visible to voters
          debugPrint(
            '🏗️ Profile Completion: Creating candidate record for ${candidate.name}',
          );
          debugPrint(
            '   District: ${candidate.districtId}, Body: ${candidate.bodyId}, Ward: ${candidate.wardId}',
          );
          debugPrint('   Temp ID: ${candidate.candidateId}');
          //create candidate and get actual ID
          final actualCandidateId = await candidateRepository.createCandidate(
            candidate,
          );

          // here we have to create candidate chat room as well
          chatController.createCandidateChatRoom(
            actualCandidateId,
            candidate.name,
          );
          debugPrint(
            '✅ Basic candidate record created with ID: $actualCandidateId',
          );

          // Update user document with the actual candidateId
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .update({'candidateId': actualCandidateId});
          debugPrint(
            '✅ User document updated with candidateId: $actualCandidateId',
          );
        } catch (e) {
          debugPrint('⚠️ Failed to create basic candidate record: $e');
          // Continue with navigation even if candidate creation fails
        }
      }

      // Navigate to home for all users (streamlined flow)
      Get.offAllNamed('/home');
      if (currentRole == 'candidate') {
        Get.snackbar(
          localizations.profileCompleted,
          'Profile completed! You can update your manifesto and other details from your dashboard.',
          duration: const Duration(seconds: 4),
        );
      } else {
        // For voters, don't mention ward chat creation since they don't create rooms
        Get.snackbar(
          localizations.success,
          localizations.profileCompleted,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      Get.snackbar(
        localizations.error,
        localizations.failedToSaveProfile(e.toString()),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.completeYourProfile),
        automaticallyImplyLeading: false, // Prevent back button
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
                  localizations.welcomeCompleteYourProfile,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final currentUser = FirebaseAuth.instance.currentUser;
                    String loginMethod = localizations.autoFilledFromAccount;

                    if (currentUser?.providerData.isNotEmpty ?? false) {
                      final provider = currentUser!.providerData.first;
                      if (provider.providerId == 'google.com') {
                        loginMethod = 'Google account';
                      } else if (provider.providerId == 'phone') {
                        loginMethod = 'phone number';
                      }
                    }

                    return Text(
                      localizations.preFilledFromAccount(loginMethod),
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    );
                  },
                ),
                const SizedBox(height: 16),


                // Name Field
                TextFormField(
                  controller: nameController,
                  decoration: _buildInputDecoration(
                    context,
                    label: localizations.fullNameRequired,
                    hint: localizations.enterYourFullName,
                    icon: Icons.person,
                    showPreFilledHelper: _isNamePreFilled,
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

                // Phone Field
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: _buildInputDecoration(
                    context,
                    label: localizations.phoneNumberRequired,
                    hint: localizations.enterYourPhoneNumber,
                    icon: Icons.phone,
                    showPreFilledHelper: _isPhonePreFilled,
                  ).copyWith(prefixText: '+91 '),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return localizations.pleaseEnterYourPhoneNumber;
                    }
                    if (value.trim().length != 10) {
                      return localizations.phoneNumberMustBe10Digits;
                    }
                    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value.trim())) {
                      return localizations.pleaseEnterValidPhoneNumber;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Birth Date Field
                TextFormField(
                  controller: birthDateController,
                  readOnly: true,
                  onTap: () => _selectBirthDate(context),
                  decoration: InputDecoration(
                    labelText: localizations.birthDateRequired,
                    hintText: localizations.selectYourBirthDate,
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  validator: (value) {
                    if (selectedBirthDate == null) {
                      return localizations.pleaseSelectYourBirthDate;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Gender Selection
                DropdownButtonFormField<String>(
                  initialValue: selectedGender,
                  decoration: InputDecoration(
                    labelText: localizations.genderRequired,
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.people),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'Male',
                      child: Text(localizations.male),
                    ),
                    DropdownMenuItem(
                      value: 'Female',
                      child: Text(localizations.female),
                    ),
                    DropdownMenuItem(
                      value: 'Other',
                      child: Text(localizations.other),
                    ),
                    DropdownMenuItem(
                      value: 'Prefer Not to Say',
                      child: Text(localizations.preferNotToSay),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedGender = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return localizations.pleaseSelectYourGender;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // State Selection
                if (isLoadingStates)
                  const Center(child: CircularProgressIndicator())
                else
                  InkWell(
                    onTap: () => _showStateSelectionModal(context),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: localizations.stateRequired,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.map),
                        suffixIcon: const Icon(Icons.arrow_drop_down),
                      ),
                      child: selectedStateId != null
                          ? Builder(
                              builder: (context) {
                                final selectedState = states.firstWhere(
                                  (state) => state.stateId == selectedStateId,
                                );
                                // Show Marathi name if available, otherwise English name
                                final displayName = selectedState.marathiName ?? selectedState.name;
                                return Text(
                                  displayName,
                                  style: const TextStyle(fontSize: 16),
                                );
                              },
                            )
                          : const Text(
                              'Select State',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                const SizedBox(height: 24),

                // District Selection
                if (selectedStateId == null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_city, color: Colors.grey),
                        const SizedBox(width: 12),
                        Text(
                          localizations.selectStateFirst,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (isLoadingDistricts)
                  const Center(child: CircularProgressIndicator())
                else
                  InkWell(
                    onTap: () => _showDistrictSelectionModal(context),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: localizations.districtRequired,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.location_city),
                        suffixIcon: const Icon(Icons.arrow_drop_down),
                      ),
                      child: selectedDistrictId != null
                          ? Text(
                              districts
                                  .firstWhere(
                                    (d) => d.districtId == selectedDistrictId,
                                  )
                                  .name,
                              style: const TextStyle(fontSize: 16),
                            )
                          : Text(
                              localizations.selectYourDistrict,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                const SizedBox(height: 24),

                // Area Selection
                if (selectedStateId != null &&
                    selectedDistrictId != null &&
                    districtBodies[selectedDistrictId!] != null &&
                    districtBodies[selectedDistrictId!]!.isNotEmpty)
                  InkWell(
                    onTap: () => _showBodySelectionModal(context),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Area (विभाग) *',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.business),
                        suffixIcon: const Icon(Icons.arrow_drop_down),
                      ),
                      child: selectedBodyId != null
                          ? Builder(
                              builder: (context) {
                                final body =
                                    districtBodies[selectedDistrictId!]!
                                        .firstWhere(
                                          (b) => b.bodyId == selectedBodyId,
                                          orElse: () => Body(
                                            bodyId: '',
                                            districtId: '',
                                            name: '',
                                            type: '',
                                            wardCount: 0,
                                          ),
                                        );
                                return Text(
                                  body.bodyId.isNotEmpty
                                      ? '${body.name} (${body.type})'
                                      : selectedBodyId!,
                                  style: const TextStyle(fontSize: 16),
                                );
                              },
                            )
                          : const Text(
                              'Select Area (विभाग)',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.business, color: Colors.grey),
                        const SizedBox(width: 12),
                        Text(
                          selectedStateId == null
                              ? localizations.selectStateFirst
                              : selectedDistrictId == null
                              ? localizations.selectDistrictFirst
                              : districtBodies[selectedDistrictId!] == null ||
                                    districtBodies[selectedDistrictId!]!.isEmpty
                              ? 'No areas available in this district'
                              : 'Select Area (विभाग)',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),

                // Ward Selection
                if (selectedStateId != null &&
                    selectedBodyId != null &&
                    bodyWards[selectedBodyId!] != null &&
                    bodyWards[selectedBodyId!]!.isNotEmpty)
                  InkWell(
                    onTap: () => _showWardSelectionModal(context),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: localizations.wardRequired,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.home),
                        suffixIcon: const Icon(Icons.arrow_drop_down),
                      ),
                      child: selectedWard != null
                          ? Builder(
                              builder: (context) {
                                // Format ward display like "वॉर्ड 1 - Ward Name"
                                final numberMatch = RegExp(r'ward_(\d+)')
                                    .firstMatch(
                                      selectedWard!.wardId.toLowerCase(),
                                    );
                                final displayText = numberMatch != null
                                    ? 'वॉर्ड ${numberMatch.group(1)} - ${selectedWard!.name}'
                                    : selectedWard!.name;
                                return Text(
                                  displayText,
                                  style: const TextStyle(fontSize: 16),
                                );
                              },
                            )
                          : const Text(
                              'Select Ward (वॉर्ड)',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.home, color: Colors.grey),
                        const SizedBox(width: 12),
                        Text(
                          selectedStateId == null
                              ? localizations.selectStateFirst
                              : selectedBodyId == null
                              ? localizations.selectAreaFirst
                              : bodyWards[selectedBodyId!] == null ||
                                    bodyWards[selectedBodyId!]!.isEmpty
                              ? 'No wards available in this area'
                              : 'Select Ward (वॉर्ड)',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),

                // Area Selection (only show if ward has areas and user is not a candidate)
                if (selectedStateId != null &&
                    selectedWard != null &&
                    selectedWard!.areas != null &&
                    selectedWard!.areas!.isNotEmpty &&
                    currentUserRole != 'candidate') ...[
                  InkWell(
                    onTap: () => _showAreaSelectionModal(context),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: localizations.areaRequired,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.location_on),
                        suffixIcon: const Icon(Icons.arrow_drop_down),
                      ),
                      child: selectedArea != null
                          ? Text(
                              selectedArea!,
                              style: const TextStyle(fontSize: 16),
                            )
                          : Text(
                              localizations.selectYourArea,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],


                // Party Selection (only for candidates)
                if (currentUserRole == 'candidate') ...[
                  if (isLoadingParties)
                    const Center(child: CircularProgressIndicator())
                  else
                    InkWell(
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
                                localizations.pleaseSelectYourPoliticalParty,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  const SizedBox(height: 32),
                ],

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () => _saveProfile(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            localizations.completeProfile,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Debug Button (temporary - remove in production)
                if (states.isEmpty) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: OutlinedButton(
                      onPressed: () async {
                        try {
                          await SampleStatesManager.addSampleStates();
                          await SampleStatesManager.addSampleDistrictsForMaharashtra();
                          await _loadStates();
                          Get.snackbar('Success', 'Sample states added successfully');
                        } catch (e) {
                          Get.snackbar('Error', 'Failed to add sample states: $e');
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.orange),
                      ),
                      child: const Text(
                        'Add Sample States (Debug)',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Info Text
                Text(
                  localizations.requiredFields,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
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
