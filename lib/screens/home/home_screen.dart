import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../repositories/auth_repository.dart';
import '../../controllers/login_controller.dart';
import '../candidate/candidate_list_screen.dart';
import '../candidate/candidate_dashboard_screen.dart';
import '../candidate/my_area_candidates_screen.dart';
import '../settings/settings_screen.dart';
import '../monetization/monetization_screen.dart';
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
                ListTile(
                  leading: const Icon(Icons.location_on),
                  title: const Text('My Area Candidates'),
                  subtitle: const Text('Candidates from your ward'),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    Get.to(() => const MyAreaCandidatesScreen());
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
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.star, color: Colors.orange),
                  title: const Text('Premium Features'),
                  subtitle: const Text('Upgrade to unlock premium features'),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    Get.to(() => const MonetizationScreen());
                  },
                ),
                // Add more items if needed
              ],
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Section
                Text(
                  'Welcome back, ${userModel?.name ?? currentUser?.displayName ?? 'User'}!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  userModel?.role == 'candidate'
                      ? 'Manage your campaign and connect with voters'
                      : 'Stay informed about your local candidates',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),

                const SizedBox(height: 32),

                // Premium Features Card
                Card(
                  elevation: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange[400]!, Colors.orange[600]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.white,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Unlock Premium Features',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      userModel?.role == 'candidate'
                                          ? 'Get premium visibility and analytics'
                                          : 'Access exclusive content and features',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Get.to(() => const MonetizationScreen()),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.orange,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Explore Premium',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Quick Actions
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildQuickActionCard(
                      icon: Icons.people,
                      title: 'Browse Candidates',
                      onTap: () => Get.to(() => const CandidateListScreen()),
                    ),
                    _buildQuickActionCard(
                      icon: Icons.location_on,
                      title: 'My Area',
                      onTap: () => Get.to(() => const MyAreaCandidatesScreen()),
                    ),
                    _buildQuickActionCard(
                      icon: Icons.chat,
                      title: 'Chat Rooms',
                      onTap: () => Get.toNamed('/chat'),
                    ),
                    _buildQuickActionCard(
                      icon: Icons.poll,
                      title: 'Polls',
                      onTap: () => Get.toNamed('/polls'),
                    ),
                  ],
                ),

                if (userModel?.role == 'candidate') ...[
                  const SizedBox(height: 32),
                  const Text(
                    'Candidate Dashboard',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    child: ListTile(
                      leading: const Icon(Icons.dashboard, color: Colors.blue),
                      title: const Text('Manage Your Campaign'),
                      subtitle: const Text('View analytics and update your profile'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () => Get.to(() => const CandidateDashboardScreen()),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: Colors.blue,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}