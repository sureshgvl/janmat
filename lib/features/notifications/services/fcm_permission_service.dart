import 'package:firebase_messaging/firebase_messaging.dart';

/// Service responsible for FCM permission management
class FCMPermissionService {
  final FirebaseMessaging _firebaseMessaging;

  FCMPermissionService({
    FirebaseMessaging? firebaseMessaging,
  }) : _firebaseMessaging = firebaseMessaging ?? FirebaseMessaging.instance;

  /// Check notification permissions
  Future<bool> hasNotificationPermission() async {
    try {
      final settings = await _firebaseMessaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      throw Exception('Failed to check notification permission: $e');
    }
  }

  /// Request notification permissions
  Future<bool> requestNotificationPermission() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      throw Exception('Failed to request notification permission: $e');
    }
  }

  /// Get detailed notification settings
  Future<NotificationSettings> getNotificationSettings() async {
    try {
      return await _firebaseMessaging.getNotificationSettings();
    } catch (e) {
      throw Exception('Failed to get notification settings: $e');
    }
  }

  /// Check if provisional permission is granted (iOS)
  Future<bool> hasProvisionalPermission() async {
    try {
      final settings = await getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      return false;
    }
  }

  /// Check if notifications are denied
  Future<bool> isNotificationDenied() async {
    try {
      final settings = await getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.denied;
    } catch (e) {
      return true;
    }
  }

  /// Check if notifications are not determined (iOS)
  Future<bool> isNotificationNotDetermined() async {
    try {
      final settings = await getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.notDetermined;
    } catch (e) {
      return true;
    }
  }

  /// Get permission status as string
  Future<String> getPermissionStatusString() async {
    try {
      final settings = await getNotificationSettings();
      switch (settings.authorizationStatus) {
        case AuthorizationStatus.authorized:
          return 'authorized';
        case AuthorizationStatus.denied:
          return 'denied';
        case AuthorizationStatus.notDetermined:
          return 'not_determined';
        case AuthorizationStatus.provisional:
          return 'provisional';
        default:
          return 'unknown';
      }
    } catch (e) {
      return 'error';
    }
  }
}