import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:janmat/features/user/models/user_model.dart';
import 'package:janmat/features/home/services/home_services.dart';
import 'package:janmat/services/background_sync_manager.dart';
import 'package:janmat/services/background_initializer.dart';
import 'package:janmat/utils/app_logger.dart';
import 'package:janmat/utils/background_sync_manager.dart' as bg_sync;

/// Service for preloading home screen data using background services
class HomeDataPreloader {
  static final HomeDataPreloader _instance = HomeDataPreloader._internal();
  factory HomeDataPreloader() => _instance;

  HomeDataPreloader._internal();

  final HomeServices _homeServices = HomeServices();
  final BackgroundSyncManager _backgroundSync = BackgroundSyncManager();
  final bg_sync.BackgroundSyncManager _utilsSync = bg_sync.BackgroundSyncManager();

  bool _isPreloading = false;
  final StreamController<bool> _preloadStatusController = StreamController<bool>.broadcast();
  Stream<bool> get preloadStatusStream => _preloadStatusController.stream;

  /// Initialize with app startup
  Future<void> initializeWithAppStartup() async {
    AppLogger.common('🚀 Initializing home data preloader');

    // 🚀 INSTANT PRE-CACHE: Pre-cache data immediately for current user
    await _preCacheCurrentUserData();

    // Listen to authentication state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        // User signed in, start preloading
        preloadHomeDataForUser(user.uid);
      } else {
        // User signed out, clear preload data
        clearPreloadedData();
      }
    });
  }

  /// 🚀 INSTANT PRE-CACHE: Pre-cache current user's home data immediately
  Future<void> _preCacheCurrentUserData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        AppLogger.common('⚠️ No current user for instant pre-cache');
        return;
      }

      AppLogger.common('⚡ INSTANT PRE-CACHE: Starting for user ${currentUser.uid}');

      // Pre-cache user routing data first (fast)
      await _preCacheUserRoutingData(currentUser.uid);

      // Pre-cache complete home data (user + candidate) for instant display
      await _preCacheCompleteHomeData(currentUser.uid);

      AppLogger.common('✅ INSTANT PRE-CACHE: Completed for user ${currentUser.uid}');
    } catch (e) {
      AppLogger.common('⚠️ Instant pre-cache failed: $e');
      // Don't throw - this is optimization, not critical
    }
  }

  /// Pre-cache user routing data for instant navigation decisions (no-op)
  Future<void> _preCacheUserRoutingData(String uid) async {
    AppLogger.common('⚡ Routing data pre-cache skipped (no caching)');
  }

  /// Pre-cache complete home data (user + candidate) for instant display (no-op)
  Future<void> _preCacheCompleteHomeData(String uid) async {
    AppLogger.common('⚡ Home data pre-cache skipped (no caching): $uid');
  }

  /// Preload home data for authenticated user
  Future<void> preloadHomeDataForUser(String uid) async {
    if (_isPreloading) {
      AppLogger.common('⏳ Home data preload already in progress');
      return;
    }

    _isPreloading = true;
    _preloadStatusController.add(true);

    AppLogger.common('🔄 Starting home data preload for user: $uid');

    try {
      // Use background initializer for zero-frame preloading
      await BackgroundInitializer().runInIsolate(() async {
        await _preloadUserData(uid);
        await _preloadUserRoutingData(uid);
        await _warmupCacheForUser(uid);
      });

      AppLogger.common('✅ Home data preload completed for user: $uid');
    } catch (e) {
      AppLogger.commonError('❌ Home data preload failed', error: e);
    } finally {
      _isPreloading = false;
      _preloadStatusController.add(false);
    }
  }

  /// Preload user data using background sync
  Future<void> _preloadUserData(String uid) async {
    _backgroundSync.addToSyncQueue(() async {
      AppLogger.common('🔄 Background preload: User data for $uid');

      // This will populate cache automatically via HomeServices
      final result = await _homeServices.getUserData(uid);

      if (result['user'] != null) {
        AppLogger.common('✅ Background preload: User data cached for $uid');
      }
    });
  }

  /// Preload routing data for faster navigation (no-op)
  Future<void> _preloadUserRoutingData(String uid) async {
    _backgroundSync.addToSyncQueue(() async {
      AppLogger.common('🔄 Background preload: User routing data for $uid (no caching)');
      AppLogger.common('✅ Background preload: User routing data skipped for $uid');
    });
  }

  /// Warm up cache with frequently accessed data (no-op)
  Future<void> _warmupCacheForUser(String uid) async {
    _backgroundSync.addToSyncQueue(() async {
      AppLogger.common('🔄 Background preload: Cache warmup for $uid (no caching)');
      AppLogger.common('✅ Background preload: Cache warmup skipped for $uid');
    });
  }

  /// Preload data for offline use (no-op)
  Future<void> preloadForOfflineUse(String uid) async {
    _utilsSync.queueOperation('offline_user_data_$uid', () async {
      AppLogger.common('🔄 Preloading for offline: User data for $uid (no caching)');
      AppLogger.common('✅ Offline preload skipped for user: $uid');
    });
  }

  /// Get preload status
  bool get isPreloading => _isPreloading;

  /// Clear all preloaded data (no-op)
  Future<void> clearPreloadedData() async {
    AppLogger.common('🧹 Clearing preloaded home data (no caching)');
    AppLogger.common('✅ Preloaded data clear skipped');
  }

  /// Background sync for updated data
  void schedulePeriodicPreloadRefresh(String uid, {Duration interval = const Duration(minutes: 30)}) {
    Timer.periodic(interval, (timer) async {
      if (!_isPreloading && FirebaseAuth.instance.currentUser?.uid == uid) {
        AppLogger.common('🔄 Periodic preload refresh for user: $uid');
        await preloadHomeDataForUser(uid);
      }
    });
  }

  /// Dispose resources
  void dispose() {
    _preloadStatusController.close();
  }
}

/// Extension for easy preloading integration
extension HomePreloaderIntegration on HomeServices {
  /// Enhanced getUserData with preload awareness
  Future<Map<String, dynamic>> getUserDataWithPreload(
    String? uid, {
    bool forceRefresh = false,
    bool enablePreload = true,
  }) async {
    final result = await getUserData(uid, forceRefresh: forceRefresh);

    // If preload is enabled and we have valid data, trigger preload for related assets
    if (enablePreload && result['user'] != null) {
      final user = result['user'] is Map<String, dynamic>
        ? UserModel.fromJson(result['user'] as Map<String, dynamic>)
        : result['user'] as dynamic;
      if (user.role == 'candidate' && result['candidate'] != null) {
        // Preload candidate-specific data in background
        Future.microtask(() => HomeDataPreloader().preloadHomeDataForUser(uid!));
      }
    }

    return result;
  }
}

/// Global preloader instance
final homeDataPreloader = HomeDataPreloader();
