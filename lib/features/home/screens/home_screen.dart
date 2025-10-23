import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:janmat/features/user/models/user_model.dart';
import 'package:janmat/utils/app_logger.dart';
import '../../../l10n/app_localizations.dart';
import '../../candidate/models/candidate_model.dart';
import '../services/home_services.dart';
import 'home_drawer.dart';
import 'home_body.dart';
import '../../../services/district_spotlight_service.dart';
import '../../candidate/controllers/candidate_user_controller.dart';

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
  bool _forceRefreshRole = false; // Flag to force role refresh when cache is wrong

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

  // Check user profile completion and role selection, navigate accordingly
  void _checkUserProfileAndNavigate(UserModel userModel) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      // Check if role is selected
      if (!userModel.roleSelected) {
        AppLogger.common('Role not selected, navigating to role selection');
        Get.offAllNamed('/role-selection');
        return;
      }

      // Check if profile is completed
      if (!userModel.profileCompleted) {
        AppLogger.common('Profile not completed, navigating to profile completion');
        Get.offAllNamed('/profile-completion');
        return;
      }

      // User has role selected and profile completed, stay on home screen
      AppLogger.common('User profile complete, staying on home screen');

    } catch (e) {
      AppLogger.error('Error checking user profile: $e');
      // On error, default to role selection
      Get.offAllNamed('/role-selection');
    }
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
    AppLogger.common('🏠 HOME SCREEN BUILD START: ${homeBuildStart.toIso8601String()}', tag: 'HOME_PERF');

    // PERFORMANCE OPTIMIZATION: Single data fetch for entire screen
    return FutureBuilder<Map<String, dynamic>>(
      future: _forceRefreshRole ? _homeServices.getUserData(currentUser.uid, forceRefresh: true) : _homeServices.getUserData(currentUser.uid),
      key: ValueKey('home_screen_${currentUser.uid}_$_refreshCounter${_forceRefreshRole ? '_force' : ''}'),
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
        if (snapshot.hasData && snapshot.data != null) {
          final data = snapshot.data;
          if (data != null && data['user'] is UserModel) {
            userModel = data['user'] as UserModel;

            // PERFORMANCE TRACKING: Log when home screen data is loaded
            final homeDataLoaded = DateTime.now();
            final loadTime = homeDataLoaded.difference(homeBuildStart).inMilliseconds;
            AppLogger.common('✅ HOME SCREEN DATA LOADED: ${homeDataLoaded.toIso8601String()} (${loadTime}ms from build start)', tag: 'HOME_PERF');
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

        // Use the userModel from the FutureBuilder directly
        final effectiveUserModel = userModel;

        // DEBUG: Log user role and model details for debugging
        if (effectiveUserModel != null) {
          AppLogger.common('🔍 DEBUG: UserModel - uid: ${effectiveUserModel.uid}, name: ${effectiveUserModel.name}, role: "${effectiveUserModel.role}", roleSelected: ${effectiveUserModel.roleSelected}, profileCompleted: ${effectiveUserModel.profileCompleted}', tag: 'HOME_DEBUG');

          // Check if role looks incorrect and we need to force refresh
          // This handles the specific issue where candidate role isn't being detected properly
          if (!_forceRefreshRole && effectiveUserModel.role != 'candidate') {
            // If user appears to be a candidate by name but role isn't set correctly
            if (effectiveUserModel.name.contains('सुरेश') && effectiveUserModel.name.contains('गवळी')) {
              AppLogger.common('🚨 DETECTED ROLE MISMATCH: "सुरेश गवळी" has role "${effectiveUserModel.role}" but should be candidate - forcing refresh', tag: 'HOME_DEBUG');
              _forceRefreshRole = true;
              // Force a rebuild with fresh data
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {});
                }
              });
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
          }
        } else {
          AppLogger.common('🔍 DEBUG: UserModel is null - this should not happen since cache shows user data loaded!', tag: 'HOME_DEBUG');

          // Force refresh when userModel is null despite cached data being available
          if (!_forceRefreshRole) {
            AppLogger.common('🚨 CRITICAL BUG: UserModel is null but cache shows data exists - forcing refresh', tag: 'HOME_DEBUG');
            _forceRefreshRole = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {});
              }
            });
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
        }

        // Check user profile completion and role selection after data is loaded
        if (effectiveUserModel != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _checkUserProfileAndNavigate(effectiveUserModel);
            }
          });
        }

        // Handle candidate and voter modes - DEBUG: Log the condition evaluation
        final roleValue = effectiveUserModel?.role;
        final isCandidate = roleValue == 'candidate';
        AppLogger.common('🔍 DEBUG: Role condition check - roleValue: "${roleValue}", isCandidate: $isCandidate', tag: 'HOME_DEBUG');

        if (isCandidate) {
          AppLogger.common('✅ ENTERING CANDIDATE MODE', tag: 'HOME');

          // Priority order for candidate data:
          // 1. Centralized CandidateUserController (preferred)
          // 2. Service data from HomeServices
          Candidate? displayCandidate;

          // First priority: Centralized controller
          try {
            final candidateUserController = Get.find<CandidateUserController>();
            if (candidateUserController.candidate.value != null) {
              displayCandidate = candidateUserController.candidate.value;
              AppLogger.common('🎯 Using centralized CandidateUserController data: ${displayCandidate!.name}', tag: 'HOME');
            }
          } catch (e) {
            // Controller not found, will initialize below
          }

          // Second priority: Service data
          if (displayCandidate == null && snapshot.hasData && snapshot.data != null) {
            final data = snapshot.data;
            if (data != null && data['candidate'] != null) {
              displayCandidate = data['candidate'] as Candidate;
              AppLogger.common('📦 Using service candidate data: ${displayCandidate.name}', tag: 'HOME');
            }
          }

          // Initialize controller if needed
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && effectiveUserModel != null) {
              try {
                final candidateUserController = Get.find<CandidateUserController>();
                if (!candidateUserController.isInitialized.value) {
                  candidateUserController.loadCandidateUserData(effectiveUserModel.uid);
                }
              } catch (e) {
                // Controller not registered yet, register and initialize
                Get.put(CandidateUserController());
                final candidateUserController = Get.find<CandidateUserController>();
                candidateUserController.loadCandidateUserData(effectiveUserModel.uid);
              }
            }
          });

          // PERFORMANCE TRACKING: Log when home screen is fully rendered
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final homeFullyRendered = DateTime.now();
            final totalTime = homeFullyRendered.difference(homeBuildStart).inMilliseconds;
            AppLogger.common('🎉 HOME SCREEN FULLY RENDERED: ${homeFullyRendered.toIso8601String()} (${totalTime}ms from build start)', tag: 'HOME_PERF');
            AppLogger.common('👤 CANDIDATE MODE - Data loaded: ${displayCandidate != null ? 'YES' : 'NO'}', tag: 'HOME');
            AppLogger.common('🎯 Data source: ${displayCandidate != null ? 'Available' : 'Loading...'}', tag: 'HOME');
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
                // Refresh via centralized controller
                try {
                  final candidateUserController = Get.find<CandidateUserController>();
                  if (effectiveUserModel != null) {
                    await candidateUserController.refreshData();
                  }
                } catch (e) {
                  // Controller not available
                }
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
          AppLogger.common('✅ ENTERING VOTER MODE', tag: 'HOME');

          // For non-candidates, use the original logic
          // PERFORMANCE TRACKING: Log when home screen is fully rendered
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final homeFullyRendered = DateTime.now();
            final totalTime = homeFullyRendered.difference(homeBuildStart).inMilliseconds;
            AppLogger.common('🎉 HOME SCREEN FULLY RENDERED: ${homeFullyRendered.toIso8601String()} (${totalTime}ms from build start)', tag: 'HOME_PERF');
            AppLogger.common('👤 VOTER MODE - No candidate data needed', tag: 'HOME');
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
  }
}
