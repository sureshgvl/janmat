import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:janmat/utils/app_logger.dart';
import '../../../l10n/app_localizations.dart';
import '../../candidate/models/candidate_model.dart';
import 'home_drawer.dart';
import 'home_body.dart';
import '../../../services/district_spotlight_service.dart';
import '../../../services/home_screen_stream_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeScreenStreamService _streamService = HomeScreenStreamService();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  late StreamSubscription<HomeScreenData> _dataSubscription;
  HomeScreenData? _currentData;

  @override
  void initState() {
    super.initState();
    _initializeStreaming();
  }

  void _initializeStreaming() {
    // Initialize the stream service
    _streamService.initialize();

    // Listen to data stream
    _dataSubscription = _streamService.dataStream.listen((data) {
      setState(() {
        _currentData = data;
      });

      // ✅ SAFE NAVIGATION: Only navigate when complete data is available
      // Wait a bit to ensure complete data is stable before navigating
      if (data.isComplete && data.needsNavigation && data.navigationRoute != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _currentData?.isComplete == true && _currentData?.needsNavigation == true) {
            AppLogger.common('🚀 Navigating to: ${data.navigationRoute} (confirmed complete data)');
            Get.offAllNamed(data.navigationRoute!);
          }
        });
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
        DistrictSpotlightService.showDistrictSpotlightIfAvailable('maharashtra', 'pune');
      }
    });
  }

  @override
  void dispose() {
    _dataSubscription.cancel();
    _streamService.dispose();
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
    AppLogger.common('🏠 HOME SCREEN BUILD START: ${homeBuildStart.toIso8601String()}', tag: 'HOME_PERF');

    return StreamBuilder<HomeScreenData>(
      stream: _streamService.dataStream,
      builder: (context, snapshot) {
        final data = _currentData ?? snapshot.data;

        // Handle loading states
        if (data == null || data.isLoading) {
          return _buildLoadingScreen(context);
        }

        // Handle signed out state
        if (data.isSignedOut) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Get.offAllNamed('/login');
            }
          });
          return _buildLoadingScreen(context);
        }

        // Handle error state
        if (data.hasError) {
          return _buildErrorScreen(context, data.errorMessage);
        }

        // PERFORMANCE TRACKING: Log when home screen is being rendered
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final homeRendered = DateTime.now();
          final renderTime = homeRendered.difference(homeBuildStart).inMilliseconds;
          AppLogger.common('🎨 HOME SCREEN RENDERED: ${homeRendered.toIso8601String()} (${renderTime}ms from build start)', tag: 'HOME_PERF');
        });

        return _buildMainScreen(context, data);
      },
    );
  }

  /// Build loading screen with placeholders
  Widget _buildLoadingScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.home ?? 'Home'),
      ),
      drawer: _buildPlaceholderDrawer(context),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: () async {
          _streamService.refreshData(forceRefresh: false);
          await Future.delayed(const Duration(milliseconds: 300));
        },
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  /// Build error screen
  Widget _buildErrorScreen(BuildContext context, String? errorMessage) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.home ?? 'Home'),
      ),
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
  Widget _buildMainScreen(BuildContext context, HomeScreenData data) {
    final userModel = data.userModel;
    final candidateModel = data.effectiveCandidateModel as Candidate?;
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.home ?? 'Home'),
      ),
      drawer: _buildDrawer(context, data, currentUser),
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
  Widget _buildDrawer(BuildContext context, HomeScreenData data, User? currentUser) {
    if ((data.isComplete || data.hasCachedCandidate) && data.isCandidateMode) {
      return HomeDrawer(
        userModel: data.userModel!,
        candidateModel: data.effectiveCandidateModel as Candidate?,
        currentUser: currentUser!,
      );
    } else if (data.hasPartialData || data.isComplete) {
      return HomeDrawer(
        userModel: data.userModel,
        candidateModel: null,
        currentUser: currentUser!,
      );
    } else {
      return _buildPlaceholderDrawer(context);
    }
  }

  /// Build body with appropriate placeholders
  Widget _buildBody(BuildContext context, HomeScreenData data, User? currentUser) {
    if ((data.isComplete || data.hasCachedCandidate) && data.isCandidateMode) {
      return HomeBody(
        userModel: data.userModel!,
        candidateModel: data.effectiveCandidateModel as Candidate?,
        currentUser: currentUser!,
      );
    } else if ((data.hasPartialData || data.hasCachedCandidate) && data.role == 'candidate') {
      return _buildCandidatePlaceholderBody(context, data);
    } else {
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
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
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
  Widget _buildCandidatePlaceholderBody(BuildContext context, HomeScreenData data) {
    final candidateModel = data.effectiveCandidateModel as Candidate?;
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
                          errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.account_circle, size: 40, color: Colors.grey),
                        )
                      : Icon(Icons.account_circle, size: 40, color: Colors.grey),
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
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
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
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),

          // Action buttons placeholder or actual buttons
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: isUsingCachedData ? Colors.blue[50] : Colors.grey[300],
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
                    Icon(
                      Icons.cloud_done,
                      color: Colors.blue,
                      size: 32,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Using cached data\nSyncing in background...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
