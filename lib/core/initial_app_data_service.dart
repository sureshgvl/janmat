import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/language_service.dart';
import '../utils/multi_level_cache.dart';

class InitialAppDataService {
  final LanguageService _languageService = LanguageService();

  Future<Map<String, dynamic>> getInitialAppData() async {
    // Check if it's first time user (fast local check)
    final isFirstTime = await _languageService.isFirstTimeUser();
    if (isFirstTime) {
      // Set default language to English for first-time users
      await _languageService.setDefaultLanguage('en');
      return {'route': '/language-selection', 'locale': const Locale('en')};
    }

    // Get stored language preference (fast local check)
    final storedLocale = await _languageService.getStoredLocale();
    final locale = storedLocale ?? const Locale('en');

    // Debug: Print current locale being used
    debugPrint('🌐 Initial app locale: ${locale.languageCode}');

    // Wait for Firebase Auth to properly initialize and determine auth state
    debugPrint('🔐 Waiting for Firebase Auth initialization...');
    final User? currentUser = await _waitForFirebaseAuthInitialization();

    if (currentUser == null) {
      debugPrint('🔐 No authenticated user found, showing login screen');
      return {'route': '/login', 'locale': locale};
    }

    debugPrint('🔐 User authenticated: ${currentUser.uid}, checking profile status...');

    // For authenticated users, check their completion status
    // OPTIMIZATION: Use cached user data if available, otherwise fetch quickly
    try {
      // Try to get from cache first (much faster)
      final cache = MultiLevelCache();
      final cachedUserData = await cache.get<Map<String, dynamic>>('user_${currentUser.uid}');

      Map<String, dynamic>? userData;
      if (cachedUserData != null) {
        userData = cachedUserData;
        debugPrint('⚡ Using cached user data for initial route determination');
      } else {
        // Fallback to Firestore query with timeout to prevent blocking
        final userDocFuture = FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        // Add timeout to prevent blocking UI for too long (longer in debug mode)
        final timeoutDuration = kDebugMode ? const Duration(seconds: 15) : const Duration(seconds: 5);
        final userDoc = await userDocFuture.timeout(
          timeoutDuration,
          onTimeout: () {
            debugPrint('⏰ User data fetch timed out, using defaults');
            throw TimeoutException('User data fetch timed out');
          },
        );

        if (userDoc.exists) {
          userData = userDoc.data()!;

          // Cache only essential routing data to avoid serialization issues
          try {
            final routingData = {
              'role': userData['role'],
              'profileCompleted': userData['profileCompleted'],
              'districtId': userData['districtId'],
            };
            await cache.set('user_${currentUser.uid}', routingData, ttl: Duration(hours: 1));
            debugPrint('✅ Routing data cached successfully');
          } catch (e) {
            debugPrint('⚠️ Failed to cache routing data: $e');
            // Continue without caching - not critical
          }
        }
      }

      if (userData != null) {
        debugPrint('🔍 Raw user data: $userData');

        final role = userData['role'] as String? ?? '';
        final districtId = userData['districtId'] as String? ?? '';

        // Extract location data from electionAreas (new structure) OR direct fields (legacy)
        String bodyId = userData['bodyId'] ?? '';
        String wardId = userData['wardId'] ?? '';

        if (userData['electionAreas'] != null && (userData['electionAreas'] as List).isNotEmpty) {
          final electionAreas = userData['electionAreas'] as List;
          debugPrint('🔍 User has ${electionAreas.length} election areas: $electionAreas');
          final regularArea = electionAreas.firstWhere(
            (area) => area['type'] == 'regular',
            orElse: () => electionAreas.first,
          );

          if (regularArea != null) {
            bodyId = regularArea['bodyId'] ?? bodyId; // Prefer electionAreas over direct fields
            wardId = regularArea['wardId'] ?? wardId;
          }
        }

        debugPrint('🔍 User state check - Role: "$role", District: "$districtId", Body: "$bodyId", Ward: "$wardId"');
        debugPrint('🔍 Direct fields - bodyId: "${userData['bodyId']}", wardId: "${userData['wardId']}"');

        // Step 1: Check if role is selected
        if (role.isEmpty) {
          debugPrint('🎯 Redirecting to role selection - role is empty');
          return {'route': '/role-selection', 'locale': locale};
        }

        // Step 2: Check if profile is completed
        final profileCompleted = userData['profileCompleted'] ?? false;
        debugPrint('🔍 Profile completion status: $profileCompleted');

        if (!profileCompleted) {
          // Profile not completed, go to profile completion
          debugPrint('🎯 Redirecting to profile completion - profile not completed');
          return {
            'route': '/profile-completion',
            'locale': locale,
            'userData': userData, // Pass user data to avoid duplicate fetch
          };
        }

        // Step 3: Profile is completed, go to home for all users
        debugPrint('✅ Profile completed, redirecting to home');
        return {'route': '/home', 'locale': locale};
      } else {
        debugPrint('⚠️ User document not found - redirecting to login');
        return {'route': '/login', 'locale': locale};
      }
    } catch (e) {
      debugPrint('⚠️ Error checking user state: $e');
      // On error, if user is authenticated, assume profile completed and go to home
      // This provides a permanent solution for hot reload issues
      if (currentUser != null) {
        debugPrint('🔄 User authenticated but data fetch failed, defaulting to home');
        return {'route': '/home', 'locale': locale};
      } else {
        return {'route': '/login', 'locale': locale};
      }
    }
  }

  // Wait for Firebase Auth to properly initialize
  Future<User?> _waitForFirebaseAuthInitialization() async {
    // First check if we already have a current user
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      debugPrint('🔐 Firebase Auth already has current user: ${currentUser.uid}');
      return currentUser;
    }

    // Wait for auth state changes with a timeout
    try {
      final user = await FirebaseAuth.instance.authStateChanges().first.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('⏰ Firebase Auth initialization timeout');
          return null;
        },
      );
      debugPrint('🔐 Firebase Auth state determined: ${user?.uid ?? 'null'}');
      return user;
    } catch (e) {
      debugPrint('⚠️ Error waiting for Firebase Auth: $e');
      return null;
    }
  }
}

