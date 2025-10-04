import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/user_model.dart';
import '../../candidate/models/candidate_model.dart';
import '../../../widgets/highlight_banner.dart';
import '../../../widgets/highlight_carousel.dart';
import 'home_widgets.dart';
import 'feed_widgets.dart';
import 'event_poll_widgets.dart';

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
    // Get location data for highlights
    final locationData = _getLocationData();
    debugPrint('🏠 HomeBodyContent: Using location - ${locationData['districtId']}/${locationData['bodyId']}/${locationData['wardId']}');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SECTION 1: PLATINUM BANNER (Conditional)
          HighlightBanner(
            districtId: locationData['districtId']!,
            bodyId: locationData['bodyId']!,
            wardId: locationData['wardId']!,
            showViewMoreButton: true,
          ),

          // SECTION 2: HIGHLIGHT CAROUSEL
          HighlightCarousel(
            districtId: locationData['districtId']!,
            bodyId: locationData['bodyId']!,
            wardId: locationData['wardId']!,
          ),

          // SECTION 3: PUSH FEED CARDS
          _feedWidgets.buildPushFeedSection(
            context,
            widget.userModel,
            widget.candidateModel,
            locationData,
            _showCreatePostDialog,
          ),

          // SECTION 4: NORMAL FEED
          _feedWidgets.buildNormalFeedSection(
            context,
            locationData,
            _showCreatePostDialog,
          ),

          // SECTION 5: EVENT CARD
          //EventPollWidgets.buildEventCard(context),

          // SECTION 6: POLL CARD
          //EventPollWidgets.buildPollCard(context),

          // ===== EXISTING SECTIONS =====
          // Welcome Section
          HomeWidgets.buildWelcomeSection(
            context,
            widget.userModel,
            widget.currentUser,
            widget.candidateModel,
          ),

          // Trial Status Banner (only for candidates with active trials)
          if (widget.userModel?.role == 'candidate' &&
              widget.userModel?.isTrialActive == true)
            HomeWidgets.buildTrialBanner(context, widget.userModel!),

          const SizedBox(height: 32),

          // Premium Features Card
          HomeWidgets.buildPremiumCard(context, widget.userModel),

          const SizedBox(height: 32),

          // Quick Actions
          HomeWidgets.buildQuickActions(context),

          if (widget.userModel?.role == 'candidate') ...[
            const SizedBox(height: 32),
            _buildCandidateDashboard(context),
          ],
        ],
      ),
    );
  }

  Map<String, String> _getLocationData() {
    // Priority 1: Candidate's location data (for candidates)
    if (widget.candidateModel?.districtId != null &&
        widget.candidateModel!.districtId.isNotEmpty &&
        widget.candidateModel?.bodyId != null &&
        widget.candidateModel!.bodyId.isNotEmpty &&
        widget.candidateModel?.wardId != null &&
        widget.candidateModel!.wardId.isNotEmpty) {
      debugPrint('🏠 Home: Using candidate location: ${widget.candidateModel!.districtId}/${widget.candidateModel!.bodyId}/${widget.candidateModel!.wardId}');
      return {
        'districtId': widget.candidateModel!.districtId,
        'bodyId': widget.candidateModel!.bodyId,
        'wardId': widget.candidateModel!.wardId,
      };
    }

    // Priority 2: User's election areas (for voters and candidates)
    if (widget.userModel?.electionAreas != null &&
        widget.userModel!.electionAreas.isNotEmpty) {
      final primaryArea = widget.userModel!.electionAreas.first;
      final districtId = widget.userModel!.districtId ?? 'pune';
      debugPrint('🏠 Home: Using user election area: $districtId/${primaryArea.bodyId}/${primaryArea.wardId}');
      return {
        'districtId': districtId,
        'bodyId': primaryArea.bodyId,
        'wardId': primaryArea.wardId,
      };
    }

    // Priority 3: User's direct location fields (legacy support)
    if (widget.userModel?.districtId != null &&
        widget.userModel!.districtId!.isNotEmpty) {
      final districtId = widget.userModel!.districtId!;
      final bodyId = widget.userModel!.bodyId ?? 'pune_m_cop';
      final wardId = widget.userModel!.wardId ?? 'ward_17';
      debugPrint('🏠 Home: Using user direct location: $districtId/$bodyId/$wardId');
      return {
        'districtId': districtId,
        'bodyId': bodyId,
        'wardId': wardId,
      };
    }

    // Fallback: Default Pune location (consistent with voter search)
    debugPrint('🏠 Home: Using fallback location: pune/pune_m_cop/ward_17');
    return {
      'districtId': 'pune',
      'bodyId': 'pune_m_cop',
      'wardId': 'ward_17',
    };
  }

  void _showCreatePostDialog(BuildContext context, {bool isSponsored = false}) {
    final locationData = _getLocationData();
    // This would need to be implemented with the actual dialog
    // For now, just show a placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isSponsored ? 'Create Sponsored Post' : 'Create Community Post'),
      ),
    );
  }

  Widget _buildCandidateDashboard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Candidate Dashboard',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: ListTile(
            leading: const Icon(Icons.dashboard, color: Color(0xFFFF9933)),
            title: const Text('Manage Your Campaign'),
            subtitle: const Text('View analytics and update your profile'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Navigate to candidate dashboard
            },
          ),
        ),
      ],
    );
  }
}