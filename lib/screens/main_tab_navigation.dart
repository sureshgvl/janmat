import 'package:flutter/material.dart';
import 'package:janmat/utils/app_logger.dart';
import '../l10n/app_localizations.dart';
import '../features/home/screens/home_screen.dart';
import '../features/candidate/screens/candidate_list_screen.dart';
import '../features/chat/screens/chat_list_screen.dart';
import '../features/polls/screens/polls_screen.dart';
import '../widgets/in_app_notification_banner.dart';
import '../features/notifications/services/notification_manager.dart';
import '../features/notifications/services/notification_badge_service.dart';
import '../features/notifications/models/notification_model.dart';
import '../features/notifications/models/notification_type.dart';

class MainTabNavigation extends StatefulWidget {
  const MainTabNavigation({super.key});

  @override
  State<MainTabNavigation> createState() => _MainTabNavigationState();
}

class _MainTabNavigationState extends State<MainTabNavigation> {
  int _selectedIndex = 0;
  final InAppNotificationService _notificationService = InAppNotificationService();
  final NotificationManager _notificationManager = NotificationManager();
  final NotificationBadgeService _badgeService = NotificationBadgeService();
  Stream<List<NotificationModel>>? _notificationStream;

  static final List<Widget> _widgetOptions = <Widget>[
    const HomeScreen(),
    const CandidateListScreen(),
    const ChatListScreen(),
    const PollsScreen(),
    //const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _setupNotificationListener();
    _initializeBadgeService();
  }

  @override
  void dispose() {
    _notificationService.hideCurrentNotification();
    super.dispose();
  }

  void _setupNotificationListener() {
    try {
      // Initialize notification manager first
      _notificationManager.initialize().then((_) {
        // Only setup stream after initialization is complete
        _notificationStream = _notificationManager.getNotificationsStream(limit: 1);
        _notificationStream?.listen((notifications) {
          if (notifications.isNotEmpty) {
            final latestNotification = notifications.first;
            // Only show in-app notification if it's unread and recent (within last minute)
            final oneMinuteAgo = DateTime.now().subtract(const Duration(minutes: 1));
            if (latestNotification.isUnread && latestNotification.createdAt.isAfter(oneMinuteAgo)) {
              _showInAppNotification(latestNotification);
            }
          }
        });
      }).catchError((e) {
        AppLogger.error('Failed to initialize notification manager: $e');
      });
    } catch (e) {
      AppLogger.error('Failed to setup notification listener: $e');
    }
  }

  void _initializeBadgeService() {
    try {
      // Initialize badge service with current user
      // Note: In a real implementation, you'd get the current user ID from auth
      // For now, we'll initialize it when the notification manager is ready
      _notificationManager.initialize().then((_) {
        // Badge will be updated automatically when notifications change
        AppLogger.common('Badge service ready for updates');
      });
    } catch (e) {
      AppLogger.error('Failed to initialize badge service: $e');
    }
  }

  void _showInAppNotification(NotificationModel notification) {
    if (!mounted) return;

    _notificationService.showNotification(
      notification: notification,
      context: context,
      onTap: () => _handleNotificationTap(notification),
      onDismiss: () => _notificationManager.markAsRead(notification.id),
    );
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Mark as read
    _notificationManager.markAsRead(notification.id);

    // Update badge count
    final userId = (_notificationManager.controller as dynamic).currentUserId ?? '';
    if (userId.isNotEmpty) {
      _badgeService.decrementBadge(userId);
    }

    // Navigate based on notification type and data
    _navigateBasedOnNotification(notification);
  }

  void _navigateBasedOnNotification(NotificationModel notification) {
    final data = notification.data;

    switch (notification.type) {
      case NotificationType.newMessage:
      case NotificationType.mention:
        // Navigate to chat
        if (data['chatId'] != null) {
          // Navigate to specific chat room
          setState(() {
            _selectedIndex = 2; // Chat tab
          });
        }
        break;

      case NotificationType.newFollower:
      case NotificationType.candidateProfileUpdate:
        // Navigate to candidate profile
        if (data['candidateId'] != null) {
          // Navigate to candidate profile screen
          setState(() {
            _selectedIndex = 1; // Candidates tab
          });
        }
        break;

      case NotificationType.eventReminder:
      case NotificationType.newEvent:
        // Navigate to events section
        setState(() {
          _selectedIndex = 0; // Home tab (where events are shown)
        });
        break;

      case NotificationType.newPoll:
      case NotificationType.pollResult:
        // Navigate to polls
        setState(() {
          _selectedIndex = 3; // Polls tab
        });
        break;

      default:
        // Default to home
        setState(() {
          _selectedIndex = 0;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _selectedIndex == 0, // Allow pop only when on home tab
      onPopInvoked: (didPop) {
        if (!didPop && _selectedIndex != 0) {
          // If not on home tab, navigate to home tab instead of closing app
          setState(() {
            _selectedIndex = 0;
          });
        }
      },
      child: Scaffold(
        body: _widgetOptions.elementAt(_selectedIndex),
        bottomNavigationBar: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: const Icon(Icons.home),
              label: AppLocalizations.of(context)?.home ?? 'Home',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.people),
              label: AppLocalizations.of(context)?.candidates ?? 'Candidates',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.chat),
              label: AppLocalizations.of(context)?.chatRooms ?? 'Chat Rooms',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.poll),
              label: AppLocalizations.of(context)?.polls ?? 'Polls',
            ),
            // BottomNavigationBarItem(
            //   icon: const Icon(Icons.person),
            //   label: AppLocalizations.of(context)?.profile ?? 'Profile',
            // ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
        ),
      ),
    );
  }
}
