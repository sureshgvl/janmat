import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'home_screen.dart'; // Import HomeScreen directly to avoid circular dependency
import '../../../services/home_screen_stream_service.dart';

// Reactive role-based navigation wrapper (ChatGPT optimization)
class RoleBasedHomeWrapper extends StatelessWidget {
  const RoleBasedHomeWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<HomeScreenData>(
      stream: Get.find<HomeScreenStreamService>().dataStream,
      builder: (context, snapshot) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: _buildRoleBasedScreen(snapshot.data),
        );
      },
    );
  }

  Widget _buildRoleBasedScreen(HomeScreenData? data) {
    // Handle different states with smooth transitions
    if (data == null || data.isLoading || data.isSignedOut) {
      return _buildLoadingScreen();
    }

    if (data.hasError) {
      return _buildErrorScreen(data.errorMessage);
    }

    // Role-based routing without app rebuilds
    return data.isCandidateMode
        ? HomeScreen(key: const ValueKey('candidate'))
        : HomeScreen(key: const ValueKey('voter'));
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading your experience...',
              style: Get.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(String? errorMessage) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              errorMessage ?? 'Something went wrong',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Get.find<HomeScreenStreamService>().refreshData(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
