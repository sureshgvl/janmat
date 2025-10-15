import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/language_service.dart';
import '../utils/multi_level_cache.dart';
import '../utils/app_logger.dart';
import '../utils/performance_monitor.dart' as perf;

class InitialAppDataService {
  final LanguageService _languageService = LanguageService();

  Future<Map<String, dynamic>> getInitialAppData() async {
    perf.PerformanceMonitor().startTimer('initial_app_data');

    // PERFORMANCE OPTIMIZATION: Parallelize independent operations
    final languageChecks = Future.wait([
      _languageService.isFirstTimeUser(),
      _languageService.isOnboardingCompleted(),
      _languageService.getStoredLocale(),
    ]);

    final results = await languageChecks;
    final isFirstTime = results[0] as bool;
    final isOnboardingCompleted = results[1] as bool;
    final storedLocale = results[2] as Locale?;

    // Fast path for first-time users
    if (isFirstTime) {
      await _languageService.setDefaultLanguage('en');
      return {'route': '/language-selection', 'locale': const Locale('en')};
    }

    // Fast path for incomplete onboarding
    if (!isOnboardingCompleted) {
      final locale = storedLocale ?? const Locale('en');
      return {'route': '/onboarding', 'locale': locale};
    }

    final locale = storedLocale ?? const Locale('en');
    AppLogger.core('Initial app locale: ${locale.languageCode}');

    // PERFORMANCE: Ultra-fast auth check with minimal timeout
    final User? currentUser = await _fastFirebaseAuthCheck();

    if (currentUser == null) {
      AppLogger.core('No authenticated user found, showing login screen');
      return {'route': '/login', 'locale': locale};
    }

    AppLogger.core('User authenticated: ${currentUser.uid}, checking profile status...');

    // PERFORMANCE: Aggressive caching with instant fallback
    try {
      final cache = MultiLevelCache();
      final cacheKey = 'user_routing_${currentUser.uid}';

      // Try cache first (instant)
      final cachedRoutingData = await cache.get<Map<String, dynamic>>(cacheKey);
      if (cachedRoutingData != null) {
        AppLogger.core('⚡ Using cached routing data for instant navigation');
        return cachedRoutingData;
      }

      // Fast parallel fetch: cache + server race
      final cacheFuture = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get(const GetOptions(source: Source.cache));

      final serverFuture = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 2));

      // Race condition: whichever completes first wins
      final userDoc = await Future.any([cacheFuture, serverFuture]);

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final userModel = UserModel.fromJson(userData);

        final role = userModel.role;
        final profileCompleted = userModel.profileCompleted;

        AppLogger.core('User state check - Role: "$role", Profile: $profileCompleted');

        // Determine route based on user state
        String route;
        if (role.isEmpty) {
          route = '/role-selection';
        } else if (!profileCompleted) {
          route = '/profile-completion';
        } else {
          route = '/home';
        }

        final result = {'route': route, 'locale': locale};
        if (route == '/profile-completion') {
          result['userData'] = userData; // Pass data to avoid refetch
        }

        // Cache routing decision for instant future loads
        try {
          await cache.set(cacheKey, result, ttl: const Duration(hours: 1));
          AppLogger.core('💾 Routing data cached for instant future loads');
        } catch (e) {
          AppLogger.core('⚠️ Failed to cache routing data');
        }

        return result;
      } else {
        AppLogger.core('User document not found - redirecting to login');
        return {'route': '/login', 'locale': locale};
      }
    } catch (e) {
      AppLogger.coreError('Error checking user state', error: e);
      perf.PerformanceMonitor().stopTimer('initial_app_data');
      perf.PerformanceMonitor().logSlowOperation('initial_app_data', 1000); // Log if > 1 second

      // On error, default to home for authenticated users (fail-safe)
      if (currentUser != null) {
        AppLogger.core('User authenticated but data fetch failed, defaulting to home');
        return {'route': '/home', 'locale': locale};
      } else {
        return {'route': '/login', 'locale': locale};
      }
    }
  }

  // PERFORMANCE: Ultra-fast auth check with instant fallback
  Future<User?> _fastFirebaseAuthCheck() async {
    // Immediate check - if we have a current user, return instantly
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      AppLogger.core('⚡ Firebase Auth has current user: ${currentUser.uid}');
      return currentUser;
    }

    // Very short timeout for auth state determination (1 second instead of 5)
    try {
      final user = await FirebaseAuth.instance.authStateChanges().first.timeout(
        const Duration(seconds: 1),
        onTimeout: () {
          AppLogger.core('⚡ Firebase Auth check timeout - assuming no user');
          return null;
        },
      );
      AppLogger.core('Firebase Auth state determined: ${user?.uid ?? 'null'}');
      return user;
    } catch (e) {
      AppLogger.coreError('Error in fast auth check', error: e);
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

