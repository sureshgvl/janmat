import 'package:flutter/material.dart';
import '../../models/candidate_model.dart';

class ManifestoSection extends StatelessWidget {
  final Candidate candidateData;
  final Candidate? editedData;
  final bool isEditing;
  final Function(String) onManifestoChange;
  final Function(String) onManifestoPdfChange;

  const ManifestoSection({
    super.key,
    required this.candidateData,
    this.editedData,
    required this.isEditing,
    required this.onManifestoChange,
    required this.onManifestoPdfChange,
  });

  @override
  Widget build(BuildContext context) {
    final data = editedData ?? candidateData;
    final manifesto = data.extraInfo?.manifesto ?? '';

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manifesto',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (isEditing)
              TextFormField(
                initialValue: manifesto,
                decoration: const InputDecoration(
                  labelText: 'Manifesto',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                onChanged: onManifestoChange,
              )
            else
              Text(
                manifesto.isNotEmpty ? manifesto : 'No manifesto available',
                style: const TextStyle(fontSize: 16),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isEditing ? () {
                // TODO: Implement PDF upload
                onManifestoPdfChange('https://example.com/manifesto.pdf');
              } : null,
              child: const Text('Upload Manifesto PDF'),
            ),
          ],
        ),
      ),
    );
  }
}