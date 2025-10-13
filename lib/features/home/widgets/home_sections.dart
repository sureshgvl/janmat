import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/user_model.dart';
import '../../../utils/app_logger.dart';
import '../../candidate/models/candidate_model.dart';
import '../../../widgets/highlight_banner.dart';
import '../../../widgets/highlight_carousel.dart';
import '../../../services/district_promotion_service.dart';
import '../../../models/district_promotion_model.dart';
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
    // Get location data for highlights
    final locationData = _getLocationData();
    AppLogger.ui('HomeBodyContent: Using location - ${locationData['districtId']}/${locationData['bodyId']}/${locationData['wardId']}', tag: 'HOME');

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

          // SECTION 2.5: DISTRICT PROMOTION BANNER
          FutureBuilder<DistrictPromotion?>(
            future: DistrictPromotionService.getActivePromotionForDistrict(locationData['districtId']!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              }

              if (snapshot.hasData && snapshot.data != null) {
                final promotion = snapshot.data!;
                return _buildDistrictPromotionBanner(context, promotion);
              }

              return const SizedBox.shrink();
            },
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
      AppLogger.ui('Home: Using candidate location: ${widget.candidateModel!.districtId}/${widget.candidateModel!.bodyId}/${widget.candidateModel!.wardId}', tag: 'HOME');
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
      AppLogger.ui('Home: Using user election area: $districtId/${primaryArea.bodyId}/${primaryArea.wardId}', tag: 'HOME');
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
      AppLogger.ui('Home: Using user direct location: $districtId/$bodyId/$wardId', tag: 'HOME');
      return {
        'districtId': districtId,
        'bodyId': bodyId,
        'wardId': wardId,
      };
    }

    // Fallback: Default Pune location (consistent with voter search)
    AppLogger.ui('Home: Using fallback location: pune/pune_m_cop/ward_17', tag: 'HOME');
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
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDistrictPromotionBanner(BuildContext context, DistrictPromotion promotion) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () => _showDistrictPromotionDialog(context, promotion),
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              // Image section
              if (promotion.content.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    promotion.content.imageUrl,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 150,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported, size: 50),
                      );
                    },
                  ),
                ),

              // Content section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      promotion.content.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (promotion.content.subtitle != null && promotion.content.subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        promotion.content.subtitle!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${promotion.districtName}, ${promotion.stateName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          promotion.partyName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    if (promotion.content.ctaText != null && promotion.content.ctaText!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => _handlePromotionCTA(context, promotion),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(promotion.content.ctaText!),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDistrictPromotionDialog(BuildContext context, DistrictPromotion promotion) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with close button
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        promotion.content.title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              // Image
              if (promotion.content.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  child: Image.network(
                    promotion.content.imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported, size: 50),
                      );
                    },
                  ),
                ),

              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (promotion.content.subtitle != null && promotion.content.subtitle!.isNotEmpty)
                      Text(
                        promotion.content.subtitle!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${promotion.districtName}, ${promotion.stateName}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.flag, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          promotion.partyName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    if (promotion.content.ctaText != null && promotion.content.ctaText!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _handlePromotionCTA(context, promotion);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            promotion.content.ctaText!,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handlePromotionCTA(BuildContext context, DistrictPromotion promotion) {
    if (promotion.content.targetUrl != null && promotion.content.targetUrl!.isNotEmpty) {
      // Handle URL navigation (could use url_launcher package)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Opening: ${promotion.content.targetUrl}'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () {
              // Launch URL here
            },
          ),
        ),
      );
    } else {
      // Default action - could navigate to candidate list or party page
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Learn more about ${promotion.partyName}')),
      );
    }
  }
}
