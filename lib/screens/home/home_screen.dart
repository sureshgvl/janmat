import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../repositories/auth_repository.dart';
import '../../controllers/login_controller.dart';
import '../../models/user_model.dart';
import '../../models/candidate_model.dart';
import 'home_services.dart';
import 'home_drawer.dart';
import 'home_body.dart';
import 'home_actions.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeServices _homeServices = HomeServices();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when screen comes back into focus
    // This handles the case when user navigates back from candidate dashboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Small delay to ensure navigation is complete
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {});
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: () async {
        // Force refresh by clearing any cached data
        setState(() {});
        // Add a small delay to show the refresh indicator
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: FutureBuilder<Map<String, dynamic>>(
        future: _homeServices.getUserData(currentUser?.uid),
        builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        UserModel? userModel;
        Candidate? candidateModel;

        if (snapshot.hasData) {
          userModel = snapshot.data!['user'];
          candidateModel = snapshot.data!['candidate'];
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
          drawer: HomeDrawer(
            userModel: userModel,
            candidateModel: candidateModel,
            currentUser: currentUser,
            onDeleteAccount: HomeActions.showDeleteAccountDialog,
          ),
          body: HomeBody(
            userModel: userModel,
            candidateModel: candidateModel,
            currentUser: currentUser,
          ),
        );
      },
      ),
    );
  }

}