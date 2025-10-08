import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../utils/app_logger.dart';
import '../../../l10n/features/profile/profile_localizations.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../chat/controllers/chat_controller.dart';
import '../../../models/user_model.dart';
import '../../../models/ward_model.dart';
import '../../../models/state_model.dart' as state_model;
import '../../candidate/models/candidate_model.dart';
import '../../../models/district_model.dart';
import '../../../models/body_model.dart';
import '../../candidate/repositories/candidate_repository.dart';
import '../../../utils/add_sample_states.dart';
import '../../../services/local_database_service.dart';
import '../../../services/notifications/constituency_notifications.dart';

class ProfileCompletionController extends GetxController {
  // User data passed from main.dart to avoid duplicate Firebase call
  Map<String, dynamic>? passedUserData;
  bool profileCompleted = false;

  final formKey = GlobalKey<FormState>();
  final AuthController loginController = Get.find<AuthController>();
  final ChatController chatController = Get.find<ChatController>();
  final candidateRepository = CandidateRepository();

  // Location database service for automatic data caching
  final LocalDatabaseService _locationDatabase = LocalDatabaseService();

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
  // ZP+PS Election fields
  String? selectedElectionType; // 'regular' or 'zp_ps_combined'
  String? selectedZPBodyId; // Zilla Parishad body ID
  String? selectedZPWardId; // Zilla Parishad ward ID
  String? selectedZPArea; // Zilla Parishad area
  String? selectedPSBodyId; // Panchayat Samiti body ID
  String? selectedPSWardId; // Panchayat Samiti ward ID
  String? selectedPSArea; // Panchayat Samiti area

  // Party selection for candidates
  String? selectedPartyId;

  // Data collections
  List<District> districts = [];
  Map<String, List<Body>> districtBodies = {};
  Map<String, List<Ward>> bodyWards = {};
  List<state_model.State> states = [];
  bool isLoading = false;
  bool isLoadingDistricts = true;
  bool isLoadingStates = true;
  bool isNamePreFilled = false;
  bool isPhonePreFilled = false;
  String? currentUserRole;

  @override
  void onInit() async {
    super.onInit();

    // Location database service is ready to use (SQLite auto-initializes)
    AppLogger.common('✅ Location database service ready in ProfileCompletionController');

    // Get user data passed from main.dart
    final args = Get.arguments;
    if (args is Map<String, dynamic> && args.containsKey('userData')) {
      passedUserData = args['userData'];
      profileCompleted = passedUserData?['profileCompleted'] ?? false;

      AppLogger.common(
        '📥 Received user data from main.dart: profileCompleted = $profileCompleted',
      );

      // If profile is already completed, navigate to home immediately
      if (profileCompleted) {
        AppLogger.common(
          '✅ Profile already completed (from passed data), navigating to home',
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.offAllNamed('/home');
        });
        return;
      }
    } else {
      // Fallback: fetch user data if not passed (for direct navigation)
      AppLogger.common('⚠️ No user data passed, falling back to Firebase fetch');
      _checkProfileCompletion();
    }

