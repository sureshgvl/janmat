import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../repositories/auth_repository.dart';
import '../../controllers/login_controller.dart';
import '../candidate/candidate_list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

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
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(currentUser?.displayName ?? 'User'),
              accountEmail: Text(currentUser?.email ?? currentUser?.phoneNumber ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: currentUser?.photoURL != null ? NetworkImage(currentUser!.photoURL!) : null,
                child: currentUser?.photoURL == null ? Text(
                  ((currentUser?.displayName ?? 'U').isEmpty ? 'U' : (currentUser?.displayName ?? 'U')[0]).toUpperCase(),
                  style: const TextStyle(fontSize: 24, color: Colors.blue),
                ) : null,
              ),
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Get.toNamed('/profile'); // Navigate to profile screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Search by Ward'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Get.to(() => const CandidateListScreen()); // Navigate to candidate list screen
              },
            ),
            // Add more items if needed
          ],
        ),
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