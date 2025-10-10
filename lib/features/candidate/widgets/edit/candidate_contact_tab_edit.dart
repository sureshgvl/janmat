import 'package:flutter/material.dart';
import '../../models/candidate_model.dart';
import 'package:get/get.dart';

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
              // Phone number with OTP verification
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.phone, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text(
                          'Phone Number',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      phone ?? 'Not provided',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showPhoneChangeDialog(context, phone),
                        icon: const Icon(Icons.edit),
                        label: const Text('Change Phone Number'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Email (read-only)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.email, color: Colors.grey),
                        const SizedBox(width: 8),
                        const Text(
                          'Email Address',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      email ?? 'Not provided',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Email cannot be changed',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
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

  void _showPhoneChangeDialog(BuildContext context, String? currentPhone) {
    final TextEditingController newPhoneController = TextEditingController();
    final TextEditingController otpController = TextEditingController();
    bool otpSent = false;
    bool isVerifying = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Change Phone Number'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enter your new phone number. You will receive an OTP for verification.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: newPhoneController,
                      decoration: const InputDecoration(
                        labelText: 'New Phone Number',
                        hintText: '+91xxxxxxxxxx',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      enabled: !otpSent,
                    ),
                    if (otpSent) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: otpController,
                        decoration: const InputDecoration(
                          labelText: 'Enter OTP',
                          hintText: '6-digit code',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          TextButton(
                            onPressed: isVerifying ? null : () {
                              // Resend OTP logic
                              setState(() => otpSent = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('OTP sent again')),
                              );
                            },
                            child: const Text('Resend OTP'),
                          ),
                          const Spacer(),
                          Text(
                            'OTP sent to ${newPhoneController.text}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                if (!otpSent)
                  ElevatedButton(
                    onPressed: newPhoneController.text.isEmpty ? null : () {
                      // Send OTP logic (simulated)
                      setState(() => otpSent = true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('OTP sent to ${newPhoneController.text}')),
                      );
                    },
                    child: const Text('Send OTP'),
                  )
                else
                  ElevatedButton(
                    onPressed: isVerifying || otpController.text.length != 6 ? null : () async {
                      setState(() => isVerifying = true);

                      // Simulate OTP verification
                      await Future.delayed(const Duration(seconds: 2));

                      if (otpController.text == '123456') { // Demo OTP
                        // Update phone number
                        onContactChange('phone', newPhoneController.text);
                        Navigator.of(dialogContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Phone number updated successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Invalid OTP. Please try again.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        setState(() => isVerifying = false);
                      }
                    },
                    child: isVerifying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Verify & Update'),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