    // Continue with normal initialization
    // Add a small delay to ensure Firebase auth is fully initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        loadStates(); // Load only states initially
        // Removed loadParties() - not needed in profile completion UI
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
          AppLogger.common('✅ Profile already completed, navigating to home');
          Get.offAllNamed('/home');
          return;
        }
      }

      // Profile not completed, continue with normal flow
      AppLogger.common('📝 Profile not completed, showing completion screen');
    } catch (e) {
      AppLogger.commonError('⚠️ Error checking profile completion', error: e);
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

    AppLogger.common('🔍 Pre-filled user data:');
    AppLogger.common(
      '  Name: ${nameController.text} (${isNamePreFilled ? 'from auth' : 'manual'})',
    );
    AppLogger.common(
      '  Phone: ${phoneController.text} (${isPhonePreFilled ? 'from auth' : 'manual'})',
    );
    AppLogger.common('  Email: ${currentUser.email}');
    AppLogger.common('  Photo: ${currentUser.photoURL}');

    // Trigger rebuild to show helper text
    update();
  }

  Future<void> loadStates() async {
    try {
      AppLogger.common('🔍 Loading states from Firestore');

      // Load states from Firestore
      final statesSnapshot = await FirebaseFirestore.instance
          .collection('states')
          .get();

      AppLogger.common(
        '📊 Found ${statesSnapshot.docs.length} states in Firestore',
      );

      // If no states found, add sample states
      if (statesSnapshot.docs.isEmpty) {
        AppLogger.commonError('⚠️ No states found in database, adding sample states');
        try {
          await SampleStatesManager.addSampleStates();
          await SampleStatesManager.addSampleDistrictsForMaharashtra();

          // Reload states after adding samples
          final updatedSnapshot = await FirebaseFirestore.instance
              .collection('states')
              .get();

          states = updatedSnapshot.docs.map((doc) {
            final data = doc.data();
            AppLogger.common('🏛️ State: ${doc.id} - ${data['name'] ?? 'Unknown'}');
            return state_model.State.fromJson({'id': doc.id, ...data});
          }).toList();

          AppLogger.common('✅ Sample states added and loaded successfully');
        } catch (e) {
          AppLogger.commonError('❌ Failed to add sample states', error: e);
          // Continue with empty states list
          states = [];
        }
      } else {
        states = statesSnapshot.docs.map((doc) {
          final data = doc.data();
          AppLogger.common('🏛️ State: ${doc.id} - ${data['name'] ?? 'Unknown'} - Marathi: ${data['marathiName']} - Code: ${data['code']}');
          return state_model.State.fromJson({'id': doc.id, ...data});
        }).toList();

        // 🚀 OPTIMIZED: Cache states directly from fetched data (no redundant Firebase call)
        AppLogger.common('🌍 [Profile] Caching ${states.length} states in SQLite during profile completion');
        try {
          await _locationDatabase.insertDistricts(states.map((state) => District(
            id: state.id,
            name: state.name,
            stateId: state.id, // States are stored as districts with stateId = id
          )).toList());
          AppLogger.common('✅ [Profile] States cached successfully in SQLite');
        } catch (e) {
          AppLogger.commonError('❌ [Profile] Failed to cache states', error: e);
        }
      }

      // Set default state - prefer Maharashtra if available, otherwise use first available state
      final defaultState = states.firstWhere(
        (state) => state.name.toLowerCase() == 'maharashtra',
        orElse: () => states.isNotEmpty ? states.first : state_model.State(id: '', name: ''),
      );

      if (defaultState.id.isNotEmpty) {
        selectedStateId = defaultState.id;
        AppLogger.common('✅ Default state set to: ${defaultState.name} (ID: ${defaultState.id})');

        // Automatically load districts for the default state
        WidgetsBinding.instance.addPostFrameCallback((_) {
          loadDistrictsForState(defaultState.id);
        });
      } else {
        AppLogger.commonError('⚠️ No states available to set as default');
      }

      isLoadingStates = false;
      update();

      AppLogger.common('✅ Successfully loaded ${states.length} states');
    } catch (e) {
      AppLogger.commonError('❌ Failed to load states', error: e);
      Get.snackbar('Error', 'Failed to load states: $e'); // TODO: Localize this
      isLoadingStates = false;
      update();
    }
  }

  // Optimized: Load districts only for selected state
  Future<void> loadDistrictsForState(String stateId) async {
    const int maxRetries = 3;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        AppLogger.common('🔍 Loading districts for state: $stateId (attempt ${retryCount + 1})');

        final districtsSnapshot = await FirebaseFirestore.instance
            .collection('states')
            .doc(stateId)
            .collection('districts')
            .get();

        AppLogger.common('📊 Found ${districtsSnapshot.docs.length} districts in state $stateId');

        // Clear previous data
        districts.clear();
        districtBodies.clear();

        districts = districtsSnapshot.docs.map((doc) {
          final data = doc.data();
          AppLogger.common('🏙️ District: ${doc.id} - ${data['name'] ?? 'Unknown'}');
          return District.fromJson({'id': doc.id, 'stateId': stateId, ...data});
        }).toList();

        // 🚀 OPTIMIZED: Cache districts directly from fetched data (no redundant Firebase call)
        AppLogger.common('🏙️ [Profile] Caching ${districts.length} districts in SQLite for state: $stateId');
        try {
          await _locationDatabase.insertDistricts(districts);
          AppLogger.common('✅ [Profile] Districts cached successfully in SQLite');
        } catch (e) {
          AppLogger.commonError('❌ [Profile] Failed to cache districts', error: e);
        }

        // Load bodies only for the selected state
        await _loadBodiesForDistricts(stateId);

        isLoadingDistricts = false;
        update();

        AppLogger.common('✅ Successfully loaded ${districts.length} districts for state $stateId');
        return;
      } catch (e) {
        retryCount++;
        AppLogger.commonError('❌ Failed to load districts for state $stateId (attempt $retryCount)', error: e);

        if (retryCount < maxRetries) {
          AppLogger.common('🔄 Retrying in ${retryCount * 2} seconds...');
          await Future.delayed(Duration(seconds: retryCount * 2));
        } else {
          AppLogger.commonError('❌ All retry attempts failed for loading districts');
          Get.snackbar('Error', 'Failed to load districts after $maxRetries attempts: $e');
          isLoadingDistricts = false;
          update();
        }
      }
    }
  }

  // Helper method to load bodies for multiple districts
  Future<void> _loadBodiesForDistricts(String stateId) async {
    for (final district in districts) {
      try {
        final bodiesSnapshot = await FirebaseFirestore.instance
            .collection('states')
            .doc(stateId)
            .collection('districts')
            .doc(district.id)
            .collection('bodies')
            .get();

        AppLogger.common('📊 Found ${bodiesSnapshot.docs.length} bodies in district ${district.id}');

        districtBodies[district.id] = bodiesSnapshot.docs.map((doc) {
          final data = doc.data();
          return Body.fromJson({
            'id': doc.id,
            'districtId': district.id,
            'stateId': stateId,
            ...data,
          });
        }).toList();

        // 🚀 OPTIMIZED: Cache bodies directly from fetched data (no redundant Firebase call)
        AppLogger.common('🏛️ [Profile] Caching ${districtBodies[district.id]!.length} bodies in SQLite for district: ${district.id}');
        try {
          await _locationDatabase.insertBodies(districtBodies[district.id]!);
          AppLogger.common('✅ [Profile] Bodies cached successfully in SQLite');
        } catch (e) {
          AppLogger.commonError('❌ [Profile] Failed to cache bodies for district ${district.id}', error: e);
        }
      } catch (e) {
        AppLogger.commonError('❌ Failed to load bodies for district ${district.id}', error: e);
        districtBodies[district.id] = []; // Set empty list on error
      }
    }
  }

  // Optimized: Load bodies only for selected district
  Future<void> loadBodiesForDistrict(String districtId) async {
    try {
      AppLogger.common('🔍 Loading bodies for district: $districtId');

      // Clear previous bodies and wards for this district
      districtBodies.remove(districtId);
      bodyWards.clear();

      final bodiesSnapshot = await FirebaseFirestore.instance
          .collection('states')
          .doc(selectedStateId!)
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .get();

      AppLogger.common('📊 Found ${bodiesSnapshot.docs.length} bodies in district $districtId');

      districtBodies[districtId] = bodiesSnapshot.docs.map((doc) {
        final data = doc.data();
        AppLogger.common('🏢 Body: ${doc.id} - ${data['name'] ?? 'Unknown'} (${data['type'] ?? 'Unknown'})');
        return Body.fromJson({
          'id': doc.id,
          'districtId': districtId,
          'stateId': selectedStateId!,
          ...data,
        });
      }).toList();

      update();
      AppLogger.common('✅ Successfully loaded ${districtBodies[districtId]!.length} bodies for district $districtId');
    } catch (e) {
      AppLogger.commonError('❌ Failed to load bodies for district $districtId', error: e);
      Get.snackbar('Error', 'Failed to load bodies: $e');
    }
  }

  // Optimized: Load wards only for selected body
  Future<void> loadWardsForBody(String districtId, String bodyId) async {
    try {
      AppLogger.common('🔍 [PROFILE_CONTROLLER] Loading wards for body: $bodyId in district: $districtId');

      // Clear previous wards for this body
      bodyWards.remove(bodyId);

      final wardsSnapshot = await FirebaseFirestore.instance
          .collection('states')
          .doc(selectedStateId!)
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .get();

      AppLogger.common('📊 Found ${wardsSnapshot.docs.length} wards in body $bodyId');

      // Debug: Print ward IDs
      for (final doc in wardsSnapshot.docs) {
        AppLogger.common('   Ward: ${doc.id} - ${doc.data()['name'] ?? 'No name'}');
      }

      bodyWards[bodyId] = wardsSnapshot.docs.map((doc) {
        final data = doc.data();
        return Ward.fromJson({
          ...data,
          'wardId': doc.id,
          'districtId': districtId,
          'bodyId': bodyId,
          'stateId': selectedStateId!,
        });
      }).toList();

      // 🚀 OPTIMIZED: Cache wards directly from fetched data (no redundant Firebase call)
      AppLogger.common('🏛️ [Profile] Caching ${bodyWards[bodyId]!.length} wards in SQLite for $districtId/$bodyId');
      try {
        await _locationDatabase.insertWards(bodyWards[bodyId]!);
        AppLogger.common('✅ [Profile] Wards cached successfully in SQLite');
      } catch (e) {
        AppLogger.commonError('❌ [Profile] Failed to cache wards for $districtId/$bodyId', error: e);
      }

      update();
      AppLogger.common('✅ Successfully loaded ${bodyWards[bodyId]!.length} wards for body $bodyId');
    } catch (e) {
      AppLogger.commonError('❌ Failed to load wards for body $bodyId', error: e);
      Get.snackbar('Error', 'Failed to load wards: $e');
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
      AppLogger.commonError('Error loading user role', error: e);
      currentUserRole = 'voter';
      update();
    }
  }

  Future<void> loadWards(
    String districtId,
    String bodyId,
    BuildContext context,
  ) async {
    // Use the new optimized loading method
    await loadWardsForBody(districtId, bodyId);
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
    // Reset ZP+PS selections when state changes
    selectedElectionType = null;
    selectedZPBodyId = null;
    selectedZPWardId = null;
    selectedZPArea = null;
    selectedPSBodyId = null;
    selectedPSWardId = null;
    selectedPSArea = null;
    // Reset party selection when state changes
    selectedPartyId = null;

    districts.clear();
    districtBodies.clear();
    bodyWards.clear();
    isLoadingDistricts = true;
    update();

    // Load districts only for the selected state
    loadDistrictsForState(stateId);
  }

  void onDistrictSelected(String districtId) {
    AppLogger.common('🎯 District selected: $districtId');
    selectedDistrictId = districtId;
    selectedBodyId = null;
    selectedWard = null;
    // Reset ZP+PS selections when district changes
    selectedZPBodyId = null;
    selectedZPWardId = null;
    selectedZPArea = null;
    selectedPSBodyId = null;
    selectedPSWardId = null;
    selectedPSArea = null;

    bodyWards.clear();
    AppLogger.common('🔄 Cleared body and ward selections');

    // Load bodies only for the selected district
    loadBodiesForDistrict(districtId);
    update();
  }

  void onBodySelected(String bodyId) {
    AppLogger.common('🎯 [PROFILE_CONTROLLER] Body selected: $bodyId for district: $selectedDistrictId');
    selectedBodyId = bodyId;
    selectedWard = null;
    bodyWards.clear();

    // Load wards only for the selected body
    loadWardsForBody(selectedDistrictId!, bodyId);
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

  // Party selection method (for future use if needed)
  // void onPartySelected(String partyId) {
  //   selectedParty = parties.firstWhere(
  //     (party) => party.id == partyId,
  //   );
  //   update();
  // }

  // ZP+PS Election methods
  void onElectionTypeSelected(String electionType) {
    selectedElectionType = electionType;
    // Reset ZP+PS selections when election type changes
    selectedZPBodyId = null;
    selectedZPWardId = null;
    selectedPSBodyId = null;
    selectedPSWardId = null;

    // Auto-select body based on election type
    if (selectedDistrictId != null && districtBodies[selectedDistrictId!] != null) {
      final bodies = districtBodies[selectedDistrictId!]!;
      BodyType targetType;

      switch (electionType) {
        case 'municipal_corporation':
          targetType = BodyType.municipal_corporation;
          break;
        case 'municipal_council':
          targetType = BodyType.municipal_council;
          break;
        case 'nagar_panchayat':
          targetType = BodyType.nagar_panchayat;
          break;
        case 'zilla_parishad':
          targetType = BodyType.zilla_parishad;
          break;
        case 'panchayat_samiti':
          targetType = BodyType.panchayat_samiti;
          break;
        case 'zp_ps_combined':
          // For ZP+PS combined, auto-select both ZP and PS bodies
          _autoSelectZPandPSBodies();
          update();
          return;
        default:
          update();
          return;
      }

      // Find the first body of the target type
      final matchingBody = bodies.firstWhere(
        (body) => body.type == targetType,
        orElse: () => Body(
          id: '',
          name: '',
          type: targetType,
          districtId: selectedDistrictId!,
          stateId: selectedStateId ?? '',
        ),
      );

      if (matchingBody.id.isNotEmpty) {
        // For regular elections (including individual ZP/PS), set the regular body
        selectedBodyId = matchingBody.id;
        selectedWard = null;
        bodyWards.clear();
        // Load wards for the selected body
        loadWardsForBody(selectedDistrictId!, matchingBody.id);
      }
    }

    update();
  }

  void onZPBodySelected(String bodyId) {
    selectedZPBodyId = bodyId;
    selectedZPWardId = null; // Reset ward when body changes
    // Load wards only for the selected ZP body
    loadWardsForBody(selectedDistrictId!, bodyId);
    update();
  }

  void onZPWardSelected(String wardId) {
    selectedZPWardId = wardId;
    selectedZPArea = null; // Reset area when ward changes

    // Also set selectedWard to the ZP ward for consistency
    if (districtBodies.isNotEmpty && bodyWards.isNotEmpty) {
      // Find the ward in the available wards
      for (var bodyWardsList in bodyWards.values) {
        final ward = bodyWardsList.firstWhere(
          (w) => w.id == wardId,
          orElse: () => bodyWardsList.firstWhere(
            (w) => w.id.isNotEmpty,
            orElse: () => Ward(
              id: wardId,
              name: 'ZP Ward $wardId',
              districtId: selectedDistrictId ?? '',
              bodyId: selectedZPBodyId ?? '',
              stateId: selectedStateId ?? '',
            ),
          ),
        );
        selectedWard = ward;
        break;
      }
    }

    update();
  }

  void onPSBodySelected(String bodyId) {
    selectedPSBodyId = bodyId;
    selectedPSWardId = null; // Reset ward when body changes
    // Load wards only for the selected PS body
    loadWardsForBody(selectedDistrictId!, bodyId);
    update();
  }

  void onPSWardSelected(String wardId) {
    selectedPSWardId = wardId;
    selectedPSArea = null; // Reset area when ward changes
    update();
  }

  // ZP+PS Area selection methods
  void onZPAreaSelected(String area) {
    selectedZPArea = area;
    update();
  }

  void onPSAreaSelected(String area) {
    selectedPSArea = area;
    update();
  }

  void onPartySelected(String partyId) {
    selectedPartyId = partyId;
    update();
  }

  // Helper method to auto-select ZP and PS bodies for combined elections
  void _autoSelectZPandPSBodies() {
    if (selectedDistrictId == null || districtBodies[selectedDistrictId!] == null) return;

    final bodies = districtBodies[selectedDistrictId!]!;

    // Find ZP body
    final zpBody = bodies.firstWhere(
      (body) => body.type == BodyType.zilla_parishad,
      orElse: () => Body(
        id: '',
        name: '',
        type: BodyType.zilla_parishad,
        districtId: selectedDistrictId!,
        stateId: selectedStateId ?? '',
      ),
    );

    // Find PS body
    final psBody = bodies.firstWhere(
      (body) => body.type == BodyType.panchayat_samiti,
      orElse: () => Body(
        id: '',
        name: '',
        type: BodyType.panchayat_samiti,
        districtId: selectedDistrictId!,
        stateId: selectedStateId ?? '',
      ),
    );

    if (zpBody.id.isNotEmpty) {
      selectedZPBodyId = zpBody.id;
      selectedZPWardId = null;
      // Load wards for ZP body
      loadWardsForBody(selectedDistrictId!, zpBody.id);
    }

    if (psBody.id.isNotEmpty) {
      selectedPSBodyId = psBody.id;
      selectedPSWardId = null;
      // Load wards for PS body
      loadWardsForBody(selectedDistrictId!, psBody.id);
    }
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

  // Party selection method (for future use if needed)
  // void updateSelectedParty(Party party) {
  //   selectedParty = party;
  //   update();
  // }

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
        selectedGender == null) {
      Get.snackbar(
        localizations.error,
        localizations.pleaseFillAllRequiredFields,
      );
      return;
    }

    // Validate election type selection based on user role
    if (currentUserRole == 'candidate' && selectedElectionType == 'zp_ps_combined') {
      Get.snackbar(
        localizations.error,
        'Candidates can only select one election type. ZP+PS combined is only for voters.',
      );
      return;
    }

    // Prevent voters from selecting individual ZP or PS (they should use combined option)
    if (currentUserRole != 'candidate' &&
        (selectedElectionType == 'zilla_parishad' || selectedElectionType == 'panchayat_samiti')) {
      Get.snackbar(
        localizations.error,
        'Voters should select ZP+PS Combined for rural elections.',
      );
      return;
    }

    // Validate based on election type and user role
    if (selectedElectionType == 'zp_ps_combined') {
      // ZP+PS validation - Only for voters
      if (selectedZPBodyId == null ||
          selectedZPWardId == null ||
          selectedPSBodyId == null ||
          selectedPSWardId == null) {
        Get.snackbar(
          localizations.error,
          'Please select ZP body, ZP ward, PS body, and PS ward',
        );
        return;
      }
    } else {
      // Regular election validation
      if (selectedBodyId == null || selectedWard == null) {
        Get.snackbar(
          localizations.error,
          localizations.pleaseFillAllRequiredFields,
        );
        return;
      }
    }

    // Check if area selection is required and selected (only for non-candidates)
    if (currentUserRole != 'candidate' &&
        selectedWard != null &&
        selectedWard!.areas != null &&
        selectedWard!.areas!.isNotEmpty &&
        selectedArea == null) {
      Get.snackbar(localizations.error, localizations.selectYourArea);
      return;
    }

    // Validate party selection for candidates
    if (currentUserRole == 'candidate' && selectedPartyId == null) {
      Get.snackbar(
        localizations.error,
        'Please select your political party',
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


      // Create election areas based on selection type
      List<ElectionArea> electionAreas = [];

      if (selectedElectionType == 'zp_ps_combined') {
        // ZP+PS combined elections - Both ZP and PS required
        if (selectedZPBodyId != null && selectedZPWardId != null) {
          electionAreas.add(ElectionArea(
            bodyId: selectedZPBodyId!,
            wardId: selectedZPWardId!,
            area: selectedZPArea,
            type: ElectionType.zp,
          ));
        }
        if (selectedPSBodyId != null && selectedPSWardId != null) {
          electionAreas.add(ElectionArea(
            bodyId: selectedPSBodyId!,
            wardId: selectedPSWardId!,
            area: selectedPSArea,
            type: ElectionType.ps,
          ));
        }
      } else {
        // Regular elections
        if (selectedBodyId != null && selectedWard != null) {
          electionAreas.add(ElectionArea(
            bodyId: selectedBodyId!,
            wardId: selectedWard!.id,
            area: selectedArea,
            type: ElectionType.regular,
          ));
        }
      }

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
        electionAreas: electionAreas,
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
        AppLogger.common(
          '✅ Chat data refreshed successfully for user: ${currentUser.uid}',
        );
      } catch (e) {
        AppLogger.commonError('⚠️ Failed to refresh chat data, but profile saved', error: e);
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
          // Candidates can only have regular elections (ZP+PS is for voters only)
          final primaryWardId = selectedWard!.id;
          final primaryBodyId = selectedBodyId!;

           final candidate = Candidate(
            candidateId: 'temp_${currentUser.uid}', // Temporary ID
            userId: currentUser.uid,
            name: nameController.text.trim(),
            party: selectedPartyId ?? 'independent', // Use selected party or default to independent
            districtId: selectedDistrictId!,
            stateId: selectedStateId!,
            bodyId: primaryBodyId,
            wardId: primaryWardId,
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
          AppLogger.common(
            '🏗️ Profile Completion: Creating candidate record for ${candidate.name}',
          );
          AppLogger.common(
            '   District: ${candidate.districtId}, Body: ${candidate.bodyId}, Ward: ${candidate.wardId}',
          );
          AppLogger.common('   Temp ID: ${candidate.candidateId}');
          //create candidate and get actual ID
          final actualCandidateId = await candidateRepository.createCandidate(
            candidate,
            stateId: selectedStateId,
          );

          // here we have to create candidate chat room as well
          chatController.createCandidateChatRoom(
            actualCandidateId,
            candidate.name,
          );
          AppLogger.common(
            '✅ Basic candidate record created with ID: $actualCandidateId',
          );

          // Update user document with the actual candidateId
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .update({'candidateId': actualCandidateId});
          AppLogger.common(
            '✅ User document updated with candidateId: $actualCandidateId',
          );

          // Send notification to constituency voters about new candidate
          try {
            AppLogger.common('📢 Sending new candidate notification to constituency voters...');
            final constituencyNotifications = ConstituencyNotifications();
            await constituencyNotifications.sendCandidateProfileCreatedNotification(
              candidateId: actualCandidateId,
            );
            AppLogger.common('✅ New candidate notification sent successfully');
          } catch (e) {
            AppLogger.commonError('⚠️ Failed to send new candidate notification', error: e);
            // Don't fail the entire profile completion if notification fails
          }
        } catch (e) {
          AppLogger.commonError('⚠️ Failed to create basic candidate record', error: e);
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
