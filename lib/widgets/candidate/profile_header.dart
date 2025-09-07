import 'package:flutter/material.dart';
import '../../models/candidate_model.dart';

class ProfileHeader extends StatelessWidget {
  final Candidate candidate;
  final bool isPremiumCandidate;
  final String Function(String) getPartySymbolPath;
  final String Function(DateTime) formatDate;
  final Widget Function(String, String) buildStatItem;

  const ProfileHeader({
    Key? key,
    required this.candidate,
    required this.isPremiumCandidate,
    required this.getPartySymbolPath,
    required this.formatDate,
    required this.buildStatItem,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 350,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                candidate.sponsored ? Colors.grey.shade500 : Colors.blue.shade400,
                candidate.sponsored ? Colors.grey.shade700 : Colors.blue.shade600,
              ],
            ),
          ),
          child: Stack(
            children: [
              // Background Pattern
              Positioned.fill(
                child: Opacity(
                  opacity: 0.1,
                  child: Image.asset(
                    getPartySymbolPath(candidate.party),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // Candidate Photo with Premium Badge
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
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
                                        backgroundColor: candidate.sponsored ? Colors.grey.shade600 : Colors.blue,
                                        child: Text(
                                          candidate.name[0].toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 48,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : CircleAvatar(
                                    backgroundColor: candidate.sponsored ? Colors.grey.shade600 : Colors.blue,
                                    child: Text(
                                      candidate.name[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        // Premium Blue Tick
                        if (isPremiumCandidate)
                          Positioned(
                            bottom: 5,
                            right: 5,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade600,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.verified,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          candidate.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        if (isPremiumCandidate)
                          const SizedBox(width: 8),
                        if (isPremiumCandidate)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade600,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.verified,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'VERIFIED',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Followers and Following counts
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        buildStatItem('${candidate.followersCount}', 'Followers'),
                        const SizedBox(width: 24),
                        buildStatItem('${candidate.followingCount}', 'Following'),
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
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        if (candidate.sponsored)
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.star, color: Colors.grey, size: 16),
                SizedBox(width: 4),
                Text(
                  'SPONSORED',
                  style: TextStyle(
                    color: Color(0xFF374151),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
      ],
      bottom: const TabBar(
        tabs: [
          Tab(text: 'Info'),
          Tab(text: 'Manifesto'),
          Tab(text: 'Media'),
          Tab(text: 'Contact'),
        ],
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
      ),
    );
  }
}