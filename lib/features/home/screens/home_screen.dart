import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:janmat/utils/app_logger.dart';
import '../../../l10n/app_localizations.dart';
import '../../candidate/controllers/candidate_data_controller.dart';
import '../../../models/user_model.dart';
import '../../candidate/models/candidate_model.dart';
import '../services/home_services.dart';
import 'home_drawer.dart';
import 'home_body.dart';
import '../../../services/district_spotlight_service.dart';

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
  int _refreshCounter = 0; // Add counter to force future refresh

  @override
  void initState() {
    super.initState();
    // Spotlight check will be done after authentication is confirmed in build method
  }

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
      AppLogger.common('🚫 User not authenticated, redirecting to login');
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

    // PERFORMANCE TRACKING: Log when home screen starts building
    final homeBuildStart = DateTime.now();
    print('🏠 HOME SCREEN BUILD START: ${homeBuildStart.toIso8601String()}');

    // PERFORMANCE OPTIMIZATION: Single data fetch for entire screen
    return FutureBuilder<Map<String, dynamic>>(
      future: _homeServices.getUserData(currentUser.uid),
      key: ValueKey('home_screen_${currentUser.uid}_$_refreshCounter'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          // Show minimal loading state
          return Scaffold(
            appBar: AppBar(
              title: Text(AppLocalizations.of(context)!.home),
            ),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        UserModel? userModel;
        if (snapshot.hasData) {
          final data = snapshot.data!;
          if (data['user'] is UserModel) {
            userModel = data['user'] as UserModel;

            // PERFORMANCE TRACKING: Log when home screen data is loaded
            final homeDataLoaded = DateTime.now();
            final loadTime = homeDataLoaded.difference(homeBuildStart).inMilliseconds;
            print('✅ HOME SCREEN DATA LOADED: ${homeDataLoaded.toIso8601String()} (${loadTime}ms from build start)');
          }
        }

        // User is authenticated, proceed with normal UI
        // Check for spotlight after authentication is confirmed (only if not dismissed globally)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !DistrictSpotlightService.isSpotlightDismissedForSession) {
            // Show spotlight for Pune district (as per user requirement)
            DistrictSpotlightService.showDistrictSpotlightIfAvailable('maharashtra', 'pune');
          }
        });

        return GetBuilder<CandidateDataController>(
          builder: (candidateController) {
            // DEBUG: Add detailed logging to understand the issue
            print('🔍 DEBUG - User role check:');
            print('  userModel: ${userModel?.toJson()}');
            print('  role: "${userModel?.role}"');
            print('  role == candidate: ${userModel?.role == 'candidate'}');
            print('  snapshot.hasData: ${snapshot.hasData}');
            if (snapshot.hasData) {
              print('  snapshot.data: ${snapshot.data}');
              print('  candidate in snapshot: ${snapshot.data!['candidate']}');
              print('  user in snapshot: ${snapshot.data!['user']}');
            }

            // FIX: Properly extract user data from snapshot
            UserModel? extractedUserModel;
            if (snapshot.hasData && snapshot.data != null) {
              final data = snapshot.data!;
              if (data['user'] != null) {
                try {
                  extractedUserModel = UserModel.fromJson(data['user'] as Map<String, dynamic>);
                  print('✅ Successfully extracted user model: ${extractedUserModel.name}');
                } catch (e) {
                  print('❌ Failed to parse user model from snapshot: $e');
                }
              } else {
                print('❌ No user data in snapshot');
              }
            }

            // Use extracted user model, fallback to existing userModel
            final effectiveUserModel = extractedUserModel ?? userModel;

            // CRITICAL FIX: Ensure candidate data is loaded immediately for candidates
            if (effectiveUserModel?.role == 'candidate') {
              print('✅ ENTERING CANDIDATE MODE');

              // Check if we have candidate data from the service call
              Candidate? candidateFromService;
              if (snapshot.hasData && snapshot.data!['candidate'] != null) {
                candidateFromService = snapshot.data!['candidate'] as Candidate;
                print('📦 Candidate data found in service: ${candidateFromService.name}');
              } else {
                print('❌ No candidate data in service snapshot');
              }

              // Use service data if available, otherwise use controller data
              final displayCandidate = candidateFromService ?? candidateController.candidateData.value;
              print('🎯 Final display candidate: ${displayCandidate?.name ?? 'NULL'}');

              // If still no candidate data, trigger immediate load (not lazy)
              if (displayCandidate == null && !candidateController.isLoading.value) {
                print('🔄 Triggering candidate data load...');
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && !candidateController.isLoading.value) {
                    candidateController.fetchCandidateData();
                  }
                });
              }

              // PERFORMANCE TRACKING: Log when home screen is fully rendered
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final homeFullyRendered = DateTime.now();
                final totalTime = homeFullyRendered.difference(homeBuildStart).inMilliseconds;
                print('🎉 HOME SCREEN FULLY RENDERED: ${homeFullyRendered.toIso8601String()} (${totalTime}ms from build start)');
                print('👤 CANDIDATE MODE - Data loaded: ${displayCandidate != null ? 'YES' : 'NO'}');
              });

              return Scaffold(
                appBar: AppBar(
                  title: Text(AppLocalizations.of(context)!.home),
                ),
                drawer: HomeDrawer(
                  userModel: effectiveUserModel,
                  candidateModel: displayCandidate,
                  currentUser: currentUser,
                ),
                body: RefreshIndicator(
                  key: _refreshIndicatorKey,
                  onRefresh: () async {
                    setState(() {
                      _refreshCounter++;
                    });
                    await candidateController.refreshCandidateData();
                    await Future.delayed(const Duration(milliseconds: 300));
                  },
                  child: HomeBody(
                    userModel: effectiveUserModel,
                    candidateModel: displayCandidate,
                    currentUser: currentUser,
                  ),
                ),
              );
            } else {
              print('✅ ENTERING VOTER MODE');

              // For non-candidates, use the original logic
              // PERFORMANCE TRACKING: Log when home screen is fully rendered
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final homeFullyRendered = DateTime.now();
                final totalTime = homeFullyRendered.difference(homeBuildStart).inMilliseconds;
                print('🎉 HOME SCREEN FULLY RENDERED: ${homeFullyRendered.toIso8601String()} (${totalTime}ms from build start)');
                print('👤 VOTER MODE - No candidate data needed');
              });

              return Scaffold(
                appBar: AppBar(
                  title: Text(AppLocalizations.of(context)!.home),
                ),
                drawer: HomeDrawer(
                  userModel: effectiveUserModel,
                  candidateModel: null, // Voters don't have candidate data
                  currentUser: currentUser,
                ),
                body: RefreshIndicator(
                  key: _refreshIndicatorKey,
                  onRefresh: () async {
                    setState(() {
                      _refreshCounter++;
                    });
                    await Future.delayed(const Duration(milliseconds: 300));
                  },
                  child: HomeBody(
                    userModel: effectiveUserModel,
                    candidateModel: null, // Voters don't have candidate data
                    currentUser: currentUser,
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }
}

