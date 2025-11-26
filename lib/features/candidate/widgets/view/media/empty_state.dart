import 'package:flutter/material.dart';

// Empty state widget for when there are no media posts
class MediaEmptyState extends StatelessWidget {
  final bool isOwnProfile;

  const MediaEmptyState({
    super.key,
    required this.isOwnProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            isOwnProfile
                ? 'No posts yet'
                : 'No media available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isOwnProfile
                ? 'Tap above to create your first post!'
                : 'Photos and videos will appear here',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}