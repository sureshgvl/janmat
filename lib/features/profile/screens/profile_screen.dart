import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:janmat/utils/app_logger.dart';
import '../../../l10n/features/profile/profile_localizations.dart';
import '../../../models/user_model.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../chat/controllers/chat_controller.dart';
import '../../../services/file_upload_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoggingOut = false; // Add loading state for logout
  final FileUploadService _fileUploadService = FileUploadService();
  bool _isUploadingPhoto = false;

  void _showPhotoOptions(BuildContext context, UserModel userModel) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: Text(ProfileLocalizations.of(context)?.translate('uploadPhoto') ?? 'Upload Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _uploadProfilePhoto(context);
                },
              ),
              if (userModel.photoURL != null) ...[
                ListTile(
                  leading: const Icon(Icons.remove_circle_outline),
                  title: Text(ProfileLocalizations.of(context)?.translate('removePhoto') ?? 'Remove Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _showRemovePhotoConfirmation(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.visibility),
                  title: Text(ProfileLocalizations.of(context)?.translate('viewPhoto') ?? 'View Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _viewProfilePhoto(context, userModel.photoURL!);
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.cancel),
                title: Text(ProfileLocalizations.of(context)?.translate('cancel') ?? 'Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _uploadProfilePhoto(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    setState(() {
      _isUploadingPhoto = true;
    });

    try {
      final downloadUrl = await _fileUploadService.uploadProfilePhoto(
        currentUser.uid,
      );

      if (downloadUrl != null) {
        // Update the user's photoURL in Firebase Auth
        await currentUser.updatePhotoURL(downloadUrl);

        // Update the photoURL in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({'photoURL': downloadUrl});

        // Refresh the chat controller to update the user data
        final chatController = Get.find<ChatController>();
        await chatController.refreshUserDataAndChat();

        Get.snackbar(
          ProfileLocalizations.of(context)?.translate('success') ?? 'Success',
          ProfileLocalizations.of(context)?.translate('profilePhotoUpdatedSuccessfully') ?? 'Profile photo updated successfully!',
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      Get.snackbar(
        ProfileLocalizations.of(context)?.translate('error') ?? 'Error',
        ProfileLocalizations.of(context)?.translate('failedToUpdateProfilePhoto', args: {'error': e.toString()}) ?? 'Failed to update profile photo: $e',
        duration: const Duration(seconds: 3),
      );
    } finally {
      setState(() {
        _isUploadingPhoto = false;
      });
    }
  }

  void _showRemovePhotoConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(ProfileLocalizations.of(context)?.translate('removePhoto') ?? 'Remove Photo'),
          content: Text(ProfileLocalizations.of(context)?.translate('removePhotoConfirmation') ?? 'Are you sure you want to remove your profile photo?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(ProfileLocalizations.of(context)?.translate('cancel') ?? 'Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _removeProfilePhoto(context);
              },
              child: Text(
                ProfileLocalizations.of(context)?.translate('remove') ?? 'Remove',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _removeProfilePhoto(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    setState(() {
      _isUploadingPhoto = true;
    });

    try {
      // Update the user's photoURL in Firebase Auth to null
      await currentUser.updatePhotoURL(null);

      // Update the photoURL in Firestore to null
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({'photoURL': null});

      // Refresh the chat controller to update the user data
      final chatController = Get.find<ChatController>();
      await chatController.refreshUserDataAndChat();

      Get.snackbar(
        ProfileLocalizations.of(context)?.translate('success') ?? 'Success',
        ProfileLocalizations.of(context)?.translate('profilePhotoRemovedSuccessfully') ?? 'Profile photo removed successfully!',
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        ProfileLocalizations.of(context)?.translate('error') ?? 'Error',
        ProfileLocalizations.of(context)?.translate('failedToRemoveProfilePhoto', args: {'error': e.toString()}) ?? 'Failed to remove profile photo: $e',
        duration: const Duration(seconds: 3),
      );
    } finally {
      setState(() {
        _isUploadingPhoto = false;
      });
    }
  }

  void _viewProfilePhoto(BuildContext context, String photoUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(ProfileLocalizations.of(context)?.translate('profilePhoto') ?? 'Profile Photo'),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              InteractiveViewer(
                child: Image.network(photoUrl),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(ProfileLocalizations.of(context)?.translate('profile') ?? 'Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Force refresh user data
              final chatController = Get.find<ChatController>();
              chatController.refreshUserDataAndChat();
            },
          ),
        ],
      ),
      body: GetBuilder<ChatController>(
        builder: (chatController) {
          // Try to get user from ChatController first (reactive)
          UserModel? userModel = chatController.currentUser;

          // If no cached user, show loading and fetch
          if (userModel == null) {
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      '${ProfileLocalizations.of(context)?.translate('error') ?? 'Error'}: ${snapshot.error}',
                    ),
                  );
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Center(
                    child: Text(ProfileLocalizations.of(context)?.translate('userDataNotFound') ?? 'User data not found'),
                  );
                }

                final userData = snapshot.data!.data() as Map<String, dynamic>;
                userModel = UserModel.fromJson(userData);
                return _buildProfileContent(context, userModel!);
              },
            );
          }

          // Use reactive user data from ChatController
          return _buildProfileContent(context, userModel);
        },
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, UserModel userModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Avatar and user info
          Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 64,
                      backgroundColor: Colors.blue,
                      backgroundImage: userModel.photoURL != null
                          ? NetworkImage(userModel.photoURL!)
                          : null,
                      child: userModel.photoURL == null
                          ? Text(
                              (userModel.name.isEmpty ? 'U' : userModel.name[0])
                                  .toUpperCase(),
                              style: const TextStyle(
                                fontSize: 40,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _isUploadingPhoto
                            ? null
                            : () => _showPhotoOptions(context, userModel),
                        child: Container(
                          height: 32,
                          width: 32,
                          decoration: BoxDecoration(
                            color: _isUploadingPhoto
                                ? Colors.grey
                                : Colors.orange,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: _isUploadingPhoto
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 20,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  userModel.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userModel.email ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Account Details Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        ProfileLocalizations.of(context)?.translate('accountDetails') ?? 'Account Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      if (userModel.premium)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Color(0xFFF97316),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                ProfileLocalizations.of(context)?.translate('premium') ?? 'Premium',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFF97316),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.7,
                    children: [
                      _buildDetailItem(
                        context: context,
                        icon: Icons.phone,
                        label: ProfileLocalizations.of(context)?.translate('phoneNumber') ?? 'Phone Number',
                        value: userModel.phone,
                        iconColor: Colors.blue,
                      ),
                      _buildDetailItem(
                        context: context,
                        icon: Icons.star,
                        label: ProfileLocalizations.of(context)?.translate('xpPoints') ?? 'XP Points',
                        value: userModel.xpPoints.toString(),
                        iconColor: Colors.blue,
                      ),
                      _buildDetailItem(
                        context: context,
                        icon: Icons.email,
                        label: ProfileLocalizations.of(context)?.translate('email') ?? 'Email',
                        value: userModel.email ?? '',
                        iconColor: Colors.blue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Log Out Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoggingOut
                  ? null
                  : () async {
                      AppLogger.common('🔘 Profile logout button pressed');
                      setState(() => _isLoggingOut = true);

                      try {
                        final authRepository = AuthRepository();
                        await authRepository.signOut();

                        // Reset login controller state (if available)
                        try {
                          if (Get.isRegistered<AuthController>()) {
                            final loginController = Get.find<AuthController>();
                            loginController.phoneController.clear();
                            loginController.otpController.clear();
                            loginController.isOTPScreen.value = false;
                            loginController.verificationId.value = '';
                          } else {
                            AppLogger.common(
                              'ℹ️ Login controller not available - skipping state reset',
                            );
                          }
                        } catch (e) {
                          AppLogger.error('⚠️ Could not reset login controller: $e');
                        }

                        Get.offAllNamed('/login');
                      } catch (e) {
                        Get.snackbar(
                          ProfileLocalizations.of(context)?.translate('error') ?? 'Error',
                          ProfileLocalizations.of(context)?.translate('failedToLogout', args: {'error': e.toString()}) ?? 'Failed to logout: $e',
                        );
                      } finally {
                        if (mounted) {
                          setState(() => _isLoggingOut = false);
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _isLoggingOut
                    ? Colors.grey
                    : const Color(0xFFFEE2E2),
                foregroundColor: _isLoggingOut
                    ? Colors.white
                    : const Color(0xFFDC2626),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoggingOut
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(ProfileLocalizations.of(context)?.translate('loggingOut') ?? 'Logging out...'),
                      ],
                    )
                  : Text(
                      ProfileLocalizations.of(context)?.translate('logOut') ?? 'Log Out',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
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

