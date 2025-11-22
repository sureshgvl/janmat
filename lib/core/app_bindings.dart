import 'package:get/get.dart';
import 'package:janmat/utils/app_logger.dart';
import 'package:flutter/foundation.dart';
import '../features/auth/controllers/auth_controller.dart';
import '../features/chat/controllers/chat_controller.dart';
import '../features/chat/controllers/room_controller.dart';
import '../features/chat/controllers/message_controller.dart';
import '../features/candidate/controllers/candidate_controller.dart';
import '../features/candidate/controllers/manifesto_controller.dart';
import '../features/candidate/controllers/media_controller.dart';
import '../features/candidate/controllers/achievements_controller.dart';
import '../features/candidate/controllers/contact_controller.dart';
import '../features/candidate/controllers/highlights_controller.dart';
import '../features/candidate/controllers/events_controller.dart';
import '../features/candidate/controllers/analytics_controller.dart';
import '../features/candidate/controllers/save_all_coordinator.dart';
import '../services/offline_drafts_service.dart';
import '../features/candidate/services/media_cache_service.dart';
import '../features/candidate/repositories/media_repository.dart';
import '../services/sync/i_sync_service.dart';
import '../services/sync/mobile_sync_service.dart';
import '../services/sync/web_sync_service.dart';
import '../services/file_upload_service.dart';
import '../features/notifications/services/notification_manager.dart';
import '../features/user/services/user_data_service.dart';
import '../features/user/controllers/user_data_controller.dart';
import '../features/user/controllers/user_controller.dart';
import '../features/candidate/controllers/candidate_user_controller.dart';
import '../features/deviceInfo/controller/device_info_controller.dart';
import '../features/notificationSetting/controller/notification_settings_controller.dart';
import '../features/follow/controller/following_controller.dart';
import '../features/language/controller/language_controller.dart';
import '../features/highlight/controller/highlight_controller.dart';
import '../services/background_location_sync_service.dart';
import '../features/candidate/services/manifesto_sync_service.dart';

import '../features/monetization/controllers/monetization_controller.dart';
import '../features/monetization/services/razorpay_service.dart';
import '../controllers/background_color_controller.dart';
import '../services/screen_focus_service.dart';
import '../features/chat/services/background_cache_warmer.dart';
import '../features/chat/services/chat_performance_monitor.dart';
import '../features/chat/services/whatsapp_style_message_cache.dart';
import '../features/chat/services/persistent_chat_room_cache.dart';
import '../features/chat/services/whatsapp_style_chat_cache.dart';

