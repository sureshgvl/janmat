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
    final phone = contact is ExtendedContact
        ? contact.phone
        : (contact as Contact).phone;
    final email = contact is ExtendedContact
        ? contact.email
        : (contact as Contact).email;
    final socialLinks = contact is ExtendedContact
        ? contact.socialLinks
        : (contact as Contact).socialLinks;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contact Information',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (isEditing) ...[
              TextFormField(
                initialValue: phone,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => onContactChange('phone', value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: email ?? '',
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => onContactChange('email', value),
              ),
              const SizedBox(height: 16),
              // Social links
              const Text(
                'Social Links',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextFormField(
                initialValue: socialLinks?['facebook'] ?? '',
                decoration: const InputDecoration(
                  labelText: 'Facebook',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => onSocialChange('facebook', value),
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: socialLinks?['twitter'] ?? '',
                decoration: const InputDecoration(
                  labelText: 'Twitter',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => onSocialChange('twitter', value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: contact is ExtendedContact ? contact.officeAddress ?? '' : '',
                decoration: const InputDecoration(
                  labelText: 'Office Address',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => onContactChange('officeAddress', value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: contact is ExtendedContact ? contact.officeHours ?? '' : '',
                decoration: const InputDecoration(
                  labelText: 'Office Hours',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => onContactChange('officeHours', value),
              ),
            ] else ...[
              Text('Phone: $phone'),
              if (email != null) Text('Email: $email'),
              if (socialLinks != null)
                ...socialLinks.entries.map((e) => Text('${e.key}: ${e.value}')),
              if (contact is ExtendedContact && contact.officeAddress != null)
                Text('Office Address: ${contact.officeAddress}'),
              if (contact is ExtendedContact && contact.officeHours != null)
                Text('Office Hours: ${contact.officeHours}'),
            ],
          ],
        ),
      ),
    );
  }
}

