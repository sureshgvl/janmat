import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../features/user/models/user_model.dart';
import '../services/language_service.dart';
import '../utils/multi_level_cache.dart';
import '../utils/app_logger.dart';
import '../utils/performance_monitor.dart' as perf;

/// Extension to handle Locale serialization/deserialization for JSON
extension LocaleJsonExtension on Locale {
  /// Convert Locale to a JSON serializable map
  Map<String, dynamic> toJson() {
    return {
      'languageCode': languageCode,
      if (countryCode != null) 'countryCode': countryCode,
      if (scriptCode != null) 'scriptCode': scriptCode,
    };
  }

  /// Create Locale from JSON map
  static Locale fromJson(Map<String, dynamic> json) {
    return Locale.fromSubtags(
      languageCode: json['languageCode'] as String,
      countryCode: json['countryCode'] as String?,
      scriptCode: json['scriptCode'] as String?,
    );
  }
}

class InitialAppDataService {
  final LanguageService _languageService = LanguageService();

  // STREAM FOR LANGUAGE DATA: Returns reactive stream of language preferences
  Stream<Map<String, dynamic>> getLanguageData() {
    return Stream.fromFuture(_getLanguageData());
  }

  // PRIVATE METHOD: Get language data from shared preferences
  Future<Map<String, dynamic>> _getLanguageData() async {
    final locale = await _languageService.getStoredLocale();
    return {'locale': locale};
  }

  Future<Map<String, dynamic>> getInitialAppData() async {
    // SIMPLE AUTH LOGIC: Check if user is logged in, that's it!

    // Get language preferences (no complex checks)
    final languageChecks = Future.wait([
      _languageService.getStoredLocale(),
    ]);

    final results = await languageChecks;
    final storedLocale = results[0] as Locale?;
    final locale = storedLocale ?? const Locale('en');

    // SIMPLE: Wait for Firebase Auth state (no timeout like Facebook/Twitter)
    User? currentUser;
    try {
      currentUser = await FirebaseAuth.instance.authStateChanges().first;
    } catch (e) {
      // If auth fails, user is not logged in
      currentUser = null;
    }

    if (currentUser != null) {
      // User is authenticated - go to home
      AppLogger.core('User authenticated: ${currentUser.uid}, navigating to home');
      return {'route': '/home', 'locale': locale.toJson()};
    } else {
      // User not authenticated - go to login
      AppLogger.core('No authenticated user, showing login screen');
      return {'route': '/login', 'locale': locale.toJson()};
    }
  }

  // Background refresh mechanism for user data
  Future<void> _refreshUserDataInBackground(String userId) async {
    try {
      AppLogger.core('🔄 Starting background user data refresh for: $userId');

      // Fetch fresh data from server
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get(const GetOptions(source: Source.server));

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final userModel = UserModel.fromJson(userData);

        // Update routing cache with fresh data
        final cache = MultiLevelCache();
        final role = userModel.role;
        final profileCompleted = userModel.profileCompleted;

        String route;
        if (role.isEmpty) {
          route = '/role-selection';
        } else if (!profileCompleted) {
          route = '/profile-completion';
        } else {
          route = '/home';
        }

        final updatedRoutingData = {
          'route': route,
          'locale': const Locale('en').toJson(), // Default locale
        };

        await cache.setUserRoutingData(userId, updatedRoutingData);
        AppLogger.core('✅ Background refresh completed for user: $userId');
      }
    } catch (e) {
      AppLogger.core('⚠️ Background refresh failed: $e');
      // Don't throw - background operation should not fail the app
    }
  }

  // PERFORMANCE: Robust auth check without timeout (like major apps)
  Future<User?> _fastFirebaseAuthCheck() async {
    // Immediate check - if we have a current user, return instantly
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      AppLogger.core('⚡ Firebase Auth has current user: ${currentUser.uid}');
      return currentUser;
    }

    // Wait for auth state changes without timeout (like Facebook/Twitter)
    // Firebase will restore auth state based on device and network conditions
    try {
      final user = await FirebaseAuth.instance.authStateChanges().first;
      AppLogger.core('Firebase Auth state determined: ${user?.uid ?? 'null'}');
      return user;
    } catch (e) {
      AppLogger.coreError('Error in auth state check - assuming no user for security', error: e);
      return null;
    }
  }

  // Wait for Firebase Auth to properly initialize (fallback method)
  Future<User?> _waitForFirebaseAuthInitialization() async {
    // First check if we already have a current user
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      AppLogger.core('Firebase Auth already has current user: ${currentUser.uid}');
      return currentUser;
    }

    // Wait for auth state changes with a timeout
    try {
      final user = await FirebaseAuth.instance.authStateChanges().first.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          AppLogger.core('Firebase Auth initialization timeout');
          return null;
        },
      );
      AppLogger.core('Firebase Auth state determined: ${user?.uid ?? 'null'}');
      return user;
    } catch (e) {
      AppLogger.coreError('Error waiting for Firebase Auth', error: e);
      return null;
    }
  }
}
