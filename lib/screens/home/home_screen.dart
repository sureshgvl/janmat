import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../repositories/auth_repository.dart';
import '../../controllers/login_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                final authRepository = AuthRepository();
                await authRepository.signOut();

                // Reset login controller state
                final loginController = Get.find<LoginController>();
                loginController.phoneController.clear();
                loginController.otpController.clear();
                loginController.isOTPScreen.value = false;
                loginController.verificationId.value = '';

                Get.offAllNamed('/login');
              } catch (e) {
                Get.snackbar('Error', 'Failed to logout: ${e.toString()}');
              }
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Welcome to JanMat Home Screen!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}