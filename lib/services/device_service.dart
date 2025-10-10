import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_logger.dart';

class DeviceInfo {
  final String deviceId;
  final String deviceName;
  final String deviceToken;
  final String platform;
  final String appVersion;
  final DateTime lastLogin;
  final bool isActive;

  DeviceInfo({
    required this.deviceId,
    required this.deviceName,
    required this.deviceToken,
    required this.platform,
    required this.appVersion,
    required this.lastLogin,
    required this.isActive,
  });

  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'deviceToken': deviceToken,
      'platform': platform,
      'appVersion': appVersion,
      'lastLogin': Timestamp.fromDate(lastLogin),
      'isActive': isActive,
    };
  }

  factory DeviceInfo.fromMap(Map<String, dynamic> map) {
    return DeviceInfo(
      deviceId: map['deviceId'] ?? '',
      deviceName: map['deviceName'] ?? '',
      deviceToken: map['deviceToken'] ?? '',
      platform: map['platform'] ?? '',
      appVersion: map['appVersion'] ?? '',
      lastLogin: (map['lastLogin'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? false,
    );
  }
}

class DeviceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  // Get unique device identifier
  Future<String> getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        return androidInfo.id ?? 'unknown_android_device';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown_ios_device';
      } else {
        return 'unknown_device_${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (e) {
      return 'fallback_device_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  // Get device name for display
  Future<String> getDeviceName() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        return '${androidInfo.brand} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        return iosInfo.name ?? 'iOS Device';
      } else {
        return 'Unknown Device';
      }
    } catch (e) {
      return 'Unknown Device';
    }
  }

  // Get FCM device token
  Future<String?> getDeviceToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      return null;
    }
  }

  // Get platform name
  String getPlatform() {
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    return 'Unknown';
  }

  // Get app version (you can pass this from main.dart or use package_info_plus)
  String getAppVersion() {
    return '1.0.0'; // Update this based on your app version
  }

  // Register device on login
  Future<void> registerDevice(String userId) async {
    try {
      final deviceId = await getDeviceId();
      final deviceName = await getDeviceName();
      final deviceToken = await getDeviceToken();
      final platform = getPlatform();
      final appVersion = getAppVersion();

      final deviceInfo = DeviceInfo(
        deviceId: deviceId,
        deviceName: deviceName,
        deviceToken: deviceToken ?? '',
        platform: platform,
        appVersion: appVersion,
        lastLogin: DateTime.now(),
        isActive: true,
      );

      // First, deactivate all other devices for this user
      await _deactivateOtherDevices(userId, deviceId);

      // Register current device
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('devices')
          .doc(deviceId)
          .set(deviceInfo.toMap());

      // Send sign-out notifications to other devices
      await _notifyOtherDevicesSignOut(userId, deviceId);
    } catch (e) {
      AppLogger.commonError('Error registering device', error: e);
      throw Exception('Failed to register device');
    }
  }

  // Deactivate all other devices
  Future<void> _deactivateOtherDevices(
    String userId,
    String currentDeviceId,
  ) async {
    try {
      final devicesRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('devices');

      final querySnapshot = await devicesRef
          .where('isActive', isEqualTo: true)
          .get();

      final batch = _firestore.batch();

      for (var doc in querySnapshot.docs) {
        if (doc.id != currentDeviceId) {
          batch.update(doc.reference, {'isActive': false});
        }
      }

      await batch.commit();
    } catch (e) {
      AppLogger.common('Error deactivating other devices: $e');
    }
  }

  // Send sign-out notifications to other devices
  Future<void> _notifyOtherDevicesSignOut(
    String userId,
    String currentDeviceId,
  ) async {
    try {
      final devicesRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('devices');

      // Get all inactive devices first, then filter by deviceToken in code
      // This avoids the compound query that requires an index
      final querySnapshot = await devicesRef
          .where('isActive', isEqualTo: false)
          .get();

      for (var doc in querySnapshot.docs) {
        if (doc.id != currentDeviceId) {
          final deviceToken = doc.data()['deviceToken'] as String?;
          if (deviceToken != null && deviceToken.isNotEmpty) {
            await _sendSignOutNotification(deviceToken);
          }
        }
      }
    } catch (e) {
      AppLogger.common('Error sending sign-out notifications: $e');
    }
  }

  // Send FCM notification to sign out device
  Future<void> _sendSignOutNotification(String deviceToken) async {
    try {
      // Note: In a real implementation, you'd send this via your backend
      // For now, we'll just print the token for demonstration
      AppLogger.common('Would send sign-out notification to device: $deviceToken');

      // You can implement FCM message sending here or via cloud functions
      // Example:
      /*
      await FirebaseFunctions.instance
          .httpsCallable('sendSignOutNotification')
          .call({
            'deviceToken': deviceToken,
            'message': 'You have been signed out due to login from another device'
          });
      */
    } catch (e) {
      AppLogger.common('Error sending FCM notification: $e');
    }
  }

  // Check if current device is still active
  Future<bool> isDeviceActive(String userId) async {
    try {
      final deviceId = await getDeviceId();
      final deviceDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('devices')
          .doc(deviceId)
          .get();

      if (deviceDoc.exists) {
        final deviceData = deviceDoc.data();
        return deviceData?['isActive'] ?? false;
      }

      return false;
    } catch (e) {
      AppLogger.common('Error checking device status: $e');
      return false;
    }
  }

  // Get all devices for a user
  Future<List<DeviceInfo>> getUserDevices(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('devices')
          .orderBy('lastLogin', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => DeviceInfo.fromMap(doc.data()))
          .toList();
    } catch (e) {
      AppLogger.common('Error getting user devices: $e');
      return [];
    }
  }

  // Sign out from specific device
  Future<void> signOutDevice(String userId, String deviceId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('devices')
          .doc(deviceId)
          .update({'isActive': false});

      // Send sign-out notification
      final deviceDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('devices')
          .doc(deviceId)
          .get();

      if (deviceDoc.exists) {
        final deviceToken = deviceDoc.data()?['deviceToken'] as String?;
        if (deviceToken != null && deviceToken.isNotEmpty) {
          await _sendSignOutNotification(deviceToken);
        }
      }
    } catch (e) {
      AppLogger.common('Error signing out device: $e');
      throw Exception('Failed to sign out device');
    }
  }

  // Monitor device status changes (call this when user logs in)
  void monitorDeviceStatus(String userId, Function onSignOutRequired) {
    getDeviceId().then((currentDeviceId) {
      AppLogger.common('📱 Starting device monitoring for device: $currentDeviceId');

      // Add a delay to ensure device registration is complete
      Future.delayed(const Duration(seconds: 2), () {
        _firestore
            .collection('users')
            .doc(userId)
            .collection('devices')
            .doc(currentDeviceId)
            .snapshots()
            .listen((snapshot) {
              AppLogger.common('📱 Device status update received');

              if (!snapshot.exists) {
                AppLogger.common('⚠️ Device document does not exist - checking network connectivity before sign out');
                // Check if this is due to network issues before forcing sign out
                _checkNetworkBeforeSignOut(onSignOutRequired);
                return;
              }

              final deviceData = snapshot.data();
              final isActive = deviceData?['isActive'] ?? false;

              AppLogger.common('📱 Device active status: $isActive');

              if (!isActive) {
                AppLogger.common('🚪 Device marked as inactive - checking network before sign out');
                // Add network check before forcing sign out to avoid false positives
                _checkNetworkBeforeSignOut(onSignOutRequired);
              }
            }, onError: (error) {
              AppLogger.common('❌ Error monitoring device status: $error');
              // Don't force sign out on monitoring errors to avoid false positives
              // Network issues can cause temporary monitoring failures
            });
      });
    }).catchError((error) {
      AppLogger.common('❌ Failed to get device ID for monitoring: $error');
      // Don't force sign out if we can't get device ID
    });
  }

  // Check network connectivity before forcing sign out to avoid false positives
  Future<void> _checkNetworkBeforeSignOut(Function onSignOutRequired) async {
    try {
      // Wait a bit and check connectivity
      await Future.delayed(const Duration(seconds: 3));

      // Simple connectivity check - try to read the device document again
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        AppLogger.common('⚠️ No current user - forcing sign out');
        onSignOutRequired();
        return;
      }

      final deviceId = await getDeviceId();
      final deviceDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('devices')
          .doc(deviceId)
          .get()
          .timeout(const Duration(seconds: 10));

      if (!deviceDoc.exists) {
        AppLogger.common('⚠️ Device document still does not exist after network check - forcing sign out');
        onSignOutRequired();
        return;
      }

      final deviceData = deviceDoc.data();
      final isActive = deviceData?['isActive'] ?? false;

      if (!isActive) {
        AppLogger.common('🚪 Device still inactive after network check - forcing sign out');
        onSignOutRequired();
      } else {
        AppLogger.common('✅ Device is active after network check - not signing out');
      }
    } catch (error) {
      AppLogger.common('⚠️ Network check failed: $error - not forcing sign out to avoid false positives');
      // If network check fails, don't force sign out to avoid false positives
    }
  }

  // Clean up inactive devices (optional maintenance function)
  Future<void> cleanupInactiveDevices(
    String userId, {
    Duration maxAge = const Duration(days: 30),
  }) async {
    try {
      final cutoffDate = DateTime.now().subtract(maxAge);

      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('devices')
          .where('isActive', isEqualTo: false)
          .where('lastLogin', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();

      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      AppLogger.common('Error cleaning up inactive devices: $e');
    }
  }
}
