import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../l10n/app_localizations.dart';
import '../../models/candidate_model.dart';
import '../../controllers/candidate_controller.dart';
import '../../controllers/candidate_data_controller.dart';
import '../../widgets/candidate/info_tab.dart';
import '../../widgets/candidate/manifesto_tab.dart';
import '../../widgets/candidate/media_tab.dart';
import '../../widgets/candidate/contact_tab.dart';
import '../../widgets/candidate/profile_section.dart';
import '../../widgets/candidate/achievements_section.dart';
import '../../widgets/candidate/events_section.dart';
import '../../widgets/candidate/voter_events_section.dart';
import '../../widgets/candidate/highlight_section.dart';
import '../../widgets/candidate/followers_analytics_section.dart';
import '../../utils/symbol_utils.dart';
import '../../repositories/candidate_repository.dart';
import '../../screens/candidate/followers_list_screen.dart';

class CandidateProfileScreen extends StatefulWidget {
  const CandidateProfileScreen({super.key});

  @override
  State<CandidateProfileScreen> createState() => _CandidateProfileScreenState();
}

class _CandidateProfileScreenState extends State<CandidateProfileScreen> with TickerProviderStateMixin {
  Candidate? candidate;
  final CandidateController controller = Get.find<CandidateController>();
  final CandidateRepository candidateRepository = CandidateRepository();
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  TabController? _tabController;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();

    // Initialize TabController for performance monitoring
    _tabController = TabController(length: 9, vsync: this);
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
      final tabNames = ['Info', 'Profile', 'Achievements', 'Manifesto', 'Contact', 'Media', 'Events', 'Highlight', 'Analytics'];
      final currentTab = tabNames[_tabController!.index];

