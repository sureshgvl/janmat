import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:janmat/features/user/models/user_model.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/snackbar_utils.dart';
import '../../candidate/models/candidate_model.dart';
import '../../../features/highlight/widgets/candidate_highlight_banner.dart';
import '../../candidate/screens/candidate_dashboard_screen.dart';
import 'home_widgets.dart';
import 'feed_widgets.dart';

class HomeSections {
  // Main Home Body Widget
  static Widget buildHomeBody({
    required UserModel? userModel,
    required Candidate? candidateModel,
    required User? currentUser,
  }) {
    return HomeBodyContent(
      userModel: userModel,
      candidateModel: candidateModel,
      currentUser: currentUser,
    );
  }
}

class HomeBodyContent extends StatefulWidget {
  final UserModel? userModel;
  final Candidate? candidateModel;
  final User? currentUser;

  const HomeBodyContent({
    super.key,
    required this.userModel,
    required this.candidateModel,
    required this.currentUser,
  });

  @override
  _HomeBodyContentState createState() => _HomeBodyContentState();
}

class _HomeBodyContentState extends State<HomeBodyContent> {
  // Service instances
  final FeedWidgets _feedWidgets = FeedWidgets();

  @override
  Widget build(BuildContext context) {
    // Start performance timing for entire home screen build
    final homeBuildTimer = AppLogger.startSectionTimer(
      'Home Screen Build',
      tag: 'HOME_PERF',
    );

    // Get location data for highlights
    final locationData = _getLocationData();
    AppLogger.ui(
      'HomeBodyContent: Using location - ${locationData['districtId']}/${locationData['bodyId']}/${locationData['wardId']}',
      tag: 'HOME',
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
          // Start Feed Section
          Builder(
            builder: (context) {
              AppLogger.common('┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄', tag: 'FEED_SECTION');
              AppLogger.common('Start Feed Section', tag: 'FEED_SECTION');
              return const SizedBox.shrink();
            },
          ),

          // CANDIDATE HIGHLIGHT BANNER (Full width - no padding)
          Builder(
            builder: (context) {
              final bannerWidget = CandidateHighlightBanner(
                stateId: locationData['stateId'] ?? 'maharashtra',
                districtId: locationData['districtId'] ?? 'pune',
                bodyId: locationData['bodyId'] ?? 'pune_m_cop',
                wardId: locationData['wardId'] ?? 'ward_17',
              );
              return bannerWidget;
            },
          ),

          // Add padding container for sections below
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SECTION 3: PUSH FEED CARDS
                Builder(
                  builder: (context) {
                    AppLogger.common(
                      'Loading Push Feed Cards...',
                      tag: 'FEED_SECTION',
                    );
                    return _feedWidgets.buildPushFeedSection(
                      context,
                      widget.userModel,
                      widget.candidateModel,
                      locationData,
                      _showCreatePostDialog,
                    );
                  },
                ),

                // SECTION 4: NORMAL FEED
                Builder(
                  builder: (context) {
                    AppLogger.common(
                      'Loading Normal Feed...',
                      tag: 'FEED_SECTION',
                    );
                    return _feedWidgets.buildNormalFeedSection(
                      context,
                      locationData,
                      _showCreatePostDialog,
                    );
                  },
                ),

                Builder(
                  builder: (context) {
                    AppLogger.common('End Feed Section', tag: 'FEED_SECTION');
                    AppLogger.common(
                      '┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄',
                      tag: 'FEED_SECTION',
                    );
                    return const SizedBox.shrink();
                  },
                ),

                // SECTION 5: EVENT CARD
                //EventPollWidgets.buildEventCard(context),

                // SECTION 6: POLL CARD
                //EventPollWidgets.buildPollCard(context),

                // ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
                // Start Static Sections
                Builder(
                  builder: (context) {
                    AppLogger.common(
                      '┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄',
                      tag: 'STATIC_SECTIONS',
                    );
                    AppLogger.common(
                      'Start Static Sections',
                      tag: 'STATIC_SECTIONS',
                    );
                    return const SizedBox.shrink();
                  },
                ),

                // ===== EXISTING SECTIONS =====
                // Welcome Section
                Builder(
                  builder: (context) {
                    AppLogger.common(
                      'Loading Welcome Section...',
                      tag: 'STATIC_SECTIONS',
                    );
                    return HomeWidgets.buildWelcomeSection(
                      context,
                      widget.userModel,
                      widget.currentUser,
                    );
                  },
                ),

                // Trial Status Banner (only for candidates with active trials)
                if (widget.userModel?.role == 'candidate' &&
                    widget.userModel?.isTrialActive == true) ...[
                  Builder(
                    builder: (context) {
                      AppLogger.common(
                        'Loading Trial Status Banner...',
                        tag: 'STATIC_SECTIONS',
                      );
                      return HomeWidgets.buildTrialBanner(
                        context,
                        widget.userModel!,
                      );
                    },
                  ),
                ],

                const SizedBox(height: 32),

                // Premium Features Card - only show for candidates
                if (widget.userModel?.role == 'candidate') ...[
                  Builder(
                    builder: (context) {
                      AppLogger.common(
                        'Loading Premium Features Card...',
                        tag: 'STATIC_SECTIONS',
                      );
                      return HomeWidgets.buildPremiumCard(
                        context,
                        widget.userModel,
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ],

                const SizedBox(height: 32),

                // Quick Actions
                Builder(
                  builder: (context) {
                    AppLogger.common(
                      'Loading Quick Actions...',
                      tag: 'STATIC_SECTIONS',
                    );
                    return HomeWidgets.buildQuickActions(context);
                  },
                ),

                Builder(
                  builder: (context) {
                    AppLogger.common(
                      'End Static Sections',
                      tag: 'STATIC_SECTIONS',
                    );
                    AppLogger.common(
                      '┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄',
                      tag: 'STATIC_SECTIONS',
                    );
                    return const SizedBox.shrink();
                  },
                ),

                if (widget.userModel?.role == 'candidate') ...[
                  const SizedBox(height: 32),
                  Builder(
                    builder: (context) {
                      AppLogger.common(
                        'Loading Candidate Dashboard...',
                        tag: 'STATIC_SECTIONS',
                      );
                      return _buildCandidateDashboard(context);
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, String> _getLocationData() {
    // Priority 1: Candidate's location data (for candidates)
    if (widget.candidateModel?.location.districtId != null &&
        widget.candidateModel!.location.districtId?.isNotEmpty == true &&
        widget.candidateModel?.location.bodyId?.isNotEmpty == true &&
        widget.candidateModel?.location.wardId?.isNotEmpty == true) {
      final location = {
        'stateId': widget.candidateModel!.location.stateId ?? 'maharashtra',
        'districtId': widget.candidateModel!.location.districtId ?? '',
        'bodyId': widget.candidateModel!.location.bodyId ?? '',
        'wardId': widget.candidateModel!.location.wardId ?? '',
      };
      return location;
    }

    // Priority 2: User's election areas (for voters and candidates)
    if (widget.userModel?.electionAreas != null &&
        widget.userModel!.electionAreas.isNotEmpty) {
      final primaryArea = widget.userModel!.electionAreas.first;
      final districtId = widget.userModel!.districtId ?? 'pune';
      final stateId =
          widget.userModel!.stateId ??
          'maharashtra'; // Assume Maharashtra for now
      final location = {
        'stateId': stateId,
        'districtId': districtId,
        'bodyId': primaryArea.bodyId,
        'wardId': primaryArea.wardId,
      };
      return location;
    }

    // Priority 3: User's direct location fields (legacy support)
    if (widget.userModel?.districtId != null &&
        widget.userModel!.districtId!.isNotEmpty) {
      final stateId =
          widget.userModel!.stateId ??
          'maharashtra'; // Assume Maharashtra for now
      final districtId = widget.userModel!.districtId!;
      final bodyId = widget.userModel!.bodyId ?? 'pune_m_cop';
      final wardId = widget.userModel!.wardId ?? 'ward_17';
      final location = {
        'stateId': stateId,
        'districtId': districtId,
        'bodyId': bodyId,
        'wardId': wardId,
      };
      AppLogger.ui(
        '🏠 HomeSections: Priority 3 - Using user direct location: ${location['stateId']}/${location['districtId']}/${location['bodyId']}/${location['wardId']}',
        tag: 'HOME',
      );
      AppLogger.ui(
        '🏠 HomeSections: User role: ${widget.userModel?.role}',
        tag: 'HOME',
      );
      AppLogger.ui(
        '🏠 HomeSections: Direct location - stateId: $stateId, districtId: $districtId, bodyId: $bodyId, wardId: $wardId',
        tag: 'HOME',
      );
      AppLogger.ui(
        '🏠 HomeSections: === GETTING LOCATION DATA END ===\n',
        tag: 'HOME',
      );
      return location;
    }

    // Fallback: Default Pune location (consistent with voter search)
    final location = {
      'stateId': 'maharashtra',
      'districtId': 'pune',
      'bodyId': 'pune_m_cop',
      'wardId': 'ward_17',
    };
    AppLogger.ui(
      '🏠 HomeSections: Fallback - Using default location: ${location['stateId']}/${location['districtId']}/${location['bodyId']}/${location['wardId']}',
      tag: 'HOME',
    );
    AppLogger.ui(
      '🏠 HomeSections: User role: ${widget.userModel?.role}',
      tag: 'HOME',
    );
    AppLogger.ui(
      '🏠 HomeSections: No location data found, using fallback',
      tag: 'HOME',
    );
    AppLogger.ui(
      '🏠 HomeSections: === GETTING LOCATION DATA END ===\n',
      tag: 'HOME',
    );
    return location;
  }

  void _showCreatePostDialog(BuildContext context, {bool isSponsored = false}) {
    final locationData = _getLocationData();
    // This would need to be implemented with the actual dialog
    // For now, just show a placeholder
    SnackbarUtils.showScaffoldInfo(
      context,
      isSponsored ? 'Create Sponsored Post' : 'Create Community Post',
    );
  }

  Widget _buildCandidateDashboard(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onSurfaceColor = theme.colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Candidate Dashboard',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: onSurfaceColor,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: ListTile(
            leading: Icon(Icons.dashboard, color: primaryColor),
            title: const Text('Manage Your Campaign'),
            subtitle: const Text('View analytics and update your profile'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Navigate to candidate dashboard
              Get.to(() => const CandidateDashboardScreen());
            },
          ),
        ),
      ],
    );
  }
}
