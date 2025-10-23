import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:janmat/features/user/services/user_cache_service.dart';
import '../../../../../../../utils/app_logger.dart';
import '../../chat/controllers/chat_controller.dart';

/// Service responsible for synchronizing user document updates.
/// Follows Single Responsibility Principle - handles only user document sync.
class UserSyncService {
  /// Update user document for basic info fields (name, photo)
  Future<bool> updateUserDocumentForBasicInfo({
    required String candidateName,
    required String? candidatePhoto,
    required String? originalName,
    required String? originalPhoto,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      // Get current user data
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return false;
      final userData = userDoc.data()!;

      Map<String, dynamic> userUpdates = {};

      // Check if name was changed
      if (candidateName != originalName) {
        userUpdates['name'] = candidateName;
        AppLogger.database('Updating user name: $candidateName', tag: 'USER_SYNC_SERVICE');
      }

      // Check if photo was changed
      if (candidatePhoto != originalPhoto) {
        userUpdates['photo'] = candidatePhoto;
        AppLogger.database('Updating user photo: $candidatePhoto', tag: 'USER_SYNC_SERVICE');
      }

      // Update user document if there are changes
      if (userUpdates.isNotEmpty) {
        await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(userUpdates);

        AppLogger.database('User document updated with: ${userUpdates.keys.join(', ')}', tag: 'USER_SYNC_SERVICE');

        // Invalidate cached user data in ChatController and other controllers
        await _invalidateUserCache(user.uid);

        // Update UserCacheService with new user data
        await _updateUserCache(userData, userUpdates, user.uid);

        return true; // Indicate that user document was updated
      }
      return false; // No updates made
    } catch (e) {
      AppLogger.databaseError('Error updating user document', tag: 'USER_SYNC_SERVICE', error: e);
      // Don't throw - allow candidate data to still be saved
      return false;
    }
  }

  /// Update user document for photo changes
  Future<bool> updateUserDocumentForPhoto(String photoUrl) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      // Get current user data
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return false;
      final userData = userDoc.data()!;

      // Update user document with new photo
      await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({'photo': photoUrl});

      AppLogger.database('User document updated with photo: $photoUrl', tag: 'USER_SYNC_SERVICE');

      // Invalidate cached user data in ChatController and other controllers
      await _invalidateUserCache(user.uid);

      // Update UserCacheService with new photo
      await _updateUserCache(userData, {'photo': photoUrl}, user.uid);

      return true;
    } catch (e) {
      AppLogger.databaseError('Error updating user document for photo', tag: 'USER_SYNC_SERVICE', error: e);
      return false;
    }
  }

  /// Invalidate user cache across controllers
  Future<void> _invalidateUserCache(String userId) async {
    try {
      final chatController = Get.find<ChatController>();
      chatController.invalidateUserCache(userId);
      AppLogger.database('Invalidated user cache after profile update', tag: 'USER_SYNC_SERVICE');
    } catch (e) {
      AppLogger.database('Could not invalidate chat controller cache: $e', tag: 'USER_SYNC_SERVICE');
    }
  }

  /// Update user cache service with new data
  Future<void> _updateUserCache(
    Map<String, dynamic> userData,
    Map<String, dynamic> updates,
    String userId,
  ) async {
    try {
      final userCacheService = UserCacheService();
      // Create updated user model
      final updatedUserData = {
        'uid': userId,
        'name': updates['name'] ?? userData['name'],
        'email': userData['email'],
        'photoURL': updates['photo'] ?? userData['photo'],
      };
      await userCacheService.updateCachedUserData(updatedUserData);
      AppLogger.database('Updated user cache after profile update', tag: 'USER_SYNC_SERVICE');
    } catch (e) {
      AppLogger.database('Could not update user cache: $e', tag: 'USER_SYNC_SERVICE');
    }
  }
}