      // Only log in debug mode
      assert(() {
        debugPrint('🔄 Tab switched to: $currentTab');
        return true;
      }());
    }
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
  void _addDummyDataIfNeeded() {
    // Removed all dummy data - now showing actual Firebase data only
    // The app will display real data from Firestore or show empty states
  }


  // Format date
  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Refresh candidate data
  Future<void> _refreshCandidateData() async {
    try {
      // Refresh follow status if user is logged in
      if (currentUserId != null && candidate != null) {
        await controller.checkFollowStatus(currentUserId!, candidate!.candidateId);
      }

      // Simulate a brief delay for refresh animation
      await Future.delayed(const Duration(seconds: 1));

      Get.snackbar(
        'Success',
        'Profile data refreshed!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to refresh data: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
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
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.groups),
              label: 'Candidates',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.my_location),
              label: 'My Ward',
            ),
          ],
          currentIndex: 1, // Candidates tab is selected
          onTap: (index) {
            // Handle navigation
            switch (index) {
              case 0:
                Get.offAllNamed('/home');
                break;
              case 1:
                // Already on candidates
                break;
              case 2:
                Get.offAllNamed('/chat');
                break;
              case 3:
                Get.offAllNamed('/my-ward');
                break;
            }
          },
        ),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            // Sliver app bar that can be scrolled away
            SliverAppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              pinned: true,
              floating: false,
              expandedHeight: 280, // Height of the scrollable header
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      // Back Button and Edit Button Row
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                              onPressed: () => Navigator.of(context).pop(),
                              tooltip: 'Back',
                            ),
                            const Spacer(),
                            // Edit Party & Symbol Button (Own Profile Only)
                            if (currentUserId == candidate!.userId)
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.black),
                                onPressed: () {
                                  Navigator.of(context).pushNamed(
                                    '/change-party-symbol',
                                    arguments: candidate,
                                  );
                                },
                                tooltip: 'Edit Party & Symbol',
                              ),
                          ],
                        ),
                      ),

                      // Sponsored Ad Banner
                      if (candidate!.sponsored)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                              'Sponsored Candidate Ad',
                              style: TextStyle(
                                color: Color(0xFF374151),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                      // Profile Header Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Profile Picture
                            Stack(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: candidate!.photo != null && candidate!.photo!.isNotEmpty
                                        ? Image.network(
                                            candidate!.photo!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return CircleAvatar(
                                                backgroundColor: Colors.blue.shade100,
                                                child: Text(
                                                  candidate!.name[0].toUpperCase(),
                                                  style: const TextStyle(
                                                    color: Colors.blue,
                                                    fontSize: 32,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              );
                                            },
                                          )
                                        : CircleAvatar(
                                            backgroundColor: Colors.blue.shade100,
                                            child: Text(
                                              candidate!.name[0].toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.blue,
                                                fontSize: 32,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                                if (_isUploadingPhoto)
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black.withOpacity(0.5),
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                // Blue Tick Badge for Premium Candidates
                                if (isPremiumCandidate)
                                  Positioned(
                                    bottom: -2,
                                    right: -2,
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade600,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(
                                        Icons.verified,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 16),

                            // Profile Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    candidate!.name,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    candidate!.party,
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Ward 25, Pune', // Using placeholder for now
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Follow/Followers/Following Row
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Follow Button (hide if user.id == candidate.id)
                            if (currentUserId != candidate!.userId)
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      // TODO: Implement follow functionality
                                    },
                                    icon: const Icon(Icons.person_add, size: 16),
                                    label: const Text('Follow'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            // Followers Count (Clickable)
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  Get.to(() => FollowersListScreen(
                                    candidateId: candidate!.candidateId,
                                    candidateName: candidate!.name,
                                  ));
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Column(
                                    children: [
                                      Text(
                                        _formatNumber(candidate!.followersCount.toString()),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const Text(
                                        'Followers',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Following Count (Clickable)
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  // Debug: Log all candidate data in system
                                  try {
                                    final controller = Get.find<CandidateDataController>();
                                    await controller.logAllCandidateData();

                                    // Show detailed candidate info in a dialog
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text('Candidate Data Audit'),
                                          content: SingleChildScrollView(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text('Current Candidate: ${candidate!.name}'),
                                                Text('Party: ${candidate!.party}'),
                                                Text('ID: ${candidate!.candidateId}'),
                                                Text('User ID: ${candidate!.userId}'),
                                                Text('City: ${candidate!.cityId}'),
                                                Text('Ward: ${candidate!.wardId}'),
                                                Text('Approved: ${candidate!.approved}'),
                                                Text('Status: ${candidate!.status}'),
                                                Text('Followers: ${candidate!.followersCount}'),
                                                const SizedBox(height: 16),
                                                const Text(
                                                  '📊 System audit completed! Check console logs for full details.',
                                                  style: TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(),
                                              child: const Text('OK'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  } catch (e) {
                                    Get.snackbar(
                                      'Debug Error',
                                      'Failed to log candidate data: $e',
                                      backgroundColor: Colors.red,
                                      colorText: Colors.white,
                                    );
                                  }
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Column(
                                    children: [
                                      Text(
                                        _formatNumber(candidate!.followingCount.toString()),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const Text(
                                        'Following',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Pinned Tab Bar
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: const [
                    Tab(
                      child: Text(
                        'Info',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Tab(
                      child: Text(
                        'Profile',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Tab(
                      child: Text(
                        'Achievements',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Tab(
                      child: Text(
                        'Manifesto',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Tab(
                      child: Text(
                        'Contact',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Tab(
                      child: Text(
                        'Media',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Tab(
                      child: Text(
                        'Events',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Tab(
                      child: Text(
                        'Highlight',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Tab(
                      child: Text(
                        'Analytics',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                  indicatorColor: Colors.blue,
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.grey,
                  indicatorWeight: 2,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                  labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  unselectedLabelStyle: const TextStyle(fontSize: 14),
                  tabAlignment: TabAlignment.start,
                ),
              ),
            ),
          ];
        },
        body: RefreshIndicator(
          onRefresh: _refreshCandidateData,
          child: TabBarView(
            controller: _tabController,
            children: [
              // Info Tab
              InfoTab(
                candidate: candidate!,
                getPartySymbolPath: (party) => SymbolUtils.getPartySymbolPath(party, candidate: candidate),
                formatDate: formatDate,
              ),
              // Profile Tab (Bio section)
              ProfileSection(
                candidateData: candidate!,
                editedData: null,
                isEditing: false,
                onBioChange: (value) {},
              ),
              // Achievements Tab
              AchievementsSection(
                candidateData: candidate!,
                editedData: null,
                isEditing: false,
                onAchievementsChange: (value) {},
              ),
              // Manifesto Tab
              ManifestoTab(candidate: candidate!),
              // Contact Tab
              ContactTab(candidate: candidate!),
              // Media Tab
              MediaTab(candidate: candidate!),
              // Events Tab
              if (currentUserId == candidate!.userId)
                EventsSection(
                  candidateData: candidate!,
                  editedData: null,
                  isEditing: false,
                  onEventsChange: (value) {},
                )
              else
                VoterEventsSection(
                  candidateData: candidate!,
                ),
              // Highlight Tab
              HighlightSection(
                candidateData: candidate!,
                editedData: null,
                isEditing: false,
                onHighlightChange: (value) {},
              ),
              // Analytics Tab
              FollowersAnalyticsSection(
                candidateData: candidate!,
              ),
            ],
          ),
        ),
      ),
    );
  }


  Future<void> _changeProfilePhoto() async {
    if (candidate == null || currentUserId == null) return;

    setState(() {
      _isUploadingPhoto = true;
    });

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        // Check image file size (5MB limit)
        final file = File(image.path);
        final fileSize = await file.length();
        const maxSizeInBytes = 5 * 1024 * 1024; // 5MB

        if (fileSize > maxSizeInBytes) {
          Get.snackbar(
            AppLocalizations.of(context)!.error,
            AppLocalizations.of(context)!.imageSizeMustBeLessThan5MB,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          setState(() {
            _isUploadingPhoto = false;
          });
          return;
        }

        // Upload to Firebase Storage
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('candidate_photos')
            .child('${currentUserId}_${DateTime.now().millisecondsSinceEpoch}.jpg');

        final uploadTask = storageRef.putFile(File(image.path));
        final snapshot = await uploadTask.whenComplete(() => null);

        final downloadUrl = await snapshot.ref.getDownloadURL();

        // Update candidate with new photo URL
        final updatedCandidate = candidate!.copyWith(photo: downloadUrl);
        await candidateRepository.updateCandidateExtraInfo(updatedCandidate);

        // Update local state
        setState(() {
          candidate = updatedCandidate;
        });

        Get.snackbar(
          AppLocalizations.of(context)!.success,
          'Profile photo updated successfully!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        AppLocalizations.of(context)!.error,
        'Failed to update profile photo: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isUploadingPhoto = false;
      });
    }
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
      BuildContext context, double shrinkOffset, bool overlapsContent) {
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
