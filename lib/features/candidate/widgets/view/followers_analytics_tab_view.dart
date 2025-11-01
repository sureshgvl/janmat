import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/candidate_controller.dart';
import '../../models/candidate_model.dart';
import '../../repositories/candidate_repository.dart';
import '../../screens/followers_list_screen.dart';
import '../../../../utils/app_logger.dart';
import '../../services/realtime_analytics_service.dart';

class FollowersAnalyticsSection extends StatefulWidget {
  final Candidate candidateData;

  const FollowersAnalyticsSection({super.key, required this.candidateData});

  @override
  State<FollowersAnalyticsSection> createState() =>
      _FollowersAnalyticsSectionState();
}

class _FollowersAnalyticsSectionState extends State<FollowersAnalyticsSection> {
  final CandidateController controller = Get.find<CandidateController>();
  final CandidateRepository repository = CandidateRepository();
  final RealtimeAnalyticsService _analyticsService = RealtimeAnalyticsService();

  List<Map<String, dynamic>> followers = [];
  Map<String, Map<String, dynamic>?> userDataCache = {};
  bool isLoadingFollowers = true;

  // Real-time follower count
  int _realtimeFollowerCount = 0;
  late Stream<int> _followerCountStream;

  @override
  void initState() {
    super.initState();
    _initializeRealtimeFollowerCount();
    _loadFollowersData();
  }

  void _initializeRealtimeFollowerCount() {
    _followerCountStream = _analyticsService.getFollowerCountStream(widget.candidateData.candidateId);
    _followerCountStream.listen((count) {
      if (mounted) {
        setState(() => _realtimeFollowerCount = count);
      }
    });
  }

  Future<void> _loadFollowersData() async {
    try {
      setState(() {
        isLoadingFollowers = true;
      });

      followers = await controller.getCandidateFollowers(
        widget.candidateData.candidateId,
      );

      // Fetch user data for all followers
      for (var follower in followers) {
        final userId = follower['userId'] as String;
        if (!userDataCache.containsKey(userId)) {
          userDataCache[userId] = await repository.getUserData(userId);
        }
      }

      setState(() {
        isLoadingFollowers = false;
      });
    } catch (e) {
      setState(() {
        isLoadingFollowers = false;
      });
      AppLogger.candidateError('Error loading followers: $e');
    }
  }

  @override
  void dispose() {
    // Cancel real-time stream subscription
    _analyticsService.cancelSubscription('follower_count_${widget.candidateData.candidateId}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.analytics, size: 28, color: Colors.blue),
              const SizedBox(width: 12),
              const Text(
                'Followers Analytics',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Key Metrics Cards
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Total Followers',
                  value: _realtimeFollowerCount.toString(),
                  icon: Icons.people,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  title: 'Following',
                  value: widget.candidateData.followingCount.toString(),
                  icon: Icons.person_add,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Followers List Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Followers',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              TextButton(
                onPressed: () {
                  Get.to(
                    () => FollowersListScreen(
                      candidateId: widget.candidateData.candidateId,
                      candidateName: widget.candidateData.basicInfo!.fullName!,
                    ),
                  );
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Followers List
          if (isLoadingFollowers)
            const Center(child: CircularProgressIndicator())
          else if (followers.isEmpty)
            _buildEmptyState()
          else
            _buildFollowersList(),

          const SizedBox(height: 24),

          // Engagement Tips
          _buildEngagementTips(),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No followers yet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share your profile to attract followers!',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFollowersList() {
    final recentFollowers = followers.take(5).toList();

    return Column(
      children: recentFollowers.map((follower) {
        final userId = follower['userId'] as String;
        final userData = userDataCache[userId];

        // Get user display name
        final displayName = userData != null
            ? (userData['name'] as String?) ?? 'Unknown User'
            : 'Loading...';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              backgroundImage: userData != null && userData['photoURL'] != null
                  ? NetworkImage(userData['photoURL'])
                  : null,
              child: userData == null || userData['photoURL'] == null
                  ? Icon(Icons.person, color: Theme.of(context).primaryColor)
                  : null,
            ),
            title: Text(displayName),
            subtitle: Text(
              'Followed ${_formatDate(follower['followedAt'])}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            trailing: follower['notificationsEnabled'] == true
                ? Icon(Icons.notifications, size: 16, color: Colors.grey[600])
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEngagementTips() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Engagement Tips',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTipItem('Post regular updates to keep followers engaged'),
            _buildTipItem('Share your campaign activities and achievements'),
            _buildTipItem('Respond to follower questions and feedback'),
            _buildTipItem('Use polls and Q&A sessions for interaction'),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•', style: TextStyle(color: Colors.blue[700])),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(fontSize: 14, color: Colors.blue[800]),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'recently';

    DateTime date;
    if (timestamp is DateTime) {
      date = timestamp;
    } else {
      date = (timestamp as dynamic).toDate();
    }

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}

