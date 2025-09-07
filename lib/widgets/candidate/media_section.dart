import 'package:flutter/material.dart';
import '../../models/candidate_model.dart';

class MediaSection extends StatelessWidget {
  final Candidate candidateData;
  final Candidate? editedData;
  final bool isEditing;
  final Function(List<String>) onImagesChange;
  final Function(List<String>) onVideosChange;

  const MediaSection({
    super.key,
    required this.candidateData,
    this.editedData,
    required this.isEditing,
    required this.onImagesChange,
    required this.onVideosChange,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Media Gallery',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Media upload functionality to be implemented'),
            if (isEditing) ...[
              ElevatedButton(
                onPressed: () => onImagesChange(['https://example.com/image1.jpg']),
                child: const Text('Add Images'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => onVideosChange(['https://example.com/video1.mp4']),
                child: const Text('Add Videos'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}