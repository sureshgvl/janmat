import 'package:flutter/material.dart';
import 'package:janmat/features/candidate/models/candidate_model.dart';

// Facebook-style "What's on your mind?" post composer
class FacebookStylePostComposer extends StatelessWidget {
  final Candidate candidate;
  final VoidCallback onTap;

  const FacebookStylePostComposer({
    super.key,
    required this.candidate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Profile avatar placeholder
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue.shade100,
                  child:
                      candidate.basicInfo!.photo != null &&
                          candidate.basicInfo!.photo!.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            candidate.basicInfo!.photo!,
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
                  child: GestureDetector(
                    onTap: onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        "What's on your mind?",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Photo/Video button
                Expanded(
                  child: TextButton.icon(
                    onPressed: onTap,
                    icon: Icon(Icons.photo_library, color: Colors.green),
                    label: Text(
                      'Photo/Video',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                Container(width: 1, height: 24, color: Colors.grey.shade300),
                // YouTube button
                Expanded(
                  child: TextButton.icon(
                    onPressed: onTap,
                    icon: Icon(Icons.video_call, color: Colors.red),
                    label: Text(
                      'YouTube',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}