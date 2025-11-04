import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:janmat/features/user/models/user_model.dart';
import '../controllers/candidate_controller.dart';
import '../repositories/candidate_repository.dart';
import '../models/candidate_model.dart';
import '../widgets/follower_card.dart';

class FollowingListScreen extends StatefulWidget {
  final String candidateId;
  final String candidateName;
  final Candidate? candidateData;

  const FollowingListScreen({
    super.key,
    required this.candidateId,
    required this.candidateName,
    this.candidateData,
  });

  @override
  State<FollowingListScreen> createState() => _FollowingListScreenState();
}

class _FollowingListScreenState extends State<FollowingListScreen> {
  final CandidateController controller = Get.find<CandidateController>();
  final CandidateRepository repository = CandidateRepository();
  List<Map<String, dynamic>> following = [];
  Map<String, UserModel?> userDataCache = {};
  bool isLoading = true;
  String? errorMessage;
  bool _isLoadingLong = false;

  @override
  void initState() {
    super.initState();
    _loadFollowing();

    // Show "taking longer" message after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && isLoading) {
        setState(() {
          _isLoadingLong = true;
        });
      }
    });
  }

  @override
  void dispose() {
    // Cancel any ongoing operations
    super.dispose();
  }

  Future<void> _loadFollowing() async {
    try {
      if (!mounted) return;

      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Get the user ID for the candidate
      final candidateUserId = widget.candidateData?.userId ?? widget.candidateId;

      // Add timeout to prevent infinite loading
      final followingFuture = controller.getUserFollowing(candidateUserId);
      final followingData = await followingFuture.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Loading following list timed out. Please try again.');
        },
      );

      // Use the full following data directly (already contains userId, followedAt, notificationsEnabled)
      following = followingData;

      // Fetch candidate data for all following with timeout
      for (var follow in following) {
        if (!mounted) return; // Check if still mounted before continuing

        final userId = follow['userId'] as String;
        if (!userDataCache.containsKey(userId)) {
          try {
            // Add timeout to prevent hanging
            final candidateDataFuture = repository.getCandidateData(userId);
            final candidateData = await candidateDataFuture.timeout(
              const Duration(seconds: 5),
              onTimeout: () => null,
            );

            // Convert candidate data to UserModel format for FollowerCard
            if (candidateData != null) {
              userDataCache[userId] = UserModel(
                uid: candidateData.userId ?? userId,
                name: candidateData.basicInfo?.fullName ?? 'Unknown Candidate',
                phone: '', // Not available in candidate data
                email: null, // Not available in candidate data
                role: 'candidate',
                roleSelected: true,
                profileCompleted: true,
                xpPoints: 0,
                premium: false,
                createdAt: DateTime.now(),
                photoURL: candidateData.basicInfo?.photo,
                followingCount: 0,
              );
            } else {
              userDataCache[userId] = null;
            }
          } catch (e) {
            // If candidate data fetch fails, continue with null
            userDataCache[userId] = null;
          }
        }
      }

      if (mounted) {
        setState(() {
          isLoading = false;
          _isLoadingLong = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          _isLoadingLong = false;
          errorMessage = 'Failed to load following list: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.candidateName} Following'),
        elevation: 0,
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    _isLoadingLong
                        ? 'Loading is taking longer than expected...'
                        : 'Loading following list...',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  if (_isLoadingLong) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          isLoading = false;
                          errorMessage = 'Loading timed out. Please try again.';
                        });
                      },
                      child: const Text('Cancel'),
                    ),
                  ],
                ],
              ),
            )
          : errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadFollowing,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : following.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Not following anyone yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.candidateName} hasn\'t followed any candidates yet.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadFollowing,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: following.length,
                itemBuilder: (context, index) {
                  final follow = following[index];
                  final userId = follow['userId'] as String;
                  final userData = userDataCache[userId];

                  return FollowerCard(
                    follower: follow,
                    userData: userData,
                  );
                },
              ),
            ),
    );
  }
}
