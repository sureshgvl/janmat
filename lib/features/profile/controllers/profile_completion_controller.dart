import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:janmat/features/user/models/user_model.dart';
import 'package:janmat/features/user/services/user_status_manager.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/snackbar_utils.dart';
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
import '../../../core/services/cache_service.dart';

import '../../notifications/services/constituency_notifications.dart';

class ProfileCompletionController extends GetxController {
  // User data passed from main.dart to avoid duplicate Firebase call
  Map<String, dynamic>? passedUserData;
  bool profileCompleted = false;

  final formKey = GlobalKey<FormState>();
  final AuthController loginController = Get.find<AuthController>();
  final ChatController chatController = Get.find<ChatController>();
  final candidateRepository = CandidateRepository();

  // No local database service - using only Firebase for web compatibility

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
  String _loginMethod = 'unknown';

  String get loginMethod => _loginMethod;

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

    // Detect login method
    _loginMethod = 'unknown';
    if (currentUser.providerData.isNotEmpty) {
      final provider = currentUser.providerData.first;
      if (provider.providerId == 'google.com') {
        _loginMethod = 'google';
      } else if (provider.providerId == 'phone') {
        _loginMethod = 'phone';
      }
    }

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
    AppLogger.common('  Login Method: $_loginMethod');
    AppLogger.common('  Email: ${currentUser.email}');
    AppLogger.common('  Photo: ${currentUser.photoURL}');

