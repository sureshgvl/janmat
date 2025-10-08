import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/notification_settings_controller.dart';

class NotificationPreferencesScreen extends StatelessWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final NotificationSettingsController controller = Get.find<NotificationSettingsController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
        actions: [
          Obx(() {
            if (controller.isLoading.value) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      body: Obx(() {
        if (!controller.isInitialized.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.settings.value == null) {
          return _buildErrorState();
        }

        return _buildPreferencesContent(controller);
      }),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Failed to load preferences'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final controller = Get.find<NotificationSettingsController>();
              controller.loadNotificationSettings(controller.userId ?? '');
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesContent(NotificationSettingsController controller) {
    return ListView(
      children: [
        _buildMasterToggles(controller),
        const Divider(),
        _buildCategoryToggles(controller),
        const Divider(),
        _buildQuietHours(controller),
        const Divider(),
        _buildAdvancedSettings(controller),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildMasterToggles(NotificationSettingsController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'General Settings',
            style: Get.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Obx(() => SwitchListTile(
          title: const Text('Push Notifications'),
          subtitle: const Text('Receive notifications when app is closed'),
          value: controller.pushEnabled,
          onChanged: (value) => controller.togglePushNotifications(value),
        )),
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Notification Types',
            style: Get.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Obx(() => SwitchListTile(
          title: const Text('Chat Messages'),
          subtitle: const Text('Messages, mentions, and chat updates'),
          value: controller.chatEnabled,
          onChanged: controller.pushEnabled
              ? (value) => controller.toggleChatNotifications(value)
              : null,
        )),
        Obx(() => SwitchListTile(
          title: const Text('Candidate Activity'),
          subtitle: const Text('New followers, posts, and updates'),
          value: controller.candidateEnabled,
          onChanged: controller.pushEnabled
              ? (value) => controller.toggleCandidateNotifications(value)
              : null,
        )),
        Obx(() => SwitchListTile(
          title: const Text('Polls & Surveys'),
          subtitle: const Text('New polls, results, and deadlines'),
          value: controller.pollEnabled,
          onChanged: controller.pushEnabled
              ? (value) => controller.togglePollNotifications(value)
              : null,
        )),
        Obx(() => SwitchListTile(
          title: const Text('System Updates'),
          subtitle: const Text('App updates, security, and maintenance'),
          value: controller.systemEnabled,
          onChanged: controller.pushEnabled
              ? (value) => controller.toggleSystemNotifications(value)
              : null,
        )),
      ],
    );
  }

  Widget _buildCategoryToggles(NotificationSettingsController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Important Notifications',
            style: Get.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'These notifications are always important and help protect your account and keep you informed about critical updates.',
            style: Get.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ),
        const SizedBox(height: 8),
        _buildImportantNotificationItem(
          'Security Alerts',
          'Security issues and account alerts',
        ),
        _buildImportantNotificationItem(
          'Election Reminders',
          'Election day and voting reminders',
        ),
        _buildImportantNotificationItem(
          'Event Reminders',
          'Upcoming event notifications',
        ),
        _buildImportantNotificationItem(
          'Poll Deadlines',
          'Poll closing reminders',
        ),
      ],
    );
  }

  Widget _buildImportantNotificationItem(String title, String subtitle) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.info, color: Colors.blue),
      onTap: () => _showImportantNotificationInfo(title, subtitle),
    );
  }

  Widget _buildQuietHours(NotificationSettingsController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Quiet Hours',
            style: Get.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Obx(() => SwitchListTile(
          title: const Text('Enable Quiet Hours'),
          subtitle: const Text('Pause notifications during specified hours'),
          value: controller.quietHoursEnabled,
          onChanged: controller.pushEnabled
              ? (value) => controller.toggleQuietHours(value)
              : null,
        )),
        if (controller.quietHoursEnabled) ...[
          Obx(() => ListTile(
            title: const Text('Start Time'),
            subtitle: Text(_formatTime(controller.quietHoursStart ?? '22:00')),
            trailing: const Icon(Icons.access_time),
            onTap: () => _selectTime(true, controller),
          )),
          Obx(() => ListTile(
            title: const Text('End Time'),
            subtitle: Text(_formatTime(controller.quietHoursEnd ?? '08:00')),
            trailing: const Icon(Icons.access_time),
            onTap: () => _selectTime(false, controller),
          )),
        ],
      ],
    );
  }

  Widget _buildAdvancedSettings(NotificationSettingsController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Advanced Settings',
            style: Get.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Obx(() => SwitchListTile(
          title: const Text('Do Not Disturb'),
          subtitle: const Text('Block all notifications temporarily'),
          value: controller.doNotDisturbEnabled,
          onChanged: (value) => controller.toggleDoNotDisturb(value),
        )),
        const Divider(),
        ListTile(
          title: const Text('Reset to Defaults'),
          subtitle: const Text('Restore all settings to default values'),
          trailing: const Icon(Icons.restore, color: Colors.orange),
          onTap: () => _showResetConfirmation(controller),
        ),
      ],
    );
  }

  Future<void> _selectTime(bool isStartTime, NotificationSettingsController controller) async {
    final currentTime = isStartTime
        ? (controller.quietHoursStart ?? '22:00')
        : (controller.quietHoursEnd ?? '08:00');

    final timeParts = currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.tryParse(timeParts[0]) ?? 22,
      minute: int.tryParse(timeParts[1]) ?? 0,
    );

    final pickedTime = await showTimePicker(
      context: Get.context!,
      initialTime: initialTime,
    );

    if (pickedTime != null) {
      final timeString = '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
      await controller.setQuietHoursTimes(
        startTime: isStartTime ? timeString : controller.quietHoursStart,
        endTime: isStartTime ? controller.quietHoursEnd : timeString,
      );
    }
  }

  void _showImportantNotificationInfo(String title, String subtitle) {
    Get.dialog(
      AlertDialog(
        title: Text(title),
        content: Text(_getImportantNotificationInfo(title)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _getImportantNotificationInfo(String title) {
    switch (title) {
      case 'Security Alerts':
        return 'These notifications help protect your account and data. They cannot be disabled to ensure your security.';
      case 'Election Reminders':
        return 'Stay informed about important election dates and voting opportunities. These reminders help ensure your voice is heard.';
      case 'Event Reminders':
        return 'Never miss important political events and rallies. These notifications help you stay engaged with your community.';
      case 'Poll Deadlines':
        return 'Get reminded before polls close so you don\'t miss your chance to participate in important decisions.';
      default:
        return 'This is an important notification that helps keep you informed about critical updates.';
    }
  }

  void _showResetConfirmation(NotificationSettingsController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text('Are you sure you want to reset all notification settings to their default values?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await controller.resetToDefaults();
              Get.snackbar(
                'Success',
                'Settings reset to defaults',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? timeString) {
    if (timeString == null) return 'Not set';

    final parts = timeString.split(':');
    if (parts.length != 2) return timeString;

    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;

    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');

    return '$displayHour:$displayMinute $period';
  }

}