import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/notification_model.dart';
import '../services/notification_manager.dart';
import '../services/test_notifications.dart';
import '../../../l10n/features/notifications/notifications_localizations.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final NotificationManager _notificationManager = NotificationManager();
  final ScrollController _scrollController = ScrollController();

  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _loadUnreadCount();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications({bool refresh = false}) async {
    try {
      if (refresh) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      final notifications = await _notificationManager.getNotifications(
        limit: 20,
        startAfter: refresh ? null : (_notifications.isNotEmpty ? _notifications.last : null),
      );

      setState(() {
        if (refresh) {
          _notifications = notifications;
        } else {
          _notifications.addAll(notifications);
        }
        _hasMore = notifications.length >= 20;
        _isLoading = false;
        _isLoadingMore = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load notifications: $e';
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await _notificationManager.getUnreadCount();
      setState(() {
        _unreadCount = count;
      });
    } catch (e) {
      // Silently fail for unread count
      print('Failed to load unread count: $e');
    }
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;

    try {
      await _notificationManager.markAsRead(notification.id);
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = notification.markAsRead();
          _unreadCount = (_unreadCount - 1).clamp(0, double.infinity).toInt();
        }
      });
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to mark notification as read',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _markAsUnread(NotificationModel notification) async {
    if (notification.isUnread) return;

    try {
      await _notificationManager.markAsUnread(notification.id);
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = notification.markAsUnread();
          _unreadCount++;
        }
      });
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to mark notification as unread',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _deleteNotification(NotificationModel notification) async {
    try {
      await _notificationManager.deleteNotification(notification.id);
      setState(() {
        _notifications.removeWhere((n) => n.id == notification.id);
        if (notification.isUnread) {
          _unreadCount = (_unreadCount - 1).clamp(0, double.infinity).toInt();
        }
      });

      Get.snackbar(
        'Deleted',
        'Notification deleted',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete notification',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationManager.markAllAsRead();
      setState(() {
        _notifications = _notifications.map((n) => n.markAsRead()).toList();
        _unreadCount = 0;
      });

      Get.snackbar(
        'Success',
        'All notifications marked as read',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to mark all as read',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _deleteAllNotifications() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(NotificationsLocalizations.of(context)?.translate('deleteAllNotifications') ?? 'Delete All Notifications'),
        content: Text(NotificationsLocalizations.of(context)?.translate('deleteAllNotificationsConfirm') ?? 'Are you sure you want to delete all notifications? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(NotificationsLocalizations.of(context)?.translate('cancel') ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(NotificationsLocalizations.of(context)?.translate('deleteAll') ?? 'Delete all'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _notificationManager.deleteAllNotifications();
      setState(() {
        _notifications.clear();
        _unreadCount = 0;
      });

      Get.snackbar(
        'Success',
        'All notifications deleted',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete all notifications',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${NotificationsLocalizations.of(context)?.translate('notificationsTitle') ?? 'Notifications'}${_unreadCount > 0 ? ' ($_unreadCount)' : ''}'),
        actions: [
          // Test button for development
          IconButton(
            icon: Icon(Icons.bug_report),
            tooltip: NotificationsLocalizations.of(context)?.translate('testNotifications') ?? 'Test Notifications',
            onPressed: _showTestMenu,
          ),
          if (_notifications.isNotEmpty) ...[
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'mark_all_read':
                    _markAllAsRead();
                    break;
                  case 'delete_all':
                    _deleteAllNotifications();
                    break;
                  case 'clear_test':
                    notificationTester.clearTestNotifications();
                    _loadNotifications(refresh: true);
                    _loadUnreadCount();
                    break;
                  case 'stats':
                    notificationTester.printNotificationStats();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'mark_all_read',
                  child: Text(NotificationsLocalizations.of(context)?.translate('markAllAsRead') ?? 'Mark all as read'),
                ),
                PopupMenuItem(
                  value: 'delete_all',
                  child: Text(NotificationsLocalizations.of(context)?.translate('deleteAll') ?? 'Delete all'),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'clear_test',
                  child: Text(NotificationsLocalizations.of(context)?.translate('clearTestNotifications') ?? 'Clear test notifications'),
                ),
                PopupMenuItem(
                  value: 'stats',
                  child: Text(NotificationsLocalizations.of(context)?.translate('printStats') ?? 'Print stats'),
                ),
              ],
            ),
          ],
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _notifications.isEmpty) {
      return _buildErrorState();
    }

    if (_notifications.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => _loadNotifications(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _notifications.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _notifications.length) {
            // Load more indicator
            if (!_isLoadingMore) {
              _loadMoreNotifications();
            }
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final notification = _notifications[index];
          return Dismissible(
            key: Key(notification.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20.0),
              color: Colors.red,
              child: const Icon(
                Icons.delete,
                color: Colors.white,
              ),
            ),
            confirmDismiss: (direction) async {
              return await Get.dialog<bool>(
                AlertDialog(
                  title: const Text('Delete Notification'),
                  content: const Text('Are you sure you want to delete this notification?'),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(result: false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Get.back(result: true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
            onDismissed: (direction) {
              _deleteNotification(notification);
            },
            child: NotificationCard(
              notification: notification,
              onTap: () => _markAsRead(notification),
              onLongPress: () => _showNotificationOptions(notification),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Something went wrong',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _loadNotifications(refresh: true),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.notifications_none,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            NotificationsLocalizations.of(context)?.translate('noNotificationsYet') ?? 'No notifications yet',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            NotificationsLocalizations.of(context)?.translate('noNotificationsDescription') ?? 'You\'ll see your notifications here when you receive them.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadMoreNotifications() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    await _loadNotifications();
  }

  void _showTestMenu() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Test Notifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.person_add, color: Colors.green),
              title: const Text('Test New Follower'),
              subtitle: const Text('Simulate someone following you'),
              onTap: () async {
                Get.back();
                await notificationTester.testNewFollowerNotification();
                _loadNotifications(refresh: true);
                _loadUnreadCount();
                Get.snackbar('Test', 'New Follower notification sent');
              },
            ),
            ListTile(
              leading: const Icon(Icons.emoji_events, color: Colors.amber),
              title: const Text('Test Level Up'),
              subtitle: const Text('Simulate level progression'),
              onTap: () async {
                Get.back();
                await notificationTester.testLevelUpNotification();
                _loadNotifications(refresh: true);
                _loadUnreadCount();
                Get.snackbar('Test', 'Level Up notification sent');
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat, color: Colors.blue),
              title: const Text('Test Chat Message'),
              subtitle: const Text('Simulate new chat message'),
              onTap: () async {
                Get.back();
                await notificationTester.testChatMessageNotification();
                _loadNotifications(refresh: true);
                _loadUnreadCount();
                Get.snackbar('Test', 'Chat message notification sent');
              },
            ),
            ListTile(
              leading: const Icon(Icons.poll, color: Colors.orange),
              title: const Text('Test Poll'),
              subtitle: const Text('Simulate new poll notification'),
              onTap: () async {
                Get.back();
                await notificationTester.testPollNotification();
                _loadNotifications(refresh: true);
                _loadUnreadCount();
                Get.snackbar('Test', 'Poll notification sent');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.cleaning_services, color: Colors.red),
              title: const Text('Clear All Tests'),
              subtitle: const Text('Remove all test notifications'),
              onTap: () async {
                Get.back();
                await notificationTester.clearTestNotifications();
                _loadNotifications(refresh: true);
                _loadUnreadCount();
                Get.snackbar('Test', 'Test notifications cleared');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationOptions(NotificationModel notification) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                notification.isRead ? Icons.markunread : Icons.mark_email_read,
              ),
              title: Text(
                notification.isRead ? 'Mark as unread' : 'Mark as read',
              ),
              onTap: () {
                Get.back();
                if (notification.isRead) {
                  _markAsUnread(notification);
                } else {
                  _markAsRead(notification);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete'),
              onTap: () {
                Get.back();
                _deleteNotification(notification);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: notification.isUnread ? 2 : 0,
      color: notification.isUnread
          ? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3)
          : null,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getNotificationColor(context),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getNotificationIcon(),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and time
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: notification.isUnread
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Text(
                          notification.timeAgo,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Body
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Category badge
                    if (notification.category.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          notification.category,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Unread indicator
              if (notification.isUnread)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getNotificationColor(BuildContext context) {
    final category = notification.category;
    switch (category) {
      case 'Chat':
        return Colors.blue;
      case 'Following':
        return Colors.green;
      case 'Events':
        return Colors.purple;
      case 'Polls':
        return Colors.orange;
      case 'Achievements':
        return Colors.amber;
      case 'System':
        return Colors.red;
      case 'Social':
        return Colors.pink;
      case 'Content':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon() {
    final category = notification.category;
    switch (category) {
      case 'Chat':
        return Icons.chat;
      case 'Following':
        return Icons.person_add;
      case 'Events':
        return Icons.event;
      case 'Polls':
        return Icons.poll;
      case 'Achievements':
        return Icons.emoji_events;
      case 'System':
        return Icons.settings;
      case 'Social':
        return Icons.favorite;
      case 'Content':
        return Icons.article;
      default:
        return Icons.notifications;
    }
  }

  Color _getCategoryColor() {
    // Use the extension method through the model
    final category = notification.category;
    switch (category) {
      case 'Chat':
        return Colors.blue.shade700;
      case 'Following':
        return Colors.green.shade700;
      case 'Events':
        return Colors.purple.shade700;
      case 'Polls':
        return Colors.orange.shade700;
      case 'Achievements':
        return Colors.amber.shade700;
      case 'System':
        return Colors.red.shade700;
      case 'Social':
        return Colors.pink.shade700;
      case 'Content':
        return Colors.teal.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
}
