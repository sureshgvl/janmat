import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:janmat/features/user/models/user_model.dart';
import '../../../utils/app_logger.dart';
import '../../../l10n/features/profile/profile_localizations.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../chat/controllers/chat_controller.dart';
import '../../../models/ward_model.dart';
import '../../../models/state_model.dart' as state_model;
import '../../candidate/models/candidate_model.dart';
import '../../candidate/models/basic_info_model.dart';
import '../../candidate/models/location_model.dart';
import '../../candidate/models/contact_model.dart';
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
          AppLogger.common('🏛️ State: ${doc.id} - ${data['name'] ?? 'Unknown'} - Marathi: ${data['marathiName']} - Code: ${data['code']} - Active: ${data['isActive']}');
          return state_model.State.fromJson({'id': doc.id, ...data});
        }).toList();

        // Filter out inactive states
        final originalCount = states.length;
        states = states.where((state) => state.isActive != false).toList();
        final filteredCount = originalCount - states.length;

        if (filteredCount > 0) {
          AppLogger.common('🚫 Filtered out $filteredCount inactive states. Active states: ${states.length}');
        }

        // 🚀 OPTIMIZED: Cache states directly from fetched data (no redundant Firebase call)
        AppLogger.common('🌍 [Profile] Caching ${states.length} active states in SQLite during profile completion');
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

      // No default state selection - user must choose
      AppLogger.common('✅ States loaded successfully. No default state selected - user must choose.');

      // District dropdown will be disabled until state is selected
      districts.clear();
      districtBodies.clear();
      isLoadingDistricts = false;

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

  // Optimized: Load districts only for selected state with caching
  Future<void> loadDistrictsForState(String stateId) async {
    const int maxRetries = 3;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        AppLogger.common('🔍 Loading districts for state: $stateId (attempt ${retryCount + 1})');

        // 🚀 OPTIMIZATION: First try to load from local cache - COMMENTED OUT FOR TESTING
        /*
        try {
          // Check if districts are cached for this state
          final db = await _locationDatabase.database;
          final cachedDistrictsMaps = await db.query(
            'districts',
            where: 'stateId = ?',
            whereArgs: [stateId],
          );

          if (cachedDistrictsMaps.isNotEmpty) {
            final cachedDistricts = cachedDistrictsMaps.map((map) => District.fromJson(map)).toList();
            AppLogger.common('🎯 Found ${cachedDistricts.length} districts in cache for state: $stateId');

            // Check if this is the old cached data (states stored as districts)
            // If so, clear cache and reload from Firestore
            if (cachedDistricts.length == 1 && cachedDistricts.first.id == stateId) {
              AppLogger.common('⚠️ Found old cached data (state stored as district), clearing cache and reloading from Firestore');
              try {
                await _locationDatabase.database.then((db) => db.delete('districts', where: 'stateId = ?', whereArgs: [stateId]));
                AppLogger.common('✅ Cleared old cache data for state: $stateId');
              } catch (e) {
                AppLogger.commonError('❌ Failed to clear old cache data', error: e);
              }
            } else {
              districts = cachedDistricts;
              districtBodies.clear();

              // Load bodies for cached districts
              await _loadBodiesForDistricts(stateId);

              isLoadingDistricts = false;
              update();
              AppLogger.common('✅ Successfully loaded ${districts.length} districts from cache for state $stateId');
              return;
            }
          } else {
            AppLogger.common('⚠️ No districts found in cache for state: $stateId, loading from Firestore');
          }
        } catch (cacheError) {
          AppLogger.common('⚠️ Cache load failed, falling back to Firestore: $cacheError');
        }
        */

        // Load from Firestore if cache miss
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
          AppLogger.common('🏙️ District: ${doc.id} - ${data['name'] ?? 'Unknown'} - Active: ${data['isActive']}');
          return District.fromJson({'id': doc.id, 'stateId': stateId, ...data});
        }).toList();

        // Filter out inactive districts
        final originalDistrictCount = districts.length;
        districts = districts.where((district) => district.isActive != false).toList();
        final filteredDistrictCount = originalDistrictCount - districts.length;

        if (filteredDistrictCount > 0) {
          AppLogger.common('🚫 Filtered out $filteredDistrictCount inactive districts. Active districts: ${districts.length}');
        }

        AppLogger.common('✅ Loaded ${districts.length} active districts from Firestore for state $stateId');

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

      // Sort wards by ward number ascending
      bodyWards[bodyId]!.sort((a, b) {
        final aNumber = int.tryParse(RegExp(r'ward_(\d+)').firstMatch(a.id.toLowerCase())?.group(1) ?? '0') ?? 0;
        final bNumber = int.tryParse(RegExp(r'ward_(\d+)').firstMatch(b.id.toLowerCase())?.group(1) ?? '0') ?? 0;
        return aNumber.compareTo(bNumber);
      });

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
    AppLogger.common('🎯 State selected: $stateId');
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
    // Reset all selections when election type changes
    selectedBodyId = null;
    selectedWard = null;
    selectedZPBodyId = null;
    selectedZPWardId = null;
    selectedZPArea = null;
    selectedPSBodyId = null;
    selectedPSWardId = null;
    selectedPSArea = null;

    // Clear body wards
    bodyWards.clear();

    // For ZP+PS combined, auto-select both ZP and PS bodies
    if (electionType == 'zp_ps_combined') {
      _autoSelectZPandPSBodies();
      update();
      return;
    }

    // For regular elections, don't auto-select - let user choose from filtered list
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

  // Validation methods
  bool _validateBasicFields(BuildContext context) {
    final localizations = ProfileLocalizations.of(context)!;

    if (!formKey.currentState!.validate()) return false;

    if (selectedStateId == null || selectedDistrictId == null || selectedGender == null) {
      Get.snackbar(localizations.error, localizations.pleaseFillAllRequiredFields);
      return false;
    }

    return true;
  }

  // Voter-specific validation methods
  bool _validateVoterElectionType(BuildContext context) {
    final localizations = ProfileLocalizations.of(context)!;

    // Voters cannot select individual ZP or PS (must use combined)
    if (selectedElectionType == 'zilla_parishad' || selectedElectionType == 'panchayat_samiti') {
      Get.snackbar(localizations.error, 'Voters should select ZP+PS Combined for rural elections.');
      return false;
    }

    return true;
  }

  bool _validateVoterElectionFields(BuildContext context) {
    final localizations = ProfileLocalizations.of(context)!;

    if (selectedElectionType == 'zp_ps_combined') {
      if (selectedZPBodyId == null || selectedZPWardId == null ||
          selectedPSBodyId == null || selectedPSWardId == null) {
        Get.snackbar(localizations.error, 'Please select ZP body, ZP ward, PS body, and PS ward');
        return false;
      }
    } else {
      if (selectedBodyId == null || selectedWard == null) {
        Get.snackbar(localizations.error, localizations.pleaseFillAllRequiredFields);
        return false;
      }
    }

    return true;
  }

  bool _validateVoterAdditionalFields(BuildContext context) {
    final localizations = ProfileLocalizations.of(context)!;

    // Area selection required for voters if ward has areas
    if (selectedWard != null &&
        selectedWard!.areas != null &&
        selectedWard!.areas!.isNotEmpty &&
        selectedArea == null) {
      Get.snackbar(localizations.error, localizations.selectYourArea);
      return false;
    }

    return true;
  }

  // Candidate-specific validation methods
  bool _validateCandidateElectionType(BuildContext context) {
    final localizations = ProfileLocalizations.of(context)!;

    // Candidates cannot select ZP+PS combined
    if (selectedElectionType == 'zp_ps_combined') {
      Get.snackbar(localizations.error, 'Candidates can only select one election type. ZP+PS combined is only for voters.');
      return false;
    }

    return true;
  }

  bool _validateCandidateElectionFields(BuildContext context) {
    final localizations = ProfileLocalizations.of(context)!;

    // Candidates can only have regular elections
    if (selectedBodyId == null || selectedWard == null) {
      Get.snackbar(localizations.error, localizations.pleaseFillAllRequiredFields);
      return false;
    }

    return true;
  }

  bool _validateCandidateAdditionalFields(BuildContext context) {
    final localizations = ProfileLocalizations.of(context)!;

    // Party selection required for candidates
    if (selectedPartyId == null) {
      Get.snackbar(localizations.error, 'Please select your political party');
      return false;
    }

    return true;
  }


  List<ElectionArea> _createElectionAreas() {
    final electionAreas = <ElectionArea>[];

    if (selectedElectionType == 'zp_ps_combined') {
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
      if (selectedBodyId != null && selectedWard != null) {
        electionAreas.add(ElectionArea(
          bodyId: selectedBodyId!,
          wardId: selectedWard!.id,
          area: selectedArea,
          type: ElectionType.regular,
        ));
      }
    }

    return electionAreas;
  }

  Future<void> _saveUserData(UserModel updatedUser) async {
    final currentUser = FirebaseAuth.instance.currentUser!;
    await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).set({
      ...updatedUser.toJson(),
      'birthDate': selectedBirthDate?.toIso8601String(),
      'gender': selectedGender,
      'area': selectedArea,
      'profileCompleted': true,
    });
  }

  Future<void> _createCandidateRecord(String currentRole, String currentUserUid) async {
    try {
      int? age;
      if (selectedBirthDate != null) {
        final now = DateTime.now();
        age = now.year - selectedBirthDate!.year;
        if (now.month < selectedBirthDate!.month ||
            (now.month == selectedBirthDate!.month && now.day < selectedBirthDate!.day)) {
          age--;
        }
      }

      // Get FCM token from user profile if available
      String? userFcmToken;
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUserUid).get();
        userFcmToken = userDoc.data()?['fcmToken'] as String?;
      } catch (e) {
        AppLogger.common('⚠️ Could not fetch FCM token during candidate creation: $e');
      }

      final candidate = Candidate(
        candidateId: 'temp_$currentUserUid',
        userId: currentUserUid,
        party: selectedPartyId ?? 'independent',
        location: LocationModel(
          stateId: selectedStateId,
          districtId: selectedDistrictId,
          bodyId: selectedBodyId,
          wardId: selectedWard!.id,
        ),
        contact: ExtendedContact(
          phone: '+91${phoneController.text.trim()}',
          email: FirebaseAuth.instance.currentUser!.email,
        ),
        sponsored: false,
        createdAt: DateTime.now(),
        manifestoData: null,
        basicInfo: BasicInfoModel(
          fullName: nameController.text.trim(),
          dateOfBirth: selectedBirthDate,
          age: age,
          gender: selectedGender,
        ),
        fcmToken: userFcmToken, // Include FCM token if available
      );

      AppLogger.common('🏗️ Profile Completion: Creating candidate record for ${candidate.basicInfo!.fullName}');
      // 🚀 OPTIMIZATION: Pass stateId directly instead of making it search for it
      final actualCandidateId = await candidateRepository.createCandidate(candidate, stateId: selectedStateId);

      // Update user document with candidateId
      await FirebaseFirestore.instance.collection('users').doc(currentUserUid).update({'candidateId': actualCandidateId});

      // Send notification (non-blocking)
      try {
        final constituencyNotifications = ConstituencyNotifications();
        // Don't await - let it run in background
        constituencyNotifications.sendCandidateProfileCreatedNotification(candidateId: actualCandidateId);
      } catch (e) {
        AppLogger.commonError('⚠️ Failed to send new candidate notification', error: e);
      }
    } catch (e) {
      AppLogger.commonError('⚠️ Failed to create basic candidate record', error: e);
    }
  }

  Future<void> saveProfile(BuildContext context) async {
    final startTime = DateTime.now();
    AppLogger.common('⏱️ [PROFILE_COMPLETION] Starting profile save operation');

    final localizations = ProfileLocalizations.of(context)!;

    // Early validations with immediate returns
    if (!_validateBasicFields(context)) {
      final validationTime = DateTime.now().difference(startTime).inMilliseconds;
      AppLogger.common('❌ [PROFILE_COMPLETION] Validation failed after ${validationTime}ms');
      return;
    }

    // Get user role to determine which save method to use
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      Get.snackbar(localizations.error, 'User not authenticated');
      final authTime = DateTime.now().difference(startTime).inMilliseconds;
      AppLogger.common('❌ [PROFILE_COMPLETION] User not authenticated after ${authTime}ms');
      return;
    }

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
    final currentRole = userDoc.data()?['role'] ?? 'voter';

    AppLogger.common('👤 [PROFILE_COMPLETION] User role: $currentRole, starting save operation');

    // Delegate to role-specific save methods
    if (currentRole == 'candidate') {
      await _saveCandidateProfile(context, currentUser, localizations);
    } else {
      await _saveVoterProfile(context, currentUser, localizations);
    }

    final totalTime = DateTime.now().difference(startTime).inMilliseconds;
    AppLogger.common('✅ [PROFILE_COMPLETION] Profile save completed successfully in ${totalTime}ms');
  }

  Future<void> _saveVoterProfile(BuildContext context, User currentUser, ProfileLocalizations localizations) async {
    final voterStartTime = DateTime.now();
    AppLogger.common('🗳️ [PROFILE_COMPLETION] Starting voter profile save');

    // Voter-specific validations
    if (!_validateVoterElectionType(context)) {
      AppLogger.common('❌ [PROFILE_COMPLETION] Voter election type validation failed');
      return;
    }
    if (!_validateVoterElectionFields(context)) {
      AppLogger.common('❌ [PROFILE_COMPLETION] Voter election fields validation failed');
      return;
    }
    if (!_validateVoterAdditionalFields(context)) {
      AppLogger.common('❌ [PROFILE_COMPLETION] Voter additional fields validation failed');
      return;
    }

    isLoading = true;
    update();

    try {
      final electionAreasStartTime = DateTime.now();
      final electionAreas = _createElectionAreas();
      final electionAreasTime = DateTime.now().difference(electionAreasStartTime).inMilliseconds;
      AppLogger.common('📊 [PROFILE_COMPLETION] Election areas created in ${electionAreasTime}ms');

      final userModelStartTime = DateTime.now();
      final updatedUser = UserModel(
        uid: currentUser.uid,
        name: nameController.text.trim(),
        phone: '+91${phoneController.text.trim()}',
        email: currentUser.email,
        role: 'voter',
        roleSelected: true,
        profileCompleted: true,
        location: LocationModel(
          stateId: selectedStateId,
          districtId: selectedDistrictId,
          bodyId: selectedBodyId,
          wardId: selectedWard?.id,
        ),
        electionAreas: electionAreas,
        xpPoints: 0,
        premium: false,
        createdAt: DateTime.now(),
        photoURL: currentUser.photoURL,
      );
      final userModelTime = DateTime.now().difference(userModelStartTime).inMilliseconds;
      AppLogger.common('👤 [PROFILE_COMPLETION] User model created in ${userModelTime}ms');

      final saveUserStartTime = DateTime.now();
      await _saveUserData(updatedUser);
      final saveUserTime = DateTime.now().difference(saveUserStartTime).inMilliseconds;
      AppLogger.common('💾 [PROFILE_COMPLETION] User data saved in ${saveUserTime}ms');

      // Refresh chat for voter
      final chatRefreshStartTime = DateTime.now();
      try {
        await chatController.refreshUserDataAndChat();
        final chatRefreshTime = DateTime.now().difference(chatRefreshStartTime).inMilliseconds;
        AppLogger.common('💬 [PROFILE_COMPLETION] Chat data refreshed in ${chatRefreshTime}ms');
      } catch (e) {
        final chatRefreshTime = DateTime.now().difference(chatRefreshStartTime).inMilliseconds;
        AppLogger.commonError('⚠️ Failed to refresh chat data for voter after ${chatRefreshTime}ms, but profile saved', error: e);
      }

      // Navigate and show voter success message
      Get.offAllNamed('/home');
      Get.snackbar(
        localizations.success,
        localizations.profileCompleted,
        duration: const Duration(seconds: 4),
      );

      final totalVoterTime = DateTime.now().difference(voterStartTime).inMilliseconds;
      AppLogger.common('✅ [PROFILE_COMPLETION] Voter profile save completed in ${totalVoterTime}ms');
    } catch (e) {
      final errorTime = DateTime.now().difference(voterStartTime).inMilliseconds;
      AppLogger.commonError('❌ [PROFILE_COMPLETION] Voter profile save failed after ${errorTime}ms', error: e);
      Get.snackbar(localizations.error, localizations.failedToSaveProfile(e.toString()));
    }

    isLoading = false;
    update();
  }

  Future<void> _saveCandidateProfile(BuildContext context, User currentUser, ProfileLocalizations localizations) async {
    final candidateStartTime = DateTime.now();
    AppLogger.common('👤 [PROFILE_COMPLETION] Starting candidate profile save');

    // Candidate-specific validations
    if (!_validateCandidateElectionType(context)) {
      AppLogger.common('❌ [PROFILE_COMPLETION] Candidate election type validation failed');
      return;
    }
    if (!_validateCandidateElectionFields(context)) {
      AppLogger.common('❌ [PROFILE_COMPLETION] Candidate election fields validation failed');
      return;
    }
    if (!_validateCandidateAdditionalFields(context)) {
      AppLogger.common('❌ [PROFILE_COMPLETION] Candidate additional fields validation failed');
      return;
    }

    isLoading = true;
    update();

    try {
      // Show initial loading status
      _updateLoadingStatus('Creating election areas...');

      final electionAreasStartTime = DateTime.now();
      final electionAreas = _createElectionAreas();
      final electionAreasTime = DateTime.now().difference(electionAreasStartTime).inMilliseconds;
      AppLogger.common('📊 [PROFILE_COMPLETION] Election areas created in ${electionAreasTime}ms');

      _updateLoadingStatus('Preparing user profile...');

      final userModelStartTime = DateTime.now();
      final updatedUser = UserModel(
        uid: currentUser.uid,
        name: nameController.text.trim(),
        phone: '+91${phoneController.text.trim()}',
        email: currentUser.email,
        role: 'candidate',
        roleSelected: true,
        profileCompleted: true,
        location: LocationModel(
          stateId: selectedStateId,
          districtId: selectedDistrictId,
          bodyId: selectedBodyId,
          wardId: selectedWard!.id,
        ),
        electionAreas: electionAreas,
        xpPoints: 0,
        premium: false,
        subscriptionPlanId: 'free_plan',
        createdAt: DateTime.now(),
        photoURL: currentUser.photoURL,
      );
      final userModelTime = DateTime.now().difference(userModelStartTime).inMilliseconds;
      AppLogger.common('👤 [PROFILE_COMPLETION] User model created in ${userModelTime}ms');

      _updateLoadingStatus('Saving profile data...');

      final saveUserStartTime = DateTime.now();
      await _saveUserData(updatedUser);
      final saveUserTime = DateTime.now().difference(saveUserStartTime).inMilliseconds;
      AppLogger.common('💾 [PROFILE_COMPLETION] User data saved in ${saveUserTime}ms');

      _updateLoadingStatus('Creating candidate record...');

      // Create candidate record (this is the main bottleneck we optimized)
      final candidateRecordStartTime = DateTime.now();
      await _createCandidateRecord('candidate', currentUser.uid);
      final candidateRecordTime = DateTime.now().difference(candidateRecordStartTime).inMilliseconds;
      AppLogger.common('🏗️ [PROFILE_COMPLETION] Candidate record created in ${candidateRecordTime}ms');

      // 🚀 OPTIMIZATION: Skip chat operations during profile completion
      // Chat setup will happen when user first accesses chat feature
      // This saves significant time and prevents blocking profile completion
      /*
      _updateLoadingStatus('Setting up chat system...');

      // Chat refresh is not critical for profile completion - can fail without breaking the flow
      try {
        // Don't await - let it run in background after profile completion
        chatController.refreshUserDataAndChat().then((_) {
          AppLogger.common('💬 [PROFILE_COMPLETION] Chat data refreshed successfully (background)');
        }).catchError((e) {
          AppLogger.commonError('⚠️ Chat data refresh failed in background, but profile completed', error: e);
        });

        // Create chat room in background (also non-critical)
        FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get().then((userDoc) {
          if (userDoc.exists && userDoc.data()?['candidateId'] != null) {
            final candidateId = userDoc.data()!['candidateId'];
            chatController.createCandidateChatRoom(candidateId, nameController.text.trim());
          }
        }).catchError((e) {
          AppLogger.commonError('⚠️ Chat room creation failed in background', error: e);
        });
      } catch (e) {
        AppLogger.commonError('⚠️ Failed to start background chat operations, but profile saved', error: e);
      }
      */

      _updateLoadingStatus('Profile completed successfully!');

      // Small delay to show success message
      await Future.delayed(const Duration(milliseconds: 500));

      // Navigate and show candidate success message
      Get.offAllNamed('/home');
      Get.snackbar(
        localizations.profileCompleted,
        localizations.profileCompletedMessage,
        duration: const Duration(seconds: 4),
      );

      final totalCandidateTime = DateTime.now().difference(candidateStartTime).inMilliseconds;
      AppLogger.common('✅ [PROFILE_COMPLETION] Candidate profile save completed in ${totalCandidateTime}ms');
    } catch (e) {
      final errorTime = DateTime.now().difference(candidateStartTime).inMilliseconds;
      AppLogger.commonError('❌ [PROFILE_COMPLETION] Candidate profile save failed after ${errorTime}ms', error: e);
      Get.snackbar(localizations.error, localizations.failedToSaveProfile(e.toString()));
    }

    isLoading = false;
    update();
  }

  // Helper method to update loading status
  void _updateLoadingStatus(String status) {
    // This would be used by a loading overlay to show current operation
    AppLogger.common('🔄 [PROFILE_COMPLETION] Status: $status');
    update(); // Trigger UI update to show new status
  }
}
