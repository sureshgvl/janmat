import 'package:get/get.dart';
import '../controllers/login_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Put LoginController immediately since it's needed on initial route
    Get.put<LoginController>(LoginController());
  }
}