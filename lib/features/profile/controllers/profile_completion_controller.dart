import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../l10n/features/profile/profile_localizations.dart';
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

class ProfileCompletionController extends GetxController {
  // User data passed from main.dart to avoid duplicate Firebase call
  Map<String, dynamic>? passedUserData;
  bool profileCompleted = false;

  final formKey = GlobalKey<FormState>();
  final AuthController loginController = Get.find<AuthController>();
  final ChatController chatController = Get.find<ChatController>();
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

  // Data collections
  List<District> districts = [];
  Map<String, List<Body>> districtBodies = {};
  Map<String, List<Ward>> bodyWards = {};
  List<Party> parties = [];
  List<state_model.State> states = [];
  bool isLoading = false;
  bool isLoadingDistricts = true;
  bool isLoadingParties = true;
  bool isLoadingStates = true;
  bool isNamePreFilled = false;
  bool isPhonePreFilled = false;
  String? currentUserRole;

  @override
  void onInit() {
    super.onInit();

    // Get user data passed from main.dart
    final args = Get.arguments;
    if (args is Map<String, dynamic> && args.containsKey('userData')) {
      passedUserData = args['userData'];
      profileCompleted = passedUserData?['profileCompleted'] ?? false;

      debugPrint(
        '📥 Received user data from main.dart: profileCompleted = $profileCompleted',
      );

      // If profile is already completed, navigate to home immediately
      if (profileCompleted) {
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
        loadStates();
        loadDistricts();
        loadParties();
        loadUserRole();
        preFillUserData();
      });
    });
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    birthDateController.dispose();
    super.onClose();
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
  void preFillUserData() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Pre-fill name from display name (Google login) or email prefix
    if (currentUser.displayName != null &&
        currentUser.displayName!.isNotEmpty) {
      nameController.text = currentUser.displayName!;
      isNamePreFilled = true;
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
      isNamePreFilled = true;
    }

    // Pre-fill phone number from Firebase Auth (remove +91 prefix for display)
    if (currentUser.phoneNumber != null &&
        currentUser.phoneNumber!.isNotEmpty) {
      phoneController.text = currentUser.phoneNumber!.replaceFirst('+91', '');
      isPhonePreFilled = true;
    }

    debugPrint('🔍 Pre-filled user data:');
    debugPrint(
      '  Name: ${nameController.text} (${isNamePreFilled ? 'from auth' : 'manual'})',
    );
    debugPrint(
      '  Phone: ${phoneController.text} (${isPhonePreFilled ? 'from auth' : 'manual'})',
    );
    debugPrint('  Email: ${currentUser.email}');
    debugPrint('  Photo: ${currentUser.photoURL}');

    // Trigger rebuild to show helper text
    update();
  }

  Future<void> loadStates() async {
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
            return state_model.State.fromJson({'id': doc.id, ...data});
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
        orElse: () => states.isNotEmpty ? states.first : state_model.State(id: '', name: ''),
      );

      if (maharashtraState.id.isNotEmpty) {
        selectedStateId = maharashtraState.id;
        debugPrint('✅ Default state set to: ${maharashtraState.name}');
      }

      isLoadingStates = false;
      update();

      debugPrint('✅ Successfully loaded ${states.length} states');
    } catch (e) {
      debugPrint('❌ Failed to load states: $e');
      Get.snackbar('Error', 'Failed to load states: $e'); // TODO: Localize this
      isLoadingStates = false;
      update();
    }
  }

  Future<void> loadDistricts() async {
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
          return District.fromJson({'id': doc.id, 'stateId': selectedStateId!, ...data});
        }).toList();

        // Load bodies for each district
        for (final district in districts) {
          final bodiesSnapshot = await FirebaseFirestore.instance
              .collection('states')
              .doc(selectedStateId!)
              .collection('districts')
              .doc(district.id)
              .collection('bodies')
              .get();

          debugPrint(
            '📊 Found ${bodiesSnapshot.docs.length} bodies in district ${district.id}',
          );

          districtBodies[district.id] = bodiesSnapshot.docs.map((doc) {
            final data = doc.data();
            debugPrint(
              '🏢 Body: ${doc.id} - ${data['name'] ?? 'Unknown'} (${data['type'] ?? 'Unknown'})',
            );
            return Body.fromJson({
              'id': doc.id,
              'districtId': district.id,
              'stateId': selectedStateId!,
              ...data,
            });
          }).toList();
        }

        isLoadingDistricts = false;
        update();

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
            'Error', // TODO: Localize this
            'Failed to load districts after $maxRetries attempts: $e',
          );
          isLoadingDistricts = false;
          update();
        }
      }
    }
  }

  Future<void> loadParties() async {
    try {
      parties = await partyRepository.getActiveParties();
      isLoadingParties = false;
      update();
    } catch (e) {
      Get.snackbar('Error', 'Failed to load parties: $e'); // TODO: Localize this
      isLoadingParties = false;
      update();
    }
  }

  Future<void> loadUserRole() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      currentUserRole = userDoc.data()?['role'] ?? 'voter';
      update();
    } catch (e) {
      debugPrint('Error loading user role: $e');
      currentUserRole = 'voter';
      update();
    }
  }

  Future<void> loadWards(
    String districtId,
    String bodyId,
    BuildContext context,
  ) async {
    final localizations = ProfileLocalizations.of(context)!;

    try {
      final wards = await candidateRepository.getWardsByDistrictAndBody(
        districtId,
        bodyId,
      );
      bodyWards[bodyId] = wards;
      update();
    } catch (e) {
      Get.snackbar(
        localizations.error,
        localizations.failedToLoadWards(e.toString()),
      );
    }
  }

  Future<void> selectBirthDate(BuildContext context) async {
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
      selectedBirthDate = picked;
      birthDateController.text =
          '${picked.day}/${picked.month}/${picked.year}';
      update();
    }
  }

  void onStateSelected(String stateId) {
    selectedStateId = stateId;
    selectedDistrictId = null;
    selectedBodyId = null;
    selectedWard = null;
    districts.clear();
    districtBodies.clear();
    bodyWards.clear();
    isLoadingDistricts = true;
    update();
    // Reload districts for the selected state
    loadDistricts();
  }

  void onDistrictSelected(String districtId) {
    selectedDistrictId = districtId;
    selectedBodyId = null;
    selectedWard = null;
    bodyWards.clear();
    update();
  }

  void onBodySelected(String bodyId) {
    selectedBodyId = bodyId;
    selectedWard = null;
    bodyWards.clear();
    update();
  }

  void onWardSelected(String wardId) {
    final ward = bodyWards[selectedBodyId!]!.firstWhere(
      (w) => w.id == wardId,
    );
    selectedWard = ward;
    selectedArea = null; // Reset area when ward changes
    update();
  }

  void onAreaSelected(String area) {
    selectedArea = area;
    update();
  }

  void onPartySelected(String partyId) {
    selectedParty = parties.firstWhere(
      (party) => party.id == partyId,
    );
    update();
  }

  void updateSelectedGender(String? value) {
    selectedGender = value;
    update();
  }

  void updateSelectedState(String stateId) {
    onStateSelected(stateId);
  }

  void updateSelectedDistrict(String districtId) {
    onDistrictSelected(districtId);
  }

  void updateSelectedBody(String bodyId) {
    onBodySelected(bodyId);
  }

  void updateSelectedWard(Ward ward) {
    selectedWard = ward;
    selectedArea = null; // Reset area when ward changes
    update();
  }

  void updateSelectedArea(String area) {
    onAreaSelected(area);
  }

  void updateSelectedParty(Party party) {
    selectedParty = party;
    update();
  }

  InputDecoration buildInputDecoration(
    BuildContext context, {
    required String label,
    required String hint,
    required IconData icon,
    bool showPreFilledHelper = false,
  }) {
    final localizations = ProfileLocalizations.of(context)!;

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

  Future<void> saveProfile(BuildContext context) async {
    final localizations = ProfileLocalizations.of(context)!;

    if (!formKey.currentState!.validate()) return;

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

    isLoading = true;
    update();

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
        wardId: selectedWard!.id,
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
            wardId: selectedWard!.id,
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
          localizations.profileCompletedMessage,
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

    isLoading = false;
    update();
  }
}