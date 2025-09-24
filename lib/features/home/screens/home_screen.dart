import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../candidate/controllers/candidate_controller.dart';
import '../../chat/controllers/chat_controller.dart';
import '../../monetization/controllers/monetization_controller.dart';
import '../../../models/user_model.dart';
import '../../candidate/models/candidate_model.dart';
import '../services/home_services.dart';
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
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  bool _shouldRefreshData = false;
  bool _isLoggingOut = false; // Add loading state for logout
  int _refreshCounter = 0; // Add counter to force future refresh

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only refresh data when explicitly needed (not on tab navigation)
    if (_shouldRefreshData) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Small delay to ensure navigation is complete
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            setState(() {
              _refreshCounter++; // Force refresh of futures
            });
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

  // Method to force immediate refresh of user data
  void forceRefreshData() {
    setState(() {
      _refreshCounter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    // If user is not authenticated, redirect to login immediately
    if (currentUser == null) {
      debugPrint('🚫 User not authenticated, redirecting to login');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Get.offAllNamed('/login');
        }
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // User is authenticated, proceed with normal UI
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.home),
        actions: [
          //logout
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
            onPressed: _isLoggingOut
                ? null
                : () async {
                    debugPrint('🔘 Logout button pressed');
                    setState(() => _isLoggingOut = true);

                    try {
                      final authRepository = AuthRepository();
                      await authRepository.signOut();

                      // Delete all controllers to prevent state persistence between users
                      try {
                        if (Get.isRegistered<CandidateController>()) {
                          Get.delete<CandidateController>();
                          debugPrint('✅ CandidateController deleted');
                        }
                        if (Get.isRegistered<ChatController>()) {
                          Get.delete<ChatController>();
                          debugPrint('✅ ChatController deleted');
                        }
                        if (Get.isRegistered<MonetizationController>()) {
                          Get.delete<MonetizationController>();
                          debugPrint('✅ MonetizationController deleted');
                        }
                        if (Get.isRegistered<AuthController>()) {
                          Get.delete<AuthController>();
                          debugPrint('✅ AuthController deleted');
                        }
                      } catch (e) {
                        debugPrint('⚠️ Could not delete controllers: $e');
                      }

                      // Reset login controller state (if available) - but since we deleted it, this is not needed
                      // The controller will be recreated when needed

                      // Small delay to ensure auth state change has propagated
                      await Future.delayed(const Duration(milliseconds: 500));

                      // Force navigation to login screen
                      Get.offAllNamed('/login');
                    } catch (e) {
                      debugPrint('❌ Logout failed: $e');
                      Get.snackbar(
                        AppLocalizations.of(context)!.error,
                        AppLocalizations.of(
                          context,
                        )!.failedToLogout(e.toString()),
                      );
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
        future: _homeServices.getUserData(currentUser.uid), // User is guaranteed to be non-null here
        key: ValueKey('drawer_${currentUser.uid}_$_refreshCounter'), // Force rebuild with counter
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
            onDeleteAccount: (context, userModel) async =>
                await HomeActions.showDeleteAccountDialog(
                  context,
                  userModel,
                  AppLocalizations.of(context)!,
                ),
          );
        },
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: () async {
          // Force refresh by incrementing counter to create new future
          setState(() {
            _refreshCounter++;
          });
          // Add a small delay to show the refresh indicator
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: FutureBuilder<Map<String, dynamic>>(
          future: _homeServices.getUserData(currentUser.uid), // User is guaranteed to be non-null here
          key: ValueKey('body_${currentUser.uid}_$_refreshCounter'), // Force rebuild with counter
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
