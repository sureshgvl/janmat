import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as https from 'https';

// Initialize Firebase Admin - let it auto-discover credentials
admin.initializeApp();

// Note: Using Firebase Admin SDK with FCM V1 API - no server key needed
// The Admin SDK handles authentication automatically via service account

// Test function to check Firebase Admin SDK
export const testFirebaseAdmin = functions.https.onCall(async (data, context) => {
  try {
    console.log('🧪 Testing Firebase Admin SDK...');

    // Test basic Admin SDK functionality
    const testMessage = {
      notification: {
        title: 'Test Notification',
        body: 'This is a test from Firebase Functions',
      },
      data: {
        test: 'true',
        timestamp: Date.now().toString(),
      },
      token: 'test-token', // This will fail but we'll see the error
    };

    console.log('📤 Attempting to send test message...');
    const result = await admin.messaging().send(testMessage);

    return {
      success: true,
      message: 'Firebase Admin SDK is working',
      result: result,
    };
  } catch (error: any) {
    console.error('❌ Firebase Admin SDK test failed:', error);
    return {
      success: false,
      error: error.message,
      code: error.code,
      details: JSON.stringify(error, null, 2),
    };
  }
});

// Send push notification
export const sendPushNotification = functions.https.onCall(async (data, context) => {
  try {
    const { token, title, body, notificationData } = data;

    console.log('📨 SendPushNotification called with:', { token: token?.substring(0, 20) + '...', title, body });

    if (!token) {
      throw new functions.https.HttpsError('invalid-argument', 'FCM token is required');
    }

    if (!title || !body) {
      throw new functions.https.HttpsError('invalid-argument', 'Title and body are required');
    }

    // Create notification payload for Admin SDK
    const payload = {
      notification: {
        title: title,
        body: body,
        clickAction: 'FLUTTER_NOTIFICATION_CLICK',
      },
      data: {
        ...notificationData,
        timestamp: Date.now().toString(),
      },
      token: token, // Use token instead of to
    };

    console.log('🔧 Using payload for Admin SDK:', JSON.stringify(payload, null, 2));

    // Send via Firebase Admin SDK (FCM V1 API)
    console.log('🚀 Sending via Firebase Admin SDK (FCM V1 API)...');
    console.log('📦 Payload:', JSON.stringify(payload, null, 2));

    try {
      const response = await admin.messaging().send(payload);
      console.log('✅ Push notification sent successfully via Admin SDK:', response);
      return {
        success: true,
        messageId: response,
        method: 'admin_sdk',
      };
    } catch (adminError: any) {
      console.error('❌ Admin SDK error:', adminError);
      console.error('❌ Error code:', adminError?.code);
      console.error('❌ Error message:', adminError?.message);

      // Check specific error types
      if (adminError?.code === 'messaging/authentication-error') {
        console.error('❌ Authentication error - Firebase project configuration issue');
      } else if (adminError?.code === 'messaging/invalid-argument') {
        console.error('❌ Invalid argument - payload format issue');
      } else if (adminError?.code === 'messaging/invalid-registration-token') {
        console.error('❌ Invalid FCM token provided');
      } else if (adminError?.code === 'messaging/registration-token-not-registered') {
        console.error('❌ FCM token not registered - user may have uninstalled app');
      }

      throw adminError;
    }
  } catch (error) {
    console.error('❌ Error sending push notification:', error);
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    throw new functions.https.HttpsError('internal', `Failed to send push notification: ${errorMessage}`);
  }
});

