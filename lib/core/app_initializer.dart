import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';
import '../services/background_initializer.dart';
import '../services/background_sync_manager.dart';
import '../services/fcm_service.dart';
import '../utils/performance_monitor.dart';
import '../utils/error_recovery_manager.dart';
import '../utils/advanced_analytics.dart';
import '../utils/memory_manager.dart';
import '../utils/multi_level_cache.dart';
import '../utils/ab_testing_framework.dart';
import '../utils/data_compression.dart';

class AppInitializer {
  Future<void> initialize() async {
    // Start performance monitoring
    startPerformanceTimer('app_startup');

    WidgetsFlutterBinding.ensureInitialized();

    // Initialize background services asynchronously for better performance
    final backgroundInit = BackgroundInitializer();
    // Run in parallel with other initializations
    final backgroundInitFuture = backgroundInit.initializeAllServices();

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
      debugPrint('✅ Firestore configured with optimizations');

      debugPrint('✅ Firebase initialized');

      // Initialize FCM for push notifications
      try {
        final fcmService = FCMService();
        await fcmService.initialize();
        debugPrint('✅ FCM service initialized');
      } catch (e) {
        debugPrint('⚠️ FCM initialization failed: $e');
      }
    } catch (e) {
      debugPrint('❌ Firebase initialization failed: $e');
    }
    stopPerformanceTimer('firebase_init');

    // Initialize essential services in parallel
    startPerformanceTimer('services_init');
    try {
      final futures = <Future>[];

      // Initialize optimization systems in parallel
      futures.add(Future(() async {
        final errorRecovery = ErrorRecoveryManager();
        debugPrint('✅ Error recovery system initialized');
      }));

      futures.add(Future(() async {
        final analytics = AdvancedAnalyticsManager();
        debugPrint('✅ Advanced analytics system initialized');
      }));

      futures.add(Future(() async {
        final memoryManager = MemoryManager();
        debugPrint('✅ Memory management system initialized');
      }));

      futures.add(Future(() async {
        final cache = MultiLevelCache();
        debugPrint('✅ Multi-level cache system initialized');
      }));

      futures.add(Future(() async {
        final abTesting = ABTestingFramework();
        debugPrint('✅ A/B testing framework initialized');
      }));

      futures.add(Future(() async {
        final dataCompression = DataCompressionManager();
        debugPrint('✅ Data compression system initialized');
      }));

      // Wait for background init to complete
      await backgroundInitFuture;

      // Initialize background sync manager (non-blocking)
      Future(() async {
        try {
          final syncManager = BackgroundSyncManager();
          syncManager.initialize();
          debugPrint('✅ Background sync manager initialized');
        } catch (e) {
          debugPrint('⚠️ Background sync manager initialization failed: $e');
        }
      });

      // Wait for essential services to complete
      await Future.wait(futures);

      // Start user session tracking if user is logged in (non-blocking)
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        Future(() async {
          final analytics = AdvancedAnalyticsManager();
          analytics.startUserSession(currentUser.uid, 'unknown');
          debugPrint('✅ User session tracking started for: ${currentUser.uid}');
        });
      }

    } catch (e) {
      debugPrint('⚠️ Services initialization failed: $e');
    }
    stopPerformanceTimer('services_init');

    // Check for app updates (run in background, don't block startup)
    Future(() async {
      try {
        await checkForUpdate();
      } catch (e) {
        debugPrint('Update check failed: $e');
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
      debugPrint('Update check failed: $e');
    }
  }
}