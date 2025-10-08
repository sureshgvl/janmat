import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/language_service.dart';
import '../utils/multi_level_cache.dart';
import '../utils/app_logger.dart';

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

    // Check if onboarding is completed
    final isOnboardingCompleted = await _languageService.isOnboardingCompleted();
    if (!isOnboardingCompleted) {
      // Get stored language preference for onboarding
      final storedLocale = await _languageService.getStoredLocale();
      final locale = storedLocale ?? const Locale('en');
      return {'route': '/onboarding', 'locale': locale};
    }

    // Get stored language preference (fast local check)
    final storedLocale = await _languageService.getStoredLocale();
    final locale = storedLocale ?? const Locale('en');

    // Debug: Print current locale being used
    AppLogger.core('Initial app locale: ${locale.languageCode}');

    // Wait for Firebase Auth to properly initialize and determine auth state
    AppLogger.core('Waiting for Firebase Auth initialization...');
    final User? currentUser = await _waitForFirebaseAuthInitialization();

    if (currentUser == null) {
      AppLogger.core('No authenticated user found, showing login screen');
      return {'route': '/login', 'locale': locale};
    }

    AppLogger.core('User authenticated: ${currentUser.uid}, checking profile status...');

    // For authenticated users, check their completion status
    // OPTIMIZATION: Use cached user data if available, otherwise fetch quickly
    try {
      // Try to get from cache first (much faster)
      final cache = MultiLevelCache();
      final cachedUserData = await cache.get<Map<String, dynamic>>('user_${currentUser.uid}');

      Map<String, dynamic>? userData;
      if (cachedUserData != null) {
        userData = cachedUserData;
        AppLogger.core('Using cached user data for initial route determination');
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
            AppLogger.core('User data fetch timed out, using defaults');
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
            AppLogger.core('Routing data cached successfully');
          } catch (e) {
            AppLogger.coreError('Failed to cache routing data', error: e);
            // Continue without caching - not critical
          }
        }
      }

      if (userData != null) {
        // Create UserModel from raw data
        final userModel = UserModel.fromJson(userData);
        AppLogger.core('Raw user data: $userData');

        final role = userModel.role;
        final districtId = userModel.districtId ?? '';
        final bodyId = userModel.bodyId ?? '';
        final wardId = userModel.wardId;

        AppLogger.core('User state check - Role: "$role", District: "$districtId", Body: "$bodyId", Ward: "$wardId"');

        // Step 1: Check if role is selected
        if (role.isEmpty) {
          AppLogger.core('Redirecting to role selection - role is empty');
          return {'route': '/role-selection', 'locale': locale};
        }

        // Step 2: Check if profile is completed
        final profileCompleted = userModel.profileCompleted;
        AppLogger.core('Profile completion status: $profileCompleted');

        if (!profileCompleted) {
          // Profile not completed, go to profile completion
          AppLogger.core('Redirecting to profile completion - profile not completed');
          return {
            'route': '/profile-completion',
            'locale': locale,
            'userData': userData, // Pass user data to avoid duplicate fetch
          };
        }

        // Step 3: Profile is completed, go to home for all users
        AppLogger.core('Profile completed, redirecting to home');
        return {'route': '/home', 'locale': locale};
      } else {
        AppLogger.core('User document not found - redirecting to login');
        return {'route': '/login', 'locale': locale};
      }
    } catch (e) {
      AppLogger.coreError('Error checking user state', error: e);
      // On error, if user is authenticated, assume profile completed and go to home
      // This provides a permanent solution for hot reload issues
      if (currentUser != null) {
        AppLogger.core('User authenticated but data fetch failed, defaulting to home');
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

