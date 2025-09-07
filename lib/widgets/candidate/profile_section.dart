import 'package:flutter/material.dart';
import '../../models/candidate_model.dart';

class ProfileSection extends StatelessWidget {
  final Candidate candidateData;
  final Candidate? editedData;
  final bool isEditing;
  final Function(String) onBioChange;
  final Function(String) onPhotoChange;

  const ProfileSection({
    super.key,
    required this.candidateData,
    this.editedData,
    required this.isEditing,
    required this.onBioChange,
    required this.onPhotoChange,
  });

  @override
  Widget build(BuildContext context) {
    final data = editedData ?? candidateData;
    final bio = data.extraInfo?.bio ?? '';

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (isEditing)
              TextFormField(
                initialValue: bio,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: onBioChange,
              )
            else
              Text(
                bio.isNotEmpty ? bio : 'No bio available',
                style: const TextStyle(fontSize: 16),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isEditing ? () {
                // TODO: Implement photo upload
                // For now, just show a placeholder
                onPhotoChange('https://example.com/photo.jpg');
              } : null,
              child: const Text('Upload Photo'),
            ),
          ],
        ),
      ),
    );
  }
}