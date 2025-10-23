import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';
import '../../../utils/app_logger.dart';

class UserController extends GetxController {
  static UserController get to => Get.find();

  final Rx<UserModel?> user = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isInitialized = false.obs;

  final UserRepository _userRepository = UserRepository();

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
      }
    });
  }

  @override
  void onClose() {
    AppLogger.common('🧑 UserController disposed');
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

        AppLogger.common('✅ User data loaded successfully in ${loadDuration.inMilliseconds}ms');
        if (user.value != null) {
          AppLogger.common('👤 User: ${user.value!.name} (${user.value!.role})');
        }
      } else {
        AppLogger.common('⚠️ User document not found for UID: $uid');
        throw Exception('User profile not found');
      }
    } catch (e) {
      AppLogger.commonError('❌ Failed to load user data', error: e);
      rethrow;
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
