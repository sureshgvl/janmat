import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/user_model.dart';
import '../../candidate/models/candidate_model.dart';
import '../../../services/trial_service.dart';
import '../../../utils/symbol_utils.dart';
import '../../../utils/helpers.dart';
import '../../../widgets/highlight_banner.dart';
import '../../../widgets/highlight_carousel.dart';
import '../../candidate/screens/candidate_list_screen.dart';
import '../../candidate/screens/candidate_dashboard_screen.dart';
import '../../candidate/screens/my_area_candidates_screen.dart';
import '../../monetization/screens/monetization_screen.dart';
import '../widgets/home_widgets.dart';
import 'home_navigation.dart';

class HomeBody extends StatelessWidget {
  final UserModel? userModel;
  final Candidate? candidateModel;
  final User? currentUser;

  const HomeBody({
    super.key,
    required this.userModel,
    required this.candidateModel,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    // Get location data for highlights
    final locationData = _getLocationData();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SECTION 1: PLATINUM BANNER (Conditional)
          // Platinum Banner (only shows if available for this location)
          HighlightBanner(
            districtId: locationData['districtId']!,
            bodyId: locationData['bodyId']!,
            wardId: locationData['wardId']!,
          ),

          // SECTION 2: HIGHLIGHT CAROUSEL
          // Highlight Carousel (shows Gold/Platinum highlights for this location)
          HighlightCarousel(
            districtId: locationData['districtId']!,
            bodyId: locationData['bodyId']!,
            wardId: locationData['wardId']!,
          ),

          const SizedBox(height: 24),

          // SECTION 3: PUSH FEED CARDS
          _buildPushFeedSection(context),

          const SizedBox(height: 24),

          // SECTION 4: NORMAL FEED
          _buildNormalFeedSection(context),

          const SizedBox(height: 32),

          // ===== EXISTING SECTIONS =====
          // Welcome Section
          _buildWelcomeSection(context),

          // Trial Status Banner (only for candidates with active trials)
          if (userModel?.role == 'candidate' &&
              userModel?.isTrialActive == true)
            _buildTrialBanner(context),

          const SizedBox(height: 32),

          // Premium Features Card
          _buildPremiumCard(context),

          const SizedBox(height: 32),

          // Quick Actions
          _buildQuickActions(context),

          if (userModel?.role == 'candidate') ...[
            const SizedBox(height: 32),
            _buildCandidateDashboard(context),
          ],
        ],
      ),
    );
  }

  Map<String, String> _getLocationData() {
    // Priority: Candidate's location data
    if (candidateModel?.districtId != null && candidateModel!.districtId.isNotEmpty &&
        candidateModel?.bodyId != null && candidateModel!.bodyId.isNotEmpty &&
        candidateModel?.wardId != null && candidateModel!.wardId.isNotEmpty) {
      return {
        'districtId': candidateModel!.districtId,
        'bodyId': candidateModel!.bodyId,
        'wardId': candidateModel!.wardId,
      };
    }

    // For voters or when candidate data is incomplete
    // You can implement location-based detection here
    // For now, return default Pune location
    return {
      'districtId': 'Pune',
      'bodyId': 'pune_city',
      'wardId': 'ward_pune_1',
    };
  }

  String _getWardId() {
    // Legacy method for backward compatibility
    return _getLocationData()['wardId']!;
  }

  Future<List<Map<String, dynamic>>> _loadPushFeedData() async {
    try {
      final locationData = _getLocationData();

      // For now, return mock data - replace with actual service call
      // TODO: Replace with actual push feed service call
      return [
        {
          'title': 'Ward Meeting Tomorrow',
          'message': 'Join us for the upcoming ward development meeting at 10 AM in ${locationData['wardId']}.',
          'imageUrl': null,
          'isSponsored': true,
        },
        {
          'title': 'New Infrastructure Project',
          'message': 'Exciting updates on the new road construction in our ${locationData['wardId']} area.',
          'imageUrl': null,
          'isSponsored': true,
        },
      ];

      // Future implementation:
      // final pushFeedService = PushFeedService();
      // return await pushFeedService.getPushFeedForWard(
      //   locationData['districtId']!,
      //   locationData['bodyId']!,
      //   locationData['wardId']!,
      // );

    } catch (e) {
      debugPrint('Error loading push feed data: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadNormalFeedData() async {
    try {
      final locationData = _getLocationData();

      // For now, return mock data with location context - replace with actual service call
      // TODO: Replace with actual community feed service call
      return [
        {
          'author': 'Rajesh Kumar',
          'content': 'Great meeting with local residents today in ${locationData['wardId']}. Discussed important community issues.',
          'timestamp': '2 hours ago',
          'likes': 12,
          'comments': 3,
        },
        {
          'author': 'Priya Sharma',
          'content': 'Attended the ward committee meeting in ${locationData['districtId']}. Good progress on infrastructure development.',
          'timestamp': '4 hours ago',
          'likes': 8,
          'comments': 2,
        },
        {
          'author': 'Amit Patel',
          'content': 'Community cleanup drive was successful in ${locationData['wardId']}. Thanks to all volunteers!',
          'timestamp': '6 hours ago',
          'likes': 15,
          'comments': 5,
        },
      ];

      // Future implementation:
      // final feedService = CommunityFeedService();
      // return await feedService.getCommunityFeedForWard(
      //   locationData['districtId']!,
      //   locationData['bodyId']!,
      //   locationData['wardId']!,
      // );

    } catch (e) {
      debugPrint('Error loading normal feed data: $e');
      return [];
    }
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                '${userModel?.name ?? currentUser?.displayName ?? 'User'}!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (candidateModel != null) ...[
              const SizedBox(width: 12),
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: Image(
                    image: SymbolUtils.getSymbolImageProvider(
                      SymbolUtils.getPartySymbolPath(
                        candidateModel!.party,
                        candidate: candidateModel,
                      ),
                    ),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/symbols/default.png',
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          userModel?.role == 'candidate'
              ? AppLocalizations.of(
                  context,
                )!.manageYourCampaignAndConnectWithVoters
              : AppLocalizations.of(
                  context,
                )!.stayInformedAboutYourLocalCandidates,
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildTrialBanner(BuildContext context) {
    return FutureBuilder<int>(
      future: TrialService().getTrialDaysRemaining(userModel!.uid),
      builder: (context, snapshot) {
        final daysRemaining = snapshot.data ?? 0;
        if (daysRemaining <= 0) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFF9933).withOpacity(0.8),
                const Color(0xFFFF9933),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.star, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.premiumTrialActive,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      daysRemaining == 1
                          ? AppLocalizations.of(context)!.oneDayRemainingUpgrade
                          : AppLocalizations.of(
                              context,
                            )!.daysRemainingInTrial(daysRemaining.toString()),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
              if (daysRemaining <= 1)
                ElevatedButton(
                  onPressed: () {
                    // TODO: Navigate to premium upgrade screen
                    Helpers.showWarningSnackBar(
                      context,
                      AppLocalizations.of(
                        context,
                      )!.premiumUpgradeFeatureComingSoon,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: Text(AppLocalizations.of(context)!.upgrade),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPremiumCard(BuildContext context) {
    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF138808).withOpacity(0.8),
              const Color(0xFF138808),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.unlockPremiumFeatures,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userModel?.role == 'candidate'
                              ? (userModel?.isTrialActive == true
                                    ? AppLocalizations.of(
                                        context,
                                      )!.enjoyFullPremiumFeaturesDuringTrial
                                    : AppLocalizations.of(
                                        context,
                                      )!.getPremiumVisibilityAndAnalytics)
                              : AppLocalizations.of(
                                  context,
                                )!.accessExclusiveContentAndFeatures,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      HomeNavigation.toRightToLeft(const MonetizationScreen()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFFF9933),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.explorePremium,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.quickActions,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            HomeWidgets.buildAnimatedQuickActionCard(
              icon: Icons.people,
              title: AppLocalizations.of(context)!.browseCandidates,
              page: const CandidateListScreen(),
            ),
            HomeWidgets.buildAnimatedQuickActionCard(
              icon: Icons.location_on,
              title: AppLocalizations.of(context)!.myArea,
              page: const MyAreaCandidatesScreen(),
            ),
            HomeWidgets.buildAnimatedQuickActionCard(
              icon: Icons.chat,
              title: AppLocalizations.of(context)!.chatRooms,
              routeName: '/chat',
            ),
            HomeWidgets.buildAnimatedQuickActionCard(
              icon: Icons.poll,
              title: AppLocalizations.of(context)!.polls,
              routeName: '/polls',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPushFeedSection(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadPushFeedData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const SizedBox.shrink(); // Hide section on error
        }

        final pushFeedItems = snapshot.data ?? [];

        if (pushFeedItems.isEmpty) {
          return const SizedBox.shrink(); // Hide section if no data
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.campaign, color: Colors.orange, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Sponsored Updates',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...pushFeedItems.map((item) => Column(
              children: [
                _buildPushFeedCard(
                  context,
                  title: item['title'] ?? '',
                  message: item['message'] ?? '',
                  imageUrl: item['imageUrl'],
                  isSponsored: item['isSponsored'] ?? true,
                ),
                const SizedBox(height: 12),
              ],
            )),
          ],
        );
      },
    );
  }

  Widget _buildNormalFeedSection(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadNormalFeedData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const SizedBox.shrink(); // Hide section on error
        }

        final feedItems = snapshot.data ?? [];

        if (feedItems.isEmpty) {
          return const SizedBox.shrink(); // Hide section if no data
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.article, color: Colors.blue, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Community Feed',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...feedItems.map((item) => Column(
              children: [
                _buildNormalFeedCard(
                  context,
                  author: item['author'] ?? '',
                  content: item['content'] ?? '',
                  timestamp: item['timestamp'] ?? '',
                  likes: item['likes'] ?? 0,
                  comments: item['comments'] ?? 0,
                ),
                const SizedBox(height: 12),
              ],
            )),
          ],
        );
      },
    );
  }

  Widget _buildPushFeedCard(
    BuildContext context, {
    required String title,
    required String message,
    String? imageUrl,
    required bool isSponsored,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Profile photo placeholder
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[300],
              ),
              child: const Icon(Icons.person, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSponsored) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'SPONSORED',
                            style: TextStyle(
                              fontSize: 8,
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        child: const Text('Learn More'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Dismiss',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNormalFeedCard(
    BuildContext context, {
    required String author,
    required String content,
    required String timestamp,
    required int likes,
    required int comments,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author info
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.shade100,
                  ),
                  child: const Icon(Icons.person, color: Colors.blue, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        author,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1f2937),
                        ),
                      ),
                      Text(
                        timestamp,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Content
            Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF374151),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            // Engagement stats
            Row(
              children: [
                Row(
                  children: [
                    const Icon(Icons.thumb_up, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      likes.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    const Icon(Icons.comment, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      comments.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCandidateDashboard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.candidateDashboard,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: ListTile(
            leading: const Icon(Icons.dashboard, color: Color(0xFFFF9933)),
            title: Text(AppLocalizations.of(context)!.manageYourCampaign),
            subtitle: Text(
              AppLocalizations.of(context)!.viewAnalyticsAndUpdateYourProfile,
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () =>
                HomeNavigation.toRightToLeft(const CandidateDashboardScreen()),
          ),
        ),
      ],
    );
  }
}
