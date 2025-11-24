import 'dart:async';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';
import '../../../utils/app_logger.dart';

class UserController extends GetxController {
  static UserController get to => Get.find();

  final Rx<UserModel?> user = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isInitialized = false.obs;

  final UserRepository _userRepository = UserRepository();
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSubscription;

  @override
  void onInit() {
    super.onInit();
    AppLogger.common('🧑 UserController initialized');
    _setupAuthStateListener();
  }

  /// Setup Firebase Auth state listener to automatically load user data on login
  void _setupAuthStateListener() {
    FirebaseAuth.instance.authStateChanges().listen((User? firebaseUser) {
      if (firebaseUser != null) {
        loadUserData(firebaseUser.uid);
      } else {
        clearUserData();
        _cancelUserDocSubscription();
      }
    });
  }

  /// Setup real-time listener for user document changes
  void _setupUserDocListener(String uid) {
    _cancelUserDocSubscription(); // Cancel any existing subscription

    _userDocSubscription = _userRepository.listenToUserDocument(uid).listen(
      (DocumentSnapshot<Map<String, dynamic>> snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          final userData = snapshot.data()!;
          user.value = UserModel.fromJson(userData);
          isInitialized.value = true;
          AppLogger.common('🔄 User data updated from real-time listener');
        }
      },
      onError: (error) {
        AppLogger.commonError('❌ Error in user document listener', error: error);
      },
    );
  }

  /// Cancel the user document subscription
  void _cancelUserDocSubscription() {
    _userDocSubscription?.cancel();
    _userDocSubscription = null;
  }

  @override
  void onClose() {
    AppLogger.common('🧑 UserController disposed');
    _cancelUserDocSubscription();
    super.onClose();
  }

  // Load user data from repository
  Future<void> loadUserData(String uid) async {
    if (isInitialized.value) {
      AppLogger.common('ℹ️ User data already loaded, skipping');
      return;
    }

    try {
      isLoading.value = true;
      AppLogger.common('📥 Loading user data for UID: $uid');

      final startTime = DateTime.now();
      final userDoc = await _userRepository.getUserDocument(uid);
      final loadDuration = DateTime.now().difference(startTime);

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        user.value = UserModel.fromJson(userData);
        isInitialized.value = true;

        // Setup real-time listener for future updates
        _setupUserDocListener(uid);

        AppLogger.common('✅ User data loaded successfully in ${loadDuration.inMilliseconds}ms');
        if (user.value != null) {
          AppLogger.common('👤 User: ${user.value!.name} (${user.value!.role})');
        }
      } else {
        // Document doesn't exist - this is normal for new users during role selection
        AppLogger.common('⚠️ User document not found for UID: $uid - likely new user, will load later');
        // Don't set isInitialized to true, so it will try again when document is created
        user.value = null; // Clear any existing user data
        return;
      }
    } catch (e) {
      AppLogger.commonError('❌ Failed to load user data', error: e);
      clearUserData(); // Reset to clean state
      // Don't rethrow for document-not-found errors to prevent app crashes for new users
      if (!e.toString().contains('User profile not found')) {
        rethrow;
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Update user data
  Future<void> updateUserData(Map<String, dynamic> updates) async {
    if (user.value == null) return;

    try {
      AppLogger.common('🔄 Updating user data: ${updates.keys.join(', ')}');

      await _userRepository.updateUserDocument(user.value!.uid, updates);

      // Update local user object using copyWith
      user.value = user.value!.copyWith(
        name: updates['name'],
        phone: updates['phone'],
        email: updates['email'],
        role: updates['role'],
        roleSelected: updates['roleSelected'],
        profileCompleted: updates['profileCompleted'],
        xpPoints: updates['xpPoints'],
        premium: updates['premium'],
        photoURL: updates['photoURL'],
        followingCount: updates['followingCount'],
      );

      AppLogger.common('✅ User data updated successfully');
    } catch (e) {
      AppLogger.commonError('❌ Failed to update user data', error: e);
      rethrow;
    }
  }

  // Refresh user data from repository
  Future<void> refreshUserData() async {
    if (user.value == null) return;

    try {
      AppLogger.common('🔄 Refreshing user data from repository');

      final userDoc = await _userRepository.getUserDocument(user.value!.uid);

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        user.value = UserModel.fromJson(userData);
        AppLogger.common('✅ User data refreshed successfully');
      }
    } catch (e) {
      AppLogger.commonError('❌ Failed to refresh user data', error: e);
    }
  }

  // Clear user data (on logout)
  void clearUserData() {
    user.value = null;
    isInitialized.value = false;
    isLoading.value = false;
    AppLogger.common('🧹 User data cleared');
  }

  // Get user property safely
  T? getUserProperty<T>(T? Function(UserModel) getter) {
    return user.value != null ? getter(user.value!) : null;
  }

  // Check if user has specific role
  bool hasRole(String role) {
    return user.value?.role == role;
  }

  // Check if profile is completed
  bool get isProfileCompleted {
    return user.value?.profileCompleted ?? false;
  }

  // Check if role is selected
  bool get isRoleSelected {
    return user.value?.roleSelected ?? false;
  }
}
