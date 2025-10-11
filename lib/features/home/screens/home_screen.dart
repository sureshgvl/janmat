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
        return Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.home),
          ),
          drawer: FutureBuilder<Map<String, dynamic>>(
            future: _homeServices.getUserData(currentUser.uid),
            key: ValueKey('drawer_${currentUser.uid}_${candidateController.candidateData.value?.name ?? ''}_$_refreshCounter'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              UserModel? userModel;
              Candidate? candidateModel = candidateController.candidateData.value;

              if (snapshot.hasData) {
                userModel = snapshot.data!['user'];
              }


              return HomeDrawer(
                userModel: userModel,
                candidateModel: candidateModel,
                currentUser: currentUser,
              );
            },
          ),
          body: RefreshIndicator(
            key: _refreshIndicatorKey,
            onRefresh: () async {
              setState(() {
                _refreshCounter++;
              });
              await candidateController.refreshCandidateData();
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: FutureBuilder<Map<String, dynamic>>(
              future: _homeServices.getUserData(currentUser.uid),
              key: ValueKey('body_${currentUser.uid}_${candidateController.candidateData.value?.name ?? ''}_$_refreshCounter'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                UserModel? userModel;
                Candidate? candidateModel = candidateController.candidateData.value;

                if (snapshot.hasData) {
                  userModel = snapshot.data!['user'];
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
      },
    );
  }
}

