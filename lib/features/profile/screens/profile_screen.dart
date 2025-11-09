import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:janmat/features/user/models/user_model.dart';
import 'package:janmat/utils/app_logger.dart';
import 'package:janmat/utils/snackbar_utils.dart';
import '../../../l10n/features/profile/profile_localizations.dart';
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
  bool _isLoggingOut = false;
  final FileUploadService _fileUploadService = FileUploadService();
  bool _isUploadingPhoto = false;

  void _showPhotoOptions(BuildContext context, UserModel userModel) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    child: Icon(
                      Icons.photo_camera,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    ProfileLocalizations.of(context)?.translate('uploadPhoto') ??
                        'Upload Photo',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _uploadProfilePhoto(context, userModel);
                  },
                ),
                if (userModel.photoURL != null) ...[
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.red.withOpacity(0.1),
                      child: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.red,
                      ),
                    ),
                    title: Text(
                      ProfileLocalizations.of(context)?.translate('removePhoto') ??
                          'Remove Photo',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showRemovePhotoConfirmation(context, userModel);
                    },
                  ),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      child: const Icon(
                        Icons.visibility,
                        color: Colors.blue,
                      ),
                    ),
                    title: Text(
                      ProfileLocalizations.of(context)?.translate('viewPhoto') ??
                          'View Photo',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _viewProfilePhoto(context, userModel.photoURL!);
                    },
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _uploadProfilePhoto(
    BuildContext context,
    UserModel userModel,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final localizations = ProfileLocalizations.of(context);
    final successTitle = localizations?.translate('success') ?? 'Success';
    final successMessage =
        localizations?.translate('profilePhotoUpdatedSuccessfully') ??
        'Profile photo updated successfully!';
    final errorTitle = localizations?.translate('error') ?? 'Error';
    final errorMessageTemplate =
        localizations?.translate(
          'failedToUpdateProfilePhoto',
          args: {'error': ''},
        ) ??
        'Failed to update profile photo: ';

    setState(() {
      _isUploadingPhoto = true;
    });

    try {
      if (userModel.photoURL != null) {
        await _fileUploadService.deleteFile(userModel.photoURL!);
      }

      final downloadUrl = await _fileUploadService.uploadProfilePhoto(
        currentUser.uid,
      );

      if (downloadUrl != null) {
        await currentUser.updatePhotoURL(downloadUrl);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({'photoURL': downloadUrl});

        final chatController = Get.find<ChatController>();
        await chatController.refreshUserDataAndChat();

        if (mounted) {
          SnackbarUtils.showSuccess(successMessage);
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(errorMessageTemplate + e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
        });
      }
    }
  }

  void _showRemovePhotoConfirmation(BuildContext context, UserModel userModel) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.delete_outline,
                  size: 48,
                  color: Colors.red.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  ProfileLocalizations.of(context)?.translate('removePhoto') ??
                      'Remove Photo',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  ProfileLocalizations.of(
                        context,
                      )?.translate('removePhotoConfirmation') ??
                      'Are you sure you want to remove your profile photo?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          ProfileLocalizations.of(context)?.translate('cancel') ??
                              'Cancel',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _removeProfilePhoto(context, userModel);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          ProfileLocalizations.of(context)?.translate('remove') ??
                              'Remove',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _removeProfilePhoto(
    BuildContext context,
    UserModel userModel,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final localizations = ProfileLocalizations.of(context);
    final successTitle = localizations?.translate('success') ?? 'Success';
    final successMessage =
        localizations?.translate('profilePhotoRemovedSuccessfully') ??
        'Profile photo removed successfully!';
    final errorTitle = localizations?.translate('error') ?? 'Error';
    final errorMessageTemplate =
        localizations?.translate(
          'failedToRemoveProfilePhoto',
          args: {'error': ''},
        ) ??
        'Failed to remove profile photo: ';

    setState(() {
      _isUploadingPhoto = true;
    });

    try {
      if (userModel.photoURL != null) {
        await _fileUploadService.deleteFile(userModel.photoURL!);
      }

      await currentUser.updatePhotoURL(null);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({'photoURL': null});

      final chatController = Get.find<ChatController>();
      await chatController.refreshUserDataAndChat();

      if (mounted) {
        SnackbarUtils.showSuccess(successMessage);
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(errorMessageTemplate + e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
        });
      }
    }
  }

  void _viewProfilePhoto(BuildContext context, String photoUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.photo,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        ProfileLocalizations.of(context)?.translate('profilePhoto') ??
                            'Profile Photo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: InteractiveViewer(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(photoUrl),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          ProfileLocalizations.of(context)?.translate('profile') ?? 'Profile',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
              Colors.white,
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: GetBuilder<ChatController>(
          builder: (chatController) {
            UserModel? userModel = chatController.currentUser;

            if (userModel == null) {
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser?.uid)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${ProfileLocalizations.of(context)?.translate('error') ?? 'Error'}: ${snapshot.error}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_circle_outlined,
                            size: 48,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            ProfileLocalizations.of(context)?.translate('userDataNotFound') ??
                                'User data not found',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final userData = snapshot.data!.data() as Map<String, dynamic>;
                  userModel = UserModel.fromJson(userData);
                  return _buildProfileContent(context, userModel!);
                },
              );
            }

            return _buildProfileContent(context, userModel);
          },
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, UserModel userModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const SizedBox(height: kToolbarHeight + 20),
          // Profile Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Avatar Section
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.transparent,
                        backgroundImage: userModel.photoURL != null
                            ? NetworkImage(userModel.photoURL!)
                            : null,
                        child: userModel.photoURL == null
                            ? Text(
                                (userModel.name.isEmpty ? 'U' : userModel.name[0])
                                    .toUpperCase(),
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
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
                            height: 36,
                            width: 36,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
                                ],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
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
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // User Name
                Text(
                  userModel.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                // Email
                if (userModel.email != null)
                  Text(
                    userModel.email!,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                // Premium Badge
                if (userModel.premium) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFF59E0B),
                          const Color(0xFFF97316),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF97316).withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          ProfileLocalizations.of(context)?.translate('premium') ??
                              'Premium',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),



          // Account Details Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 20),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.person_outline,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      ProfileLocalizations.of(context)?.translate('accountDetails') ??
                          'Account Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
                  child: Column(
                    children: [
                      _buildDetailItem(
                        context: context,
                        icon: Icons.phone,
                        label: ProfileLocalizations.of(context)?.translate('phoneNumber') ?? 'Phone Number',
                        value: userModel.phone,
                        iconColor: Theme.of(context).colorScheme.primary,
                      ),
                      if (userModel.email != null)
                        _buildDetailItem(
                          context: context,
                          icon: Icons.email,
                          label: ProfileLocalizations.of(context)?.translate('email') ?? 'Email',
                          value: userModel.email!,
                          iconColor: Theme.of(context).colorScheme.primary,
                        ),
                      _buildDetailItem(
                        context: context,
                        icon: Icons.calendar_today,
                        label: 'Member Since',
                        value: '${userModel.createdAt.day}/${userModel.createdAt.month}/${userModel.createdAt.year}',
                        iconColor: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Logout Button
          Container(
            width: double.infinity,
            height: 56,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton(
              onPressed: _isLoggingOut
                  ? null
                  : () async {
                      AppLogger.common('🔘 Profile logout button pressed');
                      setState(() => _isLoggingOut = true);

                      try {
                        final authRepository = AuthRepository();
                        await authRepository.signOut();

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
                          AppLogger.error(
                            '⚠️ Could not reset login controller: $e',
                          );
                        }

                        Get.offAllNamed('/login');
                      } catch (e) {
                        SnackbarUtils.showError(
                          ProfileLocalizations.of(context)?.translate('failedToLogout', args: {'error': e.toString()}) ??
                              'Failed to logout: $e',
                        );
                      } finally {
                        if (mounted) {
                          setState(() => _isLoggingOut = false);
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _isLoggingOut ? Colors.grey.shade400 : Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: _isLoggingOut ? 0 : 8,
                shadowColor: Colors.redAccent.withOpacity(0.4),
              ),
              child: _isLoggingOut
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Logging out...',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.logout, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          ProfileLocalizations.of(context)?.translate('logOut') ?? 'Log Out',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
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
