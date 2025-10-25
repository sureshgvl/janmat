import 'package:flutter/material.dart';
import '../../../l10n/features/candidate/candidate_localizations.dart';

class ProfileTabBarWidget extends StatelessWidget {
  final TabController tabController;
  final bool isOwnProfile;

  const ProfileTabBarWidget({
    super.key,
    required this.tabController,
    required this.isOwnProfile,
  });

  @override
  Widget build(BuildContext context) {
    // Build tabs list conditionally
    final List<Widget> tabs = [
      //basic info
      Tab(
        child: Text(
          CandidateTranslations.tr('info'),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      //Manifesto
      Tab(
        child: Text(
          CandidateTranslations.tr('manifesto'),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      //Achievements
      Tab(
        child: Text(
          CandidateTranslations.tr('achievements'),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      //Media
      Tab(
        child: Text(
          CandidateTranslations.tr('media'),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      //Contact
      Tab(
        child: Text(
          CandidateTranslations.tr('contact'),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      //Events
      Tab(
        child: Text(
          CandidateTranslations.tr('events'),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ];

    // Add Analytics tab only for own profile
    if (isOwnProfile) {
      tabs.add(
        Tab(
          child: Text(
            CandidateTranslations.tr('analytics'),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverAppBarDelegate(
        TabBar(
          controller: tabController,
          isScrollable: true,
          tabs: tabs,
          indicatorColor: Colors.blue,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorWeight: 2,
          labelPadding: const EdgeInsets.symmetric(horizontal: 16),
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 14),
          tabAlignment: TabAlignment.start,
        ),
      ),
    );
  }
}

// Helper class for SliverPersistentHeader
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.white, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
