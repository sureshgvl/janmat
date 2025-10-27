import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/app_logger.dart';
import 'auth_repository.dart';

/// Business Logic Layer: Handles authentication flows, state management, and reactive UI updates
/// Clean separation between data (Repository) and logic (ViewModel)
enum AuthState { loading, loggedOut, loggedIn }

class AuthViewModel extends GetxController {
  // Repository for data operations
  late final AuthRepository _repo;

  // Reactive state
  var authState = AuthState.loading.obs;
  var user = Rxn<User>();
  var role = ''.obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;

  // UI state
  var showProfileCompletion = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeRepository();
    _initializeAuth();
  }

  /// Initialize repository dependency
  void _initializeRepository() {
    // Get SharedPreferences from GetX dependency injection
    final prefs = Get.find<SharedPreferences>();
    _repo = AuthRepository(prefs);
  }

  /// Initialize authentication state and setup listeners
  Future<void> _initializeAuth() async {
    AppLogger.auth('🔄 Initializing AuthViewModel...');

    // Clear any existing error state
    errorMessage.value = '';

    // Get current Firebase user (might be null)
    user.value = await _repo.getCurrentUser();

    // Try cache-first loading for instant UX
    final cachedRole = await _repo.getCachedRole();
    if (cachedRole != null && cachedRole.isNotEmpty) {
      role.value = cachedRole;
      AppLogger.auth('✅ CACHE FIRST: Loaded cached role - $cachedRole');

      // If we have cached auth data, show logged in state immediately
      if (user.value != null) {
        authState.value = AuthState.loggedIn;
        await _validateCurrentRole(); // Background server validation
        return;
      }
    }

    // Determine initial state
    if (user.value != null) {
      authState.value = AuthState.loggedIn;
      await _syncUserRole(); // Get fresh role from server
    } else {
      authState.value = AuthState.loggedOut;
    }

    // Setup reactive listeners for real-time updates
    _setupAuthStateListener();
    _setupRoleUpdateListener();

    AppLogger.auth('✅ AuthViewModel initialization complete');
  }

  /// Setup Firebase auth state listener for reactive UI updates
  void _setupAuthStateListener() {
    _repo.authStateChanges().listen(
      (User? firebaseUser) async {
        AppLogger.auth('🔄 Firebase auth state changed');

        // Update reactive user observable
        user.value = firebaseUser;

        if (firebaseUser == null) {
          // User logged out
          authState.value = AuthState.loggedOut;
          role.value = '';
          errorMessage.value = '';
          isLoading.value = false;
        } else {
          // User logged in or switched
          authState.value = AuthState.loggedIn;
          await _syncUserRole(); // Get/update role
        }
      },
      onError: (error) {
        AppLogger.error('AuthViewModel: Auth state listener error - $error');
        errorMessage.value = 'Authentication state error';
      },
    );
  }

  /// Setup role update listener (for future role changes, biometrics, etc.)
  void _setupRoleUpdateListener() {
    // Listen for potential role updates from other parts of the app
    ever(role, (String newRole) {
      if (newRole.isNotEmpty) {
        AppLogger.auth('🔄 Role updated reactively: $newRole');
        _onRoleChanged(newRole);
      }
    });
  }

  /// Handle role change events
  void _onRoleChanged(String newRole) {
    // Update UI state based on role
    showProfileCompletion.value =
        newRole == 'candidate' && !_isProfileCompleted();

    AppLogger.common('📱 Role UI state updated - Profile completion needed: ${showProfileCompletion.value}');
  }

  /// Check if user profile is completed (basic implementation)
  bool _isProfileCompleted() {
    // TODO: Implement based on actual profile completion logic
    return false; // Placeholder - implement user profile checks
  }

  /// Validate current cached role against server
  Future<void> _validateCurrentRole() async {
    if (user.value == null) return;

    try {
      AppLogger.auth('🔍 Validating cached role against server...');
      await _syncUserRole(); // This will update if cache doesn't match server
    } catch (error) {
      AppLogger.error('AuthViewModel: Role validation failed - $error');
      // Keep using cached role - better UX than no role
    }
  }

  /// Sync user role with Firebase (server truth)
  Future<void> _syncUserRole() async {
    if (user.value == null) {
      AppLogger.warning('AuthViewModel: Cannot sync role - no user');
      return;
    }

    try {
      AppLogger.auth('🔄 Syncing user role with server...');

      final userData = await _repo.fetchUserRole(user.value!.uid);

      if (userData != null && userData['role'] != null) {
        final serverRole = userData['role'] as String;

        // Cache for instant future loads
        await _repo.cacheRole(serverRole);

        // Update reactive state
        role.value = serverRole;

        AppLogger.auth('✅ ROLE SYNCED: Server role - $serverRole');
        _onRoleChanged(serverRole);
      } else {
        // No role from server - user might need role selection
        AppLogger.warning('AuthViewModel: No role found in Firestore');
        errorMessage.value = 'role_not_set';

        // Clear cached role
        role.value = '';
        await _repo.cacheRole('');
      }
    } catch (error) {
      AppLogger.error('AuthViewModel: Role sync failed - $error');
      errorMessage.value = 'Failed to sync user role';

      // Keep using cached role as fallback (don't break UX)
      final cachedRole = await _repo.getCachedRole();
      if (cachedRole?.isNotEmpty ?? false) {
        AppLogger.common('⚠️ Keeping cached role as fallback');
        role.value = cachedRole!;
      }
    }
  }

  /// Complete Google sign-in flow
  Future<bool> signInWithGoogle([bool forceAccountPicker = false]) async {
    try {
      AppLogger.auth('🚪 Starting Google sign-in flow...');
      errorMessage.value = '';
      isLoading.value = true;

      // 1. Get Google user account
      final googleUser = await _repo.signInWithGoogle(forceAccountPicker);

      if (googleUser == null) {
        AppLogger.warning('AuthViewModel: Google sign-in cancelled by user');
        isLoading.value = false;
        return false;
      }

      // 2. Create Firebase credential
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 3. Authenticate with Firebase
      final firebaseUser = await _repo.authenticateWithFirebase(credential);

      if (firebaseUser != null) {
        // Success - update state
        user.value = firebaseUser;
        authState.value = AuthState.loggedIn;

        // Get and cache role
        await _syncUserRole();

        AppLogger.auth('🎉 Google sign-in successful: ${firebaseUser.email}');
        isLoading.value = false;
        return true;
      } else {
        errorMessage.value = 'Firebase authentication failed';
        AppLogger.error('AuthViewModel: Firebase auth returned null');
      }
    } catch (error) {
      errorMessage.value = 'Sign-in failed: ${error.toString()}';
      AppLogger.error('AuthViewModel: Google sign-in error - $error');
    }

    isLoading.value = false;
    return false;
  }

  /// Get last Google account for UI display
  Future<Map<String, dynamic>?> getLastGoogleAccount() async {
    return await _repo.getLastGoogleAccount();
  }

  /// Force refresh role from server (emergency recovery)
  Future<void> refreshRole() async {
    await _syncUserRole();
  }

  /// Enhanced logout with clean state reset
  Future<void> logout() async {
    try {
      AppLogger.auth('🚪 Starting enhanced logout...');
      errorMessage.value = '';

      // Sign out from all providers
      await _repo.signOut();

      // Reset local state
      authState.value = AuthState.loggedOut;
      user.value = null;
      role.value = '';
      errorMessage.value = '';
      showProfileCompletion.value = false;

      Get.delete<AuthViewModel>();

      AppLogger.auth('🚪 Logout complete - clean slate');

      // Navigate to login (clears navigation stack)
      await Get.offAllNamed('/login');
    } catch (error) {
      errorMessage.value = 'Logout failed: ${error.toString()}';
      AppLogger.error('AuthViewModel: Logout error - $error');
    }
  }

  /// Get current user data for UI
  User? getCurrentUser() {
    return user.value;
  }

  /// Get current user role for UI
  String getCurrentRole() {
    return role.value;
  }

  /// Check if user is candidate role
  bool isCandidate() {
    return role.value == 'candidate';
  }

  /// Check if user is voter role
  bool isVoter() {
    return role.value == 'voter';
  }

  /// Check authentication status
  bool isAuthenticated() {
    return authState.value == AuthState.loggedIn && user.value != null;
  }
}
