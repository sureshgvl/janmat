import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:janmat/features/candidate/controllers/contact_controller.dart';
import 'package:janmat/features/candidate/models/candidate_model.dart';
import 'package:janmat/features/candidate/models/contact_model.dart';
import 'package:janmat/features/user/services/user_data_service.dart';
import 'package:janmat/utils/app_logger.dart';
import 'package:janmat/utils/snackbar_utils.dart';


class ContactSection extends StatefulWidget {
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
  State<ContactSection> createState() => _ContactSectionState();
}

class _ContactSectionState extends State<ContactSection> {
  final ContactController _contactController = Get.find<ContactController>();
  String _loginMethod = 'unknown';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _detectLoginMethod();
  }

  Future<void> _detectLoginMethod() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Check provider data
        bool hasGoogleProvider = user.providerData
            .any((info) => info.providerId == 'google.com');
        bool hasPhoneProvider = user.providerData
            .any((info) => info.providerId == 'phone');

        setState(() {
          if (hasGoogleProvider) {
            _loginMethod = 'google';
          } else if (hasPhoneProvider) {
            _loginMethod = 'phone';
          } else {
            _loginMethod = 'unknown';
          }
        });
      } else {
        setState(() {
          _loginMethod = 'unknown';
        });
      }
    } catch (e) {
      setState(() {
        _loginMethod = 'unknown';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.editedData ?? widget.candidateData;
    final contact = data.contact;
    final socialLinks = (contact as ContactModel?)?.socialLinks;

    // Get current user data from UserDataService
    final userDataService = Get.find<UserDataService>();
    final currentUser = userDataService.currentUser.value;

    // Use phone and email from user data for view mode
    final phone = currentUser?.phone;
    final email = currentUser?.email;

    final card = Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          80,
        ), // Added 80px bottom padding to prevent content from being hidden behind floating action buttons
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contact Information',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (widget.isEditing) ...[
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
                      currentUser?.phone ?? 'Not provided',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showPhoneChangeDialog(context, currentUser?.phone),
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
              // Email (conditionally editable based on login method)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _loginMethod == 'google' ? Colors.grey.shade100 : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _loginMethod == 'google' ? Colors.grey.shade300 : Colors.blue.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.email,
                          color: _loginMethod == 'google' ? Colors.grey : Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Email Address',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _loginMethod == 'google' ? Colors.grey : Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_loginMethod == 'google') ...[
                      Text(
                        currentUser?.email ?? 'Not provided',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Email is managed by Google and cannot be changed',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ] else ...[
                      TextFormField(
                        initialValue: email ?? '',
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onChanged: (value) => widget.onContactChange('email', value),
                      ),
                    ],
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
                onChanged: (value) => widget.onSocialChange('facebook', value),
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: socialLinks?['twitter'] ?? '',
                decoration: const InputDecoration(
                  labelText: 'Twitter',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => widget.onSocialChange('twitter', value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: '',
                decoration: const InputDecoration(
                  labelText: 'Office Address',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => widget.onContactChange('officeAddress', value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: '',
                decoration: const InputDecoration(
                  labelText: 'Office Hours',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => widget.onContactChange('officeHours', value),
              ),
            ] else ...[
              // Display phone and email from user data
              if (phone != null && phone.isNotEmpty) Text('Phone: $phone'),
              if (email != null && email.isNotEmpty) Text('Email: $email'),
              if (socialLinks != null)
                ...socialLinks.entries.map((e) => Text('${e.key}: ${e.value}')),
              // Office address and hours are not displayed in view mode for now
            ],
          ],
        ),
      ),
    );

    // Add Save and Cancel buttons at the bottom
    return Stack(
      children: [
        card,
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveContact,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Saving...' : 'Save Contact'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
                              SnackbarUtils.showScaffoldInfo(context, 'OTP sent again');
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
                      SnackbarUtils.showScaffoldInfo(context, 'OTP sent to ${newPhoneController.text}');
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
                        try {
                          // Update profile data first
                          widget.onContactChange('phone', newPhoneController.text);

                          // Update user data in UserDataService
                          final userDataService = Get.find<UserDataService>();
                          await userDataService.updateUserData({
                            'phone': newPhoneController.text,
                          });

                          // If user logged in with phone, update Firebase Auth
                          if (_loginMethod == 'phone') {
                            User? user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              // Update Firebase Auth phone number
                              await user.updatePhoneNumber(
                                PhoneAuthProvider.credential(
                                  verificationId: 'demo_verification_id', // In real app, this would come from phone verification
                                  smsCode: otpController.text,
                                ),
                              );
                              AppLogger.candidate('Firebase Auth phone number updated successfully');
                            }
                          }

                          Navigator.of(dialogContext).pop();
                          SnackbarUtils.showScaffoldSuccess(context, _loginMethod == 'phone'
                            ? 'Phone number and authentication updated successfully'
                            : 'Phone number updated successfully');
                        } catch (authError) {
                          AppLogger.candidateError('Failed to update Firebase Auth: $authError');
                          // Still allow profile update even if auth update fails
                          SnackbarUtils.showScaffoldWarning(context, 'Phone number updated, but authentication sync failed');
                          Navigator.of(dialogContext).pop();
                        }
                      } else {
                        SnackbarUtils.showScaffoldError(context, 'Invalid OTP. Please try again.');
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

  Future<void> _saveContact() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final data = widget.editedData ?? widget.candidateData;

      // Create ContactModel from current form data
      final contact = ContactModel(
        phone: data.contact.phone,
        email: data.contact.email,
        address: data.contact.address,
        socialLinks: data.contact.socialLinks ?? {},
        officeAddress: data.contact.officeAddress,
        officeHours: data.contact.officeHours,
      );

      // Save using the controller
      final success = await _contactController.saveContactTab(
        candidate: data,
        contact: contact,
        candidateName: data.basicInfo!.fullName,
        photoUrl: data.photo,
        onProgress: (message) {
          SnackbarUtils.showScaffoldInfo(context, message);
        },
      );

      if (success) {
        SnackbarUtils.showScaffoldSuccess(context, 'Contact information saved successfully!');
        Navigator.of(context).pop();
      } else {
        SnackbarUtils.showScaffoldError(context, 'Failed to save contact information');
      }
    } catch (e) {
      SnackbarUtils.showScaffoldError(context, 'Error saving contact information: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
}
