/// Service class for handling user information retrieval
import 'package:get/get.dart';
import 'package:janmat/features/candidate/controllers/candidate_user_controller.dart';
import 'package:janmat/features/auth/controllers/auth_controller.dart';

class UserInfoService {
  UserInfoService._();

  /// Get current user ID
  static String getCurrentUserId() {
    try {
      final authController = Get.find<AuthController>();
      final currentUser = authController.currentUser.value;
      return currentUser?.uid ?? '';
    } catch (e) {
      return '';
    }
  }

  /// Get current user information (name and photo)
  static Map<String, String> getCurrentUserInfo() {
    try {
      // Try to get user info from CandidateUserController first
      final candidateController = Get.find<CandidateUserController>();
      if (candidateController.candidate.value != null) {
        final candidate = candidateController.candidate.value!;
        return {
          'name': candidate.basicInfo?.fullName ?? 'Anonymous User',
          'photo': candidate.basicInfo?.photo ?? '',
        };
      }
    } catch (e) {
      // Continue to fallback
    }

    // Fallback to auth user display name
    try {
      final authController = Get.find<AuthController>();
      final currentUser = authController.currentUser.value;
      
      return {
        'name': currentUser?.displayName ?? 'Anonymous User',
        'photo': currentUser?.photoURL ?? '',
      };
    } catch (e) {
      return {
        'name': 'Anonymous User',
        'photo': '',
      };
    }
  }

  /// Check if user is logged in
  static bool isUserLoggedIn() {
    try {
      final authController = Get.find<AuthController>();
      final currentUser = authController.currentUser.value;
      return currentUser != null && currentUser.uid.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get candidate display name
  static String getCandidateDisplayName(Map<String, dynamic>? candidateData) {
    if (candidateData == null) return 'Unknown Candidate';
    
    try {
      final basicInfo = candidateData['basicInfo'];
      if (basicInfo != null) {
        final fullName = basicInfo['fullName'];
        if (fullName != null && fullName.toString().isNotEmpty) {
          return fullName.toString();
        }
      }
    } catch (e) {
      // Continue to fallback
    }

    return candidateData['fullName']?.toString() ?? 'Unknown Candidate';
  }

  /// Get candidate photo URL
  static String getCandidatePhotoUrl(Map<String, dynamic>? candidateData) {
    if (candidateData == null) return '';
    
    try {
      final basicInfo = candidateData['basicInfo'];
      if (basicInfo != null) {
        final photo = basicInfo['photo'];
        if (photo != null && photo.toString().isNotEmpty) {
          return photo.toString();
        }
      }
    } catch (e) {
      // Continue to fallback
    }

    return candidateData['photo']?.toString() ?? '';
  }

  /// Validate user permissions for editing posts
  static bool canEditPost(String? postAuthorId) {
    final currentUserId = getCurrentUserId();
    return currentUserId.isNotEmpty && currentUserId == postAuthorId;
  }

  /// Get user initials from name for avatar fallback
  static String getUserInitials(String name) {
    if (name.isEmpty) return 'U';
    
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, 2).toUpperCase();
    } else {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
  }
}
