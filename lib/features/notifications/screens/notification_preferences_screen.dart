import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/notification_settings_controller.dart';
import '../../../utils/app_logger.dart';
import '../../../l10n/features/notifications/notifications_localizations.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  @override
  Widget build(BuildContext context) {
    AppLogger.notifications('🔍 NotificationPreferencesScreen build called');
    final NotificationSettingsController controller;
    try {
      controller = Get.find<NotificationSettingsController>();
      AppLogger.notifications('🔍 Controller found successfully');
      AppLogger.notifications('🔍 Controller state - isInitialized: ${controller.isInitialized.value}, isLoading: ${controller.isLoading.value}, hasSettings: ${controller.settings.value != null}');

      // Force initialization if not initialized
      if (!controller.isInitialized.value && !controller.isLoading.value) {
        AppLogger.notifications('🔍 Controller not initialized, forcing initialization');
        final currentUser = controller.currentUser;
        if (currentUser != null) {
          AppLogger.notifications('🔍 Found current user, loading settings: ${currentUser.uid}');
          controller.loadNotificationSettings(currentUser.uid);
        } else {
          AppLogger.notifications('🔍 No current user, cannot initialize');
        }
      }
    } catch (e) {
      AppLogger.notifications('❌ Failed to find NotificationSettingsController: $e');
      return const Scaffold(
        body: Center(
          child: Text('Controller not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(() {
          final translated = NotificationsLocalizations.of(context)?.translate('notificationPreferences') ?? 'Notification Preferences';
          AppLogger.notifications('🔍 Translated title: "$translated"');
          return translated;
        }()),
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
        AppLogger.notifications('🔍 Obx rebuild - isInitialized: ${controller.isInitialized.value}, isLoading: ${controller.isLoading.value}, hasSettings: ${controller.settings.value != null}');
        if (!controller.isInitialized.value) {
          AppLogger.notifications('🔍 Showing loading indicator - not initialized');
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.settings.value == null) {
          AppLogger.notifications('🔍 Showing error state - settings is null');
          return _buildErrorState();
        }

        AppLogger.notifications('🔍 Showing preferences content');
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
          Text(NotificationsLocalizations.of(context)?.translate('failedToLoadPreferences') ?? 'Failed to load preferences'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final controller = Get.find<NotificationSettingsController>();
              final userId = controller.userId;
              if (userId != null && userId.isNotEmpty) {
                controller.loadNotificationSettings(userId);
              } else {
                // If no user ID, try to get from Firebase Auth
                final currentUser = controller.currentUser;
                if (currentUser != null) {
                  controller.loadNotificationSettings(currentUser.uid);
                }
              }
            },
            child: Text(NotificationsLocalizations.of(context)?.translate('retry') ?? 'Retry'),
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
            NotificationsLocalizations.of(context)?.translate('generalSettings') ?? 'General Settings',
            style: Get.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Obx(() => SwitchListTile(
          title: Text(NotificationsLocalizations.of(context)?.translate('pushNotifications') ?? 'Push Notifications'),
          subtitle: Text(NotificationsLocalizations.of(context)?.translate('pushNotificationsDescription') ?? 'Receive notifications when app is closed'),
          value: controller.pushEnabled,
          onChanged: (value) => controller.togglePushNotifications(value),
        )),
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            NotificationsLocalizations.of(Get.context!)?.translate('notificationTypes') ?? 'Notification Types',
            style: Get.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Obx(() => SwitchListTile(
          title: Text(NotificationsLocalizations.of(Get.context!)?.translate('chatMessages') ?? 'Chat Messages'),
          subtitle: Text(NotificationsLocalizations.of(Get.context!)?.translate('chatMessagesDescription') ?? 'Messages, mentions, and chat updates'),
          value: controller.chatEnabled,
          onChanged: controller.pushEnabled
              ? (value) => controller.toggleChatNotifications(value)
              : null,
        )),
        Obx(() => SwitchListTile(
          title: Text(NotificationsLocalizations.of(Get.context!)?.translate('candidateActivity') ?? 'Candidate Activity'),
          subtitle: Text(NotificationsLocalizations.of(Get.context!)?.translate('candidateActivityDescription') ?? 'New followers, posts, and updates'),
          value: controller.candidateEnabled,
          onChanged: controller.pushEnabled
              ? (value) => controller.toggleCandidateNotifications(value)
              : null,
        )),
        Obx(() => SwitchListTile(
          title: Text(NotificationsLocalizations.of(Get.context!)?.translate('pollsAndSurveys') ?? 'Polls & Surveys'),
          subtitle: Text(NotificationsLocalizations.of(Get.context!)?.translate('pollsAndSurveysDescription') ?? 'New polls, results, and deadlines'),
          value: controller.pollEnabled,
          onChanged: controller.pushEnabled
              ? (value) => controller.togglePollNotifications(value)
              : null,
        )),
        Obx(() => SwitchListTile(
          title: Text(NotificationsLocalizations.of(Get.context!)?.translate('systemUpdates') ?? 'System Updates'),
          subtitle: Text(NotificationsLocalizations.of(Get.context!)?.translate('systemUpdatesDescription') ?? 'App updates, security, and maintenance'),
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
            NotificationsLocalizations.of(Get.context!)?.translate('importantNotifications') ?? 'Important Notifications',
            style: Get.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            NotificationsLocalizations.of(Get.context!)?.translate('importantNotificationsDescription') ?? 'These notifications are always important and help protect your account and keep you informed about critical updates.',
            style: Get.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ),
        const SizedBox(height: 8),
        _buildImportantNotificationItem(
          NotificationsLocalizations.of(Get.context!)?.translate('securityAlerts') ?? 'Security Alerts',
          NotificationsLocalizations.of(Get.context!)?.translate('securityAlertsDescription') ?? 'Security issues and account alerts',
        ),
        _buildImportantNotificationItem(
          NotificationsLocalizations.of(Get.context!)?.translate('electionReminders') ?? 'Election Reminders',
          NotificationsLocalizations.of(Get.context!)?.translate('electionRemindersDescription') ?? 'Election day and voting reminders',
        ),
        _buildImportantNotificationItem(
          NotificationsLocalizations.of(Get.context!)?.translate('eventReminders') ?? 'Event Reminders',
          NotificationsLocalizations.of(Get.context!)?.translate('eventRemindersDescription') ?? 'Upcoming event notifications',
        ),
        _buildImportantNotificationItem(
          NotificationsLocalizations.of(Get.context!)?.translate('pollDeadlines') ?? 'Poll Deadlines',
          NotificationsLocalizations.of(Get.context!)?.translate('pollDeadlinesDescription') ?? 'Poll closing reminders',
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
            NotificationsLocalizations.of(Get.context!)?.translate('quietHours') ?? 'Quiet Hours',
            style: Get.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Obx(() => SwitchListTile(
          title: Text(NotificationsLocalizations.of(Get.context!)?.translate('enableQuietHours') ?? 'Enable Quiet Hours'),
          subtitle: Text(NotificationsLocalizations.of(Get.context!)?.translate('quietHoursDescription') ?? 'Pause notifications during specified hours'),
          value: controller.quietHoursEnabled,
          onChanged: controller.pushEnabled
              ? (value) => controller.toggleQuietHours(value)
              : null,
        )),
        if (controller.quietHoursEnabled) ...[
          Obx(() => ListTile(
            title: Text(NotificationsLocalizations.of(Get.context!)?.translate('startTime') ?? 'Start Time'),
            subtitle: Text(_formatTime(controller.quietHoursStart ?? '22:00')),
            trailing: const Icon(Icons.access_time),
            onTap: () => _selectTime(true, controller),
          )),
          Obx(() => ListTile(
            title: Text(NotificationsLocalizations.of(Get.context!)?.translate('endTime') ?? 'End Time'),
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
            NotificationsLocalizations.of(Get.context!)?.translate('advancedSettings') ?? 'Advanced Settings',
            style: Get.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Obx(() => SwitchListTile(
          title: Text(NotificationsLocalizations.of(Get.context!)?.translate('doNotDisturb') ?? 'Do Not Disturb'),
          subtitle: Text(NotificationsLocalizations.of(Get.context!)?.translate('doNotDisturbDescription') ?? 'Block all notifications temporarily'),
          value: controller.doNotDisturbEnabled,
          onChanged: (value) => controller.toggleDoNotDisturb(value),
        )),
        const Divider(),
        ListTile(
          title: Text(NotificationsLocalizations.of(Get.context!)?.translate('resetToDefaults') ?? 'Reset to Defaults'),
          subtitle: Text(NotificationsLocalizations.of(Get.context!)?.translate('resetToDefaultsDescription') ?? 'Restore all settings to default values'),
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
    final localizations = NotificationsLocalizations.of(Get.context!);
    switch (title) {
      case 'Security Alerts':
        return localizations?.translate('securityAlertsDescription') ?? 'These notifications help protect your account and data. They cannot be disabled to ensure your security.';
      case 'Election Reminders':
        return localizations?.translate('electionRemindersDescription') ?? 'Stay informed about important election dates and voting opportunities. These reminders help ensure your voice is heard.';
      case 'Event Reminders':
        return localizations?.translate('eventRemindersDescription') ?? 'Never miss important political events and rallies. These notifications help you stay engaged with your community.';
      case 'Poll Deadlines':
        return localizations?.translate('pollDeadlinesDescription') ?? 'Get reminded before polls close so you don\'t miss your chance to participate in important decisions.';
      default:
        return 'This is an important notification that helps keep you informed about critical updates.';
    }
  }

  void _showResetConfirmation(NotificationSettingsController controller) {
    Get.dialog(
      AlertDialog(
        title: Text(NotificationsLocalizations.of(Get.context!)?.translate('resetSettings') ?? 'Reset Settings'),
        content: Text(NotificationsLocalizations.of(Get.context!)?.translate('resetSettingsConfirm') ?? 'Are you sure you want to reset all notification settings to their default values?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(NotificationsLocalizations.of(Get.context!)?.translate('cancel') ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await controller.resetToDefaults();
              Get.snackbar(
                NotificationsLocalizations.of(Get.context!)?.translate('success') ?? 'Success',
                NotificationsLocalizations.of(Get.context!)?.translate('settingsResetToDefaults') ?? 'Settings reset to defaults',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            child: Text(NotificationsLocalizations.of(Get.context!)?.translate('resetToDefaults') ?? 'Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? timeString) {
    if (timeString == null) return NotificationsLocalizations.of(Get.context!)?.translate('notSet') ?? 'Not set';

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