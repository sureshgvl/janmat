import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../candidate/models/candidate_model.dart';
import '../services/community_feed_service.dart';
import '../services/push_feed_service.dart';
import '../models/post_model.dart';

class FeedWidgets {
  final CommunityFeedService _communityFeedService = CommunityFeedService();
  final PushFeedService _pushFeedService = PushFeedService();

  // Push Feed Section Widget
  Widget buildPushFeedSection(
    BuildContext context,
    UserModel? userModel,
    Candidate? candidateModel,
    Map<String, String> locationData,
    Function(BuildContext, {bool isSponsored}) showCreatePostDialog,
  ) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadPushFeedData(locationData),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const SizedBox.shrink(); // Hide section on error
        }

        final pushFeedItems = snapshot.data ?? [];

        if (pushFeedItems.isEmpty) {
          return const SizedBox.shrink(); // Hide section if no data
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.campaign, color: Colors.orange, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sponsored Updates',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                if (userModel?.role == 'candidate') ...[
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.orange),
                    onPressed: () => showCreatePostDialog(context, isSponsored: true),
                    tooltip: 'Create Sponsored Update',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            ...pushFeedItems.map(
              (item) => Column(
                children: [
                  _buildPushFeedCard(
                    context,
                    title: item['title'] ?? '',
                    message: item['message'] ?? '',
                    imageUrl: item['imageUrl'],
                    isSponsored: item['isSponsored'] ?? true,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  // Normal Feed Section Widget
  Widget buildNormalFeedSection(
    BuildContext context,
    Map<String, String> locationData,
    Function(BuildContext, {bool isSponsored}) showCreatePostDialog,
  ) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadNormalFeedData(locationData),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const SizedBox.shrink(); // Hide section on error
        }

        final feedItems = snapshot.data ?? [];

        if (feedItems.isEmpty) {
          return const SizedBox.shrink(); // Hide section if no data
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.article, color: Colors.blue, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Community Feed',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.blue),
                  onPressed: () => showCreatePostDialog(context, isSponsored: false),
                  tooltip: 'Create Community Post',
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...feedItems.map(
              (item) => Column(
                children: [
                  _buildNormalFeedCard(
                    context,
                    author: item['author'] ?? '',
                    content: item['content'] ?? '',
                    timestamp: item['timestamp'] ?? '',
                    likes: item['likes'] ?? 0,
                    comments: item['comments'] ?? 0,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  // Push Feed Card Widget
  Widget _buildPushFeedCard(
    BuildContext context, {
    required String title,
    required String message,
    String? imageUrl,
    required bool isSponsored,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1976d2).withValues(alpha: 0.05), // Light blue background
        borderRadius: BorderRadius.circular(20), // More rounded
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Profile photo
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                backgroundColor: Colors.grey[100],
                child: imageUrl == null
                    ? const Icon(Icons.person, color: Colors.grey, size: 24)
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Read Now Button
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF138808), // Green color
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'Read Now',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Normal Feed Card Widget
  Widget _buildNormalFeedCard(
    BuildContext context, {
    required String author,
    required String content,
    required String timestamp,
    required int likes,
    required int comments,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // More rounded
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Author info and content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author info
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade200, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.grey[100],
                        child: const Icon(Icons.person, color: Colors.grey, size: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            author,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1f2937),
                            ),
                          ),
                          Text(
                            timestamp,
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Content
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF374151),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          // Bottom section with View Profile button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976d2), // Primary blue
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text('View Profile'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for data loading
  Future<List<Map<String, dynamic>>> _loadPushFeedData(Map<String, String> locationData) async {
    try {
      // Fetch actual sponsored updates from Firestore
      final sponsoredUpdates = await _pushFeedService.getPushFeedForWard(
        locationData['districtId']!,
        locationData['bodyId']!,
        locationData['wardId']!,
      );

      // Convert SponsoredUpdate objects to the expected Map format
      return sponsoredUpdates
          .map(
            (update) => {
              'title': update.title,
              'message': update.message,
              'imageUrl': update.imageUrl,
              'isSponsored': true,
              'authorName': update.authorName,
              'timestamp': update.timestamp,
            },
          )
          .toList();
    } catch (e) {
      debugPrint('Error loading push feed data: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadNormalFeedData(Map<String, String> locationData) async {
    try {
      // Fetch actual community posts from Firestore
      final communityPosts = await _communityFeedService
          .getCommunityFeedForWard(
            locationData['districtId']!,
            locationData['bodyId']!,
            locationData['wardId']!,
          );

      // Convert CommunityPost objects to the expected Map format
      return communityPosts
          .map(
            (post) => {
              'author': post.authorName,
              'content': post.content,
              'timestamp': _formatTimestamp(post.timestamp),
              'likes': post.likes,
              'comments': post.comments,
              'postId': post.id,
              'authorId': post.authorId,
            },
          )
          .toList();
    } catch (e) {
      debugPrint('Error loading normal feed data: $e');
      return [];
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}

