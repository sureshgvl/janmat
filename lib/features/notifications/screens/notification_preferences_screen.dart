import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/notification_preferences.dart';
import '../models/notification_type.dart';
import '../services/notification_manager.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  final NotificationManager _notificationManager = NotificationManager();
  NotificationPreferences? _preferences;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      setState(() => _isLoading = true);
      final prefs = await _notificationManager.getUserPreferences();
      setState(() {
        _preferences = prefs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar(
        'Error',
        'Failed to load notification preferences',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _savePreferences(NotificationPreferences newPreferences) async {
    try {
      setState(() => _isSaving = true);
      await _notificationManager.updateUserPreferences(newPreferences);
      setState(() {
        _preferences = newPreferences;
        _isSaving = false;
      });

      Get.snackbar(
        'Success',
        'Notification preferences saved',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      setState(() => _isSaving = false);
      Get.snackbar(
        'Error',
        'Failed to save preferences',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _updatePreference(bool Function(NotificationPreferences) updater) {
    if (_preferences == null) return;

    final newPreferences = NotificationPreferences(
      userId: _preferences!.userId,
      notificationsEnabled: updater(_preferences!),
      pushNotificationsEnabled: _preferences!.pushNotificationsEnabled,
      inAppNotificationsEnabled: _preferences!.inAppNotificationsEnabled,
      categoryPreferences: _preferences!.categoryPreferences,
      typePreferences: _preferences!.typePreferences,
      quietHoursEnabled: _preferences!.quietHoursEnabled,
      quietHoursStart: _preferences!.quietHoursStart,
      quietHoursEnd: _preferences!.quietHoursEnd,
      batchNotificationsEnabled: _preferences!.batchNotificationsEnabled,
      batchIntervalMinutes: _preferences!.batchIntervalMinutes,
    );

    _savePreferences(newPreferences);
  }

  void _updateCategoryPreference(String category, bool enabled) {
    if (_preferences == null) return;

    final newCategoryPreferences = Map<String, bool>.from(_preferences!.categoryPreferences);
    newCategoryPreferences[category] = enabled;

    final newPreferences = NotificationPreferences(
      userId: _preferences!.userId,
      notificationsEnabled: _preferences!.notificationsEnabled,
      pushNotificationsEnabled: _preferences!.pushNotificationsEnabled,
      inAppNotificationsEnabled: _preferences!.inAppNotificationsEnabled,
      categoryPreferences: newCategoryPreferences,
      typePreferences: _preferences!.typePreferences,
      quietHoursEnabled: _preferences!.quietHoursEnabled,
      quietHoursStart: _preferences!.quietHoursStart,
      quietHoursEnd: _preferences!.quietHoursEnd,
      batchNotificationsEnabled: _preferences!.batchNotificationsEnabled,
      batchIntervalMinutes: _preferences!.batchIntervalMinutes,
    );

    _savePreferences(newPreferences);
  }

  void _updateTypePreference(NotificationType type, bool enabled) {
    if (_preferences == null) return;

    final newTypePreferences = Map<NotificationType, bool>.from(_preferences!.typePreferences);
    newTypePreferences[type] = enabled;

    final newPreferences = NotificationPreferences(
      userId: _preferences!.userId,
      notificationsEnabled: _preferences!.notificationsEnabled,
      pushNotificationsEnabled: _preferences!.pushNotificationsEnabled,
      inAppNotificationsEnabled: _preferences!.inAppNotificationsEnabled,
      categoryPreferences: _preferences!.categoryPreferences,
      typePreferences: newTypePreferences,
      quietHoursEnabled: _preferences!.quietHoursEnabled,
      quietHoursStart: _preferences!.quietHoursStart,
      quietHoursEnd: _preferences!.quietHoursEnd,
      batchNotificationsEnabled: _preferences!.batchNotificationsEnabled,
      batchIntervalMinutes: _preferences!.batchIntervalMinutes,
    );

    _savePreferences(newPreferences);
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    if (_preferences == null) return;

    final initialTime = TimeOfDay(
      hour: isStartTime ? _preferences!.quietHoursStart : _preferences!.quietHoursEnd,
      minute: 0,
    );

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (pickedTime != null) {
      final newPreferences = NotificationPreferences(
        userId: _preferences!.userId,
        notificationsEnabled: _preferences!.notificationsEnabled,
        pushNotificationsEnabled: _preferences!.pushNotificationsEnabled,
        inAppNotificationsEnabled: _preferences!.inAppNotificationsEnabled,
        categoryPreferences: _preferences!.categoryPreferences,
        typePreferences: _preferences!.typePreferences,
        quietHoursEnabled: _preferences!.quietHoursEnabled,
        quietHoursStart: isStartTime ? pickedTime.hour : _preferences!.quietHoursStart,
        quietHoursEnd: isStartTime ? _preferences!.quietHoursEnd : pickedTime.hour,
        batchNotificationsEnabled: _preferences!.batchNotificationsEnabled,
        batchIntervalMinutes: _preferences!.batchIntervalMinutes,
      );

      _savePreferences(newPreferences);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _preferences == null
              ? _buildErrorState()
              : _buildPreferencesContent(),
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
            onPressed: _loadPreferences,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesContent() {
    return ListView(
      children: [
        _buildMasterToggles(),
        const Divider(),
        _buildCategoryPreferences(),
        const Divider(),
        _buildImportantNotifications(),
        const Divider(),
        _buildQuietHours(),
        const Divider(),
        _buildAdvancedSettings(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildMasterToggles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'General Settings',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SwitchListTile(
          title: const Text('All Notifications'),
          subtitle: const Text('Enable or disable all notifications'),
          value: _preferences!.notificationsEnabled,
          onChanged: (value) => _updatePreference((prefs) => value),
        ),
        if (_preferences!.notificationsEnabled) ...[
          SwitchListTile(
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive notifications when app is closed'),
            value: _preferences!.pushNotificationsEnabled,
            onChanged: (value) {
              final newPreferences = NotificationPreferences(
                userId: _preferences!.userId,
                notificationsEnabled: _preferences!.notificationsEnabled,
                pushNotificationsEnabled: value,
                inAppNotificationsEnabled: _preferences!.inAppNotificationsEnabled,
                categoryPreferences: _preferences!.categoryPreferences,
                typePreferences: _preferences!.typePreferences,
                quietHoursEnabled: _preferences!.quietHoursEnabled,
                quietHoursStart: _preferences!.quietHoursStart,
                quietHoursEnd: _preferences!.quietHoursEnd,
                batchNotificationsEnabled: _preferences!.batchNotificationsEnabled,
                batchIntervalMinutes: _preferences!.batchIntervalMinutes,
              );
              _savePreferences(newPreferences);
            },
          ),
          SwitchListTile(
            title: const Text('In-App Notifications'),
            subtitle: const Text('Show notifications within the app'),
            value: _preferences!.inAppNotificationsEnabled,
            onChanged: (value) {
              final newPreferences = NotificationPreferences(
                userId: _preferences!.userId,
                notificationsEnabled: _preferences!.notificationsEnabled,
                pushNotificationsEnabled: _preferences!.pushNotificationsEnabled,
                inAppNotificationsEnabled: value,
                categoryPreferences: _preferences!.categoryPreferences,
                typePreferences: _preferences!.typePreferences,
                quietHoursEnabled: _preferences!.quietHoursEnabled,
                quietHoursStart: _preferences!.quietHoursStart,
                quietHoursEnd: _preferences!.quietHoursEnd,
                batchNotificationsEnabled: _preferences!.batchNotificationsEnabled,
                batchIntervalMinutes: _preferences!.batchIntervalMinutes,
              );
              _savePreferences(newPreferences);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildCategoryPreferences() {
    final categories = [
      'Chat',
      'Following',
      'Events',
      'Polls',
      'Achievements',
      'System',
      'Social',
      'Content',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Categories',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...categories.map((category) => SwitchListTile(
          title: Text(category),
          subtitle: Text(_getCategoryDescription(category)),
          value: _preferences!.categoryPreferences[category] ?? true,
          onChanged: _preferences!.notificationsEnabled
              ? (value) => _updateCategoryPreference(category, value)
              : null,
        )),
      ],
    );
  }

  Widget _buildImportantNotifications() {
    final importantTypes = [
      NotificationType.securityAlert,
      NotificationType.electionReminder,
      NotificationType.eventReminder,
      NotificationType.pollDeadline,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Important Notifications',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'These notifications are always important and cannot be disabled',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...importantTypes.map((type) => ListTile(
          title: Text(type.displayName),
          subtitle: Text(_getTypeDescription(type)),
          trailing: const Icon(Icons.info, color: Colors.blue),
          onTap: () => _showImportantNotificationInfo(type),
        )),
      ],
    );
  }

  Widget _buildQuietHours() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Quiet Hours',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SwitchListTile(
          title: const Text('Enable Quiet Hours'),
          subtitle: const Text('Pause notifications during specified hours'),
          value: _preferences!.quietHoursEnabled,
          onChanged: _preferences!.notificationsEnabled
              ? (value) {
                  final newPreferences = NotificationPreferences(
                    userId: _preferences!.userId,
                    notificationsEnabled: _preferences!.notificationsEnabled,
                    pushNotificationsEnabled: _preferences!.pushNotificationsEnabled,
                    inAppNotificationsEnabled: _preferences!.inAppNotificationsEnabled,
                    categoryPreferences: _preferences!.categoryPreferences,
                    typePreferences: _preferences!.typePreferences,
                    quietHoursEnabled: value,
                    quietHoursStart: _preferences!.quietHoursStart,
                    quietHoursEnd: _preferences!.quietHoursEnd,
                    batchNotificationsEnabled: _preferences!.batchNotificationsEnabled,
                    batchIntervalMinutes: _preferences!.batchIntervalMinutes,
                  );
                  _savePreferences(newPreferences);
                }
              : null,
        ),
        if (_preferences!.quietHoursEnabled) ...[
          ListTile(
            title: const Text('Start Time'),
            subtitle: Text(_formatTime(_preferences!.quietHoursStart)),
            trailing: const Icon(Icons.access_time),
            onTap: () => _selectTime(context, true),
          ),
          ListTile(
            title: const Text('End Time'),
            subtitle: Text(_formatTime(_preferences!.quietHoursEnd)),
            trailing: const Icon(Icons.access_time),
            onTap: () => _selectTime(context, false),
          ),
        ],
      ],
    );
  }

  Widget _buildAdvancedSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Advanced Settings',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SwitchListTile(
          title: const Text('Batch Notifications'),
          subtitle: const Text('Group similar notifications together'),
          value: _preferences!.batchNotificationsEnabled,
          onChanged: _preferences!.notificationsEnabled
              ? (value) {
                  final newPreferences = NotificationPreferences(
                    userId: _preferences!.userId,
                    notificationsEnabled: _preferences!.notificationsEnabled,
                    pushNotificationsEnabled: _preferences!.pushNotificationsEnabled,
                    inAppNotificationsEnabled: _preferences!.inAppNotificationsEnabled,
                    categoryPreferences: _preferences!.categoryPreferences,
                    typePreferences: _preferences!.typePreferences,
                    quietHoursEnabled: _preferences!.quietHoursEnabled,
                    quietHoursStart: _preferences!.quietHoursStart,
                    quietHoursEnd: _preferences!.quietHoursEnd,
                    batchNotificationsEnabled: value,
                    batchIntervalMinutes: _preferences!.batchIntervalMinutes,
                  );
                  _savePreferences(newPreferences);
                }
              : null,
        ),
      ],
    );
  }

  String _getCategoryDescription(String category) {
    switch (category) {
      case 'Chat':
        return 'Messages, mentions, and chat updates';
      case 'Following':
        return 'New followers, profile updates, and posts';
      case 'Events':
        return 'Event invitations, reminders, and updates';
      case 'Polls':
        return 'New polls, results, and deadlines';
      case 'Achievements':
        return 'Badges, levels, and milestones';
      case 'System':
        return 'App updates, security, and maintenance';
      case 'Social':
        return 'Likes, comments, and interactions';
      case 'Content':
        return 'Recommendations and trending topics';
      default:
        return '';
    }
  }

  String _getTypeDescription(NotificationType type) {
    switch (type) {
      case NotificationType.securityAlert:
        return 'Security issues and account alerts';
      case NotificationType.electionReminder:
        return 'Election day and voting reminders';
      case NotificationType.eventReminder:
        return 'Upcoming event notifications';
      case NotificationType.pollDeadline:
        return 'Poll closing reminders';
      default:
        return '';
    }
  }

  String _formatTime(int hour) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:00 $period';
  }

  void _showImportantNotificationInfo(NotificationType type) {
    Get.dialog(
      AlertDialog(
        title: Text(type.displayName),
        content: Text(_getImportantNotificationInfo(type)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _getImportantNotificationInfo(NotificationType type) {
    switch (type) {
      case NotificationType.securityAlert:
        return 'These notifications help protect your account and data. They cannot be disabled to ensure your security.';
      case NotificationType.electionReminder:
        return 'Stay informed about important election dates and voting opportunities. These reminders help ensure your voice is heard.';
      case NotificationType.eventReminder:
        return 'Never miss important political events and rallies. These notifications help you stay engaged with your community.';
      case NotificationType.pollDeadline:
        return 'Get reminded before polls close so you don\'t miss your chance to participate in important decisions.';
      default:
        return '';
    }
  }
}