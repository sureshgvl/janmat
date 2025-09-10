import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../l10n/app_localizations.dart';
import '../../controllers/login_controller.dart';
import '../../controllers/chat_controller.dart';
import '../../models/user_model.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  final loginController = Get.find<LoginController>();
  final chatController = Get.find<ChatController>();
  String? selectedRole;
  bool isLoading = false;

  Future<void> _saveRole() async {
    final localizations = AppLocalizations.of(context)!;

    if (selectedRole == null) {
      Get.snackbar(localizations.error, localizations.pleaseSelectARoleToContinue);
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Update user role in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({
            'role': selectedRole,
            'roleSelected': true,
          });

      // After role selection, navigate to profile completion
      if (selectedRole == 'candidate') {
        Get.offAllNamed('/profile-completion');
        Get.snackbar(
          localizations.roleSelected,
          localizations.youSelectedCandidatePleaseCompleteYourProfile,
          duration: const Duration(seconds: 3),
        );
      } else {
        // For voter role, go to profile completion
        Get.offAllNamed('/profile-completion');
        Get.snackbar(
          localizations.roleSelected,
          localizations.youSelectedVoterPleaseCompleteYourProfile,
          duration: const Duration(seconds: 3),
        );
      }

    } catch (e) {
      Get.snackbar(localizations.error, localizations.failedToSaveRole(e.toString()));
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    final List<Map<String, dynamic>> roles = [
      {
        'id': 'voter',
        'title': localizations.voter,
        'subtitle': localizations.stayInformedAndParticipateInDiscussions,
        'description': localizations.accessWardDiscussionsPollsAndCommunityUpdates,
        'icon': Icons.how_to_vote,
        'color': Colors.blue,
      },
      {
        'id': 'candidate',
        'title': localizations.candidate,
        'subtitle': localizations.runForOfficeAndConnectWithVoters,
        'description': localizations.createYourProfileShareManifestoAndEngageWithCommunity,
        'icon': Icons.account_balance,
        'color': Colors.green,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.chooseYourRole),
        automaticallyImplyLeading: false, // Prevent back button
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                localizations.howWouldYouLikeToParticipate,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                localizations.selectYourRoleToCustomizeExperience,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 32),

              // Role Selection Cards
              Expanded(
                child: ListView.builder(
                  itemCount: roles.length,
                  itemBuilder: (context, index) {
                    final role = roles[index];
                    final isSelected = selectedRole == role['id'];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: isSelected ? 8 : 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isSelected ? role['color'] : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            selectedRole = role['id'];
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              // Icon
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: role['color'].withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  role['icon'],
                                  color: role['color'],
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      role['title'],
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? role['color'] : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      role['subtitle'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      role['description'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Selection Indicator
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: role['color'],
                                  size: 28,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _saveRole,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedRole != null ? Colors.blue : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                             localizations.continueButton,
                             style: TextStyle(
                               fontSize: 16,
                               fontWeight: FontWeight.bold,
                             ),
                           ),
                ),
              ),

              const SizedBox(height: 16),

              // Info Text
              Center(
                child: Text(
                  localizations.youCanChangeYourRoleLaterInSettings,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}