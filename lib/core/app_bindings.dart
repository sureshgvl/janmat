import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../features/auth/controllers/auth_controller.dart';
import '../features/chat/controllers/chat_controller.dart';
import '../features/candidate/controllers/candidate_controller.dart';
import '../features/candidate/controllers/candidate_data_controller.dart';
import '../features/notifications/services/notification_manager.dart';
import '../services/admob_service.dart';
import '../services/razorpay_service.dart';
import '../services/background_location_sync_service.dart';
import '../services/manifesto_sync_service.dart';

class AppBindings extends Bindings {
  @override
  Future<void> dependencies() async {
    // Put AuthController to ensure it's always available
    Get.put<AuthController>(AuthController());

    // Put other controllers
    Get.put<ChatController>(ChatController());
    Get.put<CandidateController>(CandidateController());
    Get.put<CandidateDataController>(CandidateDataController());

    // Put services
    Get.put<AdMobService>(AdMobService());
    Get.put<RazorpayService>(RazorpayService());

    // Initialize background location sync service
    final backgroundLocationSync = BackgroundLocationSyncService.instance;
    backgroundLocationSync.initialize();

    // Initialize manifesto sync service (singleton, auto-initializes)
    ManifestoSyncService();

    // Initialize notification manager
    try {
      final notificationManager = NotificationManager();
      await notificationManager.initialize();
      debugPrint('✅ NotificationManager initialized successfully');
    } catch (e) {
      debugPrint('⚠️ Failed to initialize NotificationManager: $e');
    }
  }
}

