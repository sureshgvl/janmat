import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controllers/candidate_controller.dart';
import '../../models/candidate_model.dart';
import '../../repositories/candidate_repository.dart';

class FollowersListScreen extends StatefulWidget {
  final String candidateId;
  final String candidateName;

  const FollowersListScreen({
    Key? key,
    required this.candidateId,
    required this.candidateName,
  }) : super(key: key);

  @override
  State<FollowersListScreen> createState() => _FollowersListScreenState();
}

class _FollowersListScreenState extends State<FollowersListScreen> {
  final CandidateController controller = Get.find<CandidateController>();
  final CandidateRepository repository = CandidateRepository();
  List<Map<String, dynamic>> followers = [];
  Map<String, Map<String, dynamic>?> userDataCache = {};
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFollowers();
  }

  Future<void> _loadFollowers() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      followers = await controller.getCandidateFollowers(widget.candidateId);

      // Fetch user data for all followers
      for (var follower in followers) {
        final userId = follower['userId'] as String;
        if (!userDataCache.containsKey(userId)) {
          userDataCache[userId] = await repository.getUserData(userId);
        }
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load followers: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.candidateName} Followers'),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
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
                        onPressed: _loadFollowers,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : followers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No followers yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Be the first to follow ${widget.candidateName}!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadFollowers,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: followers.length,
                        itemBuilder: (context, index) {
                          final follower = followers[index];
                          final userId = follower['userId'] as String;
                          final userData = userDataCache[userId];
                          final followedAt = follower['followedAt'] as Timestamp?;
                          final notificationsEnabled = follower['notificationsEnabled'] as bool? ?? true;

                          // Get user display name
                          final displayName = userData != null
                              ? (userData['name'] as String?) ?? 'Unknown User'
                              : 'Loading...';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                backgroundImage: userData != null && userData['photoURL'] != null
                                    ? NetworkImage(userData['photoURL'])
                                    : null,
                                child: userData == null || userData['photoURL'] == null
                                    ? Icon(
                                        Icons.person,
                                        color: Theme.of(context).primaryColor,
                                      )
                                    : null,
                              ),
                              title: Text(
                                displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (followedAt != null)
                                    Text(
                                      'Followed ${_formatDate(followedAt.toDate())}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  if (notificationsEnabled)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.notifications,
                                          size: 14,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Notifications enabled',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Follower',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    }
  }
}