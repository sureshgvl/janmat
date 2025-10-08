// Debug script to check FCM token storage and permissions
// Run this in debug console

import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './utils/app_logger.dart';

class FCMTokenDebugger {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check current FCM status
  Future<void> checkFCMStatus() async {
    AppLogger.fcm('🔍 Checking FCM Status...');

    try {
      // Check current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        AppLogger.fcm('❌ No user logged in');
        return;
      }

      AppLogger.fcm('👤 Current User: ${currentUser.uid}');
      AppLogger.fcm('📧 Email: ${currentUser.email}');

      // Check notification permissions
      final settings = await _fcm.getNotificationSettings();
      AppLogger.fcm('🔐 Notification Permissions:');
      AppLogger.fcm('   Authorized: ${settings.authorizationStatus == AuthorizationStatus.authorized}');
      AppLogger.fcm('   Status: ${settings.authorizationStatus}');

      // Get FCM token
      final token = await _fcm.getToken();
      AppLogger.fcm('🎫 FCM Token: ${token != null ? "Present (${token.substring(0, 20)}...)" : "NULL"}');

      if (token != null) {
        AppLogger.fcm('   Full Token: $token');
      }

      // Check if token is stored in user document
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        final storedToken = userData?['fcmToken'];
        AppLogger.fcm('💾 Stored FCM Token: ${storedToken != null ? "Present (${storedToken.substring(0, 20)}...)" : "NULL"}');

        if (storedToken != null && token != null) {
          final tokensMatch = storedToken == token;
          AppLogger.fcm('   Tokens Match: $tokensMatch');
          if (!tokensMatch) {
            AppLogger.fcm('   ❌ MISMATCH! Stored token is different from current token');
          }
        }
      } else {
        AppLogger.fcm('❌ User document does not exist');
      }

    } catch (e) {
      AppLogger.fcmError('❌ Error checking FCM status', error: e);
    }
  }

  // Force update FCM token
  Future<void> forceUpdateFCMToken() async {
    AppLogger.fcm('🔄 Force updating FCM token...');

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        AppLogger.fcm('❌ No user logged in');
        return;
      }

      final token = await _fcm.getToken();
      if (token == null) {
        AppLogger.fcm('❌ No FCM token available');
        return;
      }

      // Update token in user document
      await _firestore.collection('users').doc(currentUser.uid).update({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });

      AppLogger.fcm('✅ FCM token updated for user: ${currentUser.uid}');
      AppLogger.fcm('   Token: ${token.substring(0, 20)}...');

    } catch (e) {
      AppLogger.fcmError('❌ Error updating FCM token', error: e);
    }
  }

  // Request notification permissions
  Future<void> requestPermissions() async {
    AppLogger.fcm('🔐 Requesting notification permissions...');

    try {
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      AppLogger.fcm('📋 Permission Results:');
      AppLogger.fcm('   Authorized: ${settings.authorizationStatus == AuthorizationStatus.authorized}');
      AppLogger.fcm('   Alert: ${settings.alert}');
      AppLogger.fcm('   Badge: ${settings.badge}');
      AppLogger.fcm('   Sound: ${settings.sound}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        AppLogger.fcm('✅ Permissions granted - FCM should work now');
        await forceUpdateFCMToken();
      } else {
        AppLogger.fcm('❌ Permissions denied - notifications will not work');
      }

    } catch (e) {
      AppLogger.fcmError('❌ Error requesting permissions', error: e);
    }
  }

  // Check all users with FCM tokens
  Future<void> checkAllUsersFCM() async {
    AppLogger.fcm('👥 Checking FCM tokens for all users...');

    try {
      final usersSnapshot = await _firestore.collection('users').get();

      for (var userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final userId = userDoc.id;
        final email = userData['email'] as String?;
        final role = userData['role'] as String?;
        final fcmToken = userData['fcmToken'];

        if (fcmToken != null) {
          AppLogger.fcm('✅ User $userId ($email, role: $role) has FCM token');
        } else {
          AppLogger.fcm('❌ User $userId ($email, role: $role) missing FCM token');
        }
      }

    } catch (e) {
      AppLogger.fcmError('❌ Error checking all users', error: e);
    }
  }

  // Test notification sending
  Future<void> testNotification(String targetUserId) async {
    AppLogger.fcm('🧪 Testing notification to user: $targetUserId');

    try {
      // Get target user's FCM token
      final userDoc = await _firestore.collection('users').doc(targetUserId).get();
      if (!userDoc.exists) {
        AppLogger.fcm('❌ Target user does not exist');
        return;
      }

      final userData = userDoc.data();
      final fcmToken = userData?['fcmToken'];

      if (fcmToken == null) {
        AppLogger.fcm('❌ Target user has no FCM token');
        return;
      }

      AppLogger.fcm('🎫 Target FCM Token: ${fcmToken.substring(0, 20)}...');

      // Send test notification via Firebase Functions
      // This would normally call your Firebase Function
      AppLogger.fcm('📤 Would send notification with payload:');
      AppLogger.fcm('   Title: "Test Notification"');
      AppLogger.fcm('   Body: "This is a test from debug script"');
      AppLogger.fcm('   Token: $fcmToken');

    } catch (e) {
      AppLogger.fcmError('❌ Error testing notification', error: e);
    }
  }
}

// Usage examples:
/*
import 'debug_fcm_token.dart';

final debugger = FCMTokenDebugger();

// 1. Check current FCM status
await debugger.checkFCMStatus();

// 2. Request permissions (if not granted)
await debugger.requestPermissions();

// 3. Force update token
await debugger.forceUpdateFCMToken();

// 4. Check all users
await debugger.checkAllUsersFCM();

// 5. Test notification to specific user
await debugger.testNotification('user_id_here');
*/
