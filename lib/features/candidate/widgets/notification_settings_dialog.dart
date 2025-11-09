import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/snackbar_utils.dart';
import '../controllers/candidate_controller.dart';

class NotificationSettingsDialog extends StatefulWidget {
  final String candidateId;
  final String candidateName;
  final String userId;
  final bool currentNotificationsEnabled;

  const NotificationSettingsDialog({
    super.key,
    required this.candidateId,
    required this.candidateName,
    required this.userId,
    required this.currentNotificationsEnabled,
  });

  @override
  State<NotificationSettingsDialog> createState() =>
      _NotificationSettingsDialogState();
}

class _NotificationSettingsDialogState
    extends State<NotificationSettingsDialog> {
  late bool notificationsEnabled;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    notificationsEnabled = widget.currentNotificationsEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Notification Settings'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Get notified when ${widget.candidateName} posts updates',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive notifications on your device'),
            value: notificationsEnabled,
            onChanged: isLoading
                ? null
                : (value) {
                    setState(() {
                      notificationsEnabled = value;
                    });
                  },
            activeThumbColor: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 8),
          const Text(
            'You can change this setting anytime from your following list.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isLoading
              ? null
              : () async {
                  setState(() {
                    isLoading = true;
                  });

                  try {
                    final controller = Get.find<CandidateController>();
                    await controller.updateFollowNotificationSettings(
                      widget.userId,
                      widget.candidateId,
                      notificationsEnabled,
                    );

                    SnackbarUtils.showSuccess('Notification settings updated');

                    Navigator.of(context).pop();
                  } catch (e) {
                    SnackbarUtils.showError('Failed to update settings: $e');
                  }

                  setState(() {
                    isLoading = false;
                  });
                },
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
