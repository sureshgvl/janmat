// Debug script to check FCM token storage and permissions
// Run this in debug console

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FCMTokenDebugger {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check current FCM status
  Future<void> checkFCMStatus() async {
    print('🔍 Checking FCM Status...');

    try {
      // Check current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ No user logged in');
        return;
      }

      print('👤 Current User: ${currentUser.uid}');
      print('📧 Email: ${currentUser.email}');

      // Check notification permissions
      final settings = await _fcm.getNotificationSettings();
      print('🔐 Notification Permissions:');
      print('   Authorized: ${settings.authorizationStatus == AuthorizationStatus.authorized}');
      print('   Status: ${settings.authorizationStatus}');

      // Get FCM token
      final token = await _fcm.getToken();
      print('🎫 FCM Token: ${token != null ? "Present (${token.substring(0, 20)}...)" : "NULL"}');

      if (token != null) {
        print('   Full Token: $token');
      }

      // Check if token is stored in user document
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        final storedToken = userData?['fcmToken'];
        print('💾 Stored FCM Token: ${storedToken != null ? "Present (${storedToken.substring(0, 20)}...)" : "NULL"}');

        if (storedToken != null && token != null) {
          final tokensMatch = storedToken == token;
          print('   Tokens Match: $tokensMatch');
          if (!tokensMatch) {
            print('   ❌ MISMATCH! Stored token is different from current token');
          }
        }
      } else {
        print('❌ User document does not exist');
      }

    } catch (e) {
      print('❌ Error checking FCM status: $e');
    }
  }

  // Force update FCM token
  Future<void> forceUpdateFCMToken() async {
    print('🔄 Force updating FCM token...');

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ No user logged in');
        return;
      }

      final token = await _fcm.getToken();
      if (token == null) {
        print('❌ No FCM token available');
        return;
      }

      // Update token in user document
      await _firestore.collection('users').doc(currentUser.uid).update({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });

      print('✅ FCM token updated for user: ${currentUser.uid}');
      print('   Token: ${token.substring(0, 20)}...');

    } catch (e) {
      print('❌ Error updating FCM token: $e');
    }
  }

  // Request notification permissions
  Future<void> requestPermissions() async {
    print('🔐 Requesting notification permissions...');

    try {
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print('📋 Permission Results:');
      print('   Authorized: ${settings.authorizationStatus == AuthorizationStatus.authorized}');
      print('   Alert: ${settings.alert}');
      print('   Badge: ${settings.badge}');
      print('   Sound: ${settings.sound}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ Permissions granted - FCM should work now');
        await forceUpdateFCMToken();
      } else {
        print('❌ Permissions denied - notifications will not work');
      }

    } catch (e) {
      print('❌ Error requesting permissions: $e');
    }
  }

  // Check all users with FCM tokens
  Future<void> checkAllUsersFCM() async {
    print('👥 Checking FCM tokens for all users...');

    try {
      final usersSnapshot = await _firestore.collection('users').get();

      for (var userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final userId = userDoc.id;
        final email = userData['email'] as String?;
        final role = userData['role'] as String?;
        final fcmToken = userData['fcmToken'];

        if (fcmToken != null) {
          print('✅ User $userId ($email, role: $role) has FCM token');
        } else {
          print('❌ User $userId ($email, role: $role) missing FCM token');
        }
      }

    } catch (e) {
      print('❌ Error checking all users: $e');
    }
  }

  // Test notification sending
  Future<void> testNotification(String targetUserId) async {
    print('🧪 Testing notification to user: $targetUserId');

    try {
      // Get target user's FCM token
      final userDoc = await _firestore.collection('users').doc(targetUserId).get();
      if (!userDoc.exists) {
        print('❌ Target user does not exist');
        return;
      }

      final userData = userDoc.data();
      final fcmToken = userData?['fcmToken'];

      if (fcmToken == null) {
        print('❌ Target user has no FCM token');
        return;
      }

      print('🎫 Target FCM Token: ${fcmToken.substring(0, 20)}...');

      // Send test notification via Firebase Functions
      // This would normally call your Firebase Function
      print('📤 Would send notification with payload:');
      print('   Title: "Test Notification"');
      print('   Body: "This is a test from debug script"');
      print('   Token: $fcmToken');

    } catch (e) {
      print('❌ Error testing notification: $e');
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