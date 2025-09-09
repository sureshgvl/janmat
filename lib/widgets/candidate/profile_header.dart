import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/candidate_model.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/theme_constants.dart';

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

   const ProfileHeader({
     Key? key,
     required this.candidate,
     required this.isPremiumCandidate,
     required this.getPartySymbolPath,
     required this.formatDate,
     required this.buildStatItem,
     this.onCoverPhotoChange,
     this.onProfilePhotoChange,
     this.currentUserId,
     this.tabController,
   }) : super(key: key);

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
             Text(
               'Info',
               style: TextStyle(color: Colors.black),
             ),
           ],
         ),
       ),
       Tab(
         child: Row(
           mainAxisSize: MainAxisSize.min,
           children: [
             Icon(Icons.description_outlined, size: 16, color: Colors.black),
             SizedBox(width: 4),
             Text(
               'Manifesto',
               style: TextStyle(color: Colors.black),
             ),
           ],
         ),
       ),
       Tab(
         child: Row(
           mainAxisSize: MainAxisSize.min,
           children: [
             Icon(Icons.photo_library_outlined, size: 16, color: Colors.black),
             SizedBox(width: 4),
             Text(
               'Media',
               style: TextStyle(color: Colors.black),
             ),
           ],
         ),
       ),
       Tab(
         child: Row(
           mainAxisSize: MainAxisSize.min,
           children: [
             Icon(Icons.contact_phone_outlined, size: 16, color: Colors.black),
             SizedBox(width: 4),
             Text(
               'Contact',
               style: TextStyle(color: Colors.black),
             ),
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
      expandedHeight: 480, // Increased height for Facebook-style layout with action buttons
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
                Colors.black.withOpacity(0.3),
              ],
              stops: const [0.0, 0.7, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Party Symbol Background with Blur Effect
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(getPartySymbolPath(candidate.party)),
                      fit: BoxFit.cover,
                      opacity: 0.1,
                    ),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                    child: Container(
                      color: Colors.black.withOpacity(0.1),
                    ),
                  ),
                ),
              ),

              // Cover Photo (Premium Feature) - Facebook Style
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 240, // Increased height for Facebook-style layout
                child: Stack(
                  children: [
                    // Cover Photo or Default Gradient
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        image: candidate.coverPhoto != null && candidate.coverPhoto!.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(candidate.coverPhoto!),
                                fit: BoxFit.cover,
                              )
                            : null,
                        gradient: candidate.coverPhoto == null || candidate.coverPhoto!.isEmpty
                            ? LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  partyColors[0].withOpacity(0.1),
                                  partyColors[1].withOpacity(0.1),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              )
                            : null,
                      ),
                    ),

                    // Cover Photo Overlay
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.1),
                            Colors.black.withOpacity(0.3),
                            Colors.black.withOpacity(0.1),
                          ],
                          stops: const [0.0, 0.7, 1.0],
                        ),
                      ),
                    ),

                    // Change Cover Photo Button (Premium + Own Profile Only)
                    if (isPremiumCandidate && onCoverPhotoChange != null && currentUserId == candidate.userId)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            onPressed: onCoverPhotoChange,
                            icon: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                            tooltip: 'Change Cover Photo',
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                      ),

                    // Premium Badge for Cover Photo
                    if (isPremiumCandidate && candidate.coverPhoto != null && candidate.coverPhoto!.isNotEmpty)
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Premium Cover',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Facebook-style Profile Picture (overlaps cover photo)
              Positioned(
                top: 160, // Position to overlap cover photo
                left: 20,
                child: Stack(
                  children: [
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: candidate.photo != null && candidate.photo!.isNotEmpty
                            ? Image.network(
                                candidate.photo!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return CircleAvatar(
                                    backgroundColor: partyColors[1],
                                    child: Text(
                                      candidate.name[0].toUpperCase(),
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
                                  candidate.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 60,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    // Premium/Free Badge on Profile Picture (Facebook-style)
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isPremiumCandidate
                              ? Colors.blue.shade600
                              : Colors.grey.shade500,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          isPremiumCandidate ? Icons.verified : Icons.person,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),

                    // Profile Picture Change Button (Premium + Own Profile Only)
                    if (isPremiumCandidate && onProfilePhotoChange != null && currentUserId == candidate.userId)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
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

              // Facebook-style Name and Info Section (positioned to the right of profile picture)
              Positioned(
                top: 200, // Position below the profile picture
                left: 200, // Start after profile picture
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Candidate Name
                    Text(
                      candidate.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          const Shadow(
                            color: Color(0xB3000000), // Equivalent to Colors.black.withOpacity(0.7)
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Party and Location Info
                    // Container(
                    //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    //   decoration: BoxDecoration(
                    //     color: Colors.black.withOpacity(0.4),
                    //     borderRadius: BorderRadius.circular(20),
                    //     border: Border.all(
                    //       color: Colors.white.withOpacity(0.3),
                    //       width: 1,
                    //     ),
                    //   ),
                    //   child: Text(
                    //     '${candidate.party} • ${candidate.cityId}',
                    //     style: const TextStyle(
                    //       color: Colors.white,
                    //       fontSize: 14,
                    //       fontWeight: FontWeight.w500,
                    //     ),
                    //   ),
                    // ),

                    const SizedBox(height: 12),

                    // Premium/Free Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isPremiumCandidate
                            ? Colors.blue.shade600
                            : Colors.grey.shade600,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPremiumCandidate ? Icons.verified : Icons.free_breakfast,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isPremiumCandidate
                                ? AppLocalizations.of(context)!.verified
                                : 'Free',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Facebook-style Action Buttons and Stats
              // Positioned(
              //   top: 320,
              //   left: 20,
              //   right: 20,
              //   child: Column(
              //     children: [
              //       // Followers and Following counts (Facebook-style)
              //       Container(
              //         padding: const EdgeInsets.symmetric(vertical: 16),
              //         decoration: BoxDecoration(
              //           color: Colors.white,
              //           borderRadius: BorderRadius.circular(12),
              //           boxShadow: [
              //             BoxShadow(
              //               color: Colors.black.withOpacity(0.1),
              //               blurRadius: 8,
              //               offset: const Offset(0, 4),
              //             ),
              //           ],
              //         ),
              //         child: Row(
              //           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              //           children: [
              //             _buildFacebookStyleStat(
              //               '${_formatNumber(candidate.followersCount.toString())}',
              //               AppLocalizations.of(context)!.followers,
              //               Icons.people,
              //             ),
              //             Container(
              //               width: 1,
              //               height: 30,
              //               color: Colors.grey.shade300,
              //             ),
              //             _buildFacebookStyleStat(
              //               '${_formatNumber(candidate.followingCount.toString())}',
              //               AppLocalizations.of(context)!.following,
              //               Icons.person_add,
              //             ),
              //           ],
              //         ),
              //       ),

              //       const SizedBox(height: 12),

              //       // Facebook-style Action Buttons
              //       Row(
              //         children: [
              //           // Follow/Unfollow Button
              //           Expanded(
              //             child: Container(
              //               height: 36,
              //               decoration: BoxDecoration(
              //                 color: Colors.blue.shade600,
              //                 borderRadius: BorderRadius.circular(6),
              //               ),
              //               child: TextButton.icon(
              //                 onPressed: () {
              //                   // TODO: Implement follow/unfollow
              //                 },
              //                 icon: const Icon(
              //                   Icons.person_add,
              //                   color: Colors.white,
              //                   size: 18,
              //                 ),
              //                 label: Text(
              //                   'Follow',
              //                   style: const TextStyle(
              //                     color: Colors.white,
              //                     fontSize: 14,
              //                     fontWeight: FontWeight.w600,
              //                   ),
              //                 ),
              //                 style: TextButton.styleFrom(
              //                   padding: EdgeInsets.zero,
              //                 ),
              //               ),
              //             ),
              //           ),
              //           const SizedBox(width: 8),

              //           // Message Button
              //           Expanded(
              //             child: Container(
              //               height: 36,
              //               decoration: BoxDecoration(
              //                 color: Colors.grey.shade200,
              //                 borderRadius: BorderRadius.circular(6),
              //               ),
              //               child: TextButton.icon(
              //                 onPressed: () {
              //                   // TODO: Implement messaging
              //                 },
              //                 icon: const Icon(
              //                   Icons.message,
              //                   color: Colors.black87,
              //                   size: 18,
              //                 ),
              //                 label: Text(
              //                   'Message',
              //                   style: const TextStyle(
              //                     color: Colors.black87,
              //                     fontSize: 14,
              //                     fontWeight: FontWeight.w600,
              //                   ),
              //                 ),
              //                 style: TextButton.styleFrom(
              //                   padding: EdgeInsets.zero,
              //                 ),
              //               ),
              //             ),
              //           ),
              //           const SizedBox(width: 8),

              //           // More Options Button
              //           Container(
              //             width: 36,
              //             height: 36,
              //             decoration: BoxDecoration(
              //               color: Colors.grey.shade200,
              //               borderRadius: BorderRadius.circular(6),
              //             ),
              //             child: IconButton(
              //               onPressed: () {
              //                 // TODO: Show more options menu
              //               },
              //               icon: const Icon(
              //                 Icons.more_horiz,
              //                 color: Colors.black87,
              //                 size: 18,
              //               ),
              //               padding: EdgeInsets.zero,
              //             ),
              //           ),
              //         ],
              //       ),
              //     ],
              //   ),
              // ),
            ],
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        // Edit Party & Symbol Button (Own Profile Only)
        if (currentUserId == candidate.userId)
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              Navigator.of(context).pushNamed(
                '/change-party-symbol',
                arguments: candidate,
              );
            },
            tooltip: 'Edit Party & Symbol',
          ),

        if (candidate.sponsored)
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  AppLocalizations.of(context)!.sponsored,
                  style: const TextStyle(
                    color: Color(0xFF374151),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
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
            Icon(
              icon,
              size: 16,
              color: Colors.grey[600],
            ),
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