import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../repositories/auth_repository.dart';
import '../../controllers/login_controller.dart';
import '../candidate/candidate_list_screen.dart';
import '../candidate/candidate_dashboard_screen.dart';
import '../settings/settings_screen.dart';
import '../../models/user_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(currentUser?.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        UserModel? userModel;
        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          userModel = UserModel.fromJson(userData);
        }

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
                  accountName: Text(userModel?.name ?? currentUser?.displayName ?? 'User'),
                  accountEmail: Text(userModel?.email ?? currentUser?.email ?? currentUser?.phoneNumber ?? ''),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    backgroundImage: userModel?.photoURL != null
                        ? NetworkImage(userModel!.photoURL!)
                        : currentUser?.photoURL != null
                            ? NetworkImage(currentUser!.photoURL!)
                            : null,
                    child: userModel?.photoURL == null && currentUser?.photoURL == null
                        ? Text(
                            ((userModel?.name ?? currentUser?.displayName ?? 'U').isEmpty
                                ? 'U'
                                : (userModel?.name ?? currentUser?.displayName ?? 'U')[0]).toUpperCase(),
                            style: const TextStyle(fontSize: 24, color: Colors.blue),
                          )
                        : null,
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
                if (userModel?.role == 'candidate')
                  ListTile(
                    leading: const Icon(Icons.dashboard),
                    title: const Text('Candidate Dashboard'),
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      Get.to(() => const CandidateDashboardScreen()); // Navigate to candidate dashboard
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
                ListTile(
                  leading: const Icon(Icons.chat),
                  title: const Text('Chat Rooms'),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    Get.toNamed('/chat'); // Navigate to chat list screen
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings'),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    Get.toNamed('/settings'); // Navigate to settings screen
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
      },
    );
  }
}