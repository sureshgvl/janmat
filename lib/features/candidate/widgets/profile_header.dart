import 'package:flutter/material.dart';
import '../models/candidate_model.dart';
import '../../../l10n/features/candidate/candidate_localizations.dart';
import '../../../utils/symbol_utils.dart';

class ProfileHeader extends StatelessWidget {
  final Candidate candidate;
  final bool isPremiumCandidate;
  final String Function(String) getPartySymbolPath;
  final String Function(DateTime) formatDate;
  final Widget Function(String, String) buildStatItem;
  final VoidCallback? onCoverPhotoChange;
  final VoidCallback? onProfilePhotoChange;
  final String? currentUserId;
  final TabController? tabController;
  final bool isUploadingPhoto;

  const ProfileHeader({
    super.key,
    required this.candidate,
    required this.isPremiumCandidate,
    required this.getPartySymbolPath,
    required this.formatDate,
    required this.buildStatItem,
    this.onCoverPhotoChange,
    this.onProfilePhotoChange,
    this.currentUserId,
    this.tabController,
    this.isUploadingPhoto = false,
  });

  // Get party colors for gradient and borders
  List<Color> getPartyColors(String party) {
    // Handle independent candidates
    if (party.toLowerCase().contains('independent') || party.trim().isEmpty) {
      return [Colors.grey.shade600, Colors.grey.shade800];
    }

    // For now, use the same gradient for all parties
    // In the future, this can be customized per party from Firebase
    return [Colors.blue.shade600, Colors.blue.shade900];
  }

  // Build TabBar widget for outside profile section
  Widget buildTabBar(BuildContext context) {
    return const TabBar(
      isScrollable: true,
      tabs: [
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.black),
              SizedBox(width: 4),
              Text('Info', style: TextStyle(color: Colors.black)),
            ],
          ),
        ),
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.description_outlined, size: 16, color: Colors.black),
              SizedBox(width: 4),
              Text('Manifesto', style: TextStyle(color: Colors.black)),
            ],
          ),
        ),
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.photo_library_outlined, size: 16, color: Colors.black),
              SizedBox(width: 4),
              Text('Media', style: TextStyle(color: Colors.black)),
            ],
          ),
        ),
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.contact_phone_outlined, size: 16, color: Colors.black),
              SizedBox(width: 4),
              Text('Contact', style: TextStyle(color: Colors.black)),
            ],
          ),
        ),
      ],
      indicatorColor: Colors.black,
      labelColor: Colors.black,
      unselectedLabelColor: Colors.black54,
      indicatorWeight: 3,
      labelPadding: EdgeInsets.symmetric(horizontal: 8),
      labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 13),
      tabAlignment: TabAlignment.start,
    );
  }

  @override
  Widget build(BuildContext context) {
    final partyColors = getPartyColors(candidate.party);

    return SliverAppBar(
      expandedHeight: 320, // Reduced height without cover photo
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                partyColors[0],
                partyColors[1],
                Colors.black.withValues(alpha: 0.3),
              ],
              stops: const [0.0, 0.7, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Facebook-style Profile Picture
              Positioned(
                top: 80, // Adjusted position without cover photo
                left: 20,
                child: Stack(
                  children: [
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Stack(
                          children: [
                            candidate.basicInfo!.photo != null &&
                                    candidate.basicInfo!.photo!.isNotEmpty
                                ? Image.network(
                                    candidate.basicInfo!.photo!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return CircleAvatar(
                                        backgroundColor: partyColors[1],
                                        child: Text(
                                          candidate.basicInfo!.fullName![0].toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 60,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : CircleAvatar(
                                    backgroundColor: partyColors[1],
                                    child: Text(
                                      candidate.basicInfo!.fullName![0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 60,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                            if (isUploadingPhoto)
                              Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withValues(alpha: 0.5),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    // Star Badge on Profile Picture (matching HTML design)
                    Positioned(
                      bottom: -1,
                      right: -1,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.yellow.shade400,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.star,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),

                    // Profile Picture Change Button (Premium + Own Profile Only)
                    if (isPremiumCandidate &&
                        onProfilePhotoChange != null &&
                        currentUserId == candidate.userId)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: IconButton(
                            onPressed: onProfilePhotoChange,
                            icon: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 18,
                            ),
                            tooltip: 'Change Profile Picture',
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(6),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Name and Info Section (matching HTML design)
              Positioned(
                top: 140, // Adjusted position
                left: 200, // Start after profile picture
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Candidate Name
                    Text(
                      candidate.basicInfo!.fullName!,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Party Name
                    Text(
                      SymbolUtils.getPartyFullNameWithLocale(
                        candidate.party,
                        Localizations.localeOf(context).languageCode,
                      ),
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    // Location
                    Text(
                      'Ward 25, Pune', // Using placeholder for now
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),

              // Facebook-style Action Buttons and Stats
              Positioned(
                top: 240, // Adjusted position without cover photo
                left: 20,
                right: 20,
                child: Column(
                  children: [
                    // Followers and Following counts (Facebook-style)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildFacebookStyleStat(
                            _formatNumber(candidate.followersCount.toString()),
                            CandidateTranslations.tr('followers'),
                            Icons.people,
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color: Colors.grey.shade300,
                          ),
                          _buildFacebookStyleStat(
                            _formatNumber(candidate.followingCount.toString()),
                            CandidateTranslations.tr('following'),
                            Icons.person_add,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Facebook-style Action Buttons
                    Row(
                      children: [
                        // Follow/Unfollow Button
                        Expanded(
                          child: Container(
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade600,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: TextButton.icon(
                              onPressed: () {
                                // TODO: Implement follow/unfollow
                              },
                              icon: const Icon(
                                Icons.person_add,
                                color: Colors.white,
                                size: 18,
                              ),
                              label: Text(
                                'Follow',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Message Button
                        Expanded(
                          child: Container(
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: TextButton.icon(
                              onPressed: () {
                                // TODO: Implement messaging
                              },
                              icon: const Icon(
                                Icons.message,
                                color: Colors.black87,
                                size: 18,
                              ),
                              label: Text(
                                'Message',
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // More Options Button
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: IconButton(
                            onPressed: () {
                              // TODO: Show more options menu
                            },
                            icon: const Icon(
                              Icons.more_horiz,
                              color: Colors.black87,
                              size: 18,
                            ),
                            padding: EdgeInsets.zero,
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
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Candidate Profile',
        style: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.white,
      elevation: 2,
      actions: [
        // Edit Party & Symbol Button (Own Profile Only)
        if (currentUserId == candidate.userId)
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black),
            onPressed: () {
              Navigator.of(
                context,
              ).pushNamed('/change-party-symbol', arguments: candidate);
            },
            tooltip: 'Edit Party & Symbol',
          ),
      ],
    );
  }

  Widget _buildFacebookStyleStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1f2937),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatNumber(String value) {
    try {
      final num = int.parse(value);
      if (num >= 1000000) {
        return '${(num / 1000000).toStringAsFixed(1)}M';
      } else if (num >= 1000) {
        return '${(num / 1000).toStringAsFixed(1)}K';
      }
      return value;
    } catch (e) {
      return value;
    }
  }
}

