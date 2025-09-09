import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/candidate_model.dart';
import '../../l10n/app_localizations.dart';

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

  // Get party colors for gradient and borders
  List<Color> getPartyColors(String party) {
    final partyColors = {
      'Indian National Congress': [Colors.blue.shade400, Colors.blue.shade600],
      'Bharatiya Janata Party': [Colors.orange.shade400, Colors.orange.shade600],
      'Nationalist Congress Party': [Colors.blue.shade500, Colors.blue.shade700],
      'Shiv Sena': [Colors.red.shade400, Colors.red.shade600],
      'Maharashtra Navnirman Sena': [Colors.green.shade400, Colors.green.shade600],
      'Communist Party of India': [Colors.red.shade500, Colors.red.shade700],
      'Bahujan Samaj Party': [Colors.blue.shade600, Colors.blue.shade800],
      'Samajwadi Party': [Colors.red.shade400, Colors.red.shade600],
      'All India Majlis-e-Ittehad-ul-Muslimeen': [Colors.green.shade500, Colors.green.shade700],
    };

    // Try exact match
    if (partyColors.containsKey(party)) {
      return partyColors[party]!;
    }

    // Try partial matches
    for (var entry in partyColors.entries) {
      if (party.toUpperCase().contains(entry.key.toUpperCase().replaceAll(' ', '')) ||
          entry.key.toUpperCase().contains(party.toUpperCase().replaceAll(' ', ''))) {
        return entry.value;
      }
    }

    // Default colors
    return [Colors.blue.shade400, Colors.blue.shade600];
  }

  @override
  Widget build(BuildContext context) {
    final partyColors = getPartyColors(candidate.party);

    return SliverAppBar(
      expandedHeight: 380,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                partyColors[0].withOpacity(0.8),
                partyColors[1].withOpacity(0.9),
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

              // Cover Banner Effect
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 200,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        partyColors[0].withOpacity(0.6),
                        partyColors[1].withOpacity(0.8),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),

              // Candidate Photo with Party-Colored Border
              Positioned(
                top: 120,
                left: MediaQuery.of(context).size.width / 2 - 70,
                child: Stack(
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: partyColors[0],
                          width: 6,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
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
                                        fontSize: 50,
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
                                    fontSize: 50,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    // Premium Blue Tick
                    if (isPremiumCandidate)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade600,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.verified,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Name and Info Section
              Positioned(
                top: 280,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Text(
                      candidate.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    if (isPremiumCandidate)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade600,
                          borderRadius: BorderRadius.circular(16),
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
                            const Icon(
                              Icons.verified,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              AppLocalizations.of(context)!.verified,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Followers and Following counts
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        buildStatItem('${candidate.followersCount}', AppLocalizations.of(context)!.followers),
                        const SizedBox(width: 32),
                        buildStatItem('${candidate.followingCount}', AppLocalizations.of(context)!.following),
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
      bottom: TabBar(
        tabs: [
          Tab(text: AppLocalizations.of(context)!.info),
          Tab(text: AppLocalizations.of(context)!.manifesto),
          Tab(text: AppLocalizations.of(context)!.media),
          Tab(text: AppLocalizations.of(context)!.contact),
        ],
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorWeight: 3,
      ),
    );
  }
}