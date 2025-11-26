import 'package:flutter/material.dart';
import 'package:janmat/features/candidate/models/candidate_model.dart';
import 'package:janmat/features/candidate/models/media_model.dart';
import 'media_content.dart';

// Facebook-style media post card
class FacebookStylePostCard extends StatefulWidget {
  final MediaItem item;
  final Candidate candidate;
  final bool isOwnProfile;
  final Function(MediaItem) onEdit;
  final Function(MediaItem) onDelete;
  final Function(List<String>, int) onImageTap;
  final Function(MediaItem)? onItemUpdated;

  const FacebookStylePostCard({
    super.key,
    required this.item,
    required this.candidate,
    this.isOwnProfile = false,
    required this.onEdit,
    required this.onDelete,
    required this.onImageTap,
    this.onItemUpdated,
  });

  @override
  State<FacebookStylePostCard> createState() => _FacebookStylePostCardState();
}

class _FacebookStylePostCardState extends State<FacebookStylePostCard> {

  @override
  Widget build(BuildContext context) {
    // Create a stable unique key for this post card to prevent UI issues
    final postKey = '${widget.item.title}_${widget.item.date}';

    return Container(
      key: ValueKey(postKey),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Profile Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue.shade100,
                  child:
                      widget.candidate.basicInfo!.photo != null &&
                          widget.candidate.basicInfo!.photo!.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            widget.candidate.basicInfo!.photo!,
                            fit: BoxFit.cover,
                            width: 40,
                            height: 40,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.person,
                              color: Colors.blue.shade600,
                              size: 20,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.person,
                          color: Colors.blue.shade600,
                          size: 20,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.candidate.basicInfo!.fullName ?? 'Candidate',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1f2937),
                        ),
                      ),
                      Text(
                        _formatDate(widget.item.date),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // 3-dot menu for edit/delete (only for own profile)
                if (widget.isOwnProfile) ...[
                  PopupMenuButton<String>(
                    key: ValueKey('menu_$postKey'),
                    onSelected: (value) {
                      // Use a post-frame callback to avoid UI conflicts
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (value == 'edit') {
                          widget.onEdit(widget.item);
                        } else if (value == 'delete') {
                          widget.onDelete(widget.item);
                        }
                      });
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                    icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),

          // Post Title
          if (widget.item.title.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                widget.item.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1f2937),
                ),
              ),
            ),
          ],

          // Media Content
          if (widget.item.images.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: FacebookStyleImageLayout(
                images: widget.item.images,
                onImageTap: widget.onImageTap,
              ),
            ),
          ],

          // Videos
          if (widget.item.videos.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: VideoContentWidget(item: widget.item),
            ),
          ],

          // YouTube Links
          if (widget.item.youtubeLinks.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: YouTubeContentWidget(item: widget.item),
            ),
          ],

        ],
      ),
    );
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return '';
    try {
      // Assuming the date is in YYYY-MM-DD format, convert to DD/MM/YYYY
      final parts = date.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
      return date;
    } catch (e) {
      return date;
    }
  }

}