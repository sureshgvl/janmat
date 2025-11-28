import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_logger.dart';
import '../../../core/services/user_prefs_service.dart';

/// User Status Manager - Centralized service for managing role and profile status
/// with SharedPreferences for instant access and Firebase fallbacks
class UserStatusManager {
  static final UserStatusManager _instance = UserStatusManager._internal();
  factory UserStatusManager() => _instance;

  UserStatusManager._internal();

  static const String _roleKey = 'user_role';
  static const String _roleSelectedKey = 'user_role_selected';
  static const String _profileCompletedKey = 'user_profile_completed';
  static const String _lastUpdatedKey = 'user_status_last_updated';

  SharedPreferences? _prefs;
  final UserPrefsService _userPrefs = UserPrefsService();

  /// Initialize the status manager
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    AppLogger.common('✅ User Status Manager initialized');
  }

  /// Get user role with fallback strategy: SharedPreferences → Firebase
  Future<String?> getUserRole(String userId) async {
    try {
      // 1. Try SharedPreferences first (instant access)
      final role = _prefs?.getString('$_roleKey\_$userId');
      if (role != null && role.isNotEmpty) {
        AppLogger.common('⚡ User role from SharedPreferences: $role for user: $userId');
        return role;
      }

      // 2. Fallback to Firebase
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get(const GetOptions(source: Source.server));

      if (userDoc.exists) {
        final userData = userDoc.data();
        final firebaseRole = userData?['role'] as String?;
        if (firebaseRole != null && firebaseRole.isNotEmpty) {
          // Update SharedPreferences for future instant access
          await _updateSharedPreferences(userId, role: firebaseRole);
          AppLogger.common('🔥 User role from Firebase: $firebaseRole for user: $userId');
          return firebaseRole;
        }
      }

      AppLogger.common('⚠️ No role found for user: $userId');
      return null;
    } catch (e) {
      AppLogger.commonError('❌ Error getting user role for $userId', error: e);
      return null;
    }
  }

  /// Get role selected status with fallback strategy
  Future<bool> getRoleSelected(String userId) async {
    try {
      // 1. Try UserPrefsService first (global preference)
      if (_userPrefs.isRoleSelected) {
        AppLogger.common('⚡ Role selected from UserPrefsService: true for user: $userId');
        return true;
      }

      // 2. Fallback to Firebase
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get(const GetOptions(source: Source.server));

      if (userDoc.exists) {
        final userData = userDoc.data();
        final firebaseRoleSelected = userData?['roleSelected'] as bool? ?? false;
        if (firebaseRoleSelected) {
          await _userPrefs.setRoleSelected(true);
        }
        AppLogger.common('🔥 Role selected from Firebase: $firebaseRoleSelected for user: $userId');
        return firebaseRoleSelected;
      }

      return false;
    } catch (e) {
      AppLogger.commonError('❌ Error getting role selected status for $userId', error: e);
      return false;
    }
  }

  /// Get profile completed status with fallback strategy
  Future<bool> getProfileCompleted(String userId) async {
    try {
      // 1. Try UserPrefsService first (global preference)
      if (_userPrefs.isProfileCompleted) {
        AppLogger.common('⚡ Profile completed from UserPrefsService: true for user: $userId');
        return true;
      }

      // 2. Fallback to Firebase
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get(const GetOptions(source: Source.server));

      if (userDoc.exists) {
        final userData = userDoc.data();
        final firebaseProfileCompleted = userData?['profileCompleted'] as bool? ?? false;
        if (firebaseProfileCompleted) {
          await _userPrefs.setProfileCompleted(true);
        }
        AppLogger.common('🔥 Profile completed from Firebase: $firebaseProfileCompleted for user: $userId');
        return firebaseProfileCompleted;
      }

      return false;
    } catch (e) {
      AppLogger.commonError('❌ Error getting profile completed status for $userId', error: e);
      return false;
    }
  }

  /// Get complete user status (role, roleSelected, profileCompleted)
  Future<UserStatus> getUserStatus(String userId) async {
    final results = await Future.wait([
      getUserRole(userId),
      getRoleSelected(userId),
      getProfileCompleted(userId),
    ]);

    return UserStatus(
      role: results[0] as String?,
      roleSelected: results[1] as bool,
      profileCompleted: results[2] as bool,
    );
  }

  /// Update role when selected (called from role selection screen)
  Future<void> updateRole(String userId, String role) async {
    try {
      // Update SharedPreferences (user-specific role)
      await _updateSharedPreferences(userId, role: role);

      // Update UserPrefsService (global role selected flag)
      await _userPrefs.setRoleSelected(true);

      // Update Firebase (async, don't wait)
      _updateFirebaseAsync(userId, role: role, roleSelected: true);

      AppLogger.common('✅ Role updated to: $role for user: $userId');
    } catch (e) {
      AppLogger.commonError('❌ Error updating role for $userId', error: e);
      rethrow;
    }
  }

  /// Update profile completed status (called from profile completion screen)
  Future<void> updateProfileCompleted(String userId, bool completed) async {
    try {
      // Update UserPrefsService (global profile completed flag)
      await _userPrefs.setProfileCompleted(completed);

      // Update Firebase (async, don't wait)
      _updateFirebaseAsync(userId, profileCompleted: completed);

      AppLogger.common('✅ Profile completed updated to: $completed for user: $userId');
    } catch (e) {
      AppLogger.commonError('❌ Error updating profile completed for $userId', error: e);
      rethrow;
    }
  }

  /// Clear all status data for a user (logout, account deletion, etc.)
  Future<void> clearUserStatus(String userId) async {
    try {
      // Clear SharedPreferences (user-specific data)
      await _prefs?.remove('$_roleKey\_$userId');
      await _prefs?.remove('$_roleSelectedKey\_$userId');
      await _prefs?.remove('$_profileCompletedKey\_$userId');
      await _prefs?.remove('$_lastUpdatedKey\_$userId');

      // Clear UserPrefsService (global user flow data)
      await _userPrefs.clearAllUserData();

      AppLogger.common('🧹 Cleared all status data for user: $userId');
    } catch (e) {
      AppLogger.commonError('❌ Error clearing user status for $userId', error: e);
    }
  }

  /// Update SharedPreferences
  Future<void> _updateSharedPreferences(String userId, {
    String? role,
    bool? roleSelected,
    bool? profileCompleted,
  }) async {
    if (_prefs == null) return;

    if (role != null) {
      await _prefs!.setString('$_roleKey\_$userId', role);
    }
    if (roleSelected != null) {
      await _prefs!.setBool('$_roleSelectedKey\_$userId', roleSelected);
    }
    if (profileCompleted != null) {
      await _prefs!.setBool('$_profileCompletedKey\_$userId', profileCompleted);
    }

    await _prefs!.setString('$_lastUpdatedKey\_$userId', DateTime.now().toIso8601String());
  }


  /// Update Firebase asynchronously
  Future<void> _updateFirebaseAsync(String userId, {
    String? role,
    bool? roleSelected,
    bool? profileCompleted,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (role != null) updates['role'] = role;
      if (roleSelected != null) updates['roleSelected'] = roleSelected;
      if (profileCompleted != null) updates['profileCompleted'] = profileCompleted;

      if (updates.isNotEmpty) {
        // Use set with merge: true to create document if it doesn't exist
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .set(updates, SetOptions(merge: true));
        AppLogger.common('🔥 Firebase document created/updated for user: $userId with: $updates');
      }
    } catch (e) {
      AppLogger.commonError('❌ Error creating/updating Firebase document for $userId', error: e);
      // Don't rethrow - Firebase update failure shouldn't break the flow
    }
  }

  /// Get navigation route based on user status (priority: role selection first, then profile completion)
  Future<String?> getNavigationRoute(String userId) async {
    final status = await getUserStatus(userId);

    // If role not selected, go to role selection
    if (!status.roleSelected) {
      return '/role-selection';
    }

    // If profile not completed, go to profile completion
    if (!status.profileCompleted) {
      return '/profile-completion';
    }

    // Both completed, stay on home
    return null;
  }

  /// Check if user needs navigation (has incomplete setup)
  Future<bool> needsNavigation(String userId) async {
    final route = await getNavigationRoute(userId);
    return route != null;
  }
}

/// User status data class
class UserStatus {
  final String? role;
  final bool roleSelected;
  final bool profileCompleted;

  const UserStatus({
    required this.role,
    required this.roleSelected,
    required this.profileCompleted,
  });

  @override
  String toString() {
    return 'UserStatus(role: $role, roleSelected: $roleSelected, profileCompleted: $profileCompleted)';
  }
}
