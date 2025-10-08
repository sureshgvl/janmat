import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:janmat/utils/app_logger.dart';
import '../features/notifications/services/fcm_permission_service.dart';

/// Dialog to request notification permissions from users
class NotificationPermissionDialog extends StatefulWidget {
  const NotificationPermissionDialog({super.key});

  @override
  State<NotificationPermissionDialog> createState() => _NotificationPermissionDialogState();
}

class _NotificationPermissionDialogState extends State<NotificationPermissionDialog> {
  final FCMPermissionService _permissionService = FCMPermissionService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Stay Updated'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_active,
            size: 48,
            color: Colors.blue,
          ),
          SizedBox(height: 16),
          Text(
            'Get notified about important updates, new followers, and campaign activities.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'You can customize your notification preferences anytime in settings.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => _denyPermission(),
          child: const Text('Not Now'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : () => _grantPermission(),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Allow Notifications'),
        ),
      ],
    );
  }

  void _denyPermission() {
    Get.back(result: false);
  }

  Future<void> _grantPermission() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final granted = await _permissionService.requestNotificationPermission();

      if (granted) {
        Get.snackbar(
          'Notifications Enabled',
          'You\'ll now receive notifications for important updates.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      } else {
        Get.snackbar(
          'Permission Denied',
          'You can enable notifications later in your device settings.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      }

      Get.back(result: granted);
    } catch (e) {
      AppLogger.error('Error requesting notification permission: $e');
      Get.snackbar(
        'Error',
        'Failed to request notification permission. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.back(result: false);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

/// Service to manage notification permission prompts
class NotificationPermissionPromptService {
  static final NotificationPermissionPromptService _instance = NotificationPermissionPromptService._internal();
  factory NotificationPermissionPromptService() => _instance;
  NotificationPermissionPromptService._internal();

  final FCMPermissionService _permissionService = FCMPermissionService();

  /// Check if we should show permission prompt
  Future<bool> shouldShowPermissionPrompt() async {
    try {
      // Don't show if already authorized
      if (await _permissionService.hasNotificationPermission()) {
        return false;
      }

      // Don't show if denied (respect user choice)
      if (await _permissionService.isNotificationDenied()) {
        return false;
      }

      // Show if not determined or provisional
      return await _permissionService.isNotificationNotDetermined() ||
             await _permissionService.hasProvisionalPermission();
    } catch (e) {
      AppLogger.error('Error checking if should show permission prompt: $e');
      return false;
    }
  }

  /// Show permission dialog if appropriate
  Future<bool?> showPermissionDialog(BuildContext context) async {
    if (!await shouldShowPermissionPrompt()) {
      return null; // Don't show dialog
    }

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must make a choice
      builder: (context) => const NotificationPermissionDialog(),
    );
  }
}