class AppBindings extends Bindings {
  @override
  Future<void> dependencies() async {
    AppLogger.common('🔧 AppBindings dependencies() called - LAZY LOADING OPTIMIZATION');

    // 🚀 CRITICAL CONTROLLERS: Only load these immediately as they're needed for app startup
    Get.put<AuthController>(AuthController());
    Get.put<UserDataController>(UserDataController());
    Get.put<UserDataService>(UserDataService());
    Get.put<UserController>(UserController());
    Get.put<CandidateUserController>(CandidateUserController());
    Get.put<LanguageController>(LanguageController());
    Get.put<ScreenFocusController>(ScreenFocusController());
    Get.put<MonetizationController>(MonetizationController());
    Get.put<BackgroundColorController>(BackgroundColorController());
    // Platform-specific sync service
    Get.put<ISyncService>(kIsWeb ? WebSyncService() : MobileSyncService());

    // 🎯 LAZY LOAD ALL FEATURE-SPECIFIC CONTROLLERS: Load only when screens are accessed
    // Chat controllers: Hybrid approach - lazy load but ensure proper dependency order
    Get.put<RoomController>(RoomController());
    Get.put<MessageController>(MessageController());
    Get.lazyPut<ChatController>(() => ChatController(), fenix: true);
    Get.lazyPut<CandidateController>(() => CandidateController());
    Get.lazyPut<MediaController>(() => MediaController());
    Get.lazyPut<MediaRepository>(() => MediaRepository());
    Get.lazyPut<AchievementsController>(() => AchievementsController());
    Get.lazyPut<ManifestoController>(() => ManifestoController());
    Get.lazyPut<ContactController>(() => ContactController());
    Get.lazyPut<EventsController>(() => EventsController());
    Get.lazyPut<AnalyticsController>(() => AnalyticsController());
    Get.lazyPut<HighlightsController>(() => HighlightsController());
    Get.lazyPut<SaveAllCoordinator>(() => SaveAllCoordinator());
    Get.lazyPut<OfflineDraftsService>(() => OfflineDraftsService());
    Get.lazyPut<DeviceInfoController>(() => DeviceInfoController());
    Get.lazyPut<NotificationSettingsController>(() => NotificationSettingsController());
    Get.lazyPut<FollowingController>(() => FollowingController());
    Get.lazyPut<HighlightController>(() => HighlightController());

    // 🎯 LAZY LOAD SERVICES: Only initialize when needed
    Get.lazyPut<RazorpayService>(() => RazorpayService());
    Get.lazyPut<FileUploadService>(() => FileUploadService());

    // 🚀 ASYNC INITIALIZATION: Move heavy operations to background
    // Initialize media cache service asynchronously
    Get.putAsync<MediaCacheService>(() => MediaCacheService.getInstance());

    // Initialize background services asynchronously (non-blocking)
    Future.microtask(() async {
      try {
        // Initialize background location sync service
        final backgroundLocationSync = BackgroundLocationSyncService.instance;
        backgroundLocationSync.initialize();

        // Initialize manifesto sync service (singleton, auto-initializes)
        ManifestoSyncService();

        // 🚀 LAZY NOTIFICATION MANAGER: Initialize in background, not blocking startup
        _initializeNotificationManagerInBackground();

        // 🔥 BACKGROUND CACHE WARMER: Initialize WhatsApp-style cache warming
        _initializeBackgroundCacheWarmer();

        // 📊 CHAT PERFORMANCE MONITOR: Initialize real-time performance monitoring
        _initializeChatPerformanceMonitor();

        AppLogger.common('✅ Background services initialized successfully');
      } catch (e) {
        AppLogger.common('⚠️ Background services initialization failed: $e');
      }
    });
  }

  /// 🚀 LAZY NOTIFICATION MANAGER: Initialize asynchronously in background
  void _initializeNotificationManagerInBackground() {
    Future.microtask(() async {
      try {
        final notificationManager = NotificationManager();
        await notificationManager.initialize();
        AppLogger.common('✅ NotificationManager initialized successfully (background)');
      } catch (e) {
        AppLogger.common('⚠️ Failed to initialize NotificationManager: $e');
      }
    });
  }

  /// 🔥 BACKGROUND CACHE WARMER: Initialize WhatsApp-style cache warming
  void _initializeBackgroundCacheWarmer() {
    Future.microtask(() async {
      try {
        final cacheWarmer = BackgroundCacheWarmer();
        await cacheWarmer.initialize();
        Get.put<BackgroundCacheWarmer>(cacheWarmer);
        AppLogger.common('✅ BackgroundCacheWarmer initialized successfully (background)');
      } catch (e) {
        AppLogger.common('⚠️ Failed to initialize BackgroundCacheWarmer: $e');
      }
    });
  }

  /// 📊 CHAT PERFORMANCE MONITOR: Initialize real-time performance monitoring
  void _initializeChatPerformanceMonitor() {
    Future.microtask(() async {
      try {
        // Get dependencies (they should be initialized by now)
        final messageCache = Get.find<WhatsAppStyleMessageCache>();
        final roomCache = Get.find<PersistentChatRoomCache>();
        final chatCache = Get.find<WhatsAppStyleChatCache>();
        final cacheWarmer = Get.find<BackgroundCacheWarmer>();

        final performanceMonitor = ChatPerformanceMonitor(
          messageCache: messageCache,
          roomCache: roomCache,
          chatCache: chatCache,
          cacheWarmer: cacheWarmer,
        );

        await performanceMonitor.initialize();
        Get.put<ChatPerformanceMonitor>(performanceMonitor);
        AppLogger.common('✅ ChatPerformanceMonitor initialized successfully (background)');
      } catch (e) {
        AppLogger.common('⚠️ Failed to initialize ChatPerformanceMonitor: $e');
      }
    });
  }
}
