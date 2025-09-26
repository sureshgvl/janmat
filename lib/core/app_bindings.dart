import 'package:get/get.dart';
import '../features/auth/controllers/auth_controller.dart';
import '../features/chat/controllers/chat_controller.dart';
import '../features/candidate/controllers/candidate_controller.dart';
import '../features/candidate/controllers/candidate_data_controller.dart';
import '../services/admob_service.dart';
import '../services/razorpay_service.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Put AuthController to ensure it's always available
    Get.put<AuthController>(AuthController());

    // Put other controllers
    Get.put<ChatController>(ChatController());
    Get.put<CandidateController>(CandidateController());
    Get.put<CandidateDataController>(CandidateDataController());

    // Put services
    Get.put<AdMobService>(AdMobService());
    Get.put<RazorpayService>(RazorpayService());
  }
}
