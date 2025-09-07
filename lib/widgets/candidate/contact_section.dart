import 'package:flutter/material.dart';
import '../../models/candidate_model.dart';

class ContactSection extends StatelessWidget {
  final Candidate candidateData;
  final Candidate? editedData;
  final bool isEditing;
  final Function(String, String) onContactChange;
  final Function(String, String) onSocialChange;

  const ContactSection({
    super.key,
    required this.candidateData,
    this.editedData,
    required this.isEditing,
    required this.onContactChange,
    required this.onSocialChange,
  });

  @override
  Widget build(BuildContext context) {
    final data = editedData ?? candidateData;
    final contact = data.extraInfo?.contact ?? data.contact;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contact Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (isEditing) ...[
              TextFormField(
                initialValue: contact.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => onContactChange('phone', value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: contact.email ?? '',
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => onContactChange('email', value),
              ),
              const SizedBox(height: 16),
              // Social links
              const Text('Social Links', style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                initialValue: contact.socialLinks?['facebook'] ?? '',
                decoration: const InputDecoration(
                  labelText: 'Facebook',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => onSocialChange('facebook', value),
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: contact.socialLinks?['twitter'] ?? '',
                decoration: const InputDecoration(
                  labelText: 'Twitter',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => onSocialChange('twitter', value),
              ),
            ] else ...[
              Text('Phone: ${contact.phone}'),
              if (contact.email != null) Text('Email: ${contact.email}'),
              if (contact.socialLinks != null)
                ...contact.socialLinks!.entries.map((e) => Text('${e.key}: ${e.value}')),
            ],
          ],
        ),
      ),
    );
  }
}