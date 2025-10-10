import 'package:flutter/material.dart';
import '../features/notifications/models/notification_model.dart';

/// In-app notification banner that appears at the top of the screen
/// Similar to system notification banners but within the app
class InAppNotificationBanner extends StatefulWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;
  final Duration displayDuration;

  const InAppNotificationBanner({
    super.key,
    required this.notification,
    this.onTap,
    this.onDismiss,
    this.displayDuration = const Duration(seconds: 5),
  });

  @override
  State<InAppNotificationBanner> createState() => _InAppNotificationBannerState();
}

class _InAppNotificationBannerState extends State<InAppNotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // Start the slide-in animation
    _animationController.forward();

    // Auto-dismiss after display duration
    Future.delayed(widget.displayDuration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _dismiss() {
    _animationController.reverse().then((_) {
      widget.onDismiss?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SlideTransition(
          position: _slideAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: InkWell(
                onTap: () {
                  widget.onTap?.call();
                  _dismiss();
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Notification icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _getNotificationColor(),
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
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Title
                            Text(
                              widget.notification.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),

                            // Body
                            Text(
                              widget.notification.body,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Dismiss button
                      IconButton(
                        onPressed: _dismiss,
                        icon: Icon(
                          Icons.close,
                          size: 20,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getNotificationColor() {
    final category = widget.notification.category;
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
    final category = widget.notification.category;
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
}

/// Service to manage in-app notification display
class InAppNotificationService {
  static final InAppNotificationService _instance = InAppNotificationService._internal();
  factory InAppNotificationService() => _instance;
  InAppNotificationService._internal();

  OverlayEntry? _currentOverlay;

  /// Show an in-app notification banner
  void showNotification({
    required NotificationModel notification,
    required BuildContext context,
    VoidCallback? onTap,
    VoidCallback? onDismiss,
    Duration displayDuration = const Duration(seconds: 5),
  }) {
    // Remove any existing notification
    hideCurrentNotification();

    final overlay = Overlay.of(context);
    _currentOverlay = OverlayEntry(
      builder: (context) => InAppNotificationBanner(
        notification: notification,
        onTap: onTap,
        onDismiss: () {
          hideCurrentNotification();
          onDismiss?.call();
        },
        displayDuration: displayDuration,
      ),
    );

    overlay.insert(_currentOverlay!);
  }

  /// Hide the current notification
  void hideCurrentNotification() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }

  /// Check if a notification is currently being displayed
  bool get isNotificationVisible => _currentOverlay != null;
}