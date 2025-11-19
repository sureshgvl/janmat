import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:janmat/utils/app_logger.dart';
import '../../../l10n/app_localizations.dart';
import '../../../controllers/background_color_controller.dart';
import 'home_drawer.dart';
import 'home_body.dart';
import '../../districtSpotLight/services/district_spotlight_service.dart';
import '../../../services/home_screen_stream_service.dart';
import '../../../services/screen_focus_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final HomeScreenStreamService _streamService = HomeScreenStreamService();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  late StreamSubscription<HomeScreenData> _dataSubscription;
  HomeScreenData? _currentData;

  @override
  void initState() {
    super.initState();
    // Set home screen as focused when initialized
    ScreenFocusService().setFocusedScreen('home');
    WidgetsBinding.instance.addObserver(this);
    _initializeStreaming();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Handle case when screen comes back into focus after navigation
    // This ensures the stream service continues to work when returning to home
    ScreenFocusService().setFocusedScreen('home');

    // Force refresh data when returning to home screen to ensure it's up to date
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _streamService.refreshData(forceRefresh: false);
        }
      });
    }
  }

  void _initializeStreaming() {
    AppLogger.common('🏠 [HOME_SCREEN] 🎬 STAGE 1: Starting streaming service initialization');
    // Initialize the stream service
    _streamService.initialize();
    AppLogger.common('🏠 [HOME_SCREEN] ✅ STAGE 2: Stream service initialized');

    // Listen to data stream
    _dataSubscription = _streamService.dataStream.listen((data) {
      AppLogger.common('🏠 [HOME_SCREEN] 📡 STAGE 3: Received data from stream - isLoading: ${data.isLoading}, isComplete: ${data.isComplete}, hasUser: ${data.userModel != null}');

      setState(() {
        _currentData = data;
      });

      if (data.isLoading) {
        AppLogger.common('🏠 [HOME_SCREEN] ⏳ STAGE 4: Data loading... showing loading screen');
        return;
      }

      if (data.isSignedOut) {
        AppLogger.common('🏠 [HOME_SCREEN] 🚪 User signed out, navigation to login');
        return;
      }

      if (data.hasError) {
        AppLogger.common('🏠 [HOME_SCREEN] ❌ Error in data: ${data.errorMessage}');
        return;
      }

      // ✅ USER DATA COMPLETE: No modal checks needed since flow is controlled pre-navigation
      if (data.isComplete) {
        AppLogger.common('🏠 [HOME_SCREEN] � Data is complete - user setup already validated by navigation flow');
      }

      // Handle district spotlight when user is authenticated
      if (data.isComplete && data.userModel != null) {
        _checkDistrictSpotlight();
      }
    });
  }

  void _checkDistrictSpotlight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !DistrictSpotlightService.isSpotlightDismissedForSession) {
        // Show spotlight for Pune district
        DistrictSpotlightService.showDistrictSpotlightIfAvailable(
          'maharashtra',
          'pune',
        );
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Handle app coming back to foreground
    if (state == AppLifecycleState.resumed && mounted) {
      // Refresh data when app comes back to foreground
      _streamService.refreshData(forceRefresh: false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dataSubscription.cancel();
    // Don't dispose the stream service here as it's a singleton
    // and other screens might still be using it
    super.dispose();
  }

  // Method to trigger data refresh (can be called from other screens)
  void refreshData() {
    _streamService.refreshData(forceRefresh: false);
  }

  // Method to force immediate refresh of user data
  void forceRefreshData() {
    _streamService.refreshData(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    // PERFORMANCE TRACKING: Log when home screen starts building
    final homeBuildStart = DateTime.now();
    AppLogger.common(
      '🏠 HOME SCREEN BUILD START: ${homeBuildStart.toIso8601String()}',
      tag: 'HOME_PERF',
    );

    return StreamBuilder<HomeScreenData>(
      stream: _streamService.dataStream,
      builder: (context, snapshot) {
        final data = _currentData ?? snapshot.data;

        // Handle loading states
        if (data == null || data.isLoading) {
          AppLogger.common('🏠 [HOME_SCREEN] Building loading screen - data: ${data?.toString()}');
          return _buildLoadingScreen(context);
        }

        // Handle signed out state
        if (data.isSignedOut) {
          AppLogger.common('🏠 [HOME_SCREEN] User signed out, navigating to login');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Get.offAllNamed('/login');
            }
          });
          return _buildLoadingScreen(context);
        }

        // Handle error state
        if (data.hasError) {
          AppLogger.common('🏠 [HOME_SCREEN] Error state - ${data.errorMessage}');
          return _buildErrorScreen(context, data.errorMessage);
        }

        // PERFORMANCE TRACKING: Log when home screen is being rendered
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final homeRendered = DateTime.now();
          final renderTime = homeRendered
              .difference(homeBuildStart)
              .inMilliseconds;
          AppLogger.common(
            '🎨 HOME SCREEN RENDERED: ${homeRendered.toIso8601String()} (${renderTime}ms from build start)',
            tag: 'HOME_PERF',
          );
        });

        return Obx(() {
          final backgroundColorController = Get.find<BackgroundColorController>();
          return _buildMainScreen(context, data, backgroundColor: backgroundColorController.currentBackgroundColor.value);
        });
      },
    );
  }

  /// Build loading screen with placeholders
  Widget _buildLoadingScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.home)),
      drawer: _buildPlaceholderDrawer(context),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: () async {
          _streamService.refreshData(forceRefresh: false);
          await Future.delayed(const Duration(milliseconds: 300));
        },
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  /// Build error screen
  Widget _buildErrorScreen(BuildContext context, String? errorMessage) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.home)),
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
              onPressed: () => _streamService.refreshData(forceRefresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build main screen based on data state
  Widget _buildMainScreen(BuildContext context, HomeScreenData data, {Color? backgroundColor}) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    AppLogger.common('🏠 [HOME_SCREEN] Building main screen - data state: ${data.state}, user: ${data.userModel?.name} (${data.userModel?.role}), candidate: ${data.effectiveCandidateModel?.basicInfo?.fullName ?? 'null'}');

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.home)),
      drawer: _buildDrawer(context, data, currentUser),
      backgroundColor: backgroundColor,
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: () async {
          await _streamService.refreshData(forceRefresh: false);
          await Future.delayed(const Duration(milliseconds: 300));
        },
        child: _buildBody(context, data, currentUser),
      ),
    );
  }

  /// Build drawer with appropriate placeholders
  Widget _buildDrawer(
    BuildContext context,
    HomeScreenData data,
    User? currentUser,
  ) {
    AppLogger.common('🏠 [HOME_SCREEN] Building drawer - isComplete: ${data.isComplete}, hasCachedCandidate: ${data.hasCachedCandidate}, isCandidateMode: ${data.isCandidateMode}, effectiveCandidate: ${data.effectiveCandidateModel != null}');

    if ((data.isComplete || data.hasCachedCandidate) && data.isCandidateMode) {
      AppLogger.common('🏠 [HOME_SCREEN] Building candidate drawer with candidate data - effectiveCandidate: ${data.effectiveCandidateModel?.basicInfo?.fullName ?? "null"}');
      final drawer = HomeDrawer(
        userModel: data.userModel!,
        candidateModel: data.effectiveCandidateModel,
        currentUser: currentUser!,
      );
      AppLogger.common('🏠 [HOME_SCREEN] Candidate drawer created successfully');
      return drawer;
    } else if (data.hasPartialData || data.isComplete) {
      AppLogger.common('🏠 [HOME_SCREEN] Building drawer without candidate data - user role: ${data.userModel?.role}');
      return HomeDrawer(
        userModel: data.userModel,
        candidateModel: null,
        currentUser: currentUser!,
      );
    } else {
      AppLogger.common('🏠 [HOME_SCREEN] Building placeholder drawer');
      return _buildPlaceholderDrawer(context);
    }
  }

  /// Build body - Clean implementation since all setup checks happen before navigation
  Widget _buildBody(
    BuildContext context,
    HomeScreenData data,
    User? currentUser,
  ) {
    AppLogger.common('🏠 [HOME_SCREEN] Building body - isComplete: ${data.isComplete}, hasCachedCandidate: ${data.hasCachedCandidate}, isCandidateMode: ${data.isCandidateMode}, role: ${data.role}');

    // Regular home screen logic for completed user setup
    if ((data.isComplete || data.hasCachedCandidate) && data.isCandidateMode) {
      AppLogger.common('🏠 [HOME_SCREEN] Building candidate body with candidate data');
      return HomeBody(
        userModel: data.userModel!,
        candidateModel: data.effectiveCandidateModel,
        currentUser: currentUser!,
      );
    } else if ((data.hasPartialData || data.hasCachedCandidate) &&
        data.role == 'candidate') {
      AppLogger.common('🏠 [HOME_SCREEN] Building candidate placeholder body');
      return _buildCandidatePlaceholderBody(context, data);
    } else {
      AppLogger.common('🏠 [HOME_SCREEN] Building regular body without candidate data');
      return HomeBody(
        userModel: data.userModel,
        candidateModel: null,
        currentUser: currentUser!,
      );
    }
  }

  /// Build placeholder drawer for loading states
  Widget _buildPlaceholderDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text('Loading...'),
          ),
          ListTile(
            leading: const CircularProgressIndicator(),
            title: const Text('Loading user data...'),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  /// Build candidate-specific placeholder body
  Widget _buildCandidatePlaceholderBody(
    BuildContext context,
    HomeScreenData data,
  ) {
    final candidateModel = data.effectiveCandidateModel;
    final isUsingCachedData = data.hasCachedCandidate;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome message with user name if available
          Text(
            'Welcome${data.userModel?.name != null ? ", ${data.userModel!.name}" : ""}!',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),

          // Candidate card with actual data if available
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Party symbol or photo
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: candidateModel?.photo != null
                        ? Image.network(
                            candidateModel!.photo!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.account_circle,
                              size: 40,
                              color: Colors.grey,
                            ),
                          )
                        : Icon(
                            Icons.account_circle,
                            size: 40,
                            color: Colors.grey,
                          ),
                  ),
                  const SizedBox(width: 16),
                  // Candidate info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          candidateModel?.basicInfo!.fullName ?? 'Loading...',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          candidateModel?.party ?? '',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Actions section
          Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),

          // Action buttons placeholder or actual buttons
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: isUsingCachedData
                        ? Colors.blue[50]
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isUsingCachedData ? Icons.cloud_done : Icons.refresh,
                        color: isUsingCachedData ? Colors.blue : Colors.grey,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isUsingCachedData ? 'Cached Data' : 'Refresh',
                        style: TextStyle(
                          color: isUsingCachedData ? Colors.blue : Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.people),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Status indicator based on data availability
          if (!isUsingCachedData)
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading candidate data...'),
                ],
              ),
            )
          else
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.cloud_done, color: Colors.blue, size: 32),
                    SizedBox(height: 8),
                    Text(
                      'Using cached data\nSyncing in background...',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build role selection body embedded in home screen
  Widget _buildRoleSelectionBody(BuildContext context) {
    // Show role selection modal immediately when this widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showRoleSelectionModal(context);
      }
    });

    return Container(
      padding: const EdgeInsets.all(24),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// Build profile completion body embedded in home screen
  Widget _buildProfileCompletionBody(BuildContext context, dynamic userModel) {
    // Show profile completion modal immediately when this widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showProfileCompletionModal(context, userModel);
      }
    });

    return Container(
      padding: const EdgeInsets.all(24),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// Helper method to build role selection cards
  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 48,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper method to build profile completion steps
  Widget _buildProfileStep(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 24,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
      ],
    );
  }

  /// Show role selection modal dialog
  void _showRoleSelectionModal(BuildContext context) {
    AppLogger.common('🤝 [HOME_SCREEN] Showing role selection modal');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Column(
            children: [
              Icon(
                Icons.admin_panel_settings,
                size: 64,
                color: Theme.of(dialogContext).primaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Choose Your Role',
                style: Theme.of(dialogContext).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select whether you want to register as a Candidate or Voter',
                style: Theme.of(dialogContext).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildRoleCard(
                      dialogContext,
                      title: 'Candidate',
                      subtitle: 'Run for office and campaign',
                      icon: Icons.person,
                      onTap: () => _handleRoleSelection(dialogContext, 'candidate'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildRoleCard(
                      dialogContext,
                      title: 'Voter',
                      subtitle: 'Vote and participate in elections',
                      icon: Icons.how_to_vote,
                      onTap: () => _handleRoleSelection(dialogContext, 'voter'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Show profile completion modal dialog
  void _showProfileCompletionModal(BuildContext context, dynamic userModel) {
    AppLogger.common('👤 [HOME_SCREEN] Showing profile completion modal');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Column(
            children: [
              Icon(
                Icons.edit_note,
                size: 64,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Complete Your Profile',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Set up your profile information to get started',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildProfileStep(
                      context,
                      icon: Icons.person_outline,
                      title: 'Personal Information',
                      subtitle: 'Name, age, location',
                    ),
                    const SizedBox(height: 16),
                    _buildProfileStep(
                      context,
                      icon: Icons.account_balance,
                      title: 'Political Preferences',
                      subtitle: 'Party, interests, manifesto',
                    ),
                    const SizedBox(height: 16),
                    _buildProfileStep(
                      context,
                      icon: Icons.photo_camera,
                      title: 'Profile Photo',
                      subtitle: 'Add your photo or symbol',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _handleProfileCompletion(context, userModel),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Complete Profile',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Handle role selection - update user data and refresh UI
  void _handleRoleSelection(BuildContext context, String role) async {
    AppLogger.common('🎭 [HOME_SCREEN] Role selected: $role');

    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AppLogger.common('❌ [HOME_SCREEN] No user found for role selection');
        return;
      }

      // Update user document with role and roleSelected flag
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'role': role,
        'roleSelected': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.common('✅ [HOME_SCREEN] Role updated successfully: $role');

      // Close modal and refresh data
      Navigator.of(context).pop();
      _streamService.refreshData(forceRefresh: true);

    } catch (error) {
      AppLogger.common('❌ [HOME_SCREEN] Failed to update role: $error');
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save role selection: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Handle profile completion - navigate to dedicated screen
  void _handleProfileCompletion(BuildContext context, dynamic userModel) {
    AppLogger.common('👤 [HOME_SCREEN] Profile completion triggered');
    // Close modal and navigate to profile completion screen
    Navigator.of(context).pop();
    // Force a page refresh to clear any routing issues and show fresh UI
    // This should prevent the modal from showing again after profile completion
    Future.delayed(const Duration(milliseconds: 300), () {
      Get.offAllNamed('/home', predicate: (_) => false); // Clear navigation stack
    });
  }
}
