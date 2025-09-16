import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../l10n/app_localizations.dart';
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
  bool _shouldRefreshData = false;
  bool _isLoggingOut = false; // Add loading state for logout

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only refresh data when explicitly needed (not on tab navigation)
    if (_shouldRefreshData) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Small delay to ensure navigation is complete
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            setState(() {});
            _shouldRefreshData = false; // Reset the flag
          }
        });
      });
    }
  }

  // Method to trigger data refresh (can be called from other screens)
  void refreshData() {
    _shouldRefreshData = true;
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.home),
        actions: [
          IconButton(
            icon: _isLoggingOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.logout),
            tooltip: _isLoggingOut ? 'Logging out...' : 'Logout',
            onPressed: _isLoggingOut ? null : () async {
              debugPrint('🔘 Logout button pressed');
              setState(() => _isLoggingOut = true);

              try {
                final authRepository = AuthRepository();
                await authRepository.signOut();

                // Reset login controller state (if available)
                try {
                  if (Get.isRegistered<LoginController>()) {
                    final loginController = Get.find<LoginController>();
                    loginController.phoneController.clear();
                    loginController.otpController.clear();
                    loginController.isOTPScreen.value = false;
                    loginController.verificationId.value = '';
                    debugPrint('✅ Login controller state reset');
                  } else {
                    debugPrint('ℹ️ Login controller not available - skipping state reset');
                  }
                } catch (e) {
                  debugPrint('⚠️ Could not reset login controller: $e');
                }

                // Small delay to ensure auth state change has propagated
                await Future.delayed(const Duration(milliseconds: 500));

                // Force navigation to login screen
                Get.offAllNamed('/login');
              } catch (e) {
                debugPrint('❌ Logout failed: $e');
                Get.snackbar(AppLocalizations.of(context)!.error, AppLocalizations.of(context)!.failedToLogout(e.toString()));
              } finally {
                if (mounted) {
                  setState(() => _isLoggingOut = false);
                }
              }
            },
          ),
        ],
      ),
      drawer: FutureBuilder<Map<String, dynamic>>(
        future: _homeServices.getUserData(currentUser?.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          UserModel? userModel;
          Candidate? candidateModel;

          if (snapshot.hasData) {
            userModel = snapshot.data!['user'];
            candidateModel = snapshot.data!['candidate'];
          }

          return HomeDrawer(
            userModel: userModel,
            candidateModel: candidateModel,
            currentUser: currentUser,
            onDeleteAccount: (context, userModel) async => await HomeActions.showDeleteAccountDialog(context, userModel, AppLocalizations.of(context)!),
          );
        },
      ),
      body: RefreshIndicator(
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
              return const Center(child: CircularProgressIndicator());
            }

            UserModel? userModel;
            Candidate? candidateModel;

            if (snapshot.hasData) {
              userModel = snapshot.data!['user'];
              candidateModel = snapshot.data!['candidate'];
            }

            return HomeBody(
              userModel: userModel,
              candidateModel: candidateModel,
              currentUser: currentUser,
            );
          },
        ),
      ),
    );
  }

}