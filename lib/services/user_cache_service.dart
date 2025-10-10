import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../utils/app_logger.dart';

class UserCacheService {
  static const String _userCacheKey = 'cached_user_profile';
  static const String _userDataKey = 'cached_user_data';
  static const String _cacheTimestampKey = 'user_cache_timestamp';
  static const Duration _cacheValidityDuration = Duration(hours: 24); // 24 hours

  // Cache complete user profile
  Future<void> cacheUserProfile(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(user.toJson());
      final timestamp = DateTime.now().toIso8601String();

      await Future.wait([
        prefs.setString(_userCacheKey, userJson),
        prefs.setString(_cacheTimestampKey, timestamp),
      ]);

      AppLogger.userCache('User profile cached successfully');
    } catch (e) {
      AppLogger.userCacheError('Error caching user profile: $e');
    }
  }

  // Get cached user profile
  Future<UserModel?> getCachedUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userCacheKey);

      if (userJson == null) return null;

      final userData = jsonDecode(userJson) as Map<String, dynamic>;
      return UserModel.fromJson(userData);
    } catch (e) {
      AppLogger.userCacheError('Error retrieving cached user profile: $e');
      return null;
    }
  }

  // Cache temporary user data during login
  Future<void> cacheTempUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userDataKey, jsonEncode(userData));
      AppLogger.userCache('Temporary user data cached');
    } catch (e) {
      AppLogger.userCacheError('Error caching temporary user data: $e');
    }
  }

  // Get cached temporary user data
  Future<Map<String, dynamic>?> getCachedTempUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tempDataJson = prefs.getString(_userDataKey);

      if (tempDataJson == null) return null;

      return jsonDecode(tempDataJson) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.userCacheError('Error retrieving cached temp user data: $e');
      return null;
    }
  }

  // Check if cache is valid
  Future<bool> isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampString = prefs.getString(_cacheTimestampKey);

      if (timestampString == null) return false;

      final cacheTime = DateTime.parse(timestampString);
      final now = DateTime.now();
      final difference = now.difference(cacheTime);

      return difference < _cacheValidityDuration;
    } catch (e) {
      AppLogger.userCacheError('Error checking cache validity: $e');
      return false;
    }
  }

  // Clear user cache
  Future<void> clearUserCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove(_userCacheKey),
        prefs.remove(_userDataKey),
        prefs.remove(_cacheTimestampKey),
      ]);
      AppLogger.userCache('User cache cleared');
    } catch (e) {
      AppLogger.userCacheError('Error clearing user cache: $e');
    }
  }

  // Get cached user data for quick access
  Future<Map<String, dynamic>?> getQuickUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Try to get cached user profile first
      final userJson = prefs.getString(_userCacheKey);
      if (userJson != null) {
        final userData = jsonDecode(userJson) as Map<String, dynamic>;
        return {
          'uid': userData['uid'],
          'name': userData['name'] ?? 'User',
          'email': userData['email'],
          'photoURL': userData['photoURL'],
          'cached': true,
        };
      }

      // Fallback to temporary user data
      final tempDataJson = prefs.getString(_userDataKey);
      if (tempDataJson != null) {
        final tempData = jsonDecode(tempDataJson) as Map<String, dynamic>;
        return {
          ...tempData,
          'cached': true,
        };
      }

      return null;
    } catch (e) {
      AppLogger.userCacheError('Error getting quick user data: $e');
      return null;
    }
  }

  // Update specific user data in cache
  Future<void> updateCachedUserData(Map<String, dynamic> updates) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingJson = prefs.getString(_userCacheKey);

      if (existingJson != null) {
        final existingData = jsonDecode(existingJson) as Map<String, dynamic>;
        existingData.addAll(updates);

        await prefs.setString(_userCacheKey, jsonEncode(existingData));
        AppLogger.userCache('Cached user data updated');
      }
    } catch (e) {
      AppLogger.userCacheError('Error updating cached user data: $e');
    }
  }
}

