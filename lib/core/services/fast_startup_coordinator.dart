import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/app_routes.dart';
import '../../../core/app_route_names.dart';
import '../../../utils/app_logger.dart';
import '../../../core/services/app_startup_service.dart';
import '../../../core/app_initializer.dart';
import '../../../controllers/theme_controller.dart';
import '../../../controllers/background_color_controller.dart';
import '../../../features/language/controller/language_controller.dart';
import '../../../utils/performance_monitor.dart';
import '../../../services/home_screen_stream_service.dart';
import '../../../features/user/services/user_status_manager.dart';

/// Coordinates fast app startup with parallel initialization
class FastStartupCoordinator {
  static final FastStartupCoordinator _instance = FastStartupCoordinator._internal();
  factory FastStartupCoordinator() => _instance;
  FastStartupCoordinator._internal();

  final _completer = Completer<Map<String, dynamic>>();
  bool _isInitializing = false;

  /// Start fast initialization and return completion future
  Future<Map<String, dynamic>> initializeFast() async {
    if (_isInitializing) return _completer.future;
    if (_completer.isCompleted) return _completer.future;

    _isInitializing = true;
    unawaited(_initializeAsync());
    return _completer.future;
  }

  /// Main async initialization - runs in background while splash shows
  Future<void> _initializeAsync() async {
    try {
      AppLogger.core('🚀 FAST STARTUP: Starting parallel initialization...');

      final stopwatch = Stopwatch()..start();

      // 🚀 PHASE 1: Initialize critical services parallel to Firebase setup
      final futuresPhase1 = [
        // Initialize basic controllers that are needed early
        _initializeEarlyControllers(),
        // Start Firebase and core services setup
        _initializeFirebaseServices(),
      ];

      await Future.wait(futuresPhase1);
      AppLogger.core('✅ PHASE 1: Core services initialized (${stopwatch.elapsedMilliseconds}ms)');

      // 🚀 PHASE 2: Get initial routing data while services continue initializing
      final routingData = await _getFastRoutingData();
      AppLogger.core('✅ PHASE 2: Routing data ready (${stopwatch.elapsedMilliseconds}ms)');

      // 🚀 PHASE 3: Finish remaining initialization in background
      unawaited(_completeBackgroundInitialization(routingData));

      // Complete with routing data for immediate navigation
      final startupData = {
        'isLoggedIn': routingData['isLoggedIn'],
        'initialRoute': routingData['initialRoute'],
        'user': routingData['user'],
        'totalTimeMs': stopwatch.elapsedMilliseconds,
      };

      AppLogger.core('🎯 FAST STARTUP COMPLETE: ${startupData['totalTimeMs']}ms → Route: ${startupData['initialRoute']}');

      _completer.complete(startupData);

    } catch (e, stackTrace) {
      AppLogger.coreError('❌ FAST STARTUP FAILED', error: e, stackTrace: stackTrace);

      // Fallback to default state on failure
      _completer.complete({
        'isLoggedIn': false,
        'initialRoute': AppRouteNames.languageSelection,
        'user': null,
        'totalTimeMs': -1,
      });
    }
  }

  /// Phase 1A: Initialize essential controllers (non-blocking UI)
  Future<void> _initializeEarlyControllers() async {
    try {
      // Initialize SharedPreferences FIRST (needed for other controllers)
      final prefs = await SharedPreferences.getInstance();
      Get.put<SharedPreferences>(prefs);
      AppLogger.core('✅ SharedPreferences initialized early');

      // Initialize controllers that are needed before first frame
      Get.put<ThemeController>(ThemeController());
      Get.put<BackgroundColorController>(BackgroundColorController());
      Get.put<LanguageController>(LanguageController());
      AppLogger.core('✅ Early controllers initialized');
    } catch (e) {
      AppLogger.coreError('⚠️ Early controllers failed', error: e);
      // Continue anyway
    }
  }

  /// Phase 1B: Initialize Firebase and core services
  Future<void> _initializeFirebaseServices() async {
    try {
      // Core startup service - Firebase, logging, tokens, etc.
      final startupService = AppStartupService();
      await startupService.initialize();

      // App initializer - additional services
      final appInitializer = AppInitializer();
      // Run in parallel to previous step
      await appInitializer.initialize();

      AppLogger.core('✅ Firebase and core services initialized');
    } catch (e) {
      AppLogger.coreError('⚠️ Firebase/core services failed', error: e);
      // Don't throw - let app continue with limited functionality
    }
  }

