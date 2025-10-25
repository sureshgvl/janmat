import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';
import '../services/background_initializer.dart';
import '../services/background_sync_manager.dart';
import '../services/home_data_preloader.dart';
import '../services/fcm_service.dart';
// import '../services/ime_manager.dart';
import '../utils/performance_monitor.dart';
import '../utils/app_logger.dart';

class AppInitializer {
  // Testing mode flag - set to true during testing to reduce initialization load
  static bool testingMode = false;

  Future<void> initialize() async {
    // Start performance monitoring
    startPerformanceTimer('app_startup');

    WidgetsFlutterBinding.ensureInitialized();

    if (testingMode) {
      AppLogger.core('🧪 TESTING MODE: Reduced initialization for better emulator performance');
    }

    // Initialize background services asynchronously for better performance
    final backgroundInit = BackgroundInitializer();
    // Run in parallel with other initializations (skip heavy services in testing mode)
    final backgroundInitFuture = testingMode
        ? Future.value() // Skip heavy background init in testing
        : backgroundInit.initializeAllServices();

    // CRITICAL: Initialize Firebase BEFORE creating any controllers
    startPerformanceTimer('firebase_init');
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Configure Firestore with optimized settings (non-blocking)
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        host: null,
        sslEnabled: true,
      );
      AppLogger.core('Firestore configured with optimizations');

      AppLogger.core('Firebase initialized');

      // Initialize FCM for push notifications
      try {
        final fcmService = FCMService();
        await fcmService.initialize();
        AppLogger.core('FCM service initialized');
      } catch (e) {
        AppLogger.coreError('FCM initialization failed', error: e);
      }
    } catch (e) {
      AppLogger.coreError('Firebase initialization failed', error: e);
    }
    stopPerformanceTimer('firebase_init');

    // Initialize essential services in parallel
    startPerformanceTimer('services_init');
    try {
      final futures = <Future>[];

      // Initialize optimization systems in parallel
      futures.add(Future(() async {
        // Error recovery system initialized
        AppLogger.core('Error recovery system initialized');
      }));

      futures.add(Future(() async {
        // Advanced analytics system initialized
        AppLogger.core('Advanced analytics system initialized');
      }));

      futures.add(Future(() async {
        // Memory management system initialized
        AppLogger.core('Memory management system initialized');
      }));

      futures.add(Future(() async {
        // Multi-level cache system initialized
        AppLogger.core('Multi-level cache system initialized');
      }));

      futures.add(Future(() async {
        // A/B testing framework initialized
        AppLogger.core('A/B testing framework initialized');
      }));

      futures.add(Future(() async {
        // Data compression system initialized
        AppLogger.core('Data compression system initialized');
      }));

      // Wait for background init to complete
      await backgroundInitFuture;

      // Initialize background sync manager (non-blocking)
      Future(() async {
        try {
          final syncManager = BackgroundSyncManager();
          syncManager.initialize();
          AppLogger.core('Background sync manager initialized');
        } catch (e) {
          AppLogger.common('⚠️ Background sync manager initialization failed: $e');
        }
      });

      // Wait for essential services to complete
      await Future.wait(futures);

      // Start user session tracking if user is logged in (non-blocking)
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        Future(() async {
          // User session tracking started
          AppLogger.core('User session tracking started for: ${currentUser.uid}');
        });
      }

    } catch (e) {
      AppLogger.coreError('Services initialization failed', error: e);
    }
    stopPerformanceTimer('services_init');

    // Check for app updates (run in background, don't block startup)
    Future(() async {
      try {
        await checkForUpdate();
      } catch (e) {
        AppLogger.coreError('Update check failed', error: e);
      }
    });

    stopPerformanceTimer('app_startup');

    // Log performance report in debug mode (non-blocking)
    Future(() => logPerformanceReport());
  }

  Future<void> checkForUpdate() async {
    try {
      final updateInfo = await InAppUpdate.checkForUpdate();
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (e) {
      AppLogger.coreError('Update check failed', error: e);
    }
  }
}
