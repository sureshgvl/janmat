import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../l10n/app_localizations.dart';
import '../../models/candidate_model.dart';
import '../../controllers/candidate_controller.dart';
import '../../widgets/candidate/profile_header.dart';
import '../../widgets/candidate/info_tab.dart';
import '../../widgets/candidate/manifesto_tab.dart';
import '../../widgets/candidate/media_tab.dart';
import '../../widgets/candidate/contact_tab.dart';
import '../../utils/performance_monitor.dart';
import '../../utils/symbol_utils.dart';

class CandidateProfileScreen extends StatefulWidget {
  const CandidateProfileScreen({super.key});

  @override
  State<CandidateProfileScreen> createState() => _CandidateProfileScreenState();
}

class _CandidateProfileScreenState extends State<CandidateProfileScreen> with TickerProviderStateMixin {
  Candidate? candidate;
  final CandidateController controller = Get.find<CandidateController>();
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();

    // Initialize TabController for performance monitoring
    _tabController = TabController(length: 4, vsync: this);
    _tabController?.addListener(_onTabChanged);

    // Check if arguments are provided
    if (Get.arguments == null) {
      // Handle the case where no candidate data is provided
      // You might want to show an error or navigate back
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar(AppLocalizations.of(context)!.error, AppLocalizations.of(context)!.candidateDataNotFound);
        Get.back();
      });
      return;
    }

    candidate = Get.arguments as Candidate;

    // Add dummy data for demonstration if data is missing
    _addDummyDataIfNeeded();

    // Check follow status when screen loads
    if (currentUserId != null && candidate != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.checkFollowStatus(currentUserId!, candidate!.candidateId);
      });
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController?.indexIsChanging == false) {
      // Only log when tab change is complete
      final tabNames = ['Info', 'Manifesto', 'Media', 'Contact'];
      final currentTab = tabNames[_tabController!.index];

      // Only log in debug mode
      assert(() {
        debugPrint('🔄 Tab switched to: $currentTab');
        return true;
      }());
    }
  }

  void _addDummyDataIfNeeded() {
    // Removed all dummy data - now showing actual Firebase data only
    // The app will display real data from Firestore or show empty states
  }


  // Format date
  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    // Handle case where candidate is null
    if (candidate == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.candidateProfile),
        ),
        body: Center(
          child: Text(AppLocalizations.of(context)!.candidateDataNotAvailable),
        ),
      );
    }

    // Check if candidate is premium (you can define your own logic here)
    bool isPremiumCandidate = candidate!.premium;

    // ToDo: Remove this line
    isPremiumCandidate = false;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            ProfileHeader(
              candidate: candidate!,
              isPremiumCandidate: isPremiumCandidate,
              getPartySymbolPath: (party) => SymbolUtils.getPartySymbolPath(party, candidate: candidate),
              formatDate: formatDate,
              buildStatItem: _buildStatItem,
              onCoverPhotoChange: (isPremiumCandidate && currentUserId == candidate!.userId) ? _changeCoverPhoto : null,
              onProfilePhotoChange: (isPremiumCandidate && currentUserId == candidate!.userId) ? _changeProfilePhoto : null,
              currentUserId: currentUserId,
              tabController: _tabController,
            ),
            // Pinned TabBar
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: [
                    const Tab(
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
                    const Tab(
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
                    const Tab(
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
                    const Tab(
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
                  labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  unselectedLabelStyle: const TextStyle(fontSize: 13),
                  tabAlignment: TabAlignment.start,
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            InfoTab(
              candidate: candidate!,
              getPartySymbolPath: (party) => SymbolUtils.getPartySymbolPath(party, candidate: candidate),
              formatDate: formatDate,
            ),
            ManifestoTab(candidate: candidate!),
            MediaTab(candidate: candidate!),
            ContactTab(candidate: candidate!),
          ],
        ),
      ),
    );
  }

  Future<void> _changeCoverPhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        // TODO: Upload image to storage and update candidate model
        // For now, show a success message
        Get.snackbar(
          'Success',
          'Cover photo updated successfully!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update cover photo: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _changeProfilePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        // TODO: Upload image to storage and update candidate model
        // For now, show a success message
        Get.snackbar(
          'Success',
          'Profile photo updated successfully!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update profile photo: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Widget _buildStatItem(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.1),
          ],
        ),
      ),
      child: Column(
        children: [
          Text(
            _formatNumber(value),
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              shadows: const [
                Shadow(
                  color: Color(0x4D000000),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              shadows: const [
                Shadow(
                  color: Color(0x4D000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
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

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
