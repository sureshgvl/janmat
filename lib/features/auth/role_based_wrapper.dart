import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../screens/main_tab_navigation.dart';
import '../../features/candidate/screens/candidate_dashboard_screen.dart';
import 'auth_viewmodel.dart';

/// View Layer: Reactive UI wrapper that automatically updates based on AuthViewModel state
/// Clean separation - this widget only handles UI, business logic is in ViewModel
class RoleBasedWrapper extends StatelessWidget {
  const RoleBasedWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize AuthViewModel (reactive business logic layer)
    final viewModel = Get.put(AuthViewModel());

    return Obx(() {
      // React to auth state changes
      switch (viewModel.authState.value) {
        case AuthState.loading:
          return _buildSplashScreen();

        case AuthState.loggedOut:
          return _buildLoginScreen(viewModel);

        case AuthState.loggedIn:
          return _buildRoleBasedHome(viewModel);
      }
    });
  }

  /// Loading/splash screen while determining user state
  Widget _buildSplashScreen() => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/app-icon.png', width: 100, height: 100),
          const SizedBox(height: 20),
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          const Text('Loading...', style: TextStyle(fontSize: 16)),
        ],
      ),
    ),
  );

  /// Login screen with smart account detection
  Widget _buildLoginScreen(AuthViewModel viewModel) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // App Header
              const Spacer(),
              Icon(Icons.how_to_vote, size: 80, color: Theme.of(Get.context!).primaryColor),
              const SizedBox(height: 16),
              const Text(
                'Welcome to JanMat',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Your voice, your vote, your power',
                style: TextStyle(color: Colors.grey),
              ),

              // Smart account selection
              const Spacer(),
              _buildLoginButtons(viewModel),
              const SizedBox(height: 20),

              // Error display
              Obx(() => viewModel.errorMessage.value.isNotEmpty
                ? Text(
                    viewModel.errorMessage.value,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  )
                : const SizedBox.shrink()
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Smart login buttons based on stored accounts
  Widget _buildLoginButtons(AuthViewModel viewModel) {
    return Column(
      children: [
        // Show last account if available
        FutureBuilder<Map<String, dynamic>?>(
          future: viewModel.getLastGoogleAccount(),
          builder: (context, snapshot) {
            final hasStoredAccount = snapshot.hasData && snapshot.data != null;

            return Column(
              children: [
                // "Continue as [Name]" button for returning users
                if (hasStoredAccount && !viewModel.isLoading.value)
                  ElevatedButton.icon(
                    onPressed: () => viewModel.signInWithGoogle(),
                    icon: const Icon(Icons.account_circle),
                    label: Text(
                      'Continue as ${snapshot.data!['displayName']}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),

                if (hasStoredAccount && !viewModel.isLoading.value)
                  const SizedBox(height: 12),

                // Sign in with different account button
                ElevatedButton.icon(
                  onPressed: () => viewModel.signInWithGoogle(true), // Force picker
                  icon: const Icon(Icons.switch_account),
                  label: const Text('Sign in with different account'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),

                // Loading indicator
                if (viewModel.isLoading.value)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  /// Role-based home screen routing
  Widget _buildRoleBasedHome(AuthViewModel viewModel) {
    final role = viewModel.getCurrentRole();

    // React to role changes and route accordingly
    return switch (role) {
      'candidate' => _buildCandidateHome(viewModel),
      'voter' => _buildVoterHome(viewModel),
      'admin' => _buildAdminHome(viewModel),
      _ => _buildRoleSelectionScreen(viewModel), // No role set yet
    };
  }

  /// Candidate home screen with profile completion check
  Widget _buildCandidateHome(AuthViewModel viewModel) {
    // Check if profile completion is needed
    if (viewModel.showProfileCompletion.value) {
      return _buildProfileCompletionScreen(viewModel);
    }

    // Full candidate dashboard
    return const CandidateDashboardScreen();
  }

  /// Voter home screen (standard voter feed/dashboard)
  Widget _buildVoterHome(AuthViewModel viewModel) {
    return const MainTabNavigation();
  }

  /// Admin home screen (if implemented)
  Widget _buildAdminHome(AuthViewModel viewModel) {
    // Placeholder - implement admin dashboard if needed
    return const Scaffold(
      body: Center(child: Text('Admin Dashboard - Coming Soon')),
    );
  }

  /// Role selection screen for new users
  Widget _buildRoleSelectionScreen(AuthViewModel viewModel) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Role'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () => viewModel.logout(),
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const Text(
                'How would you like to participate?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Candidate option
              Card(
                child: InkWell(
                  onTap: () => _setRole(viewModel, 'candidate'),
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        Icon(Icons.school, size: 40, color: Colors.blue),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'I want to run for office',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Become a candidate and create your manifesto',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, color: Colors.blue),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Voter option
              Card(
                child: InkWell(
                  onTap: () => _setRole(viewModel, 'voter'),
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        Icon(Icons.how_to_vote, size: 40, color: Colors.green),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'I want to vote',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Browse candidates and make informed decisions',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, color: Colors.green),
                      ],
                    ),
                  ),
                ),
              ),

              const Spacer(),
              Obx(() => viewModel.errorMessage.value.isNotEmpty
                ? Text(
                    viewModel.errorMessage.value,
                    style: const TextStyle(color: Colors.red),
                  )
                : const SizedBox.shrink()
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Profile completion screen for candidates
  Widget _buildProfileCompletionScreen(AuthViewModel viewModel) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Your Profile')),
      body: const Center(
        child: Text('Profile completion screen - implement user onboarding'),
        // TODO: Implement profile completion flow
      ),
    );
  }

  /// Set user role and update server + state
  Future<void> _setRole(AuthViewModel viewModel, String role) async {
    try {
      // TODO: Update role in Firestore
      // await _updateRoleOnServer(viewModel.getCurrentUser()?.uid, role);

      // Update reactive state
      viewModel.role.value = role;
    } catch (error) {
      viewModel.errorMessage.value = 'Failed to set role: ${error.toString()}';
    }
  }

  /// Optional: Logout prompt on back button
  Future<bool> _onWillPop() async {
    // Prevent accidental logout
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      Get.find<AuthViewModel>().logout();
      return false; // Don't pop the route (cleanup handled by logout)
    }

    return false; // Stay on current screen
  }
}
