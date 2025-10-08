import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:janmat/utils/app_logger.dart';
import '../features/auth/controllers/auth_controller.dart';
import '../features/chat/controllers/chat_controller.dart';
import '../features/candidate/controllers/candidate_controller.dart';
import '../features/candidate/controllers/candidate_data_controller.dart';
import '../controllers/highlight_controller.dart';
import '../features/notifications/services/notification_manager.dart';
import '../services/admob_service.dart';
import '../services/razorpay_service.dart';
import '../controllers/user_data_controller.dart';
import '../controllers/device_info_controller.dart';
import '../controllers/notification_settings_controller.dart';
import '../controllers/following_controller.dart';
import '../services/background_location_sync_service.dart';
import '../services/manifesto_sync_service.dart';

class AppBindings extends Bindings {
  @override
  Future<void> dependencies() async {
    // PERFORMANCE OPTIMIZATION: Use lazyPut for feature-specific controllers
    // to reduce main thread burden during app startup. Only critical controllers
    // that are always needed are eagerly loaded.
    // Eagerly load critical controllers that are always needed
    Get.put<AuthController>(AuthController());
    Get.put<UserDataController>(UserDataController());

    // Lazy load feature-specific controllers to improve startup performance
    Get.put<ChatController>(ChatController());
    Get.put<CandidateController>(CandidateController()); // Eagerly load since used in profile screens
    Get.put<CandidateDataController>(CandidateDataController());
    Get.put<HighlightController>(HighlightController());
    Get.put<DeviceInfoController>(DeviceInfoController());
    Get.put<NotificationSettingsController>( NotificationSettingsController());
    Get.put<FollowingController>( FollowingController());

    // Lazy load services that are only needed on specific screens
    Get.lazyPut<AdMobService>(() => AdMobService());
    Get.lazyPut<RazorpayService>(() => RazorpayService());

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

