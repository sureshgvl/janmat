import 'package:get/get.dart';
import 'package:janmat/utils/app_logger.dart';
import '../features/auth/controllers/auth_controller.dart';
import '../features/chat/controllers/chat_controller.dart';
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
import '../services/media_cache_service.dart';
import '../features/candidate/repositories/media_repository.dart';

import '../services/admob_service.dart';
import '../services/razorpay_service.dart';
import '../features/notifications/services/notification_manager.dart';
import '../features/user/services/user_data_service.dart';
import '../features/user/controllers/user_data_controller.dart';
import '../features/user/controllers/user_controller.dart';
import '../features/user/controllers/user_data_controller.dart';
import '../features/candidate/controllers/candidate_user_controller.dart';
import '../controllers/device_info_controller.dart';
import '../controllers/notification_settings_controller.dart';
import '../controllers/following_controller.dart';
import '../controllers/theme_controller.dart';
import '../controllers/language_controller.dart';
import '../services/background_location_sync_service.dart';
import '../services/manifesto_sync_service.dart';
import '../features/notifications/services/gamification_notification_service.dart';
import '../services/gamification_service.dart';

class AppBindings extends Bindings {
  @override
  Future<void> dependencies() async {
    AppLogger.common('🔧 AppBindings dependencies() called');
    // PERFORMANCE OPTIMIZATION: Use lazyPut for feature-specific controllers
    // to reduce main thread burden during app startup. Only critical controllers
    // that are always needed are eagerly loaded.
    // Eagerly load critical controllers that are always needed
    Get.put<AuthController>(AuthController());
    Get.put<UserDataController>(UserDataController());
    Get.put<UserDataService>(UserDataService());
    Get.put<UserController>(UserController());
    Get.put<CandidateUserController>(CandidateUserController());
    Get.put<LanguageController>(LanguageController());

    // Lazy load feature-specific controllers to improve startup performance
    Get.put<ChatController>(ChatController());
    Get.put<CandidateController>(CandidateController()); // Eagerly load since used in profile screens
    Get.put<MediaController>(MediaController());
    Get.put<MediaRepository>(MediaRepository());
    Get.put<AchievementsController>(AchievementsController());
    Get.put<ManifestoController>(ManifestoController());
    Get.put<ContactController>(ContactController());
    // Add the SaveAllCoordinator for universal save operations
    Get.put<SaveAllCoordinator>(SaveAllCoordinator());
    // Add the OfflineDraftsService for draft management
    Get.put<OfflineDraftsService>(OfflineDraftsService());
    // Initialize media cache service for optimized media loading
    Get.putAsync<MediaCacheService>(() => MediaCacheService.getInstance());
    Get.put<DeviceInfoController>(DeviceInfoController());
    Get.put<NotificationSettingsController>(NotificationSettingsController());
    AppLogger.common('✅ NotificationSettingsController put in bindings');
    Get.put<FollowingController>(FollowingController());

    // Lazy load services that are only needed on specific screens
    Get.lazyPut<AdMobService>(() => AdMobService());
    Get.lazyPut<RazorpayService>(() => RazorpayService());

    // Register gamification services for dependency injection
    Get.lazyPut<GamificationNotificationService>(() => GamificationNotificationService());
    Get.lazyPut<GamificationService>(() => GamificationService());

    // Initialize background location sync service
    final backgroundLocationSync = BackgroundLocationSyncService.instance;
    backgroundLocationSync.initialize();

    // Initialize manifesto sync service (singleton, auto-initializes)
    ManifestoSyncService();

    // Initialize notification manager
    try {
      final notificationManager = NotificationManager();
      await notificationManager.initialize();
      AppLogger.common('✅ NotificationManager initialized successfully');
    } catch (e) {
      AppLogger.common('⚠️ Failed to initialize NotificationManager: $e');
    }
  }
}