// Send push notification to multiple tokens
export const sendPushNotificationToMultiple = functions.https.onCall(async (data, context) => {
  try {
    const { tokens, title, body, notificationData } = data;

    if (!tokens || !Array.isArray(tokens) || tokens.length === 0) {
      throw new functions.https.HttpsError('invalid-argument', 'Tokens array is required');
    }

    if (!title || !body) {
      throw new functions.https.HttpsError('invalid-argument', 'Title and body are required');
    }

    // Create notification payload
    const payload = {
      notification: {
        title: title,
        body: body,
        clickAction: 'FLUTTER_NOTIFICATION_CLICK',
      },
      data: {
        ...notificationData,
        timestamp: Date.now().toString(),
      },
    };

    // Send notification to multiple tokens
    const response = await admin.messaging().sendToDevice(tokens, payload);

    console.log('✅ Push notifications sent successfully to', tokens.length, 'tokens');

    return {
      success: true,
      messageId: response,
      tokensCount: tokens.length,
    };
  } catch (error) {
    console.error('❌ Error sending push notifications to multiple tokens:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send push notifications');
  }
});

// Subscribe user to topic
export const subscribeToTopic = functions.https.onCall(async (data, context) => {
  try {
    const { tokens, topic } = data;

    if (!tokens || !Array.isArray(tokens) || tokens.length === 0) {
      throw new functions.https.HttpsError('invalid-argument', 'Tokens array is required');
    }

    if (!topic) {
      throw new functions.https.HttpsError('invalid-argument', 'Topic is required');
    }

    // Subscribe tokens to topic
    await admin.messaging().subscribeToTopic(tokens, topic);

    console.log('✅ Subscribed', tokens.length, 'tokens to topic:', topic);

    return {
      success: true,
      tokensCount: tokens.length,
    };
  } catch (error) {
    console.error('❌ Error subscribing to topic:', error);
    throw new functions.https.HttpsError('internal', 'Failed to subscribe to topic');
  }
});

// Unsubscribe user from topic
export const unsubscribeFromTopic = functions.https.onCall(async (data, context) => {
  try {
    const { tokens, topic } = data;

    if (!tokens || !Array.isArray(tokens) || tokens.length === 0) {
      throw new functions.https.HttpsError('invalid-argument', 'Tokens array is required');
    }

    if (!topic) {
      throw new functions.https.HttpsError('invalid-argument', 'Topic is required');
    }

    // Unsubscribe tokens from topic
    await admin.messaging().unsubscribeFromTopic(tokens, topic);

    console.log('✅ Unsubscribed', tokens.length, 'tokens from topic:', topic);

    return {
      success: true,
      tokensCount: tokens.length,
    };
  } catch (error) {
    console.error('❌ Error unsubscribing from topic:', error);
    throw new functions.https.HttpsError('internal', 'Failed to unsubscribe from topic');
  }
});

// Send notification to topic
export const sendNotificationToTopic = functions.https.onCall(async (data, context) => {
  try {
    const { topic, title, body, notificationData } = data;

    if (!topic) {
      throw new functions.https.HttpsError('invalid-argument', 'Topic is required');
    }

    if (!title || !body) {
      throw new functions.https.HttpsError('invalid-argument', 'Title and body are required');
    }

    // Create notification payload
    const payload = {
      notification: {
        title: title,
        body: body,
        clickAction: 'FLUTTER_NOTIFICATION_CLICK',
      },
      data: {
        ...notificationData,
        timestamp: Date.now().toString(),
      },
    };

    // Send notification to topic
    const response = await admin.messaging().sendToTopic(topic, payload);

    console.log('✅ Topic notification sent successfully to topic:', topic);

    return {
      success: true,
      messageId: response.messageId,
    };
  } catch (error) {
    console.error('❌ Error sending topic notification:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send topic notification');
  }
});

// Update user FCM token when it changes
export const updateUserFCMToken = functions.firestore
  .document('users/{userId}')
  .onUpdate(async (change, context) => {
    try {
      const newData = change.after.data();
      const oldData = change.before.data();

      const newToken = newData?.fcmToken;
      const oldToken = oldData?.fcmToken;

      // If token changed, update all subscriptions
      if (newToken && newToken !== oldToken) {
        console.log('🔄 FCM token updated for user:', context.params.userId);

        // You could update topic subscriptions here if needed
        // For now, we'll just log the change

        return {
          success: true,
          message: 'Token updated successfully',
        };
      }

      return null;
    } catch (error) {
      console.error('❌ Error updating user FCM token:', error);
      return null;
    }
  });