    // Trigger rebuild to show helper text
    update();
  }

  Future<void> loadStates() async {
    try {
      AppLogger.common('🔍 Loading states (fresh from Firestore, then cache)');

      // Load states from Firestore
      final statesSnapshot = await FirebaseFirestore.instance
          .collection('states')
          .get();

      AppLogger.common(
        '📊 Found ${statesSnapshot.docs.length} states in Firestore',
      );

      if (statesSnapshot.docs.isNotEmpty) {
        final allStatesMap = <String, Map<String, dynamic>>{};

        for (final doc in statesSnapshot.docs) {
          final data = doc.data();
          // Remove Timestamp fields that can't be serialized to cache
          final serializableData = Map<String, dynamic>.from(data);
          serializableData.remove('createdAt');
          serializableData.remove('updatedAt');
          AppLogger.common('🏛️ State: ${doc.id} - ${serializableData['name'] ?? 'Unknown'} - Marathi: ${serializableData['marathiName']} - Code: ${serializableData['code']} - Active: ${serializableData['isActive']}');

          final stateData = {'id': doc.id, ...serializableData};
          allStatesMap[doc.id] = stateData;
        }

        // Cache the complete states map for future use
        await CacheService.saveData('states', allStatesMap);
        AppLogger.common('💾 Cached all states data');

        // Convert to State objects and filter
        states = allStatesMap.values.map((stateData) {
          return state_model.State.fromJson(stateData);
        }).toList();

        // Filter out inactive states
        final originalCount = states.length;
        states = states.where((state) => state.isActive != false).toList();
        final filteredCount = originalCount - states.length;

        if (filteredCount > 0) {
          AppLogger.common('🚫 Filtered out $filteredCount inactive states. Active states: ${states.length}');
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
      SnackbarUtils.showError('Failed to load states: $e'); // TODO: Localize this
      isLoadingStates = false;
      update();
    }
  }

  // Optimized: Load districts only for selected state (fresh from Firebase, then cache)
  Future<void> loadDistrictsForState(String stateId) async {
    const int maxRetries = 3;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        AppLogger.common('🔍 Loading districts for state: $stateId (fresh from Firebase, then cache)');

        // Load from Firestore (always fresh for profile selection)
        final districtsSnapshot = await FirebaseFirestore.instance
            .collection('states')
            .doc(stateId)
            .collection('districts')
            .get();

        AppLogger.common('📊 Found ${districtsSnapshot.docs.length} districts in state $stateId');

        // Clear previous data
        districts.clear();
        districtBodies.clear();

        // Create districts map for caching and objects for use
        final allDistrictsMap = <String, Map<String, dynamic>>{};
        for (final doc in districtsSnapshot.docs) {
          final data = doc.data();
          AppLogger.common('🏙️ District: ${doc.id} - ${data['name'] ?? 'Unknown'} - Active: ${data['isActive']}');

          // Remove Timestamp fields that can't be serialized to cache
          final serializableData = Map<String, dynamic>.from(data);
          serializableData.remove('createdAt');
          serializableData.remove('updatedAt');

          final districtData = {'id': doc.id, 'stateId': stateId, ...serializableData};
          allDistrictsMap[doc.id] = districtData;
        }

        // Cache the districts map for future use
        final cacheKey = 'districts_$stateId';
        await CacheService.saveData(cacheKey, allDistrictsMap);
        AppLogger.common('💾 Cached districts for state $stateId');

        // Convert to District objects and filter
        districts = allDistrictsMap.values.map((districtData) {
          return District.fromJson(districtData);
        }).toList();

        // Filter out inactive districts
        final originalDistrictCount = districts.length;
        districts = districts.where((district) => district.isActive != false).toList();
        final filteredDistrictCount = originalDistrictCount - districts.length;

        if (filteredDistrictCount > 0) {
          AppLogger.common('🚫 Filtered out $filteredDistrictCount inactive districts. Active districts: ${districts.length}');
        }

        AppLogger.common('✅ Loaded ${districts.length} active districts from Firestore for state $stateId');

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
          SnackbarUtils.showError('Failed to load districts after $maxRetries attempts: $e');
          isLoadingDistricts = false;
          update();
        }
      }
    }
  }

  // Helper method to load bodies for multiple districts (fresh from Firebase, then cache)
  Future<void> _loadBodiesForDistricts(String stateId) async {
    for (final district in districts) {
      try {
        AppLogger.common('🔍 Loading bodies for district: ${district.id} (fresh from Firebase, then cache)');

        final bodiesSnapshot = await FirebaseFirestore.instance
            .collection('states')
            .doc(stateId)
            .collection('districts')
            .doc(district.id)
            .collection('bodies')
            .get();

        AppLogger.common('📊 Found ${bodiesSnapshot.docs.length} bodies in district ${district.id}');

        // Create bodies map for caching
        final allBodiesMap = <String, Map<String, dynamic>>{};
        for (final doc in bodiesSnapshot.docs) {
          final data = doc.data();
          // Remove Timestamp fields that can't be serialized to cache
          final serializableData = Map<String, dynamic>.from(data);
          serializableData.remove('createdAt');
          serializableData.remove('updatedAt');
          final bodyData = {
            'id': doc.id,
            'districtId': district.id,
            'stateId': stateId,
            ...serializableData,
          };
          allBodiesMap[doc.id] = bodyData;
        }

        // Cache the bodies map for future use
        final cacheKey = 'bodies_${stateId}_${district.id}';
        await CacheService.saveData(cacheKey, allBodiesMap);
        AppLogger.common('💾 Cached bodies for district ${district.id}');

        // Convert to Body objects
        districtBodies[district.id] = allBodiesMap.values.map((bodyData) {
          return Body.fromJson(bodyData);
        }).toList();
      } catch (e) {
        AppLogger.commonError('❌ Failed to load bodies for district ${district.id}', error: e);
        districtBodies[district.id] = []; // Set empty list on error
      }
    }
  }

  // Optimized: Load bodies only for selected district (fresh from Firebase, then cache)
  Future<void> loadBodiesForDistrict(String districtId) async {
    try {
      AppLogger.common('🔍 Loading bodies for district: $districtId (fresh from Firebase, then cache)');

      // Clear previous bodies and wards for this district
      districtBodies.remove(districtId);
      bodyWards.clear();

      // Load from Firestore (always fresh for profile selection)
      final bodiesSnapshot = await FirebaseFirestore.instance
          .collection('states')
          .doc(selectedStateId!)
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .get();

      AppLogger.common('📊 Found ${bodiesSnapshot.docs.length} bodies in district $districtId');

      // Create bodies map for caching
      final allBodiesMap = <String, Map<String, dynamic>>{};
      for (final doc in bodiesSnapshot.docs) {
        final data = doc.data();
        // Remove Timestamp fields that can't be serialized to cache
        final serializableData = Map<String, dynamic>.from(data);
        serializableData.remove('createdAt');
        serializableData.remove('updatedAt');
        AppLogger.common('🏢 Body: ${doc.id} - ${serializableData['name'] ?? 'Unknown'} (${serializableData['type'] ?? 'Unknown'})');

        final bodyData = {
          'id': doc.id,
          'districtId': districtId,
          'stateId': selectedStateId!,
          ...serializableData,
        };
        allBodiesMap[doc.id] = bodyData;
      }

      // Cache the bodies map for future use
      final cacheKey = 'bodies_${selectedStateId}_${districtId}';
      await CacheService.saveData(cacheKey, allBodiesMap);
      AppLogger.common('💾 Cached bodies for district $districtId');

      // Convert to Body objects
      districtBodies[districtId] = allBodiesMap.values.map((bodyData) {
        return Body.fromJson(bodyData);
      }).toList();

      update();
      AppLogger.common('✅ Successfully loaded ${districtBodies[districtId]!.length} bodies for district $districtId');
    } catch (e) {
      AppLogger.commonError('❌ Failed to load bodies for district $districtId', error: e);
      SnackbarUtils.showError('Failed to load bodies: $e');
    }
  }

  // Optimized: Load wards only for selected body (fresh from Firebase, then cache)
  Future<void> loadWardsForBody(String districtId, String bodyId) async {
    try {
      AppLogger.common('🔍 [PROFILE_CONTROLLER] Loading wards for body: $bodyId in district: $districtId (fresh from Firebase, then cache)');

      // Clear previous wards for this body
      bodyWards.remove(bodyId);

      // Load from Firestore (always fresh for profile selection)
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

      // Create wards map for caching
      final allWardsMap = <String, Map<String, dynamic>>{};
      for (final doc in wardsSnapshot.docs) {
        final data = doc.data();
        // Remove Timestamp fields that can't be serialized to cache
        final serializableData = Map<String, dynamic>.from(data);
        serializableData.remove('createdAt');
        serializableData.remove('updatedAt');
        final wardData = {
          ...serializableData,
          'id': doc.id,  // Use 'id' field for Ward.fromJson
          'districtId': districtId,
          'bodyId': bodyId,
          'stateId': selectedStateId!,
        };
        allWardsMap[doc.id] = wardData;
      }

      // Cache the wards map for future use
      final cacheKey = 'wards_${selectedStateId}_${districtId}_${bodyId}';
      await CacheService.saveData(cacheKey, allWardsMap);
      AppLogger.common('💾 Cached wards for body $bodyId');

      // Convert to Ward objects
      bodyWards[bodyId] = allWardsMap.values.map((wardData) {
        return Ward.fromJson(wardData);
      }).toList();

      // Sort wards by ward number ascending
      bodyWards[bodyId]!.sort((a, b) {
        final aNumber = int.tryParse(RegExp(r'ward_(\d+)').firstMatch(a.id.toLowerCase())?.group(1) ?? '0') ?? 0;
        final bNumber = int.tryParse(RegExp(r'ward_(\d+)').firstMatch(b.id.toLowerCase())?.group(1) ?? '0') ?? 0;
        return aNumber.compareTo(bNumber);
      });

      update();
      AppLogger.common('✅ Successfully loaded ${bodyWards[bodyId]!.length} wards for body $bodyId');
    } catch (e) {
      AppLogger.commonError('❌ Failed to load wards for body $bodyId', error: e);
      SnackbarUtils.showError('Failed to load wards: $e');
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
      SnackbarUtils.showError(localizations.pleaseFillAllRequiredFields);
      return false;
    }

    return true;
  }

  // Voter-specific validation methods
  bool _validateVoterElectionType(BuildContext context) {
    final localizations = ProfileLocalizations.of(context)!;

    // Voters cannot select individual ZP or PS (must use combined)
    if (selectedElectionType == 'zilla_parishad' || selectedElectionType == 'panchayat_samiti') {
      SnackbarUtils.showError('Voters should select ZP+PS Combined for rural elections.');
      return false;
    }

    return true;
  }

  bool _validateVoterElectionFields(BuildContext context) {
    final localizations = ProfileLocalizations.of(context)!;

    if (selectedElectionType == 'zp_ps_combined') {
      if (selectedZPBodyId == null || selectedZPWardId == null ||
          selectedPSBodyId == null || selectedPSWardId == null) {
        SnackbarUtils.showError('Please select ZP body, ZP ward, PS body, and PS ward');
        return false;
      }
    } else {
      if (selectedBodyId == null || selectedWard == null) {
        SnackbarUtils.showError(localizations.pleaseFillAllRequiredFields);
        return false;
      }
    }

    return true;
  }

  bool _validateVoterAdditionalFields(BuildContext context) {
    final localizations = ProfileLocalizations.of(context)!;

    // For ZP+PS combined elections, validate ZP and PS areas
    if (selectedElectionType == 'zp_ps_combined') {
      if (selectedZPBodyId != null && selectedZPWardId != null && selectedZPArea == null) {
        SnackbarUtils.showError('Please select your ZP area');
        return false;
      }
      if (selectedPSBodyId != null && selectedPSWardId != null && selectedPSArea == null) {
        SnackbarUtils.showError('Please select your PS area');
        return false;
      }
    } else {
      // For regular elections, area selection required for voters if ward has areas
      if (selectedWard != null &&
          selectedWard!.areas != null &&
          selectedWard!.areas!.isNotEmpty &&
          selectedArea == null) {
        SnackbarUtils.showError(localizations.selectYourArea);
        return false;
      }
    }

    return true;
  }

  // Candidate-specific validation methods
  bool _validateCandidateElectionType(BuildContext context) {
    final localizations = ProfileLocalizations.of(context)!;

    // Candidates cannot select ZP+PS combined
    if (selectedElectionType == 'zp_ps_combined') {
      SnackbarUtils.showError('Candidates can only select one election type. ZP+PS combined is only for voters.');
      return false;
    }

    return true;
  }

  bool _validateCandidateElectionFields(BuildContext context) {
    final localizations = ProfileLocalizations.of(context)!;

    // Candidates can only have regular elections
    if (selectedBodyId == null || selectedWard == null) {
      SnackbarUtils.showError(localizations.pleaseFillAllRequiredFields);
      return false;
    }

    return true;
  }

  bool _validateCandidateAdditionalFields(BuildContext context) {
    final localizations = ProfileLocalizations.of(context)!;

    // Party selection required for candidates
    if (selectedPartyId == null) {
      SnackbarUtils.showError('Please select your political party');
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
      SnackbarUtils.showError('User not authenticated');
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
      await _saveVoterProfile(context, currentUser, localizations, currentRole);
    }

    final totalTime = DateTime.now().difference(startTime).inMilliseconds;
    AppLogger.common('✅ [PROFILE_COMPLETION] Profile save completed successfully in ${totalTime}ms');
  }

  Future<void> _saveVoterProfile(BuildContext context, User currentUser, ProfileLocalizations localizations, String currentRole) async {
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

      // No caching - data will be loaded fresh from Firebase on next access
      AppLogger.common('🧹 [PROFILE_COMPLETION] No caching to clear - using fresh Firebase data');

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

      // Update UserStatusManager for instant access
      try {
        await UserStatusManager().updateProfileCompleted(currentUser.uid, true);
        AppLogger.common('✅ [PROFILE_COMPLETION] UserStatusManager updated for voter profile completion');
      } catch (e) {
        AppLogger.commonError('⚠️ Failed to update UserStatusManager for voter profile completion', error: e);
        // Don't fail the profile completion if status manager update fails
      }

      // Navigate and show voter success message
      Get.offAllNamed('/home');
      SnackbarUtils.showSuccess(localizations.profileCompleted);

      final totalVoterTime = DateTime.now().difference(voterStartTime).inMilliseconds;
      AppLogger.common('✅ [PROFILE_COMPLETION] Voter profile save completed in ${totalVoterTime}ms');
    } catch (e) {
      final errorTime = DateTime.now().difference(voterStartTime).inMilliseconds;
      AppLogger.commonError('❌ [PROFILE_COMPLETION] Voter profile save failed after ${errorTime}ms', error: e);
      SnackbarUtils.showError(localizations.failedToSaveProfile(e.toString()));
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

      // Update UserStatusManager for instant access
      try {
        await UserStatusManager().updateProfileCompleted(currentUser.uid, true);
        AppLogger.common('✅ [PROFILE_COMPLETION] UserStatusManager updated for candidate profile completion');
      } catch (e) {
        AppLogger.commonError('⚠️ Failed to update UserStatusManager for candidate profile completion', error: e);
        // Don't fail the profile completion if status manager update fails
      }

      // Navigate and show candidate success message
      Get.offAllNamed('/home');
      SnackbarUtils.showSuccess(localizations.profileCompletedMessage);

      final totalCandidateTime = DateTime.now().difference(candidateStartTime).inMilliseconds;
      AppLogger.common('✅ [PROFILE_COMPLETION] Candidate profile save completed in ${totalCandidateTime}ms');
    } catch (e) {
      final errorTime = DateTime.now().difference(candidateStartTime).inMilliseconds;
      AppLogger.commonError('❌ [PROFILE_COMPLETION] Candidate profile save failed after ${errorTime}ms', error: e);
      SnackbarUtils.showError(localizations.failedToSaveProfile(e.toString()));
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
