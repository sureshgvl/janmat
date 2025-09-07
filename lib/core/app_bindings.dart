import 'package:get/get.dart';
import '../controllers/login_controller.dart';
import '../controllers/chat_controller.dart';
import '../controllers/candidate_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Put LoginController immediately since it's needed on initial route
    Get.put<LoginController>(LoginController());

    // Put other controllers
    Get.put<ChatController>(ChatController());
    Get.put<CandidateController>(CandidateController());
  }
}