import 'package:firebase_auth/firebase_auth.dart';
import '../../../utils/app_logger.dart';
import '../services/phone_auth_service.dart';
import '../services/google_auth_service.dart';
import '../services/user_management_service.dart';
import '../services/storage_management_service.dart';
import '../services/account_deletion_service.dart';
import '../services/auth_cache_service.dart';

class AuthRepository {
  // Service instances
  final PhoneAuthService _phoneAuthService = PhoneAuthService();
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  final UserManagementService _userManagementService = UserManagementService();
  final StorageManagementService _storageManagementService = StorageManagementService();
  final AccountDeletionService _accountDeletionService = AccountDeletionService();
  final AuthCacheService _authCacheService = AuthCacheService();

  // Phone Authentication
  Future<void> verifyPhoneNumber(
    String phoneNumber,
    Function(String) onCodeSent,
  ) async {
    return _phoneAuthService.verifyPhoneNumber(phoneNumber, onCodeSent);
  }

  Future<UserCredential> signInWithOTP(
    String verificationId,
    String smsCode,
  ) async {
    return _phoneAuthService.signInWithOTP(verificationId, smsCode);
  }

  // Resend OTP using 2Factor
  Future<void> resendOTP(
    String phoneNumber,
    Function(String) onCodeSent,
  ) async {
    return _phoneAuthService.resendOTP(phoneNumber, onCodeSent);
  }

  // Google Authentication
  Future<UserCredential?> signInWithGoogle({bool forceAccountPicker = false}) async {
    return _googleAuthService.signInWithGoogle(forceAccountPicker: forceAccountPicker);
  }

  Future<Map<String, dynamic>?> getLastGoogleAccount() async {
    return _googleAuthService.getLastGoogleAccount();
  }

  Future<void> clearLastGoogleAccount() async {
    return _googleAuthService.clearLastGoogleAccount();
  }

  // User Management
  Future<void> createOrUpdateUser(
    User firebaseUser, {
    String? name,
    String? role,
  }) async {
    return _userManagementService.createOrUpdateUser(firebaseUser, name: name, role: role);
  }

  User? get currentUser => _userManagementService.currentUser;

  Stream<User?> get authStateChanges => _userManagementService.authStateChanges;

  // Storage Management
  Future<Map<String, dynamic>> getStorageInfo() async {
    return _storageManagementService.getStorageInfo();
  }

  Future<Map<String, dynamic>> manualStorageCleanup() async {
    return _storageManagementService.manualStorageCleanup();
  }

  Future<void> analyzeAndCleanupStorage() async {
    return _storageManagementService.analyzeAndCleanupStorage();
  }

  // Account Deletion
  Future<void> deleteAccount() async {
    return _accountDeletionService.deleteAccount();
  }

  // Sign out - Enhanced to properly clear Google Sign-In cache and temporary data
  Future<void> signOut() async {
    try {
      AppLogger.auth('🚪 Starting enhanced sign-out process...');

      // Step 1: Sign out from Firebase Auth
      await FirebaseAuth.instance.signOut();
      AppLogger.auth('✅ Firebase Auth sign-out completed');

      // Step 2: Sign out from Google
      await _googleAuthService.signOutFromGoogle();
      AppLogger.auth('✅ Google account signed out');

      // Step 3: Clear app setup flags to force language selection and onboarding on next login
      await _authCacheService.clearAppSetupFlags();
      AppLogger.auth('✅ App setup flags cleared (language selection and onboarding will be shown again)');

      // Step 4: Clear session-specific cache and temporary files (but keep user preferences)
      await _authCacheService.clearLogoutCache();
      AppLogger.auth('✅ Session cache cleared');

      // Step 5: Clear all GetX controllers to reset app state
      await _authCacheService.clearAllControllers();
      AppLogger.auth('✅ App controllers reset');

      AppLogger.auth('🚪 Enhanced sign-out completed successfully');
    } catch (e) {
      AppLogger.auth('⚠️ Error during enhanced sign-out: $e');
      // Fallback to basic sign-out if enhanced fails
      try {
        await FirebaseAuth.instance.signOut();
        await _googleAuthService.signOutFromGoogle();
        // Clear app setup flags even in fallback
        await _authCacheService.clearAppSetupFlags();
        await _authCacheService.clearLogoutCache();
        await _authCacheService.clearAllControllers();
        AppLogger.auth('⚠️ Fallback sign-out completed');
      } catch (fallbackError) {
        AppLogger.auth('Fallback sign-out also failed: $fallbackError');
        // At minimum, try to clear controllers
        try {
          await _authCacheService.clearAllControllers();
        } catch (controllerError) {
          AppLogger.auth('Controller cleanup also failed: $controllerError');
        }
      }
    }
  }

  // Clear all app setup flags (for complete reset)
  Future<void> clearAppSetupFlags() async {
    return _authCacheService.clearAppSetupFlags();
  }

  // Firebase Auth Reset - for corrupted auth state situations
  Future<void> resetFirebaseAuth() async {
    return _googleAuthService.resetFirebaseAuth();
  }
}