  /// Phase 2: Get routing data with fast auth check
  Future<Map<String, dynamic>> _getFastRoutingData() async {
    AppLogger.core('🔍 Getting fast routing data...');

    try {
      // Parallel auth and app state check
      final futures = [
        // Fast auth check
        FirebaseAuth.instance.authStateChanges().first.timeout(
          const Duration(seconds: 2),
          onTimeout: () => null,
        ),
        // App state check
        _getAppState(),
        // Quick user status check (if logged in)
        Future.value(null), // Placeholder for user data
      ];

      final results = await Future.wait(futures);
      final user = results[0] as User?;
      final appState = results[1] as Map<String, dynamic>;
      final isLoggedIn = user != null;

      // Determine initial route
      String initialRoute;
      if (!appState['isLanguageSelected']) {
        initialRoute = AppRouteNames.languageSelection;
      } else if (!appState['isOnboardingCompleted']) {
        initialRoute = AppRouteNames.onboarding;
      } else if (!isLoggedIn) {
        initialRoute = AppRouteNames.login;
      } else {
        // Quick route determination - deeper checks happen later in AppContent
        if (user != null) {
          initialRoute = AppRouteNames.home;
          // Unawaited deep routing check for logged-in users
          unawaited(_getDeepRoutingData(user, appState).then((deepRoute) {
            AppLogger.core('🔄 Deep routing check result: $deepRoute');
            // If deep check shows different route, navigate later in AppContent
          }));
        } else {
          initialRoute = AppRouteNames.login;
        }
      }

      return {
        'isLoggedIn': isLoggedIn,
        'user': user,
        'initialRoute': initialRoute,
      };

    } catch (e) {
      AppLogger.coreError('⚠️ Fast routing failed', error: e);
      return {
        'isLoggedIn': false,
        'user': null,
        'initialRoute': AppRouteNames.languageSelection,
      };
    }
  }

  /// Get app state (language, onboarding) synchronously
  Future<Map<String, dynamic>> _getAppState() async {
    try {
      final prefs = Get.find<SharedPreferences>();

      final isFirstTime = prefs.getBool('is_first_time') ?? true;
      final isLanguageSelected = !isFirstTime;
      final isOnboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

      return {
        'isLanguageSelected': isLanguageSelected,
        'isOnboardingCompleted': isOnboardingCompleted,
      };
    } catch (e) {
      AppLogger.core('⚠️ App state check failed: $e');
      return {
        'isLanguageSelected': false,
        'isOnboardingCompleted': false,
      };
    }
  }

  /// Deep routing check for logged-in users (runs in background)
  Future<String> _getDeepRoutingData(User user, Map<String, dynamic> appState) async {
    try {
      // Check cached routing data first
      final prefs = Get.find<SharedPreferences>();
      final routingKey = 'routing_data_${user.uid}';
      final routingData = prefs.getString(routingKey);

      if (routingData != null) {
        // Use cached routing data for faster navigation
        return AppRouteNames.home; // Default to home, fine-tune if needed
      }

      // If no cache, do quick Firebase check
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 3));

      if (userDoc != null && userDoc.exists) {
        final userData = userDoc.data();
        final role = userData?['role'] ?? '';
        final roleSelected = userData?['roleSelected'] ?? false;
        final profileCompleted = userData?['profileCompleted'] ?? false;

        if (!roleSelected) {
          return AppRouteNames.roleSelection;
        } else if (!profileCompleted) {
          return AppRouteNames.profileCompletion;
        }
      }

      return AppRouteNames.home;
    } catch (e) {
      AppLogger.core('⚠️ Deep routing check failed: $e');
      return AppRouteNames.home;
    }
  }

  /// Phase 3: Complete remaining initialization in background (non-blocking)
  Future<void> _completeBackgroundInitialization(Map<String, dynamic> routingData) async {
    try {
      AppLogger.core('🔄 Starting background initialization completion...');

      // Initialize remaining services that can run in background
      final backgroundTasks = <Future>[];

      // Service status manager
      backgroundTasks.add(UserStatusManager().initialize()
          .then((_) => AppLogger.core('✅ UserStatusManager initialized'))
          .catchError((e) => AppLogger.core('⚠️ UserStatusManager failed: $e')));

      // App bindings - Initialize Get controllers that need more setup
      try {
        await Get.putAsync<SharedPreferences>(() => SharedPreferences.getInstance());
        AppLogger.core('✅ SharedPreferences initialized');
      } catch (e) {
        AppLogger.coreError('⚠️ SharedPreferences failed, app may have limited functionality', error: e);
      }

      // Note: Other controllers are initialized via AppBindings when screens need them
      // This prevents conflicts and ensures proper dependency injection

      // Note: Additional lazy controllers are initialized via AppBindings when needed
      // This keeps the fast startup coordinator focused on core initialization

      // Performance monitoring
      PerformanceMonitor().stopTimer('app_startup');
      PerformanceMonitor().logSlowOperation('app_startup', 2000);

      await Future.wait(backgroundTasks);
      AppLogger.core('✅ All background initialization completed');

    } catch (e) {
      AppLogger.coreError('⚠️ Background initialization failed', error: e);
      // Don't throw - app is already running
    }
  }
}

/// Note: Real controller definitions are imported from their respective files above
